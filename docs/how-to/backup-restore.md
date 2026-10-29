# Back up and restore data

This project does not make backups for you. This guide shows the manual commands for the optional services: PostgreSQL databases and the Docker volumes that hold app data. Run them on the server as the admin user.

A backup that stays on the server is lost together with the server. Copy every backup to another machine.

## What to back up

| Data | Where it lives | How |
|---|---|---|
| Gitea, Umami and Semaphore databases | PostgreSQL (`postgres_data` volume) | `pg_dump` or `pg_dumpall` |
| Gitea repositories and settings | `gitea_data` volume | volume archive |
| Memos notes (SQLite) | `memos_data` volume | volume archive |
| ntfy users and message cache | `ntfy_data` volume | volume archive |
| pgAdmin settings | `pgadmin_data` volume | volume archive |
| Semaphore config | `semaphore_config` and `semaphore_data` volumes | volume archive |
| Secrets | your vault file on the control machine | keep a copy somewhere safe |

`vault_gitea_secret_key` and `vault_semaphore_access_key_encryption` are part of the backup. Without them, restored data that Gitea or Semaphore encrypted cannot be read.

List the volumes on the server:

```bash
sudo docker volume ls
```

## Back up PostgreSQL

The dump files contain all your data and the password hashes of the database users. Create them in a private folder:

```bash
mkdir -p ~/backups
chmod 700 ~/backups
cd ~/backups
```

**One database**, in PostgreSQL's custom format (`-Fc`, compressed, restored with `pg_restore`):

```bash
sudo docker exec postgres pg_dump -U postgres -Fc gitea > gitea.dump
```

Replace `gitea` with `umami` or `semaphore` for the other apps. The database names come from `gitea_db_name`, `umami_db_name` and `semaphore_db_name`.

**All databases and users** at once, as plain SQL:

```bash
sudo docker exec postgres pg_dumpall -U postgres > all.sql
```

Check that the file is not empty and ends cleanly:

```bash
ls -lh all.sql
tail -3 all.sql
```

Expected: a size that is not zero (about 430 KB in a test with three almost empty app databases), and `-- PostgreSQL database cluster dump complete` near the end.

The database stays online during the dump. `pg_dump` gives a consistent snapshot without stopping the apps.

## Restore one database

This restore was tested with Gitea on Ubuntu 24.04: the admin user and the database owner came back.

```bash
cd ~/backups
sudo docker stop gitea
sudo docker exec postgres psql -U postgres -c 'DROP DATABASE gitea WITH (FORCE)'
sudo docker exec -i postgres pg_restore -U postgres -d postgres --create < gitea.dump
sudo docker start gitea
```

What each line does:

1. Stops the app so it does not write while you restore.
2. Deletes the current database. `WITH (FORCE)` closes any connections still open.
3. `--create` recreates the database from the dump, with its original owner, then loads the data. `-d postgres` is only the database to connect to first.
4. Starts the app again.

Check: `sudo docker ps` shows the container as `healthy` after a minute, and you can log in.

## Restore all databases

Use this to move to a new server, or after the `postgres_data` volume was lost. `all.sql` must be loaded into a PostgreSQL that has no app databases yet, before the apps start and create their own tables. This path has **not been tested** end to end in this project.

1. On the new server, turn on only PostgreSQL: `postgresql_enabled: true`, and every app (`gitea_enabled`, `umami_enabled`, `semaphore_enabled`, `pgadmin_enabled`) `false`. Run the playbook.
2. Copy `all.sql` to the server and load it:

   ```bash
   sudo docker exec -i postgres psql -U postgres -d postgres < all.sql
   ```

   An error such as `role "postgres" already exists` is expected. Read any other errors.

3. Turn the apps back on and run the playbook again. It finds the users and databases from the dump and sets the database passwords from your vault.

If the apps already started on the new server, restore each database with the [one database](#restore-one-database) steps instead. That needs the per-app `.dump` files.

## Back up a Docker volume

This packs the content of a volume into a `.tgz` file in the current folder. Stop the container first, so files do not change while they are copied. The example uses Memos:

```bash
cd ~/backups
sudo docker stop memos
sudo docker run --rm -v memos_data:/data:ro -v "$PWD":/backup busybox:1.37 tar czf /backup/memos_data.tgz -C /data .
sudo docker start memos
```

The middle command starts a throwaway `busybox` container that mounts the volume read-only at `/data` and the current folder at `/backup`, runs `tar`, and is removed when done (`--rm`).

Check the archive:

```bash
tar tzf memos_data.tgz | head
```

Use the same commands for `gitea_data` (container `gitea`), `ntfy_data` (`ntfy`), `pgadmin_data` (`pgadmin`), and `semaphore_config` and `semaphore_data` (both `semaphore`).

## Restore a Docker volume

The backup side above was tested. This restore has **not been tested** in this project. Try it on a test VM first.

```bash
cd ~/backups
sudo docker stop memos
sudo docker run --rm -v memos_data:/data -v "$PWD":/backup busybox:1.37 sh -c 'rm -rf /data/* /data/.[!.]* ; tar xzf /backup/memos_data.tgz -C /data'
sudo docker start memos
```

The `rm` empties the volume first, so no files from the current state are left mixed with the backup.

## Copy backups off the server

From your control machine:

```bash
scp 'sysadmin@203.0.113.10:backups/*' ./server-backups/
```

Create `./server-backups/` first. Store the copies somewhere encrypted, because they contain your data and password hashes.

## Test your backups

A backup you have never restored is a guess. Create a test VM (see [Run the tests in Lima VMs](test-with-lima.md)), run the playbook with the same services, and restore into it.

## Sources

- `pg_dump`: https://www.postgresql.org/docs/current/app-pgdump.html
- `pg_restore`: https://www.postgresql.org/docs/current/app-pgrestore.html
- Back up Docker volumes: https://docs.docker.com/engine/storage/volumes/#back-up-restore-or-migrate-data-volumes
