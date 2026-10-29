# Tutorial: set up your first VPS

In this tutorial you take a brand new Ubuntu server and turn it into a server that only accepts SSH keys, has a firewall, installs security updates on its own, and has an admin user for daily work. You do it with the playbooks in this repository, and at the end you check the result.

It takes about an hour the first time. You need no Ansible experience. If the Linux commands are new to you, keep [Basic Linux commands](reference/linux-commands.md) open next to this page.

## Contents

1. [Words used in this tutorial](#words-used-in-this-tutorial)
2. [Get a server](#step-1-get-a-server)
3. [Create an SSH key](#step-2-create-an-ssh-key)
4. [Prepare your control machine](#step-3-prepare-your-control-machine)
5. [Describe your server in the inventory](#step-4-describe-your-server-in-the-inventory)
6. [Store the admin password in the vault](#step-5-store-the-admin-password-in-the-vault)
7. [Run the playbook](#step-6-run-the-playbook)
8. [Switch to the admin user](#step-7-switch-to-the-admin-user)
9. [Verify the server](#step-8-verify-the-server)
10. [Common errors](#common-errors)
11. [Next steps](#next-steps)

## Words used in this tutorial

- **VPS** (virtual private server): a virtual machine you rent from a hosting provider.
- **Control machine**: your own computer, where you run Ansible. Ansible connects from here to the server over SSH. Nothing needs to be installed on the server except Python, which Ubuntu already has.
- **Inventory**: a file that lists your servers and how to reach them. Here it is `inventory/hosts.yml`.
- **Playbook**: a YAML file with a list of steps for Ansible to run. Each step is a **task**, and each task uses a **module**, a small program such as `ansible.builtin.apt` that installs packages.
- **Variables**: settings the playbooks read, such as the name of the admin user. The defaults are in `inventory/group_vars/all/`.
- **Vault**: an encrypted file for secrets such as passwords. Ansible decrypts it in memory when it runs.
- **become**: Ansible's word for running a task as root with sudo.
- **Idempotent**: running the same playbook twice gives the same result. The second run changes nothing and reports `changed=0`.

## Step 1: Get a server

Create a VPS with **Ubuntu 24.04 LTS or Ubuntu 26.04 LTS**. Most providers have both images, for example DigitalOcean, Hetzner, Linode or Vultr. Other releases are refused by the playbooks.

When you pick a provider, check that it offers:

1. **Console access outside of SSH** (a web console, VNC or serial). If an SSH or firewall change goes wrong, the console is how you get back in. Do not skip this one. See [Recover from an SSH or firewall lockout](how-to/recover-access.md).
2. **A way to add your SSH public key when the server is created.** You create the key in the next step, so you may want to do step 2 first.
3. **A data center close to you or to your users**, for lower latency.

Some providers also offer disk encryption. It protects data at rest, for example on disks that are thrown away. It does not protect a running server, because the key is in memory while the server runs.

If you install Ubuntu yourself from an ISO, download it from [ubuntu.com/download/server](https://ubuntu.com/download/server) and follow the [official install tutorial](https://ubuntu.com/tutorials/install-ubuntu-server). Choose "Install OpenSSH server" during the installation.

Write down the server's public IP address. This tutorial uses `203.0.113.10` as an example. Replace it with yours everywhere.

> **Practice first.** You can do this whole tutorial on a local virtual machine before you touch a real server. [Run the tests in Lima VMs](how-to/test-with-lima.md) shows how to create one.

## Step 2: Create an SSH key

An SSH key pair has two parts. The **private key** stays on your computer and must never be shared. The **public key** goes on the server. When you connect, the server checks that you hold the private key that matches. After this tutorial, the server accepts only keys, not passwords.

1. Open a terminal on your control machine and create a key:

   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

   `-t ed25519` picks a modern key type. `-C` adds a label so you can recognise the key later.

2. Press Enter to accept the default location, `~/.ssh/id_ed25519`.

3. Enter a passphrase. It encrypts the private key on your disk, so a stolen laptop does not mean a stolen server. On macOS and most Linux desktops, the SSH agent remembers it after the first use.

4. Show the public key:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   The output is one line that starts with `ssh-ed25519`. You need this line twice: once for your provider, and once in step 4.

5. Add the public key to the server. Most providers have a field for it when you create the server. If your server already exists and you can log in with a password, copy the key with:

   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub root@203.0.113.10
   ```

6. Test the login. Use the user your provider gave you, often `root` or `ubuntu`:

   ```bash
   ssh root@203.0.113.10
   ```

   The first time, SSH asks you to confirm the server's fingerprint. Type `yes`. You should get a shell prompt on the server without typing the server password. Type `exit` to leave.

### Optional: an SSH config entry

If you have several keys, SSH may try them all and the server may close the connection with "Too many authentication failures". A short entry in `~/.ssh/config` tells SSH which key to use for this server:

```
Host 203.0.113.10
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

`IdentitiesOnly yes` only works together with `IdentityFile`: it makes SSH offer just that key. Ansible uses the same SSH settings, so this also helps the playbooks.

## Step 3: Prepare your control machine

You install Ansible into a Python **virtual environment**, a folder with its own Python packages. It keeps the exact versions this project needs away from the rest of your system. Do not use `sudo apt install ansible`: Ubuntu 24.04 ships ansible-core 2.16, which is too old for the collections used here.

You need Python 3.12, 3.13 or 3.14. Check with:

```bash
python3 --version
```

On Windows, install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) and do everything inside the Ubuntu shell it gives you. On Ubuntu and in WSL you may need `sudo apt install python3-venv git` first.

1. Get the code:

   ```bash
   git clone https://github.com/madalinpopa/ubuntu-server-automation.git
   cd ubuntu-server-automation
   ```

2. Create and activate the virtual environment:

   ```bash
   python3 -m venv .venv
   . .venv/bin/activate
   ```

   Your prompt now starts with `(.venv)`. Run `. .venv/bin/activate` again in every new terminal before you use Ansible.

3. Install Ansible and the collections:

   ```bash
   pip install -r requirements.txt
   ansible-galaxy collection install -r requirements.yml
   ```

   `requirements.txt` installs ansible-core 2.21 and ansible-lint. `requirements.yml` lists the **collections**, which are extra module packages: `community.general` (firewall, time zone), `ansible.posix` (SSH keys), `community.docker` and `community.postgresql` (optional services).

4. Check the result:

   ```bash
   ansible --version
   ansible-galaxy collection list
   ```

   The first line should show `ansible [core 2.21.x]`. The collection list should include the four collections above.

If `ansible-galaxy` fails with `CERTIFICATE_VERIFY_FAILED` on macOS, your Python from python.org has no certificates yet. Run "Install Certificates.command" from the Python folder in Applications, then try again.

All commands from now on run from the repository folder. Ansible reads `ansible.cfg` there, which points to the inventory at `inventory/hosts.yml`.

## Step 4: Describe your server in the inventory

1. Copy the example inventory:

   ```bash
   cp inventory/hosts.example.yml inventory/hosts.yml
   ```

   `inventory/hosts.yml` is in `.gitignore`, so your real server address never ends up in git.

2. Open `inventory/hosts.yml` and change three values:

   ```yaml
   all:
     hosts:
       vps1:
         ansible_host: 203.0.113.10
         ansible_user: root
         admin_ssh_keys:
           - "ssh-ed25519 AAAAC3Nza...your key... your_email@example.com"
   ```

   - `ansible_host`: your server's IP address or DNS name.
   - `ansible_user`: the user you logged in with in step 2 (`root` or `ubuntu`).
   - `admin_ssh_keys`: the public key line from step 2. You can list more than one key, for example one per computer.

   `vps1` is only a name for the server inside Ansible. You can change it.

3. Test the connection:

   ```bash
   ansible all -m ansible.builtin.ping
   ```

   This runs the `ping` module on every server in the inventory. It logs in over SSH and checks that Python works. Expected output:

   ```
   vps1 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```

   If you see `UNREACHABLE`, see [Common errors](#common-errors).

### Other settings

The defaults are in `inventory/group_vars/all/vars.yml`. Every setting has a comment. For a first run the defaults are fine. A few you may want to change now:

- `admin_user`: the admin account the playbook creates. Default `sysadmin`.
- `timezone`: default `Etc/UTC`, for example `Europe/Bucharest`.
- `fail2ban_enabled`: default `true`.

Docker, Caddy and the apps are off. Leave them off for now and turn them on later with [Enable optional services](how-to/enable-services.md). The [variables reference](reference/variables.md) lists every setting.

## Step 5: Store the admin password in the vault

The admin user logs in with your SSH key, but `sudo` asks for a password. You also need this password to log in at the provider's console if SSH ever fails. Ansible needs the **hash** of the password, not the password itself.

1. Create the hash. Type the password twice when asked:

   ```bash
   openssl passwd -6
   ```

   It prints one line that starts with `$6$`. That is a SHA-512 password hash, the same format Ubuntu uses in `/etc/shadow`.

   macOS ships LibreSSL, which may not support `-6`. In that case run the same command on the server, where `-t` lets it ask for the password:

   ```bash
   ssh -t root@203.0.113.10 openssl passwd -6
   ```

2. Copy the vault example to the place where Ansible loads it:

   ```bash
   cp inventory/vault.example.yml inventory/group_vars/all/vault.yml
   ```

   The example lives outside `group_vars` on purpose, so its placeholder values are never used by mistake.

3. Open `inventory/group_vars/all/vault.yml` and replace the value of `vault_admin_password_hash` with your `$6$...` line. Keep the double quotes. Leave the service passwords as they are for now. They are only checked when you turn a service on.

4. Encrypt the file:

   ```bash
   ansible-vault encrypt inventory/group_vars/all/vault.yml
   ```

   Ansible asks for a new **vault password**. This is a different password: it protects the vault file. Store it in your password manager. Without it the vault cannot be opened.

5. Check that the file is encrypted:

   ```bash
   head -1 inventory/group_vars/all/vault.yml
   ```

   Expected: `$ANSIBLE_VAULT;1.1;AES256`. To read or change it later use `ansible-vault view` or `ansible-vault edit` with the same path.

The real vault file is in `.gitignore` too. Keep a copy of it, or at least of the secrets in it, somewhere safe outside the server.

## Step 6: Run the playbook

Before you start:

- Open a second terminal and log in to the server with `ssh root@203.0.113.10`. Leave that session open until the end. Existing SSH sessions keep working when the SSH settings change, so this is your backup way in.
- Find the console button in your provider's dashboard.

Now run the full setup:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

`--ask-vault-pass` makes Ansible ask for the vault password from step 5.

`playbooks/site.yml` runs `base.yml`, `docker.yml`, `caddy.yml` and `services.yml` in that order. With the default settings only the base part does any work. In order, it:

1. Checks the server first: supported Ubuntu release, a key in `admin_ssh_keys`, a valid password hash. It stops before changing anything if a setting would lock you out.
2. Installs a small set of packages and sets the time zone.
3. Keeps unattended security upgrades turned on.
4. Creates the admin user with your keys and password, then opens a **new** SSH connection as that user to prove the key works.
5. Only then writes `/etc/ssh/sshd_config.d/00-hardening.conf`, which turns off password and root login, checks the configuration with `sshd -t`, reloads SSH and confirms the new settings with `sshd -T`.
6. Allows SSH in UFW and only then enables the firewall.
7. Configures fail2ban.

Each task prints `ok` (nothing to do), `changed` (it changed something) or `skipping` (turned off). The run ends with a summary like this:

```
PLAY RECAP *********************************************************
vps1    : ok=<n>  changed=<n>  unreachable=0  failed=0  skipped=<n> ...
```

The `ok`, `changed` and `skipped` counts depend on your settings. What matters is `unreachable=0` and `failed=0`.

### If the first run stops at "Check that a new SSH login works"

If `ansible_user` is `root`, the run ends like this:

```
TASK [Check that a new SSH login works] ****************************
fatal: [vps1]: UNREACHABLE! => ... root@203.0.113.10: Permission denied (publickey).
```

This is a known problem. The task logs in again as `ansible_user` to prove that new logins still work, but the hardening step has just turned off root login, so root cannot log in any more. The admin user was already tested before the SSH change, so you are not locked out. The firewall and fail2ban tasks did not run yet. Continue with step 7: the next run, as the admin user, finishes them.

If your provider gave you a user such as `ubuntu`, this does not happen.

## Step 7: Switch to the admin user

From now on you work as the admin user, not as root.

1. Test the login in a new terminal:

   ```bash
   ssh sysadmin@203.0.113.10
   sudo -v
   ```

   `sudo -v` asks for the admin password and does nothing else. If it is accepted, sudo works. Then type `exit`.

2. In `inventory/hosts.yml`, change `ansible_user: root` to `ansible_user: sysadmin` (or your `admin_user`).

3. **Ubuntu 26.04 only.** In `inventory/hosts.yml`, remove the `#` in front of this line under your host:

   ```yaml
   ansible_become_exe: sudo.ws
   ```

   Ubuntu 26.04 uses sudo-rs as its `sudo`. ansible-core 2.21.5 does not recognise the sudo-rs password prompt and fails with "Timeout waiting for privilege escalation prompt". `sudo.ws` is the classic sudo, which 26.04 still ships. The [security model](explanation/security-model.md#sudo-rs-on-ubuntu-2604) has the details.

4. Run the playbook again. `-K` (short for `--ask-become-pass`) makes Ansible ask for the sudo password:

   ```bash
   ansible-playbook playbooks/site.yml --ask-vault-pass -K
   ```

   If the first run finished without errors, this run should end with `changed=0`, because everything is already in place. If the first run stopped early, this run finishes the remaining tasks. Run it once more and you should see `changed=0`.

## Step 8: Verify the server

The playbook already checks its own work as it goes. The two verification playbooks check the result again from scratch and change nothing. Run them now, and again whenever you want to be sure the server is still in the state you expect.

1. Checks on the server:

   ```bash
   ansible-playbook playbooks/verify.yml --ask-vault-pass -K
   ```

   This reads the real state: effective SSH settings, firewall rules for IPv4 and IPv6, which ports listen on public addresses, systemd services, automatic updates, the admin user's files and fail2ban. The full list is in [what verify.yml checks](reference/playbooks.md#what-verifyyml-checks).

2. Checks from outside:

   ```bash
   ansible-playbook playbooks/verify_external.yml --ask-vault-pass
   ```

   This runs on your computer. It connects to the server's ports the way anyone on the internet would. It checks that SSH is open, that common database and admin ports are closed, that your key logs you in as the admin user, and that a login without a key is refused.

Both should end with `failed=0`. A failed check says what is wrong, for example:

```
Unexpected public listeners on TCP ports [8081]. Docker-published ports bypass UFW. ...
```

You can also look by hand. On the server:

```bash
sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication)'
sudo ufw status verbose
sudo ss -tlnp
```

Expected: `passwordauthentication no`, `permitrootlogin no`, `pubkeyauthentication yes`; UFW `Status: active` with `Default: deny (incoming)` and a rule for `22/tcp`; and only port 22 (plus 80 and 443 with Caddy) listening on `0.0.0.0` or `[::]`.

From your computer, a root login must now fail:

```bash
ssh root@203.0.113.10
```

Expected: `root@203.0.113.10: Permission denied (publickey).`

You can close the backup session from step 6 now.

## Common errors

| Error | Cause | Fix |
|---|---|---|
| `UNREACHABLE! ... Permission denied (publickey)` on the first task | Wrong `ansible_user`, or SSH does not offer the right key | Check that `ssh USER@203.0.113.10` works by hand with the same user. Add the key to the SSH agent (`ssh-add ~/.ssh/id_ed25519`) or use the [SSH config entry](#optional-an-ssh-config-entry) |
| `UNREACHABLE! ... Host key verification failed` | The server was rebuilt and has a new host key | `ssh-keygen -R 203.0.113.10`, then log in once by hand and accept the new key |
| `Too many authentication failures` | SSH offered too many keys | Use the [SSH config entry](#optional-an-ssh-config-entry) |
| `Attempting to decrypt but no vault secrets found` | The vault file is encrypted and you did not give the vault password | Add `--ask-vault-pass` |
| `Missing sudo password` | `ansible_user` is the admin user and sudo needs a password | Add `-K` |
| `Timeout (12s) waiting for privilege escalation prompt` | Ubuntu 26.04 with sudo-rs | Set `ansible_become_exe: sudo.ws` (step 7) |
| `This server runs Ubuntu 22.04 ... Supported releases: 24.04, 26.04` | Unsupported release | Reinstall with 24.04 or 26.04 |
| `Set admin_user (not root) and add at least one public key to admin_ssh_keys` | `admin_ssh_keys` is empty | Add your public key (step 4) |
| `admin_password_hash is empty or still the example value` | The vault has no real hash, or is not in `inventory/group_vars/all/vault.yml` | Repeat step 5 |
| Stops at "Check that the admin user can log in with an SSH key" | The key in `admin_ssh_keys` does not match the key your SSH client uses | Fix `admin_ssh_keys` and run again. Nothing in SSH or the firewall has changed yet at this point |
| Stops at "Check that sshd listens on ssh_port before changing anything" | sshd does not listen on `ssh_port` (default 22), for example on a server set up by an old version of this project with port 2222 | Set `ssh_port` to the port sshd really uses. Check with `sudo ss -tlnp` |
| `ssh_allow_users is [...]. It must include admin_user ...` | `ssh_allow_users` would lock out the user Ansible connects as | Add both users to the list, or leave it empty |

If you are locked out, see [Recover from an SSH or firewall lockout](how-to/recover-access.md).

## Next steps

- Turn on Docker, Caddy and apps: [Enable optional services](how-to/enable-services.md).
- Understand what was changed and why: [Security model and tradeoffs](explanation/security-model.md).
- Plan backups before you store anything important: [Back up and restore data](how-to/backup-restore.md).
- Keep the server up to date: [Upgrade packages and container images](how-to/upgrade.md).
