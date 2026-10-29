# Enable optional services

This guide turns on Docker, Caddy and one or more of the apps: PostgreSQL, pgAdmin, Gitea, Umami, Semaphore UI, Memos and ntfy. Each one is separate. Turn on only what you need.

You need a server that has already been set up with the [tutorial](../tutorial-first-vps.md). The commands assume `ansible_user` is your admin user, so they use `-K`.

## How the services are set up

- Every app runs in a Docker container and publishes its port on `127.0.0.1` only. Nothing is reachable from the internet directly. The [security model](../explanation/security-model.md#docker-and-the-firewall) explains why.
- Caddy is the only way in from outside. For each enabled app that has a domain, Caddy serves `https://<domain>` and gets a certificate for it from Let's Encrypt.
- An app without a domain is still reachable from your computer through an SSH tunnel.
- PostgreSQL is attached only to an internal Docker network. It has no published port at all.
- Every app keeps its data in a named Docker volume, so containers can be recreated without losing data.
- Before an app is reachable, the playbook creates its admin account with a password from your vault. Only then does it write the app's Caddy site, `/etc/caddy/sites/<name>.caddy`. Nobody can claim a fresh install before you.

| App | Variable | Port on 127.0.0.1 | Needs PostgreSQL | Login after setup |
|---|---|---|---|---|
| PostgreSQL | `postgresql_enabled` | none | | user `postgres`, `vault_postgresql_password` |
| pgAdmin | `pgadmin_enabled` | `pgadmin_port` (5050) | yes | `pgadmin_email`, `vault_pgadmin_password` |
| Gitea | `gitea_enabled` | `gitea_port` (3000) | yes | `gitea_admin_user` (`gitadmin`), `vault_gitea_admin_password` |
| Umami | `umami_enabled` | `umami_port` (3001) | yes | user `admin`, `vault_umami_admin_password` |
| Semaphore UI | `semaphore_enabled` | `semaphore_port` (3002) | yes | `semaphore_admin_user` (`admin`), `vault_semaphore_admin_password` |
| Memos | `memos_enabled` | `memos_port` (5230) | no | `memos_admin_user` (`memosadmin`), `vault_memos_admin_password` |
| ntfy | `ntfy_enabled` | `ntfy_port` (2586) | no | `ntfy_admin_user` (`ntfyadmin`), `vault_ntfy_admin_password` |

With everything on, a 24.04 test VM used about 1.1 GB of RAM. Plan for 2 GB or more.

## Where to change settings

Defaults live in `inventory/group_vars/all/vars.yml` (Docker, Caddy) and `inventory/group_vars/all/services.yml` (apps). You have two choices:

- Edit those files. Simple, but `git pull` may then conflict with your changes.
- Put your settings under your host in `inventory/hosts.yml`. That file is not tracked by git, and host settings win over the group defaults.

The examples below use `inventory/hosts.yml`.

## 1. Turn on Docker and Caddy

```yaml
all:
  hosts:
    vps1:
      ansible_host: 203.0.113.10
      ansible_user: sysadmin
      admin_ssh_keys:
        - "ssh-ed25519 AAAA... you@laptop"
      docker_enabled: true
      caddy_enabled: true
```

Caddy serves a small welcome page from `/var/www/html`. By default `caddy_site_address` is `":80"`, which is plain HTTP on any address. To serve the welcome page over HTTPS on your domain, set `caddy_site_address: example.com`.

## 2. Point DNS to the server

For each app you want on the internet, create a DNS **A record** that points a name to the server's IPv4 address, for example:

```
git.example.com     A    203.0.113.10
notes.example.com   A    203.0.113.10
```

If the server has IPv6, add an **AAAA** record with the IPv6 address as well. Caddy can only get a certificate when the name points to the server and ports 80 and 443 are reachable. The Caddy playbook opens both in UFW.

Check a record from your computer:

```bash
dig +short git.example.com
```

Expected: your server's IP address. On Windows or if `dig` is missing, use `nslookup git.example.com`.

## 3. Turn on the apps and set their domains

Example with PostgreSQL, Gitea and Memos:

```yaml
      postgresql_enabled: true
      gitea_enabled: true
      gitea_domain: git.example.com
      gitea_admin_email: you@example.com
      memos_enabled: true
      memos_domain: notes.example.com
```

Rules the playbook enforces:

- Every app needs `docker_enabled: true`.
- Gitea, Umami, Semaphore and pgAdmin need `postgresql_enabled: true`.
- An empty `<name>_domain` means no Caddy site. The app is then only reachable through an SSH tunnel.

pgAdmin is a special case: anyone who logs in to it controls every database. Leave `pgadmin_domain` empty and use a tunnel. If you set it anyway, the playbook prints a warning.

## 4. Add the secrets to the vault

Open the vault:

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

Set the values for the apps you turned on. The names are in `inventory/vault.example.yml`. Use a different random value for each. This command prints one:

```bash
openssl rand -hex 24
```

Semaphore's encryption key has its own format:

```bash
head -c32 /dev/urandom | base64
```

Minimum lengths, checked before anything is installed:

| Secret | Minimum |
|---|---|
| `vault_postgresql_password` and every `vault_*_db_password` | 16 characters |
| Admin passwords (`vault_*_admin_password`, `vault_pgadmin_password`) | 12 characters |
| `vault_gitea_secret_key`, `vault_umami_app_secret`, `vault_semaphore_access_key_encryption` | 32 characters |

Keep a copy of `vault_gitea_secret_key` and `vault_semaphore_access_key_encryption` with your backups. Without them, data encrypted by Gitea (such as 2FA secrets) or Semaphore (stored SSH keys and passwords) cannot be read after a restore.

## 5. Run the playbook

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass -K
```

The first run downloads images and waits for each container to report healthy, so it can take several minutes. It ends with `failed=0`.

If you only changed service settings, `playbooks/services.yml` is enough. It also updates the Caddy sites in `/etc/caddy/sites/` so they match the enabled apps.

## 6. Verify

```bash
ansible-playbook playbooks/verify.yml --ask-vault-pass -K
ansible-playbook playbooks/verify_external.yml --ask-vault-pass
```

For each enabled app, `verify.yml` checks that the container is running, is healthy, has the restart policy `unless-stopped`, and publishes ports only on 127.0.0.1. It checks that PostgreSQL has no published port and sits only on its internal network. For each app with a domain, both playbooks request `https://<domain>/` through Caddy. They use `curl --resolve`, so the check works even before DNS has spread.

Then open `https://git.example.com` in your browser and log in with the account from the table above.

## Reach an app without a domain

Open an SSH tunnel from your computer. This forwards local port 5050 to port 5050 on the server's 127.0.0.1:

```bash
ssh -L 5050:127.0.0.1:5050 sysadmin@203.0.113.10
```

Keep that session open and browse to http://localhost:5050. Use the port from the table above for other apps.

In pgAdmin, add a server with host `postgres`, port `5432`, user `postgres` and the PostgreSQL password from the vault.

For a SQL shell without pgAdmin:

```bash
sudo docker exec -it postgres psql -U postgres
```

## After the first login

- **Memos**: the playbook creates the admin account, but public sign-up stays open. Turn it off in Settings > System if you do not want other people to register.
- **ntfy**: anonymous users can neither read nor publish. Add users and give them access to a topic:

  ```bash
  sudo docker exec -it ntfy ntfy user add alice
  sudo docker exec -it ntfy ntfy access alice mytopic rw
  ```

- **Gitea**: registration is closed and Git over SSH is off. Clone and push over HTTPS. Create more users in the admin panel.
- **Changing an admin password**: change it in the app itself. The vault value is only used when the account is first created, so changing it in the vault later does nothing. The database passwords (`vault_*_db_password`) are different: the playbook is designed to update the database user and the app container when they change. That path has not been tested yet, so take a backup first.

## Turn a service off

Set `<name>_enabled: false` and run the playbook again. The playbook removes `/etc/caddy/sites/<name>.caddy` and Caddy drops the site, but the playbook does **not** remove the container or its data. That is on purpose, so a typo never deletes data. To remove it by hand, take a [backup](backup-restore.md) first, then:

```bash
sudo docker rm -f memos
sudo docker volume rm memos_data
```

List the volumes with `sudo docker volume ls`.

## Common errors

| Error | Fix |
|---|---|
| `The services run in Docker. Set docker_enabled true ...` | Set `docker_enabled: true` |
| `gitea, umami store data in PostgreSQL. Set postgresql_enabled: true.` | Set `postgresql_enabled: true` |
| `Set vault_... in the vault file (at least N characters)` | The secret is missing, too short or still `replace-me` |
| A container never gets healthy | `sudo docker logs NAME` shows why. Low memory is a common cause |
| `https://<domain>` returns an error or a certificate warning | Check DNS (`dig +short`), that ports 80 and 443 are open (`sudo ufw status`) and `sudo journalctl -u caddy` |

## Sources

- Docker port publishing and firewalls: https://docs.docker.com/engine/network/packet-filtering-firewalls/
- Caddy automatic HTTPS: https://caddyserver.com/docs/automatic-https
- PostgreSQL image (data directory for version 18): https://hub.docker.com/_/postgres
- Gitea in Docker: https://docs.gitea.com/installation/install-with-docker
- Semaphore UI in Docker: https://docs.semaphoreui.com/administration-guide/installation/docker
- ntfy configuration: https://docs.ntfy.sh/config/
- Umami install: https://umami.is/docs/install
