# Playbooks, files and checks

## Repository layout

```
ansible.cfg                     Ansible settings: inventory path, no retry files, pipelining
requirements.txt                Python packages for the control machine (ansible-core, ansible-lint)
requirements.yml                Ansible collections
inventory/
  hosts.example.yml             Example inventory. Copy to hosts.yml (ignored by git)
  vault.example.yml             Example secrets. Copy to group_vars/all/vault.yml and encrypt
  group_vars/all/vars.yml       Defaults for the base setup, Docker and Caddy
  group_vars/all/services.yml   Defaults for the optional services
playbooks/
  site.yml                      Runs base.yml, docker.yml, caddy.yml and services.yml
  base.yml                      Base setup, always runs
  docker.yml                    Docker Engine, when docker_enabled
  caddy.yml                     Caddy, when caddy_enabled
  services.yml                  The optional apps, each when <name>_enabled
  verify.yml                    Read-only checks on the server
  verify_external.yml           Read-only checks from the control machine
  templates/                    sshd, fail2ban, Docker and Caddy config templates
  files/index.html              Caddy welcome page
tasks/                          Task files imported by the playbooks, one per topic
services/                       One task file per optional app, plus app_database.yml
handlers/main.yml               Reload or restart ssh, ufw, fail2ban, docker and caddy
tests/                          Lima integration test (run.sh, inventory.yml, vars.yml)
```

The project uses plain playbooks that import task files. There are no roles. Templates and files sit next to the playbooks in `playbooks/templates/` and `playbooks/files/`, because Ansible looks for them relative to the playbook.

## Playbooks

Every command runs from the repository folder. Add `--ask-vault-pass` once the vault file exists, and `-K` when `ansible_user` needs a password for sudo. Add `-l vps1` to limit a run to one host.

| Playbook | Runs on | Changes the server | What it does |
|---|---|---|---|
| `playbooks/site.yml` | server | yes | Everything below, in order |
| `playbooks/base.yml` | server | yes | Pre-flight checks, packages and time zone, automatic updates, admin user, SSH hardening, UFW, fail2ban |
| `playbooks/docker.yml` | server | yes | Docker Engine from Docker's repository, `/etc/docker/daemon.json`, `docker_users`. Does nothing unless `docker_enabled` |
| `playbooks/caddy.yml` | server | yes | Caddy from Caddy's stable repository, `/etc/caddy/Caddyfile`, welcome page, UFW rules for 80 and 443. Does nothing unless `caddy_enabled` |
| `playbooks/services.yml` | server | yes | Containers, networks, volumes, databases and admin accounts for enabled apps. Then, for each app with a domain, its Caddy site in `/etc/caddy/sites/`. With every app off it changes nothing |
| `playbooks/verify.yml` | server | no | Checks the server's real state. See below |
| `playbooks/verify_external.yml` | control machine | no | Checks the server from outside. See below |

### What base.yml does, in order

| Step | Task file | Main effect on the server |
|---|---|---|
| Pre-flight | `tasks/preflight.yml` | Stops early if the release is not supported, `admin_user` is `root` or has no key, the password hash is missing, or `ssh_allow_users` would lock out the current user |
| Packages | `tasks/apt.yml` | Installs `ca-certificates`, `curl`, `python3-debian`, `ufw`, `unattended-upgrades`, `bash-completion`, `vim`, `git` and `extra_packages`, sets the time zone. No full upgrade |
| Updates | `tasks/updates.yml` | Writes `/etc/apt/apt.conf.d/20auto-upgrades`, enables `apt-daily.timer` and `apt-daily-upgrade.timer` |
| Admin user | `tasks/users.yml` | Creates `admin_user` in group `sudo`, sets its password and `authorized_keys`, manages `/etc/sudoers.d/90-admin-nopasswd`, then logs in as that user with a key to prove it works |
| SSH | `tasks/ssh.yml` | Checks something listens on `ssh_port`, writes `/etc/ssh/sshd_config.d/00-hardening.conf`, runs `sshd -t`, reloads `ssh.service`, checks `sshd -T`, logs in again as `admin_user` over a new connection |
| Firewall | `tasks/firewall.yml` | Sets `IPV6=yes`, allows `ssh_port/tcp` and `firewall_allowed_tcp_ports`, default deny incoming and allow outgoing, enables UFW |
| fail2ban | `tasks/fail2ban.yml` | Installs fail2ban, writes `/etc/fail2ban/jail.d/sshd.local`. Only when `fail2ban_enabled` |

### Files the playbooks write

| File | Owner and mode | Written by |
|---|---|---|
| `/etc/ssh/sshd_config.d/00-hardening.conf` | root, 0644 | `tasks/ssh.yml` |
| `/etc/apt/apt.conf.d/20auto-upgrades` | root, 0644 | `tasks/updates.yml` |
| `/etc/sudoers.d/90-admin-nopasswd` | root, 0440, only with `admin_sudo_nopasswd` | `tasks/users.yml` |
| `/etc/fail2ban/jail.d/sshd.local` | root, 0644 | `tasks/fail2ban.yml` |
| `/etc/apt/keyrings/docker.asc`, `/etc/apt/sources.list.d/docker.sources` | root, 0644 | `tasks/docker.yml` |
| `/etc/docker/daemon.json` | root, 0644 | `tasks/docker.yml` |
| `/etc/apt/keyrings/caddy-stable.asc`, `/etc/apt/sources.list.d/caddy-stable.sources` | root, 0644 | `tasks/caddy.yml` |
| `/etc/caddy/Caddyfile` | root, 0644 | `tasks/caddy.yml` |
| `/etc/caddy/sites/<name>.caddy`, one per service with a domain | root, 0644 | `tasks/caddy_site.yml`, imported by each `services/<name>.yml` as its last task |
| `/var/www/html/index.html` | root, 0644 | `tasks/caddy.yml` |

### Containers, volumes and networks

| Service | Container | Volumes | Networks |
|---|---|---|---|
| PostgreSQL | `postgres` | `postgres_data` | `postgres` (internal) |
| pgAdmin | `pgadmin` | `pgadmin_data` | `pgadmin`, `postgres` |
| Gitea | `gitea` | `gitea_data` | `gitea`, `postgres` |
| Umami | `umami` | none (data in PostgreSQL) | `umami`, `postgres` |
| Semaphore UI | `semaphore` | `semaphore_config`, `semaphore_data` | `semaphore`, `postgres` |
| Memos | `memos` | `memos_data` | `memos` |
| ntfy | `ntfy` | `ntfy_data` | `ntfy` |

All containers use the restart policy `unless-stopped` and a health check.

## What verify.yml checks

`playbooks/verify.yml` runs on the server with sudo and changes nothing. Every check prints what is wrong when it fails.

| Area | Check |
|---|---|
| System | Ubuntu release is in `supported_ubuntu_versions` |
| Time | Network time sync is on (`timedatectl show -p NTP`) |
| Services | Enabled at boot and active: `ssh.socket`, `ufw.service`, `unattended-upgrades.service`, `apt-daily.timer`, `apt-daily-upgrade.timer`, plus `fail2ban.service`, `containerd.service`, `docker.service`, `caddy.service` when turned on |
| Updates | `apt-config` shows `Update-Package-Lists "1"` and `Unattended-Upgrade "1"`, and automatic reboot is not `true` |
| Admin user | In the `sudo` group; has a password hash (unless `admin_sudo_nopasswd`); `~/.ssh` and `authorized_keys` exist, belong to the user, mode 0700 or 0600 |
| SSH login | A new SSH connection as `admin_user` with a key works |
| SSH config | `00-hardening.conf` exists, root-owned, mode 0644. `sshd -T` shows `port <ssh_port>`, `permitrootlogin no`, `passwordauthentication no`, `kbdinteractiveauthentication no`, `pubkeyauthentication yes`, `x11forwarding no` |
| Firewall | UFW active, `deny (incoming)`, `allow (outgoing)`, and an IPv4 and IPv6 allow rule for each expected port (SSH, `firewall_allowed_tcp_ports`, 80 and 443 with Caddy) |
| Listening ports | Every TCP port listening on a non-loopback address is an expected port. This is how a Docker port that bypasses UFW is caught |
| fail2ban | `fail2ban-client status sshd` succeeds |
| Docker | `daemon.json` sets `ip` to `docker_default_bind_ip`; `docker` group members equal `docker_users`; `docker info` answers |
| Caddy | With a `:`-style site address, `http://127.0.0.1/` returns 200 |
| Containers | Each enabled service container exists, is running, is healthy, uses `unless-stopped`, and publishes ports on 127.0.0.1 only |
| PostgreSQL | Its network is internal, it has no published ports and it is on no other network |
| Caddy sites | `https://<domain>/` for each service site answers with 2xx or 3xx (through `curl --resolve` to 127.0.0.1) |

Not checked: UDP listeners, file permissions outside the list above, and AppArmor.

## What verify_external.yml checks

`playbooks/verify_external.yml` runs every task on the control machine and connects to `verify_external_address` (default `ansible_host`). Run it from a network outside the server.

| Check | Expected |
|---|---|
| Open ports | SSH, `firewall_allowed_tcp_ports`, and 80 and 443 with Caddy accept TCP connections |
| Closed ports | 2019 (Caddy admin API), 2375 and 2376 (Docker API), 3000, 5432, 8000, 8080, 8081, 9000, and every service port do not accept connections |
| Key login | `ssh -o BatchMode=yes -o PreferredAuthentications=publickey admin_user@address id -un` prints `admin_user` |
| No password login | An SSH login without a key fails with `Permission denied (publickey)`, so the server offers no other method |
| Service sites | `https://<domain>/` for each service site answers with 2xx or 3xx |
