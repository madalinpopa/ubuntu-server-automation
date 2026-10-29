# Run the tests in Lima VMs

The test script `tests/run.sh` checks the playbooks on real Ubuntu virtual machines, not on your server. It needs a real VM because the risky parts, such as SSH socket activation, the firewall, Docker's network rules and fail2ban, only behave correctly with a full systemd system.

[Lima](https://lima-vm.io/) creates Linux VMs from the command line. The script was written and run on macOS on Apple Silicon. Lima also runs on Linux, but the script has not been tried there.

## What the script does

For each Ubuntu release (24.04 and 26.04 by default) it:

1. creates a fresh VM,
2. allows SSH key login as root, like on a fresh VPS, and runs `playbooks/site.yml` as root with Docker, Caddy and all seven services turned on, using fake `.test` domains and Caddy's local certificates, and checks in the log that each app's Caddy site was written only after its admin account was set up,
3. checks that root can no longer log in, then runs `site.yml` again as Lima's normal user and fails if anything changed (the idempotency check),
4. starts a test container published with `-p 8080:8080`, to prove Docker keeps it on 127.0.0.1,
5. runs `playbooks/verify.yml` on the VM,
6. runs `playbooks/verify_external.yml` from your computer against the VM's own network address,
7. deletes the VM.

The test settings are in `tests/vars.yml`. They use Lima's SSH key as the admin key and throwaway passwords. Never use that file for a real server. `tests/inventory.yml` reads the SSH settings Lima writes for each VM.

## Prerequisites

- Lima 2.x: `brew install lima` on macOS. Check with `limactl --version`.
- About 4 GB of free RAM (two VMs with 2 GB each) and a few GB of disk for the images.
- The control machine set up as in the [tutorial](../tutorial-first-vps.md#step-3-prepare-your-control-machine): virtual environment, `requirements.txt` and `requirements.yml` installed.
- On macOS, your terminal app may need the **Local Network** permission (System Settings > Privacy & Security > Local Network). Step 6 connects to the VM's address in `192.168.64.x`, and without it you get "No route to host".

## Run the tests

From the repository folder:

```bash
. .venv/bin/activate
tests/run.sh
```

Test only one release:

```bash
tests/run.sh 24.04
tests/run.sh 26.04
```

Keep the VMs afterwards so you can log in and look around:

```bash
KEEP_VMS=1 tests/run.sh 24.04
limactl shell ust-noble
```

The VMs are called `ust-noble` (24.04) and `ust-resolute` (26.04). Delete them when you are done:

```bash
limactl delete -f ust-noble ust-resolute
```

For a first run as Lima's normal user (with passwordless sudo) instead of root:

```bash
FIRST_RUN_AS_ROOT=0 tests/run.sh
```

## Expected result

A full run took about 6 minutes once the Ubuntu images were cached. The output ends with:

```
OK: first run as root finished and root login is now refused
OK: second run changed nothing
OK: verify.yml passed
OK: verify_external.yml passed
== All tests passed for Ubuntu 24.04 26.04
```

Each step writes its full Ansible output to `tests/logs/`, for example `tests/logs/site-run1.log`. When a step fails, the script prints the last 30 lines of its log and stops.

## Common problems

| Problem | Fix |
|---|---|
| `ansible-playbook: command not found` | Activate the virtual environment: `. .venv/bin/activate` |
| `couldn't resolve module/action 'community.docker...'` | Install the collections: `ansible-galaxy collection install -r requirements.yml` |
| External checks fail with "No route to host" | Give your terminal the Local Network permission (macOS), or check that the VM has a `lima0` interface |
| `CERTIFICATE_VERIFY_FAILED` when installing collections | On python.org builds for macOS run "Install Certificates.command" |
| A VM with the same name exists | The script deletes old `ust-noble` and `ust-resolute` VMs before it starts |

## Use a VM to practise the tutorial

You can create a VM by hand and follow the [tutorial](../tutorial-first-vps.md) against it before you touch a real server:

```bash
limactl start --name=practice --vm-type=vz --network=vzNAT template:ubuntu-24.04
limactl shell practice ip -4 addr show lima0
```

The second command shows the VM's address on the `192.168.64.x` network. Lima logs in with its own key, `~/.lima/_config/user`, as a user with the same name as your local user and with passwordless sudo. In your inventory use:

```yaml
all:
  hosts:
    practice:
      ansible_host: 192.168.64.2          # the address from the command above
      ansible_user: yourname              # your local user name
      ansible_ssh_private_key_file: ~/.lima/_config/user
      admin_ssh_keys:
        - "paste the content of ~/.lima/_config/user.pub here"
```

For `playbooks/verify_external.yml`, pass the key to its `ssh` command too: `-e '{"verify_external_ssh_args": ["-i", "~/.lima/_config/user"]}'`. On Ubuntu 24.04, Lima's own connection (`limactl shell`) goes through the VM's SSH port, so a firewall mistake also cuts off `limactl shell`. That is a good way to practise recovery.

## What the tests cover, and what they do not

Covered on Ubuntu 24.04 and 26.04 (arm64): a first run as root that finishes in one go and leaves root login turned off, the base setup, Docker, Caddy, all seven services, a second run with `changed=0`, all checks in `verify.yml` and `verify_external.yml`, and `become` with a sudo password on 24.04 and on 26.04 with `sudo.ws`.

Not covered yet:

- amd64 (x86_64) servers. Only arm64 VMs were tested.
- Real domains with Let's Encrypt certificates. The tests use Caddy's local certificate authority.
- Reboots.
- Upgrading from an older version of this project, including old container names, volumes and port 2222.
- PostgreSQL major upgrades, the full restore steps in [Back up and restore data](backup-restore.md), and changing passwords in the vault after the first run.
- App features beyond logging in and the health check, such as pushing to Gitea or running a playbook in Semaphore.
- UDP ports. `verify.yml` checks TCP listeners only.

## Lint and syntax checks

These run without a VM and take seconds:

```bash
ansible-lint
for p in playbooks/*.yml; do ansible-playbook -i inventory/hosts.example.yml --syntax-check "$p"; done
```

`ansible-lint` should end with `Passed: 0 failure(s), 0 warning(s)`. `--syntax-check` only parses each playbook. It does not connect to any server.
