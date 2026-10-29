# Security model and tradeoffs

This page explains what the playbooks protect against, why each measure is there, and what I chose not to do. It is background reading. For steps, see the [tutorial](../tutorial-first-vps.md) and the how-to guides.

## What we protect against

A small VPS on the internet is mostly attacked by automated scans, not by someone who targets you. Within minutes of going online it gets:

- SSH login attempts with common user names and passwords,
- scans for open databases, admin panels and the Docker API,
- requests that look for fresh, unconfigured web apps to take over.

The goal is that none of these can work, and that you do not lock yourself out while getting there. The project does not try to defend against an attacker who already has your SSH key, your vault password, or access to your provider account.

## Requirements and optional hardening

| Measure | Type | Default |
|---|---|---|
| SSH key login only, no passwords | requirement | on |
| No root login over SSH | requirement | on |
| Admin user with sudo and a password | requirement | on |
| Firewall: deny incoming except SSH (and 80/443 with Caddy) | requirement | on |
| Automatic security updates | requirement | on (Ubuntu default, kept on) |
| Container ports on 127.0.0.1 only, public access through Caddy | requirement | on when Docker is used |
| Secrets in an encrypted vault, hidden from logs | requirement | on |
| fail2ban for SSH | optional hardening | on |
| `AllowUsers` list for SSH | optional hardening | off |
| Passwordless sudo | convenience, less safe | off |
| Users in the `docker` group | convenience, less safe | none |
| Changing the SSH port | not offered | |

## SSH

### Keys only

With `PasswordAuthentication no` and `KbdInteractiveAuthentication no`, sshd accepts only keys. Password guessing cannot work, whatever the password. This is the single most useful setting in the project. `PermitRootLogin no` means you log in as the admin user and use sudo, so every root action needs both the key and the sudo password.

### Why a drop-in file named 00-hardening.conf

Ubuntu's `/etc/ssh/sshd_config` starts with `Include /etc/ssh/sshd_config.d/*.conf`, and sshd keeps **the first value it reads** for each setting. Cloud images often ship `50-cloud-init.conf` with `PasswordAuthentication yes`. A setting appended to the end of `sshd_config`, as older versions of this project did, loses against that file. Password login then stays on while the playbook reports success.

`00-hardening.conf` sorts first, so its values win. After writing it, the playbook checks the complete config with `sshd -t`, reloads SSH, and then reads the effective settings with `sshd -T` to prove they took effect. `verify.yml` repeats that check.

### Lockout prevention

The order of the base playbook is deliberate:

1. Create the admin user and its `authorized_keys`.
2. Open a **new** SSH connection as the admin user, with key login only. If that fails, stop before anything else changes.
3. Only then turn off password and root login. Validate the config before reloading.
4. Open another new SSH connection as the admin user to prove new logins still work. The rest of the run keeps using the connection that is already open, so a first run as root can finish after root login is turned off.
5. Allow the SSH port in UFW, and only then enable UFW.

A reload of the SSH server keeps existing sessions open, so a session you keep open in another terminal stays a way back in.

### SSH stays on port 22

Older versions of this project moved SSH to port 2222. This version keeps port 22 and never changes it.

Since Ubuntu 22.10, sshd is started through **systemd socket activation**: `ssh.socket` listens on the port and starts sshd for each connection. On 24.04 the port is read from `sshd_config` by a systemd generator, so a port change needs `systemctl daemon-reload` and a restart of `ssh.socket`, not just a restart of `ssh`. The old playbook only restarted the service. sshd kept listening on 22 while the firewall was told to allow only 2222, which is a lockout waiting for the next login.

Doing it safely takes several steps: change the socket, keep both ports open in the firewall, test a new connection on the new port, and only then close the old one. A different port does not stop a real attacker either; it only reduces log noise, which key-only login and fail2ban already handle. So I left it out. `ssh_port` only tells the firewall and the checks which port sshd already uses.

### Settings that were removed

- `Protocol 2`: SSH protocol 1 was removed from OpenSSH in version 7.4. The keyword does nothing.
- `ClientAliveCountMax 0`: this does not disable keepalive messages, as the old docs said. The man page says it disables connection termination.
- `MaxAuthTries 3`: it made logins fail with "Too many authentication failures" for anyone with more than three keys in their SSH agent.

## Admin user, sudo and console access

The admin user has a password, stored as a hash in the vault. It is used for `sudo` and for logging in at your provider's console. SSH never accepts it. Without a password you have no way in through the console when SSH fails.

`admin_sudo_nopasswd: true` removes the sudo password. It is convenient for automation, but then anyone with your SSH key is root. Use it only if you understand that tradeoff.

`ssh_allow_users` sets `AllowUsers`. With key-only login it adds little, so it is off. If you set it, the play first checks that it includes both `admin_user` and the user Ansible connects as.

## sudo-rs on Ubuntu 26.04

Ubuntu 26.04 replaces `sudo` with **sudo-rs**, a rewrite in Rust. The classic sudo is still installed as `sudo.ws`.

In the tests with ansible-core 2.21.5, `become` with a sudo password worked on 24.04 but failed on 26.04 with "Timeout waiting for privilege escalation prompt". sudo-rs prints its password prompt in a different form, and Ansible's sudo plugin in 2.21.5 does not recognise it. Passwordless sudo worked with sudo-rs.

The workaround is to tell Ansible to use the classic sudo for that host:

```yaml
ansible_become_exe: sudo.ws
```

With it, the full playbook and `verify.yml` passed on 26.04. Ansible merged sudo-rs prompt support upstream, and a later release may make this setting unnecessary. That has not been tested here.

`visudo` from sudo-rs validated the passwordless sudo file in the tests, so `admin_sudo_nopasswd` works on 26.04 too.

## Firewall

UFW (Uncomplicated Firewall) is set to deny incoming and allow outgoing traffic. It allows `ssh_port`, `firewall_allowed_tcp_ports`, and 80 and 443 when Caddy is on. `IPV6=yes` makes every rule apply to IPv6 too, and `verify.yml` checks that both IPv4 and IPv6 rules exist.

There is no `ufw limit` rule on SSH. It rate-limits new connections, which can block Ansible itself, and fail2ban already covers repeated failed logins.

Your provider may also have a network firewall in front of the server. It is a good second layer, but this project does not manage it.

## Docker and the firewall

This is the most important point for anyone who runs containers on a server with UFW.

When Docker publishes a port (`docker run -p 5432:5432`, or `ports:` in Compose), it adds its own firewall rules. Those rules handle the packets **before** UFW's rules see them. A port published on all addresses is reachable from the internet even when `ufw status` says incoming traffic is denied. The tests proved it: with UFW active and set to deny, a container published on `0.0.0.0:8081` was reachable from outside.

The fix is to publish ports on `127.0.0.1` only. Then only programs on the server, such as Caddy, can reach them:

- Every service in this project publishes `127.0.0.1:<port>:<container port>` explicitly.
- `/etc/docker/daemon.json` sets `"ip": "127.0.0.1"`, so `docker run -p 8080:80` is private by default. This only applies to Docker's default bridge network. On your own networks, including every Compose project, always write `127.0.0.1:8080:80`.
- PostgreSQL publishes no port at all.
- `verify.yml` fails if any TCP port other than the expected ones listens on a public address, and `verify_external.yml` checks common database and admin ports from outside.

Caddy is the only public entry point. It terminates HTTPS and forwards to `127.0.0.1:<port>`.

### Docker networks

PostgreSQL is attached only to a Docker network created with `internal: true`. Containers on an internal network cannot reach the internet, and a port published from such a container is not reachable. The apps that need the database join that network too, plus one normal network each for outbound traffic. The tradeoff: apps on the shared `postgres` network can reach each other there.

A Docker network is not "public" or "private" by itself. What makes a service reachable from the internet is port publishing.

### Fresh apps

Several apps give admin rights to whoever opens them first, or start with a known default password. The playbook closes that window before the app is reachable from outside: it creates the Gitea admin and locks the web installer, changes Umami's default `admin` / `umami` login, creates the first Memos user, creates the ntfy admin and denies anonymous access, and passes the Semaphore and pgAdmin admin accounts on first start.

Until then the app listens on 127.0.0.1 only. Caddy publishes it only after that. The main Caddyfile has the welcome page and the line `import /etc/caddy/sites/*.caddy`. The last task of each service writes that service's file, for example `/etc/caddy/sites/umami.caddy`, and Caddy reloads at the end of the play. If a service fails half way, its file is never written, so it stays private.

## The docker group is root

Anyone who can talk to the Docker daemon can start a container that mounts `/` from the host, and so can do anything root can do. Docker's own documentation says the `docker` group grants root-level privileges. That is why `docker_users` is empty by default and the docs use `sudo docker`. The admin user already has sudo, so adding it to the group mainly removes the password prompt, at the cost of making the SSH key alone enough for root.

The same goes for any tool that controls Docker or your servers. That is why Yacht was removed from this project (it mounted the Docker socket, was published on a public port and had a default password), and why pgAdmin and Semaphore UI deserve the same care as root access.

Docker also has a rootless mode. It changes networking and cannot bind ports below 1024, so it is not used here.

## fail2ban

fail2ban reads the SSH log and bans IP addresses that fail to log in too often. With password login off, nobody can guess their way in anyway, so on this server it mostly reduces log noise and wasted connections. It is on by default because it is cheap, and you can turn it off with `fail2ban_enabled: false`.

Ubuntu's package already enables the `sshd` jail, reading from the systemd journal and banning with nftables. The project only sets the port, `maxretry`, `findtime` and `bantime` in `/etc/fail2ban/jail.d/sshd.local`. On both 24.04 and 26.04 the tests confirmed that failed logins are counted and an IP gets banned.

OpenSSH 9.8 and later (26.04 ships 10.2) also has a built-in penalty system for misbehaving clients, `PerSourcePenalties`, on by default.

## Automatic security updates without automatic reboot

Ubuntu installs and enables unattended-upgrades by default. The playbook makes sure it stays on and `verify.yml` checks it. It installs updates from Ubuntu's security pocket every day.

Two limits to know about:

- **No automatic reboot.** The server never restarts on its own, because a reboot at a random time takes your apps down. Kernel and some library updates only take effect after a reboot. Check for `/var/run/reboot-required` and reboot when it suits you. See [Upgrade packages and container images](../how-to/upgrade.md).
- **Third-party repositories are not included.** Docker and Caddy come from their own apt repositories, which unattended-upgrades does not use by default. Adding them would mean Docker restarts, and with it all containers, at random times. Update them with `sudo apt full-upgrade`.

Container images are pinned to exact versions and never update on their own either. A tag that moves by itself, such as `latest`, can jump a major version without warning. That happened to this project: `postgres:latest` moved to PostgreSQL 18, which refuses to start with the old volume layout.

## Software sources

- Docker comes from Docker's official apt repository, set up the way Docker documents it, with the signing key in `/etc/apt/keyrings/`. Ubuntu's own `docker.io` packages are removed first, because they conflict.
- Caddy comes from Caddy's **stable** repository. Ubuntu's `caddy` package is much older. An older version of this project used the testing repository with the stable key, which could not work.
- Both use the deb822 `.sources` format, which replaces the old one-line format.

## Secrets

- Secrets live in `inventory/group_vars/all/vault.yml`, encrypted with Ansible Vault. Plain settings refer to them by name (`admin_password_hash: "{{ vault_admin_password_hash }}"`), so you can see which secrets exist without decrypting anything.
- Tasks that handle secrets use `no_log: true`, so passwords do not appear in the output, even with `-v`.
- Each service checks that its secrets are set, long enough and not the example value before it starts.
- The real inventory, the vault file and any `.vault-pass*` file are in `.gitignore`.

## What this project does not do

- It does not change Ubuntu's AppArmor profiles or other defaults. They are already sensible.
- It does not apply a full CIS benchmark. I used it and Ubuntu's guidance as references, and added only measures with a clear reason.
- It does not make backups, monitor the server, or send alerts. See [Back up and restore data](../how-to/backup-restore.md).
- It does not manage your provider's firewall, DNS, or snapshots.

## Sources

- SSH socket activation on Ubuntu: https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
- OpenSSH server on Ubuntu: https://ubuntu.com/server/docs/how-to/security/openssh-server/
- `sshd_config` (first value wins, `ClientAliveCountMax`): https://man.openbsd.org/sshd_config
- cloud-init enabling password login: https://bugs.launchpad.net/ubuntu/+source/cloud-init/+bug/2088207
- OpenSSH 9.8 release notes (`PerSourcePenalties`): https://www.openssh.org/txt/release-9.8
- Ubuntu 26.04 summary for LTS users (sudo-rs, chrony): https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/
- Ansible sudo-rs prompt support: https://github.com/ansible/ansible/pull/86175
- Docker install on Ubuntu and firewall limitations: https://docs.docker.com/engine/install/ubuntu/
- Docker packet filtering and firewalls: https://docs.docker.com/engine/network/packet-filtering-firewalls/
- Docker port publishing: https://docs.docker.com/engine/network/port-publishing/
- Docker post-install steps (docker group): https://docs.docker.com/engine/install/linux-postinstall/
- Docker daemon attack surface: https://docs.docker.com/engine/security/#docker-daemon-attack-surface
- Docker rootless mode: https://docs.docker.com/engine/security/rootless/
- fail2ban on Ubuntu 24.04: https://bugs.launchpad.net/ubuntu/+source/fail2ban/+bug/2055114
- Ubuntu automatic updates: https://ubuntu.com/server/docs/how-to/software/automatic-updates/
- Caddy install: https://caddyserver.com/docs/install#debian-ubuntu-raspbian
- Caddy automatic HTTPS: https://caddyserver.com/docs/automatic-https
- PostgreSQL image and the version 18 data directory: https://hub.docker.com/_/postgres and https://github.com/docker-library/postgres/pull/1259
- Ansible Vault tips: https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html
- Ansible release and maintenance (supported Python versions): https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html
