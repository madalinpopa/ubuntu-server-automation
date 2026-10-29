#!/usr/bin/env bash
# Integration test in disposable Lima VMs (macOS or Linux with Lima 2.x).
#
# For each Ubuntu release it:
#   1. creates a fresh VM
#   2. runs playbooks/site.yml (base + Docker + Caddy + all optional
#      services, with fake .test domains and Caddy's local certificates)
#   3. runs it again and fails if anything changed (idempotency)
#   4. starts a test container published with "-p 8080:8080"
#   5. runs playbooks/verify.yml on the VM (includes the service containers
#      and the Caddy sites)
#   6. runs playbooks/verify_external.yml from this computer against the
#      VM's shared network address (vzNAT, 192.168.64.x): closed service
#      ports and the service sites over HTTPS
#   7. deletes the VM (set KEEP_VMS=1 to keep it)
#
# Usage:   tests/run.sh [24.04] [26.04]      (default: both)
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
  if [ "${KEEP_VMS:-0}" = "1" ]; then
    echo "KEEP_VMS=1: leaving VMs running: ${VMS[*]}"
  else
    echo "== Deleting VMs: ${VMS[*]}"
    limactl delete -f "${VMS[@]}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Fail unless every host in the PLAY RECAP has changed=0, failed=0, unreachable=0.
check_recap() {
  local log=$1 want_changed=$2 bad
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

# 2. First run.
run_playbook site-run1 playbooks/site.yml
check_recap "$LOG_DIR/site-run1.log" any

# 3. Second run must change nothing.
run_playbook site-run2 playbooks/site.yml
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
  check_recap "$log" 0
done
echo "OK: verify_external.yml passed"

echo "== All tests passed for Ubuntu ${VERSIONS[*]}"
