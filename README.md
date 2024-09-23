# OmniOpenCon 2024

OmniOpenCon is a gathering of people, projects and communities involved in all things open: open source, open data, open science, open hardware, open education. We value openness, freedom and sharing and we want to bring together all who share these beliefs.

## Workshop: From Zero to DevOps Cloud: Ansible-Driven VPS Setup for Development

## Table of Contents

* [Abstract](#abstract)
* [Prerequisites](#prerequisites)
    * [VPS Setup](#vps-setup)
    * [Generate SSH Key Pair](#generate-ssh-key-pair)
    * [Ansible Installation](#ansible-installation)
    * [Basic Linux Commands](#basic-linux-commands)
* [Ansible Project Setup](#ansible-project-setup)
    * [Ansible "Hello World"](#ansible-hello-world)
    * [Ansible Inventory](#ansible-inventory)
    * [Ansible Configuration](#ansible-configuration)
    * [Ansible Playbooks](#ansible-playbooks)
    * [Ansible Roles](#ansible-roles)
 * [Server Configuration](#server-configuration)
    * [Package Installation](#package-installation)
        * [Common Packages](#common-packages)
        * [Docker Installation](#docker-installation)
    * [Security Setup](#security-setup)
    * [Service Configuration](#service-configuration)
* [Resources](#resources)
* [Feedback](#feedback)

## Abstract

Welcome to OmniOpenCon 2024 and this workshop titled “From Zero to DevOps Cloud: Ansible-Driven VPS Setup for Development.”

This is a hands-on workshop part of OmniOpenCon 2024, where we will explore how to automate the process of setting up a Virtual Private Server (VPS) from scratch using Ansible. We will focus on leveraging Ansible to handle all the configuration tasks that typically require manual intervention, including security setup, package installations, and service configurations.

By the end of this workshop, you will have a fully automated VPS setup for development purposes, using Ansible playbooks. You will also learn how to deploy services like Docker to run your development environments and set up secure access to your VPS and services using a VPN.

- Understand the basics of Ansible and its role in automating infrastructure setup.
- Learn how to write Ansible playbooks to define the desired state of your VPS.
- Apply your knowledge to create a fully automated VPS setup for development purposes.
- Have a fully configured VPS for development, using Ansible playbooks.
- Deploy services like Docker to run your development environments.
- Set up secure access to your VPS and services using a VPN.

This workshop is designed to minimize manual setup and centralize configuration management within Ansible, allowing you to create reproducible, scalable infrastructure deployments. Let’s dive into automation and simplify your DevOps workflow!

## Prerequisites

Before diving into the automation process, make sure you have the following:

* A VPS (Virtual Private Server) with root access. 
  * You can use any cloud provider like AWS, DigitalOcean, Linode, or a local VPS provider.
  * SSH access to your VPS.
* Local Environment Setup:
  * Ansible installed on your local machine.
  * SSH key pair for secure access to your VPS.
  * Basic knowledge of Linux commands and system administration.
  * A text editor like VS Code or Vim.

### VPS Setup

If you don’t have a VPS yet, you can follow our [VPS Setup Guide](./docs/vps-setup.md) to create one.

### Generate SSH Key Pair

If you don’t have an SSH key pair, you can follow our [SSH Key Pair Generation Guide](./docs/ssh-keypair.md) to create one.

### Ansible Installation

If you don’t have Ansible installed on your local machine, you can follow our [Ansible Installation Guide](./docs/ansible-installation.md).

### Basic Linux Commands

If you are new to Linux commands, you can refer to our [Basic Linux Commands Guide](./docs/linux-basic.md) for a quick overview.

## Ansible Project Setup 

Now that you have your VPS set up and Ansible installed, let’s start with the Ansible configuration. We will create a new Ansible project to hold our playbooks and configurations.

1. Create a new directory for your Ansible project:

```bash
mkdir ansible-project
```

2. Change to the newly created directory:

```bash
cd ansible-project
```

### Ansible "Hello World"

Let's start with a simple Ansible Playbook to print "Hello, World!" and to check the connection with your VPS. Create a new file named `site.yml` in your project directory with the following content:

```yaml
---
- hosts: localhost
  tasks:
    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"
```

Now, run the playbook using the following command:

```bash
ansible-playbook site.yml
```
If you see the output `Hello, World!`, your Ansible setup is working correctly.

### Ansible Inventory 

Ansible uses the inventory file to define the target hosts for the playbooks. The inventory file can be in various formats, including INI, YAML, and JSON. In this workshop, we will use the YAML format for the inventory file.

Ansible is looking for the inventory file in the following order:

1. The file specified using the `-i` option in the `ansible-playbook` command.
2. The default inventory file located at `/etc/ansible/hosts`.
3. The default inventory file located in the project directory named `inventory`.

Now, let's test the connection with our VPS. The first step is to create an inventory file to define the VPS host. Create a new file named `inventory.yml` in your project directory with the following content:

```yaml
vps:
  hosts:
    mycloud.com:
```
If you followed the steps in SSH Key Pair Generation Guide, you can use `mycloud.com` as the host name. If you used a different host name, replace `mycloud.com` with your VPS host name that you defined in the SSH configuration file.

After creating the inventory file, update the `site.yml` playbook to use the VPS group or host's name as the target host:

```yaml
---
- hosts: vps
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:
```
After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml 
```
If you see the output `pong`, the connection with your VPS is successful.

### Ansible Configuration

Ansible uses a configuration file to define settings like the default inventory file, remote user, and connection type. Create a new file named `ansible.cfg` in your project directory with the following content:

```ini
[defaults]
localhost_warning = False
interpreter_python=auto_silent

[inventory]
inventory_unparsed_warning = False

[privilege_escalation]
become_ask_pass = true
```
This configuration file disables the warning for using `localhost` as the target host, sets the path to the vault password file, and disables the warning for unparsed inventory files. It also sets the Python interpreter to auto-detect and disables the prompt for privilege escalation password.

As best practice, any sensitive data like passwords should be stored in an encrypted file using Ansible Vault. The `vault_password_file` setting specifies the path to the file containing the vault password.

Ansible is looking for the configuration file in the following order:

1. `ANSIBLE_CONFIG` environment variable.
2. `ansible.cfg` in the current directory.
3. `~/.ansible.cfg` in the user's home directory.
4. `/etc/ansible/ansible.cfg`.

If you want to use a different configuration file, you can set the `ANSIBLE_CONFIG` environment variable to the desired file path.
Usually is best to have the configuration file in your home directory.

### Ansible Playbooks

Ansible playbooks are YAML files that define a set of tasks to be executed on the target hosts. Playbooks can include multiple plays, each targeting different hosts or groups of hosts. Each play consists of tasks that define the actions to be performed on the target hosts.

A list with all the Ansible modules can be found [here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html).

Also, you can find a list of all the Ansible modules in the [Ansible documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html).

### Ansible Roles

Ansible roles are a way to organize playbooks and tasks into reusable units. Roles allow you to encapsulate the configuration of a specific component or service, making it easier to reuse and share across different projects.

Roles are stored in the `roles` directory within the Ansible project directory. Each role consists of a predefined directory structure containing tasks, handlers, variables, and other configuration files.

To create a new role, use the `ansible-galaxy` command:

```bash
ansible-galaxy init <role_name>
```
This command creates a new role directory structure with the following subdirectories:

- `defaults`: Contains default variables for the role.
- `files`: Contains files to be copied to the target hosts.
- `handlers`: Contains handlers that are triggered by tasks.
- `meta`: Contains metadata for the role.
- `tasks`: Contains tasks to be executed on the target hosts.
- `templates`: Contains Jinja2 templates to be rendered on the target hosts.
- `vars`: Contains variables specific to the role.

Roles can be included in playbooks using the `roles` directive:

```yaml
---
- hosts: localhost
  roles:
    - role: <role_name>
```
This directive tells Ansible to include the specified role in the playbook.

Also you can import a role from a different directory:

```yaml
---
- hosts: localhost
  tasks:
    - import_role:
        name: /path/to/role
```

In this workshop, we will create different roles as a way to organize our playbooks and tasks. Usually a role is created for each service or component that you want to configure. As per the Ansible documentation a role should be a self-contained collection of variables, tasks, files, templates, and modules that can be used to configure a specific component or service.

## Server Configuration

Now that we have our Ansible project set up, let's move on to configuring our VPS. We will focus on the following areas:

- Package Installation: Install essential packages like Docker, Git, and Python.
- Security Setup: Configure firewall rules, enable SSH hardening, and set up fail2ban.
- Service Configuration: Set up Docker and Docker Compose for running development environments.


### Package Installation

#### Common Packages

The first step in setting up our VPS is to install essential packages required for development. We will use Ansible to automate the package installation process. We will create manually an Ansible role named `packages` to handle the package installation tasks.

1. Create a new folder `roles` in your project directory:

```bash
mkdir roles
```

2. Create a new role named `packages` either using the `ansible-galaxy` command or manually:

Using `ansible-galaxy`:
```bash
ansible-galaxy init roles/packages
```
Manually:
```bash
mkdir -p roles/packages
```

3. Inside `roles/packages/tasks/`, create a new file named `apt.yml` with the following content:

```yaml
---
- name: Set timezone to Europe/Bucharest
  community.general.timezone:
    name: Europe/Bucharest

- name: Run "apt-get update"
  ansible.builtin.apt:
    update_cache: yes

- name: Update all packages to their latest version
  ansible.builtin.apt:
    name: "*"
    state: latest

- name: Install required packages
  ansible.builtin.apt:
    pkg:
    - build-essential           # Development tools
    - bash-completion           # Bash completion
    - apt-transport-https       # HTTPS support for APT
    - ca-certificates           # CA certificates
    - python3-full              # Latest Python 3
    - python3-pip               # Python package installer
    - gnupg                     # GnuPG
    - curl                      # Transfer data with URLs
    - procps                    # Process utilities    
    - file                      # File type identification
    - ufw                       # Uncomplicated Firewall
    - git                       # Version control system
    - vim                       # Text editor

```

4. Create a new file (if it doesn't exist) named `main.yml` in the `roles/packages/tasks/` directory with the following content:

```yaml
---
- import_tasks: apt.yml
```

5. Update the `site.yml` playbook to include the `packages` role:

To use a role in a playbook, you have two options: you can include the role directly in the playbook or you can use the import role task.

Using the `roles` directive:

```yaml
---
- hosts: vps
  roles:
    - role: packages
```

Using the `import_role` task:

```yaml
---
- hosts: vps
  tasks:

    # The other tasks are above
    - ansible.builtin.import_role:
        name: packages

```
We will use the second option in this workshop.

6. Run the playbook to install the required packages on your VPS:

```bash
ansible-playbook -i inventory.yml site.yml
```
Running the playbook in this form will fail. The reason is that we attempt to install packages with our regular user, which does not have the necessary permissions. To fix this, we need to tell Ansible to run the tasks with elevated privileges. We can do this by enabling privilege escalation in the playbook.

7. Update the `site.yml` playbook to enable privilege escalation:

```yaml
---
- hosts: vps
  tasks:

    - ansible.builtin.import_role:
        name: packages
      become: true
```

8. Run the playbook again with privilege escalation enabled:

```bash
ansible-playbook -i inventory.yml site.yml --ask-become-pass
```
You will be prompted to enter the password for the sudo user on your VPS. Enter the password to proceed with the installation.
To avoid passing the `--ask-become-pass` flag every time you run the playbook, you can update ansible.cfg to enable privilege escalation by default:

```ini
[privilege_escalation]
become_ask_pass = true
```

If the playbook runs successfully, you should see the required packages installed on your VPS.

#### Docker Installation

Docker is a popular platform for developing, shipping, and running applications in containers. In this section, we will automate the installation of Docker on our VPS using Ansible.

1. Create a new file named `docker.yml` in the `roles/packages/tasks/` directory with the following content:

```yaml
- name: Add Docker GPG apt Key
  vars:
    keyrings: /etc/apt/keyrings
    apt_repo: https://download.docker.com/linux/ubuntu
  block:
    - name: Create /etc/apt/keyrings directory
      ansible.builtin.file:
        path: "{{ keyrings }}"
        state: directory
        mode: '0755'

    - name: Download docker gpg key
      ansible.builtin.get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: "{{ keyrings }}/docker.asc"

    - name: Add docker apt repository
      ansible.builtin.apt_repository:
        repo: "deb [arch=amd64 signed-by={{ keyrings }}/docker.asc] {{ apt_repo }} {{ ansible_distribution_release }} stable"
        filename: docker
        state: present

- name: Install the latest version of Docker engine
  block:
    - name: Install docker package
      ansible.builtin.package:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present

    - name: Create docker group
      ansible.builtin.group:
        name: docker
        state: present

    - name: Add playbook user to docker group
      ansible.builtin.user:
        name: "{{ username }}"
        groups:
          - docker
        append: yes
        state: present

    - name: Enable docker service
      ansible.builtin.service:
        name: docker.service
        enabled: yes

    - name: Enable containerd service
      ansible.builtin.service:
        name: containerd.service
        enabled: yes

    - name: Copy daemon.json
      ansible.builtin.template:
        dest: "/etc/docker/daemon.json"
        src: "daemon.json"
      notify: restart_docker

```

2. Create a new file named `daemon.json` in the `roles/packages/files/` directory with the following content:

```json
{
  "default-address-pools": [
    {
      "base": "172.18.0.0/16",
      "size": 24
    }
  ],
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

3. Create a new file `main.yml` in the `roles/packages/handlers/` directory with the following content:

```yaml
---
- name: restart_docker
  become: true
  ansible.builtin.systemd_service:
    name: docker
    state: restarted
```
4. Update the `site.yml` playbook to include the `docker` role:

```yaml
---
- hosts: vps
  tasks:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true
```

Before running the playboo, we need to discuss a little bit how to handle sensitive data in Ansible. As you were able to see, in our docker tasks, we have a variable `username` that is not defined anywhere. This is because we don't want to hardcode sensitive data in our playbooks. Instead, we can use Ansible Vault to encrypt sensitive data and store it securely.

To create a new encrypted file using Ansible Vault, you can use the following command:

```bash
ansible-vault create secrets.yml
```
Now, you can add the sensitive data to the file and save it. To edit an existing encrypted file, you can use the `edit` command:

```bash
ansible-vault edit secrets.yml
```
To view the contents of an encrypted file, you can use the `view` command:

```bash
ansible-vault view secrets.yml
```

To run a playbook that uses an encrypted file, you need to provide the vault password using the `--ask-vault-pass` flag:

```bash
ansible-playbook -i inventory.yml site.yml --ask-vault-pass
```
However, typing the vault password every time you run a playbook can be cumbersome. To avoid this, you can store the vault password in a file and reference it in the ansible.cfg file:

```ini
[defaults]
vault_password_file = ~/.vault-pass.txt
```
Make sure to set the correct permissions on the vault password file to keep it secure:

```bash
chmod 600 ~/.vault-pass.txt
```
Now, we need to reference the `secretes.yml` file in our `site.yml` playbook. We will define the `username` variable in the `secrets.yml` file and use it in the `docker.yml` tasks.

```yaml
---
- hosts: vps
  tasks:
  vars_files:
    - secrets.yml

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true
```
After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```
This way, you can securely store and manage sensitive data in your Ansible playbooks using Ansible Vault.


