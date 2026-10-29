# Upgrade packages and container images

This guide covers the updates that do not happen on their own: non-security packages, Docker and Caddy, reboots, the app images, and the Ansible tools on your control machine.

## What updates on its own

Ubuntu's unattended-upgrades installs **security updates from the Ubuntu archive** every day. The playbook keeps it on. It does not:

- install non-security updates,
- update packages from Docker's or Caddy's own repositories,
- reboot the server,
- pull new container images.

The [security model](../explanation/security-model.md#automatic-security-updates-without-automatic-reboot) explains why.

## Upgrade all packages

On the server:

```bash
sudo apt update
sudo apt full-upgrade
```

`apt update` downloads the current package lists. `apt full-upgrade` installs every available upgrade, including Docker and Caddy from their repositories. Read the list before you answer `Y`.

A Docker upgrade restarts the Docker service, and with it every container. Do it when a few seconds of downtime are fine.

## Reboot when needed

Some updates, such as a new kernel, only take effect after a reboot. Ubuntu creates a marker file when that is the case:

```bash
cat /var/run/reboot-required
cat /var/run/reboot-required.pkgs
```

If the first file exists, reboot when it suits you:

```bash
sudo reboot
```

Containers start again on their own after the reboot (restart policy `unless-stopped`). Then check the server:

```bash
ansible-playbook playbooks/verify.yml --ask-vault-pass -K
```

Reboot behaviour has not been tested in this project yet, so do run that check.

## Upgrade an app image

Image tags are pinned, for example `gitea_image: docker.gitea.com/gitea:28.2.0`. A tag never moves on its own, so an app is only upgraded when you change its tag.

1. Read the app's release notes for every version between yours and the new one. Look for breaking changes and manual steps.
2. [Back up](backup-restore.md) the app's database and volume.
3. Change the tag in your inventory or in `inventory/group_vars/all/services.yml`:

   ```yaml
   gitea_image: docker.gitea.com/gitea:28.3.0
   ```

   This is an example. Use the real version from the release notes.

4. Run the services playbook:

   ```bash
   ansible-playbook playbooks/services.yml --ask-vault-pass -K
   ```

   The playbook pulls the new image, recreates the container and waits until it is healthy. The data volume stays.

5. Run `playbooks/verify.yml` and log in to the app.

To roll back, set the old tag and run the playbook again. This only works if the new version did not change the data format. If it did, restore the backup from step 2.

The image variables are `postgresql_image`, `pgadmin_image`, `gitea_image`, `umami_image`, `semaphore_image`, `memos_image` and `ntfy_image`.

## Upgrade PostgreSQL

**Minor versions** (for example 18.6 to 18.7) only need a new tag. Follow the steps above with `postgresql_image`.

**Major versions** (for example 18 to 19) change the on-disk format. A new tag on the old volume does not work. You need to dump the data, start the new version on an empty volume and restore. This has **not been tested** in this project. Practise on a test VM first.

1. Dump each app database (see [Back up PostgreSQL](backup-restore.md#back-up-postgresql)) and copy the dumps off the server.
2. Stop the apps and remove PostgreSQL and its volume:

   ```bash
   sudo docker stop gitea umami semaphore pgadmin
   sudo docker rm -f postgres
   sudo docker volume rm postgres_data
   ```

   Only remove the volume after you have checked the dumps.

3. Set the new `postgresql_image` and run `playbooks/services.yml`. It creates an empty PostgreSQL with the app users and databases, and starts the apps.
4. Restore each database with the [one database](backup-restore.md#restore-one-database) steps.
5. Run `playbooks/verify.yml` and log in to each app.

If you used this project before PostgreSQL 18 with a volume mounted at `/var/lib/postgresql/data`, the current playbook does not use that volume. It creates a new one named `postgres_data`. Move your data with a dump and restore in the same way.

## Upgrade the Ansible tools

On your control machine, inside the virtual environment:

```bash
. .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml --upgrade
```

`requirements.txt` and `requirements.yml` set version ranges, so this only installs versions inside those ranges. After a `git pull` that changes them, run the same commands.

## Sources

- Ubuntu automatic updates: https://ubuntu.com/server/docs/how-to/software/automatic-updates/
- PostgreSQL upgrades: https://www.postgresql.org/docs/current/upgrading.html
- PostgreSQL image: https://hub.docker.com/_/postgres
