# Basic Linux commands

A short list of the commands used in these docs, plus a few that help when you look around a server. If you are new to Linux, these are enough to follow the tutorial and check what the playbooks did.

Add `--help` to most commands, or run `man COMMAND`, to see all options.

## Files and directories

| Command | What it does |
|---|---|
| `pwd` | Print the folder you are in |
| `ls -la` | List files, including hidden ones, with owner and permissions |
| `cd /etc/ssh` | Change to another folder. `cd` alone goes to your home folder |
| `mkdir -p backups` | Create a folder. `-p` creates parent folders too and does not fail if it exists |
| `cp file1 file2` | Copy a file |
| `mv file1 file2` | Move or rename a file |
| `rm file1` | Delete a file. There is no trash bin |
| `cat file1` | Print a file |
| `less file1` | Read a file page by page. `q` quits |
| `nano file1` | Edit a file. `Ctrl+O` saves, `Ctrl+X` quits |
| `tail -f file1` | Show the end of a file and keep printing new lines. `Ctrl+C` stops |

## Users and permissions

| Command | What it does |
|---|---|
| `whoami` | Print your user name |
| `id` | Print your user and the groups you are in |
| `sudo COMMAND` | Run a command as root. Asks for your password |
| `sudo -v` | Check that sudo works, without running anything |
| `chown user:group file` | Change the owner of a file |
| `chmod 600 file` | Change permissions. `600` means only the owner can read and write |

## SSH and network

| Command | What it does |
|---|---|
| `ssh sysadmin@203.0.113.10` | Log in to a server |
| `ssh -v sysadmin@203.0.113.10` | The same, with debug output. Useful when login fails |
| `scp file sysadmin@203.0.113.10:/home/sysadmin/` | Copy a file to the server |
| `ip a` | Show network interfaces and IP addresses. Replaces the older `ifconfig`, which Ubuntu Server does not install |
| `sudo ss -tlnp` | Show which TCP ports are listening, on which address, and by which program. `0.0.0.0` or `[::]` means all addresses; `127.0.0.1` means only this server |
| `curl -I http://127.0.0.1/` | Request a web page and show only the response headers |
| `dig +short example.com` | Show the IP address a DNS name points to |

## Services and logs

Ubuntu uses **systemd** to start and supervise services. A service is a **unit**, such as `ssh.service` or `caddy.service`.

| Command | What it does |
|---|---|
| `systemctl status caddy` | Show whether a service runs, and its last log lines |
| `sudo systemctl restart caddy` | Stop and start a service |
| `sudo systemctl reload caddy` | Ask a service to reread its config without stopping |
| `systemctl list-timers` | Show scheduled jobs, such as the daily apt updates |
| `journalctl -u ssh -n 50` | Show the last 50 log lines of a service |
| `journalctl -u caddy -f` | Follow the log of a service live |

## Firewall, SSH and fail2ban

| Command | What it does |
|---|---|
| `sudo ufw status verbose` | Show whether UFW is active, its defaults and its rules |
| `sudo ufw allow 22/tcp` | Allow incoming TCP port 22 |
| `sudo sshd -t` | Test the SSH server config. No output means it is valid |
| `sudo sshd -T` | Print the settings the SSH server really uses, after all config files |
| `sudo fail2ban-client status sshd` | Show failed logins and banned IP addresses |

## Docker

These need `sudo`, because the admin user is not in the `docker` group by default.

| Command | What it does |
|---|---|
| `sudo docker ps` | List running containers, their health and published ports |
| `sudo docker logs gitea` | Show a container's log |
| `sudo docker exec -it postgres psql -U postgres` | Run a command inside a container, here a SQL shell |
| `sudo docker volume ls` | List volumes, where containers keep their data |
| `sudo docker stop gitea` / `sudo docker start gitea` | Stop or start a container |

## System

| Command | What it does |
|---|---|
| `lsb_release -a` | Show the Ubuntu release |
| `uname -a` | Show the kernel version |
| `df -h` | Show free disk space |
| `free -h` | Show memory use |
| `uptime` | Show how long the server has been running, and the load |
| `top` | Show running processes live. `q` quits |
| `timedatectl` | Show the time, the time zone and whether time sync is on |
| `sudo apt update && sudo apt full-upgrade` | Install all available updates |
| `cat /var/run/reboot-required` | Exists only when an update needs a reboot |
| `sudo reboot` | Restart the server |
