# Recover from an SSH or firewall lockout

Use this guide when you cannot log in to the server over SSH any more. It also lists how to undo each change the base playbook makes.

The playbook tries hard to prevent a lockout. It checks that the admin user can log in with a key before it changes SSH, it tests the SSH config with `sshd -t` before reloading, and it allows SSH in UFW before it enables the firewall. Things can still go wrong outside the playbook: a lost key, a manual edit, a provider firewall, or fail2ban banning your own IP.

## Before you need this

- Keep one SSH session open while you change SSH or firewall settings. A reload of the SSH server does not close existing sessions, so an open session lets you undo a bad change.
- Know where your provider's console is. It is a terminal in the browser (or VNC or serial) that does not go through SSH or the network firewall.
- Know your admin user's password. The console asks for a normal login, and SSH keys do not help there. If you use `admin_sudo_nopasswd: true` and never set a password, you cannot log in at the console. Most providers then offer a rescue mode or a root password reset instead.

## Step 1: Find out what is wrong

Run SSH with `-v` from your computer and read the last lines:

```bash
ssh -v sysadmin@203.0.113.10
```

| What you see | Likely cause | Go to |
|---|---|---|
| `Connection timed out` | Firewall (UFW or the provider's firewall) drops the traffic, or the server is down | [Firewall](#firewall) |
| `Connection refused` | Nothing listens on that port, or fail2ban banned your IP | [fail2ban](#fail2ban), then [SSH server](#ssh-server) |
| `Permission denied (publickey)` | The server is fine but does not accept your key, or the user is wrong | [Lost or wrong key](#lost-or-wrong-key) |
| `Too many authentication failures` | Your SSH client offers too many keys | Use `ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes sysadmin@203.0.113.10` |
| `Host key verification failed` | The server was rebuilt and has a new host key | `ssh-keygen -R 203.0.113.10` |

## Step 2: Log in through the console

Open the provider's console and log in as the admin user with its password. All commands below run there. They also work in a still-open SSH session.

## Firewall

Allow SSH again:

```bash
sudo ufw allow 22/tcp
sudo ufw status verbose
```

If you are not sure what is wrong, turn UFW off for a moment:

```bash
sudo ufw disable
```

This removes all UFW filtering, so turn it back on with `sudo ufw enable` as soon as you can log in again. Running the playbook again also restores the rules.

Also check the provider's own firewall in its dashboard, if it has one. It sits in front of the server, and UFW cannot see it.

## fail2ban

fail2ban bans an IP address after `fail2ban_sshd_maxretry` failed logins (default 5) within `fail2ban_sshd_findtime` (default 10 minutes), for `fail2ban_sshd_bantime` (default 1 hour). A banned IP gets `Connection refused`.

See who is banned and unban everyone:

```bash
sudo fail2ban-client status sshd
sudo fail2ban-client unban --all
```

Or wait for the ban to expire.

## SSH server

Check that the SSH socket is active and that something listens on port 22:

```bash
systemctl status ssh.socket ssh.service
sudo ss -tlnp | grep ':22 '
```

Test the configuration. Any error here tells you the file and line:

```bash
sudo sshd -t
```

To undo the playbook's SSH hardening, remove its drop-in file and reload:

```bash
sudo rm /etc/ssh/sshd_config.d/00-hardening.conf
sudo sshd -t && sudo systemctl reload ssh
```

After this, SSH falls back to Ubuntu's defaults and to whatever other files in `/etc/ssh/sshd_config.d/` say. Root login and password login may be allowed again. Running the playbook puts the file back.

If you set `ssh_allow_users` and forgot a user, the same removal undoes it.

## Lost or wrong key

From the console, add a working public key to the admin user:

```bash
nano ~/.ssh/authorized_keys
```

Paste the new public key on its own line and save. The file must belong to the user and have mode `0600`:

```bash
chmod 600 ~/.ssh/authorized_keys
ls -l ~/.ssh/authorized_keys
```

Then add the same key to `admin_ssh_keys` in your inventory, so the next playbook run keeps it. If `admin_ssh_keys_exclusive` is `true`, the playbook removes every key that is not in `admin_ssh_keys`.

## Undo other changes

| Change | Undo |
|---|---|
| Passwordless sudo (`admin_sudo_nopasswd: true`) | `sudo rm /etc/sudoers.d/90-admin-nopasswd` |
| fail2ban jail settings | `sudo rm /etc/fail2ban/jail.d/sshd.local && sudo systemctl restart fail2ban` |
| Docker daemon settings | Edit `/etc/docker/daemon.json`, then `sudo systemctl restart docker` (restarts all containers) |
| Caddy config | Edit `/etc/caddy/Caddyfile`, test with `caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile`, then `sudo systemctl reload caddy` |

The playbook writes these files again on its next run, so change the matching variable as well.

## Older installs that use port 2222

Earlier versions of this project moved SSH to port 2222. This version never changes the SSH port. If your server still listens on 2222, set `ssh_port: 2222` in your inventory so UFW keeps allowing it. The playbook stops with "Check that sshd listens on ssh_port before changing anything" if `ssh_port` does not match what sshd really uses, before it touches SSH or the firewall. The [security model](../explanation/security-model.md#ssh-stays-on-port-22) explains why the port stays at 22.

## Sources

- OpenSSH on Ubuntu: https://ubuntu.com/server/docs/how-to/security/openssh-server/
- SSH socket activation on Ubuntu: https://discourse.ubuntu.com/t/sshd-now-uses-socket-based-activation-ubuntu-22-10-and-later/30189
- `sshd_config` reference: https://man.openbsd.org/sshd_config
