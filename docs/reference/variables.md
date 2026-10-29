# Variables

Every setting the playbooks read, with its default. The defaults live in two files:

- `inventory/group_vars/all/vars.yml`: base setup, Docker and Caddy.
- `inventory/group_vars/all/services.yml`: the optional services.

Secrets live in `inventory/group_vars/all/vault.yml`, which you create from `inventory/vault.example.yml`. Settings under a host in `inventory/hosts.yml` win over both files.

## Connection (inventory)

These are standard Ansible variables. Set them per host in `inventory/hosts.yml`.

| Variable | Example | Meaning |
|---|---|---|
| `ansible_host` | `203.0.113.10` | IP address or DNS name of the server |
| `ansible_user` | `root`, later `sysadmin` | User Ansible logs in as. On the first run, the user from your provider. Afterwards, `admin_user` |
| `ansible_become_exe` | `sudo.ws` | Ubuntu 26.04 only, when sudo needs a password. See [sudo-rs](../explanation/security-model.md#sudo-rs-on-ubuntu-2604) |
| `ansible_ssh_private_key_file` | `~/.ssh/id_ed25519` | Optional. The private key to use, if not your default |

## Base setup

| Variable | Default | Meaning |
|---|---|---|
| `supported_ubuntu_versions` | `["24.04", "26.04"]` | The play stops on any other release |
| `timezone` | `Etc/UTC` | Time zone in tz database format, for example `Europe/Bucharest` |
| `extra_packages` | `[]` | More apt packages to install |

## Admin user

| Variable | Default | Meaning |
|---|---|---|
| `admin_user` | `sysadmin` | Account to create, in the `sudo` group. Must not be `root`. Avoid `admin`: Ubuntu already has an `admin` group with its own sudo rule |
| `admin_ssh_keys` | `[]` | Public keys allowed to log in as `admin_user`. At least one is required |
| `admin_ssh_keys_exclusive` | `false` | When `true`, removes keys from `authorized_keys` that are not in `admin_ssh_keys` |
| `admin_password_hash` | `"{{ vault_admin_password_hash }}"` | Password hash for sudo and console login. Set it through the vault |
| `admin_sudo_nopasswd` | `false` | When `true`, sudo needs no password (`/etc/sudoers.d/90-admin-nopasswd`). Anyone with the SSH key is then root. The password hash may stay empty |

## SSH

| Variable | Default | Meaning |
|---|---|---|
| `ssh_port` | `22` | The port sshd **already** listens on. The project does not change it. UFW allows it, and the play stops if nothing listens on it |
| `ssh_allow_users` | `[]` | Optional `AllowUsers` list. Empty means no extra limit. It must include `admin_user` and the user Ansible connects as, or the play stops |

## Firewall

| Variable | Default | Meaning |
|---|---|---|
| `firewall_allowed_tcp_ports` | `[]` | Extra TCP ports to open to everyone. SSH is always allowed. The Caddy playbook opens 80 and 443 itself |

## fail2ban

| Variable | Default | Meaning |
|---|---|---|
| `fail2ban_enabled` | `true` | Install fail2ban and tune its `sshd` jail |
| `fail2ban_sshd_maxretry` | `5` | Failed logins before a ban |
| `fail2ban_sshd_findtime` | `10m` | Time window for counting failures |
| `fail2ban_sshd_bantime` | `1h` | How long a ban lasts |

## Docker

| Variable | Default | Meaning |
|---|---|---|
| `docker_enabled` | `false` | Install Docker Engine (`playbooks/docker.yml`) |
| `docker_users` | `[]` | Users to add to the `docker` group. That group is root-equivalent. Leave it empty and use `sudo docker` |
| `docker_default_bind_ip` | `127.0.0.1` | Address that `docker run -p 8080:80` publishes on. Only affects the default bridge network |

## Caddy

| Variable | Default | Meaning |
|---|---|---|
| `caddy_enabled` | `false` | Install Caddy (`playbooks/caddy.yml`) and open ports 80 and 443 |
| `caddy_site_address` | `":80"` | Site address for the welcome page. A domain name gives HTTPS. `":80"` is plain HTTP on any address |
| `caddy_local_certs` | `false` | Use Caddy's own local certificate authority instead of Let's Encrypt. For tests only: browsers do not trust these certificates |
| `caddy_service_sites` | built from the service settings | List of `{domain, port}` for enabled services with a domain. Do not set it yourself |

## Optional services

All services are off by default. Each has `<name>_enabled`, `<name>_image`, and for web apps `<name>_port` (published on 127.0.0.1) and `<name>_domain` (empty means no Caddy site).

### PostgreSQL

| Variable | Default | Meaning |
|---|---|---|
| `postgresql_enabled` | `false` | Run PostgreSQL. Needed by Gitea, Umami, Semaphore and pgAdmin |
| `postgresql_image` | `postgres:18.6` | Image tag |
| `postgresql_password` | `"{{ vault_postgresql_password }}"` | Superuser password. Only used when the data volume is new |
| `postgresql_network` | `postgres` | Name of the internal Docker network the apps use to reach PostgreSQL |

### pgAdmin

| Variable | Default | Meaning |
|---|---|---|
| `pgadmin_enabled` | `false` | Run pgAdmin |
| `pgadmin_image` | `dpage/pgadmin4:9.18` | Image tag |
| `pgadmin_port` | `5050` | Port on 127.0.0.1 |
| `pgadmin_domain` | `""` | Leave empty and use an SSH tunnel. Setting it puts pgAdmin on the internet |
| `pgadmin_email` | `admin@example.com` | Login email. Must look like a real address |
| `pgadmin_password` | `"{{ vault_pgadmin_password }}"` | Login password, used only when the data volume is new |

### Gitea

| Variable | Default | Meaning |
|---|---|---|
| `gitea_enabled` | `false` | Run Gitea |
| `gitea_image` | `docker.gitea.com/gitea:28.2.0` | Image tag |
| `gitea_port` | `3000` | Port on 127.0.0.1 |
| `gitea_domain` | `""` | Domain for Caddy, also used for Gitea's `ROOT_URL` |
| `gitea_admin_user` | `gitadmin` | Admin account. `admin` is reserved in Gitea |
| `gitea_admin_email` | `gitadmin@example.com` | Admin email |
| `gitea_admin_password` | `"{{ vault_gitea_admin_password }}"` | Used only when the account is created |
| `gitea_secret_key` | `"{{ vault_gitea_secret_key }}"` | Gitea `SECRET_KEY`. Set once, never change |
| `gitea_db_name` | `gitea` | Database name |
| `gitea_db_user` | `gitea` | Database user |
| `gitea_db_password` | `"{{ vault_gitea_db_password }}"` | Database password |

### Umami

| Variable | Default | Meaning |
|---|---|---|
| `umami_enabled` | `false` | Run Umami |
| `umami_image` | `ghcr.io/umami-software/umami:3.4.1` | Image tag |
| `umami_port` | `3001` | Port on 127.0.0.1 |
| `umami_domain` | `""` | Domain for Caddy |
| `umami_admin_password` | `"{{ vault_umami_admin_password }}"` | Replaces the default `admin` / `umami` login on the first run |
| `umami_app_secret` | `"{{ vault_umami_app_secret }}"` | Signs login tokens |
| `umami_db_name` | `umami` | Database name |
| `umami_db_user` | `umami` | Database user |
| `umami_db_password` | `"{{ vault_umami_db_password }}"` | Database password |

### Semaphore UI

| Variable | Default | Meaning |
|---|---|---|
| `semaphore_enabled` | `false` | Run Semaphore UI |
| `semaphore_image` | `semaphoreui/semaphore:v2.19.17` | Image tag |
| `semaphore_port` | `3002` | Port on 127.0.0.1 |
| `semaphore_domain` | `""` | Domain for Caddy |
| `semaphore_admin_user` | `admin` | Admin login |
| `semaphore_admin_name` | `Semaphore Admin` | Admin display name |
| `semaphore_admin_email` | `admin@example.com` | Admin email |
| `semaphore_admin_password` | `"{{ vault_semaphore_admin_password }}"` | Used only on the first start |
| `semaphore_access_key_encryption` | `"{{ vault_semaphore_access_key_encryption }}"` | Encrypts the keys and passwords Semaphore stores. Keep a copy |
| `semaphore_db_name` | `semaphore` | Database name |
| `semaphore_db_user` | `semaphore` | Database user |
| `semaphore_db_password` | `"{{ vault_semaphore_db_password }}"` | Database password |

### Memos

| Variable | Default | Meaning |
|---|---|---|
| `memos_enabled` | `false` | Run Memos |
| `memos_image` | `neosmemo/memos:0.31.0` | Image tag |
| `memos_port` | `5230` | Port on 127.0.0.1 |
| `memos_domain` | `""` | Domain for Caddy |
| `memos_admin_user` | `memosadmin` | First account, which becomes the admin |
| `memos_admin_password` | `"{{ vault_memos_admin_password }}"` | Used only when the account is created |

### ntfy

| Variable | Default | Meaning |
|---|---|---|
| `ntfy_enabled` | `false` | Run ntfy |
| `ntfy_image` | `binwiederhier/ntfy:v2.34.0` | Image tag |
| `ntfy_port` | `2586` | Port on 127.0.0.1 |
| `ntfy_domain` | `""` | Domain for Caddy, also used as ntfy's base URL |
| `ntfy_admin_user` | `ntfyadmin` | Admin user |
| `ntfy_admin_password` | `"{{ vault_ntfy_admin_password }}"` | Used only when the user is created |

## Vault secrets

Set these in `inventory/group_vars/all/vault.yml`. Only `vault_admin_password_hash` is always needed (unless `admin_sudo_nopasswd` is `true`). The others are checked only when their service is on.

| Variable | Create with | Minimum length |
|---|---|---|
| `vault_admin_password_hash` | `openssl passwd -6` | a `$6$...` hash |
| `vault_postgresql_password` | `openssl rand -hex 24` | 16 |
| `vault_pgadmin_password` | `openssl rand -hex 24` | 12 |
| `vault_gitea_admin_password` | `openssl rand -hex 24` | 12 |
| `vault_gitea_db_password` | `openssl rand -hex 24` | 16 |
| `vault_gitea_secret_key` | `openssl rand -hex 24` | 32 |
| `vault_umami_admin_password` | `openssl rand -hex 24` | 12 |
| `vault_umami_app_secret` | `openssl rand -hex 24` | 32 |
| `vault_umami_db_password` | `openssl rand -hex 24` | 16 |
| `vault_semaphore_admin_password` | `openssl rand -hex 24` | 12 |
| `vault_semaphore_db_password` | `openssl rand -hex 24` | 16 |
| `vault_semaphore_access_key_encryption` | `head -c32 /dev/urandom \| base64` | 32 |
| `vault_memos_admin_password` | `openssl rand -hex 24` | 12 |
| `vault_ntfy_admin_password` | `openssl rand -hex 24` | 12 |

## Verification playbooks

These have defaults inside the playbooks. Override them with `-e` on the command line.

| Variable | Playbook | Default | Meaning |
|---|---|---|---|
| `verify_allowed_public_tcp_ports` | `verify.yml` | `firewall_allowed_tcp_ports` | Extra ports that may listen on public addresses |
| `verify_external_address` | `verify_external.yml` | `ansible_host` | Address to test from outside |
| `verify_external_ssh_args` | `verify_external.yml` | `[]` | Extra options for the `ssh` command, for example `["-i", "~/.ssh/id_ed25519"]` |
| `verify_external_open_tcp_ports` | `verify_external.yml` | `ssh_port`, `firewall_allowed_tcp_ports`, and 80 and 443 with Caddy | Ports that must accept connections |
| `verify_external_closed_tcp_ports` | `verify_external.yml` | 2019, 2375, 2376, 3000, 5432, 8000, 8080, 8081, 9000 and every service port | Ports that must not be reachable |

With Caddy on, port 443 is only expected when `caddy_site_address` is a domain or at least one service has a domain.

## Example: a host with Docker, Caddy and Gitea

```yaml
all:
  hosts:
    vps1:
      ansible_host: 203.0.113.10
      ansible_user: sysadmin
      admin_ssh_keys:
        - "ssh-ed25519 AAAA... you@laptop"
      timezone: Europe/Bucharest
      docker_enabled: true
      caddy_enabled: true
      caddy_site_address: example.com
      postgresql_enabled: true
      gitea_enabled: true
      gitea_domain: git.example.com
```
