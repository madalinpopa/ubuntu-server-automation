#!/usr/bin/env bash
# Integration test in disposable Lima VMs (macOS or Linux with Lima 2.x).
#
# For each Ubuntu release it:
#   1. creates a fresh VM
#   2. turns on SSH key login for root, like on a fresh VPS, and runs
#      playbooks/site.yml as root (base + Docker + Caddy + all optional
#      services, with fake .test domains and Caddy's local certificates),
#      and checks that each app's Caddy site came after its admin account
#   3. checks that root can no longer log in, then runs site.yml again as
#      the admin user with its sudo password, like the day-2 workflow
#      (sudo.ws on 26.04), and fails if anything changed (idempotency)
#   4. starts a test container published with "-p 8080:8080"
#   5. runs playbooks/verify.yml on the VM (includes the service containers
#      and the Caddy sites)
#   6. runs playbooks/verify_external.yml from this computer against the
#      VM's shared network address (vzNAT, 192.168.64.x): closed service
#      ports and the service sites over HTTPS
#   7. makes failed SSH logins from this computer until fail2ban bans its
#      address, checks the ban, then lifts it
#   8. deletes the VM (set KEEP_VMS=1 to keep it)
#
# Usage:   tests/run.sh [24.04] [26.04]      (default: both)
#          FIRST_RUN_AS_ROOT=0 tests/run.sh   first run as Lima's user instead
# Needs:   limactl, ansible-playbook (see requirements.txt), collections
#          from requirements.yml. On macOS the terminal app may need the
#          "Local Network" permission to reach 192.168.64.x.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSIONS=("$@")
if [ ${#VERSIONS[@]} -eq 0 ]; then
  VERSIONS=(24.04 26.04)
fi

LOG_DIR=tests/logs
mkdir -p "$LOG_DIR"
INVENTORY=tests/inventory.yml
TEST_VARS=tests/vars.yml
SSH_KEY="$HOME/.lima/_config/user"
# admin_user from inventory/group_vars/all/vars.yml, and the throwaway sudo
# password whose hash is in tests/vars.yml.
ADMIN_USER=sysadmin
BECOME_PASS_FILE=$(mktemp)
chmod 600 "$BECOME_PASS_FILE"
printf '%s\n' 'lima-test-password' >"$BECOME_PASS_FILE"

vm_name() {
  case "$1" in
    24.04) echo ust-noble ;;
    26.04) echo ust-resolute ;;
    *) echo "Unsupported Ubuntu version: $1" >&2; exit 2 ;;
  esac
}

VMS=()
HOSTS=()
for v in "${VERSIONS[@]}"; do
  VMS+=("$(vm_name "$v")")
  HOSTS+=("lima-$(vm_name "$v")")
done
LIMIT=$(IFS=,; echo "${HOSTS[*]}")

cleanup() {
  rm -f "$BECOME_PASS_FILE"
  if [ "${KEEP_VMS:-0}" = "1" ]; then
    echo "KEEP_VMS=1: leaving VMs running: ${VMS[*]}"
  else
    echo "== Deleting VMs: ${VMS[*]}"
    limactl delete -f "${VMS[@]}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Fail unless the PLAY RECAP has one line per host (default: every test
# host) and every line has failed=0 and unreachable=0. With want_changed=0,
# every line must also have changed=0.
check_recap() {
  local log=$1 want_changed=$2 want_hosts=${3:-${#HOSTS[@]}} found bad
  found=$(grep -cE '^lima-[a-z-]+ +: ok=' "$log" || true)
  if [ "$found" -ne "$want_hosts" ]; then
    echo "FAIL: expected $want_hosts host(s) in the PLAY RECAP of $log, found $found"; return 1
  fi
  bad=$(grep -E '^lima-[a-z-]+ +: ok=' "$log" | grep -vE "changed=0 .*unreachable=0 +failed=0" || true)
  if [ "$want_changed" = "0" ] && [ -n "$bad" ]; then
    echo "FAIL: not idempotent or failed. Recap lines:"; echo "$bad"; return 1
  fi
  if grep -qE 'unreachable=[1-9]|failed=[1-9]' "$log"; then
    echo "FAIL: see $log"; grep -E '^lima-[a-z-]+ +: ok=' "$log"; return 1
  fi
  grep -E '^lima-[a-z-]+ +: ok=' "$log"
}

run_playbook() {
  local name=$1; shift
  local log="$LOG_DIR/$name.log"
  echo "== ansible-playbook $* (log: $log)"
  if ! ansible-playbook -i "$INVENTORY" -e "@$TEST_VARS" -l "$LIMIT" "$@" >"$log" 2>&1; then
    echo "FAIL: ansible-playbook $*"; tail -30 "$log"; return 1
  fi
}

# 1. Create the VMs one at a time. Starting two at once on a fresh
#    machine can race while Lima creates its SSH key.
for i in "${!VMS[@]}"; do
  vm=${VMS[$i]}
  if limactl list -q 2>/dev/null | grep -qx "$vm"; then
    echo "== Removing old test VM $vm"
    limactl delete -f "$vm" >/dev/null 2>&1
  fi
  echo "== Creating $vm (Ubuntu ${VERSIONS[$i]})"
  limactl start --name="$vm" --tty=false --vm-type=vz --network=vzNAT \
    --mount-none --containerd=none --cpus=2 --memory=2 \
    "template:ubuntu-${VERSIONS[$i]}" >"$LOG_DIR/limactl-$vm.log" 2>&1
done

# Try a new SSH login (no shared connection) and run "true".
vm_ssh() {
  local vm=$1; shift
  ssh -F "$HOME/.lima/$vm/ssh.config" -o ControlPath=none -o BatchMode=yes "$@" "lima-$vm" true
}

# 2. First run. By default it connects as root, like on a fresh VPS.
#    Lima's images do not allow root login, so copy Lima's key to root.
FIRST_RUN_ARGS=()
if [ "${FIRST_RUN_AS_ROOT:-1}" = "1" ]; then
  for vm in "${VMS[@]}"; do
    echo "== Allowing SSH key login as root on $vm"
    ssh -F "$HOME/.lima/$vm/ssh.config" "lima-$vm" \
      "sudo install -d -m 0700 /root/.ssh && sudo install -m 0600 ~/.ssh/authorized_keys /root/.ssh/authorized_keys"
    vm_ssh "$vm" -l root || { echo "FAIL: root cannot log in to $vm before the test"; exit 1; }
  done
  FIRST_RUN_ARGS=(-u root)
fi
run_playbook site-run1 ${FIRST_RUN_ARGS[@]+"${FIRST_RUN_ARGS[@]}"} playbooks/site.yml
check_recap "$LOG_DIR/site-run1.log" any

# A fresh app must be secured before Caddy publishes it. Each service writes
# its Caddy site file as its last task, so that task must come later.
check_before() {
  local log=$1 first=$2 second=$3 a b
  a=$(grep -n -m1 -F "TASK [$first]" "$log" | cut -d: -f1)
  b=$(grep -n -m1 -F "TASK [$second]" "$log" | cut -d: -f1)
  if [ -z "$a" ] || [ -z "$b" ] || [ "$a" -ge "$b" ]; then
    echo "FAIL: '$second' must run after '$first' (see $log)"; return 1
  fi
}
check_before "$LOG_DIR/site-run1.log" "Create the Gitea admin user" "Write the Caddy site for gitea"
check_before "$LOG_DIR/site-run1.log" "Replace the default Umami admin password" "Write the Caddy site for umami"
check_before "$LOG_DIR/site-run1.log" "Create the Memos admin account" "Write the Caddy site for memos"
check_before "$LOG_DIR/site-run1.log" "Create the ntfy admin user" "Write the Caddy site for ntfy"
echo "OK: each service site was published after its admin account was set up"

if [ "${FIRST_RUN_AS_ROOT:-1}" = "1" ]; then
  for vm in "${VMS[@]}"; do
    if vm_ssh "$vm" -l root 2>/dev/null; then
      echo "FAIL: root can still log in to $vm"; exit 1
    fi
  done
  echo "OK: first run as root finished and root login is now refused"
fi

# 3. Second run must change nothing. It connects as the admin user and
#    uses its sudo password, as described in the README. On 26.04 the
#    inventory sets test_admin_become_exe to sudo.ws, because Ansible
#    does not recognise the password prompt of sudo-rs yet.
run_playbook site-run2 -u "$ADMIN_USER" --become-password-file "$BECOME_PASS_FILE" \
  -e 'ansible_become_exe={{test_admin_become_exe}}' playbooks/site.yml
check_recap "$LOG_DIR/site-run2.log" 0
echo "OK: second run changed nothing"

# 4. A container published without an address must bind to 127.0.0.1 only.
echo "== Starting a test container with -p 8080:8080"
ansible -i "$INVENTORY" -e "@$TEST_VARS" "$LIMIT" -b -m ansible.builtin.command \
  -a "docker run -d --name porttest -p 8080:8080 busybox:1.37 httpd -f -p 8080" \
  >"$LOG_DIR/porttest.log" 2>&1 || { echo "FAIL: could not start test container"; cat "$LOG_DIR/porttest.log"; exit 1; }

# 5. On-host verification.
run_playbook verify playbooks/verify.yml
check_recap "$LOG_DIR/verify.log" 0
echo "OK: verify.yml passed"

# 6. External checks from this computer, one VM at a time.
for vm in "${VMS[@]}"; do
  ip=$(ssh -F "$HOME/.lima/$vm/ssh.config" "lima-$vm" \
    "ip -4 -o addr show lima0 | awk '{print \$4}' | cut -d/ -f1")
  echo "== External checks for $vm at $ip"
  log="$LOG_DIR/verify-external-$vm.log"
  if ! ansible-playbook -i "$INVENTORY" -e "@$TEST_VARS" -l "lima-$vm" \
      -e "verify_external_address=$ip" \
      -e "{\"verify_external_ssh_args\": [\"-i\", \"$SSH_KEY\", \"-o\", \"IdentitiesOnly=yes\", \"-o\", \"StrictHostKeyChecking=no\", \"-o\", \"UserKnownHostsFile=/dev/null\"]}" \
      playbooks/verify_external.yml >"$log" 2>&1; then
    echo "FAIL: verify_external.yml for $vm"; tail -30 "$log"; exit 1
  fi
  check_recap "$log" 0 1
done
echo "OK: verify_external.yml passed"

# 7. fail2ban: failed SSH logins from this computer must get its address
#    banned. A user that does not exist fails at once ("Invalid user").
#    Lima's own connection is not affected: it comes from 192.168.5.2 on
#    24.04 and over vsock on 26.04.
for vm in "${VMS[@]}"; do
  ip=$(ssh -F "$HOME/.lima/$vm/ssh.config" "lima-$vm" \
    "ip -4 -o addr show lima0 | awk '{print \$4}' | cut -d/ -f1")
  echo "== fail2ban check for $vm at $ip"
  for _ in 1 2 3 4 5 6 7 8; do
    ssh -o BatchMode=yes -o ConnectTimeout=5 -o IdentitiesOnly=yes -o IdentityFile=/dev/null \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "no-such-user@$ip" true >/dev/null 2>&1 || true
  done
  banned=""
  for _ in $(seq 1 15); do
    banned=$(ssh -F "$HOME/.lima/$vm/ssh.config" "lima-$vm" \
      "sudo fail2ban-client get sshd banned" 2>/dev/null || true)
    case "$banned" in *192.168.64.*) break ;; esac
    sleep 2
  done
  case "$banned" in
    *192.168.64.*) echo "OK: fail2ban banned $banned on $vm" ;;
    *) echo "FAIL: fail2ban did not ban this computer on $vm (banned: $banned)"; exit 1 ;;
  esac
  ssh -F "$HOME/.lima/$vm/ssh.config" "lima-$vm" "sudo fail2ban-client unban --all" >/dev/null
done
echo "OK: fail2ban bans after failed logins"

echo "== All tests passed for Ubuntu ${VERSIONS[*]}"
