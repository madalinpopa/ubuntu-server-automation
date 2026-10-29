# Ubuntu Server Automation with Ansible

This repository sets up a fresh Ubuntu server (a VPS or a local machine) with Ansible. It creates an admin user, locks SSH down to key login, turns on the firewall and automatic security updates, and can optionally install Docker, Caddy and a few self-hosted apps.

I first built it as a hands-on workshop for [OmniOpenCon 2024](https://omniopencon.org/). Back then the README walked you through building your own Ansible project step by step. The project is now a complete, tested set of playbooks that you can run as it is, and the docs still explain every step for people who are learning.

## What it does

The base setup always runs. Everything else is off until you turn it on.

| Part | Default | What it does |
|---|---|---|
| Base | always | Checks the server first, installs a few packages, keeps automatic security updates on, creates an admin user with your SSH key and a sudo password, disables root and password login over SSH, enables the UFW firewall |
| fail2ban | on | Bans IP addresses that fail SSH login many times |
| Docker | off | Docker Engine from Docker's official repository. Published ports stay on 127.0.0.1 by default |
| Caddy | off | Web server and reverse proxy with automatic HTTPS. Opens ports 80 and 443 |
| Services | off | PostgreSQL, pgAdmin, Gitea, Umami, Semaphore UI, Memos and ntfy, each one separately, all in Docker behind Caddy |

## Requirements

- A server running **Ubuntu 24.04 LTS or 26.04 LTS** that you can reach over SSH with a key, as root or as a user with sudo.
- Console access from your provider (a web console, VNC or serial). This is your way back in if SSH stops working.
- A control machine: the computer where you run Ansible. Linux, macOS, or Windows with WSL.
- Python 3.12, 3.13 or 3.14 on the control machine. ansible-core 2.21 supports only these versions.
- For HTTPS: a domain name with DNS records that point to the server.

## Quick start

If you have never done this before, follow the [tutorial](docs/tutorial-first-vps.md) instead. It explains each step and what to expect.

```bash
# 1. Get the code and install Ansible in a virtual environment
git clone https://github.com/madalinpopa/ubuntu-server-automation.git
cd ubuntu-server-automation
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml

# 2. Describe your server: set ansible_host, ansible_user and admin_ssh_keys
cp inventory/hosts.example.yml inventory/hosts.yml
vim inventory/hosts.yml

# 3. Store the admin password hash in an encrypted vault file
openssl passwd -6          # copy the $6$... line it prints
# macOS's own openssl (LibreSSL) has no -6. Use Homebrew's OpenSSL instead:
#   $(brew --prefix openssl)/bin/openssl passwd -6
# or run it on the server: ssh -t root@SERVER openssl passwd -6
cp inventory/vault.example.yml inventory/group_vars/all/vault.yml
vim inventory/group_vars/all/vault.yml
ansible-vault encrypt inventory/group_vars/all/vault.yml

# 4. Configure the server
ansible-playbook playbooks/site.yml --ask-vault-pass
```

The run ends with a `PLAY RECAP` line. `failed=0` and `unreachable=0` mean it worked.

After the first run, root can no longer log in over SSH. Set `ansible_user` in `inventory/hosts.yml` to the admin user (`sysadmin` by default) and add `-K` so Ansible asks for the sudo password:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass -K
```

A first run as root finishes in one go, even though it turns off root login on the way. The tutorial explains why: [first run as root](docs/tutorial-first-vps.md#if-the-first-run-connects-as-root).

## Check the result

Two playbooks check the server and change nothing:

```bash
# On the server: SSH settings, firewall, updates, listening ports, containers
ansible-playbook playbooks/verify.yml --ask-vault-pass -K

# From your computer: which ports are open from outside, and that SSH accepts keys only
ansible-playbook playbooks/verify_external.yml --ask-vault-pass
```

Both must end with `failed=0`. Each failed check prints what is wrong. See [what the checks cover](docs/reference/playbooks.md#what-verifyyml-checks).

## Basic usage

- Change settings in `inventory/group_vars/all/vars.yml` (base, Docker, Caddy) and `inventory/group_vars/all/services.yml` (apps). All settings are listed in the [variables reference](docs/reference/variables.md).
- Turn on an app: [enable optional services](docs/how-to/enable-services.md).
- Run the whole setup again whenever you change something. A second run with no changes reports `changed=0`.
- Run one part on its own with `playbooks/base.yml`, `playbooks/docker.yml`, `playbooks/caddy.yml` or `playbooks/services.yml`.

## Testing

`tests/run.sh` creates throwaway Ubuntu 24.04 and 26.04 virtual machines with [Lima](https://lima-vm.io/), runs the full setup as root with every service turned on, runs it again as the admin user with its sudo password to prove nothing changes, runs both check playbooks, checks that fail2ban bans failed logins, and deletes the VMs.

```bash
tests/run.sh
```

It ends with `== All tests passed for Ubuntu 24.04 26.04`. See [run the tests](docs/how-to/test-with-lima.md) for setup, and for what is not tested.

Lint and syntax checks:

```bash
ansible-lint
for p in playbooks/*.yml; do ansible-playbook -i inventory/hosts.example.yml --syntax-check "$p"; done
```

GitHub Actions runs these checks, plus a check of the Markdown docs, on every pull request. The Lima test runs only on your own machine.

## Documentation

Start here:

- [Tutorial: set up your first VPS](docs/tutorial-first-vps.md), from creating an SSH key to a verified server.

How-to guides:

- [Enable optional services](docs/how-to/enable-services.md)
- [Back up and restore data](docs/how-to/backup-restore.md)
- [Recover from an SSH or firewall lockout](docs/how-to/recover-access.md)
- [Upgrade packages and container images](docs/how-to/upgrade.md)
- [Run the tests in Lima VMs](docs/how-to/test-with-lima.md)

Reference:

- [Variables](docs/reference/variables.md)
- [Playbooks, files and checks](docs/reference/playbooks.md)
- [Basic Linux commands](docs/reference/linux-commands.md)

Explanation:

- [Security model and tradeoffs](docs/explanation/security-model.md)

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the checks to run before you open one.

## License

[MIT](LICENSE)
