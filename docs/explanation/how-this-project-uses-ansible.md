# How this project uses Ansible

This page is for people who are new to Ansible. It starts with a playbook you can run on your own computer, then walks through how the files in this repository fit together. For the steps to set up a server, see the [tutorial](../tutorial-first-vps.md).

The workshop version of this project from [OmniOpenCon 2024](https://omniopencon.org/) built an Ansible project step by step, from an empty folder. You can still read it at [commit a662663](https://github.com/madalinpopa/ubuntu-server-automation/tree/a662663). Its playbooks are out of date, so use it for learning only, not on a server.

## A first playbook

A **playbook** is a YAML file with one or more **plays**. A play says which hosts to work on and which **tasks** to run there. Each task calls a **module**, a small program that does one job.

Save this as `hello.yml` anywhere on your computer:

```yaml
---
- name: Say hello
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "Hello, World!"
```

Run it:

```bash
ansible-playbook hello.yml
```

The output shows `"msg": "Hello, World!"` and ends with a `PLAY RECAP` line with `ok=1`. Ansible may warn that no inventory was parsed. That is fine here, because `localhost` always exists. `connection: local` runs the task on your computer without SSH.

`ansible.builtin.debug` is the module's full name, its **FQCN** (fully qualified collection name). `ansible.builtin` is the **collection** that comes with Ansible. Modules from other collections, such as `community.general.ufw`, are installed separately. This project lists the ones it needs in `requirements.yml`, and `ansible-galaxy collection install -r requirements.yml` installs them.

## The inventory

The **inventory** lists the servers Ansible manages and how to reach them. This project uses a YAML file, `inventory/hosts.yml`, copied from `inventory/hosts.example.yml`:

```yaml
all:
  hosts:
    vps1:
      ansible_host: 203.0.113.10
      ansible_user: root
```

`vps1` is a name you choose. `ansible_host` is the address Ansible connects to and `ansible_user` is the SSH user. Test the connection with the `ping` module. It logs in over SSH and checks that Python works on the server:

```bash
ansible all -m ansible.builtin.ping
```

Expected: `vps1 | SUCCESS` and `"ping": "pong"`.

Ansible reads the inventory given with `-i`. Without `-i`, it uses the `inventory` setting from `ansible.cfg`. This project sets it to `inventory/hosts.yml`, so you do not need `-i`.

## ansible.cfg

`ansible.cfg` holds settings for the `ansible` and `ansible-playbook` commands. Ansible uses the first one it finds, in this order:

1. the file named in the `ANSIBLE_CONFIG` environment variable,
2. `ansible.cfg` in the current folder,
3. `~/.ansible.cfg` in your home folder,
4. `/etc/ansible/ansible.cfg`.

That is why you run the commands from the repository folder: then the project's `ansible.cfg` is used. It sets the inventory, turns off a warning about the Python interpreter, and turns on **pipelining**, which makes runs faster. Check which file is used with `ansible --version`. The `config file =` line shows the path.

## How the playbooks fit together

`playbooks/site.yml` runs everything. It only imports the other playbooks, in order:

```
playbooks/site.yml
├── playbooks/base.yml       → tasks/preflight.yml, apt.yml, updates.yml, users.yml, ssh.yml, firewall.yml, fail2ban.yml
├── playbooks/docker.yml     → tasks/docker.yml
├── playbooks/caddy.yml      → tasks/caddy.yml
└── playbooks/services.yml   → services/postgresql.yml, gitea.yml, ... (one file per app)
```

Each playbook has one play with `hosts: all` and `become: true`. **become** means the tasks run as root through sudo. The tasks themselves live in task files, which the play pulls in with `ansible.builtin.import_tasks`. A `when:` on an import, such as `when: fail2ban_enabled | bool`, applies to every task in that file. That is how the optional parts stay off.

You can run any of the four playbooks on its own, for example `ansible-playbook playbooks/base.yml`.

## Variables

Variables are the settings the tasks read, such as `admin_user` or `docker_enabled`. The defaults live in `inventory/group_vars/all/`. Ansible loads every file in a `group_vars/<group>/` folder next to the inventory for the hosts in that group, and `all` is the group with every host.

You can override a default for one server under that host in `inventory/hosts.yml`. Host variables win over group variables. Values given with `-e` on the command line win over everything. The [variables reference](../reference/variables.md) lists them all.

Secrets go in `inventory/group_vars/all/vault.yml`, which you encrypt with `ansible-vault`. Ansible decrypts it in memory when you pass `--ask-vault-pass`. Tasks that handle a secret set `no_log: true`, so the value never shows up in the output.

## Templates and handlers

A **template** is a file with placeholders that Ansible fills in from variables before it copies the file to the server. The templates are in `playbooks/templates/`, for example `sshd_hardening.conf.j2`. The `.j2` ending stands for Jinja2, the template language Ansible uses.

A **handler** is a task that runs only when another task changed something and notified it. For example, `Reload ssh` in `handlers/main.yml` runs only when the SSH config file changed. Handlers run once, at the end of the play. So ten changes still mean one reload, and a run that changes nothing reloads nothing.

## Idempotency

Each task describes the state you want, not the steps to get there. `ansible.builtin.apt` with `state: present` installs a package only if it is missing. So a second run of the same playbook changes nothing and reports `changed=0`. `tests/run.sh` checks this on every test run.

## Why there are no roles

A **role** is a folder layout that bundles tasks, handlers, templates and default variables, so it can be shared between projects. The workshop explained roles, but its playbooks used plain task files, and so does this project. It is one project for one kind of server, and plain task files are easier to read from top to bottom. If you later want to reuse a part elsewhere, turning a task file into a role is a small step. See [Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html) in the Ansible docs.

## Sources

- Ansible getting started: https://docs.ansible.com/ansible/latest/getting_started/index.html
- Configuration file order: https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file
- Variable precedence: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence
- Handlers: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html
