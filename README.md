# Ubuntu Server Setup with Ansible: Automated Provisioning & Configuration

This repository provides a comprehensive guide to create an Ansible project and playbooks to automate the provisioning and configuration of an Ubuntu server. Whether you're setting up a cloud VPS or a local server, the included Ansible roles will install and configure essential services like Docker, Caddy for reverse proxying, Fail2Ban for security, and more. Designed for developers and system administrators, this setup simplifies server management and automates best practices for secure, scalable infrastructure.

## Table of Contents

* [Abstract](#abstract)
* [Prerequisites](#prerequisites)
    * [VPS Setup](#vps-setup)
    * [Generate SSH Key Pair](#generate-ssh-key-pair)
    * [Ansible Installation](#ansible-installation)
    * [Basic Linux Commands](#basic-linux-commands)
    * [DNS Configuration Example](#dns-configuration-example)
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
        * [Caddy Installation](#caddy-installation)
    * [Security Setup](#security-setup)
        * [SSH Configuration](#ssh-configuration)
        * [Firewall Configuration](#firewall-configuration)
        * [Fail2ban Configuration](#fail2ban-configuration)
    * [Service Configuration](#service-configuration)
        * [Docker Networks](#docker-networks)
        * [PostgreSQL Installation](#postgresql-installation)
        * [PgAdmin Installation](#pgadmin-installation)
        * [Gitea Installation](#gitea-installation)
* [Resources](#resources)
* [Feedback](#feedback)


## Abstract

Welcome to the **Ubuntu Server Setup with Ansible** project, a comprehensive guide to automating the process of setting up and configuring an Ubuntu server from scratch using Ansible.

Originally developed as part of OmniOpenCon 2024, this project has evolved into a powerful resource for developers, system administrators, and DevOps engineers looking to automate server provisioning. We leverage Ansible to handle all tasks that typically require manual intervention, including security configurations, package installations, and service setups.

By following this guide, you will:

- Gain a clear understanding of Ansible's role in automating infrastructure setup.
- Learn how to write Ansible playbooks to define the desired state of your Ubuntu server.
- Set up a fully automated VPS environment, tailored for development and production use cases.
- Deploy services like Docker to run your applications in isolated environments.
- Use Caddy as a reverse proxy to manage both public and private services.

This project is designed to minimize manual setup and centralize configuration management within Ansible, allowing for reproducible, scalable infrastructure deployments. Whether you're setting up a cloud VPS or a local server, this project aims to streamline your DevOps workflow.

Let's dive into automation and build a more efficient, scalable infrastructure!

## Prerequisites

Before diving into the automation process, make sure you have the following:

1. **A VPS (Virtual Private Server) with root access.** 
   - You can use any cloud provider like AWS, DigitalOcean, Linode, or a local VPS provider.
   - SSH access to your VPS.

2. **Local Environment Setup:**
   - Ansible installed on your local machine.
   - SSH key pair for secure access to your VPS.
   - Basic knowledge of Linux commands and system administration.
   - A text editor like VS Code or Vim.

3. **Domain Name & DNS Access:**
   - A registered domain name that you control.
   - Access to manage the domain’s DNS records (e.g., via your registrar or a DNS management service like Cloudflare).
   - You will need to set up an A or CNAME record pointing to your VPS’s public IP address.
   - The domain will be used to set up SSL certificates and access public services.

### VPS Setup

If you don’t have a VPS yet, you can follow our [VPS Setup Guide](./docs/vps-setup.md) to create one.

### Generate SSH Key Pair

If you don’t have an SSH key pair, you can follow our [SSH Key Pair Generation Guide](./docs/ssh-keypair.md) to create one.

### Ansible Installation

If you don’t have Ansible installed on your local machine, you can follow our [Ansible Installation Guide](./docs/ansible-installation.md).

### Basic Linux Commands

If you are new to Linux commands, you can refer to our [Basic Linux Commands Guide](./docs/linux-basic.md) for a quick overview.

### DNS Configuration Example

You will need to create the following DNS records:

- **A Record**: Points your domain to your VPS public IP.

  Example:  example.com -> 123.45.67.89 (your VPS public IP)

- **CNAME Records**: Points subdomains to your domain.

  Example:  www.example.com -> example.com

As we will have multiple services running on our VPS, it's a good practice to use subdomains for each service. Therefore, you can create in advance the following subdomains CNAME records:

- **pgadmin**.example.com -> example.com
- **gitea**.example.com -> example.com
- **umami**.example.com -> example.com
- **yacht**.example.com -> example.com
- **notify**.example.com -> example.com
- **memo**.example.com -> example.com
- **semaphore**.example.com -> example.com

Althoug we can use `*` to create a wildcard record, it's better to create a CNAME record for each subdomain you want to use.

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

Let's start with a simple Ansible Playbook to print "Hello, World!". Create a new file named `site.yml` in your project directory with the following content:

```yaml
---
- name: Configure VPS 
  hosts: localhost
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

Ansible uses the inventory file to define the target hosts for the playbooks. The inventory file can be in various formats, including INI, YAML, and JSON. In this guide, we will use the YAML format for the inventory file.

Ansible is looking for the inventory file in the following order:

1. The file specified using the `-i` option in the `ansible-playbook` command.
2. The default inventory file located at `/etc/ansible/hosts`.
3. The default inventory file located in the project directory named `inventory`.

Now, let's test the connection with our VPS. The first step is to create an inventory file to define the VPS host. Create a new file named `inventory.yml` in your project directory with the following content:

```yaml
---
vps:
  hosts:
    mycloud.com:
```

If you followed the steps in SSH Key Pair Generation Guide, you can use `mycloud.com` as the host name. If you used a different host name, replace `mycloud.com` with your VPS host name that you defined in the SSH configuration file.

In this example, we defined a group named `vps` with a single host named `mycloud.com`. You can define multiple hosts and groups in the inventory file based on your requirements.

After creating the inventory file, update the `site.yml` playbook to use the VPS group or host's name as the target host:

```yaml
---
- name: Configure VPS
  hosts: vps
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
🎉 If you see the output `pong`, the connection with your VPS is successful.

### Ansible Configuration

Ansible uses a configuration file to define settings like the default inventory file, remote user, and connection type. Create a new file named `ansible.cfg` in your project directory with the following content:

```ini
[defaults]
localhost_warning = False
interpreter_python=auto_silent

[inventory]
inventory_unparsed_warning = False

```
This configuration file disables the warning for using `localhost` as the target host, and disables the warning for unparsed inventory files. It also sets the Python interpreter to auto-detect.

Ansible is looking for the configuration file in the following order:

1. `ANSIBLE_CONFIG` environment variable.
2. `ansible.cfg` in the current directory.
3. `~/.ansible.cfg` in the user's home directory.
4. `/etc/ansible/ansible.cfg`.

If you want to use a different configuration file, you can set the `ANSIBLE_CONFIG` environment variable to the desired file path.
Usually is best to have the configuration file in your home directory if you don't have special settings per project.

### Ansible Playbooks

Ansible playbooks are YAML files that define a set of tasks to be executed on the target hosts. Playbooks can include multiple plays, each targeting different hosts or groups of hosts. Each play consists of tasks of modules that define the actions to be performed on the target hosts.

An Ansible module is a reusable, standalone script that performs specific tasks on the target hosts. Modules can be used to manage files, install packages, configure services, and more.

A list with all the Ansible modules can be found [here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html).

In Ansible we have also this notion of `Collections`. Collections are a distribution format for Ansible content that can include playbooks, roles, modules, and plugins. Collections make it easier to share and reuse Ansible content.

When you install Ansible, you get a set of built-in modules that are part of the `ansible.builtin` collection. You can use these modules in your playbooks without any additional configuration. Also, by default ansible will come with some of the `community` collections.

A list of all the community collections can be found [here](https://docs.ansible.com/ansible/latest/collections/community/index.html).

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
- name: Configure VPS
  hosts: localhost
  roles:
    - role: <role_name>
```
This directive tells Ansible to include the specified role in the playbook.

Also you can import a role from a different directory:

```yaml
---
- name: Configure VPS
  hosts: localhost
  tasks:
    - import_role:
        name: /path/to/role
```

In this guide, we will create different roles to organize our playbooks and tasks. Typically, a role is created for each service or component you want to configure. According to the Ansible documentation, a role should be a self-contained collection of variables, tasks, files, templates, and modules that can be reused to configure a specific component or service.

## Server Configuration

Now that we have our Ansible project set up, let's move on to configuring our VPS. We will focus on the following areas:

- **Package Installation**: Install essential packages like Docker, Cady, Git, and Python.
- **Security Setup**: Configure firewall rules, enable SSH hardening, and set up fail2ban.
- **Service Configuration**: Create an configure Docker containers with different services.

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
mkdir -p roles/packages/tasks
```

3. Inside `roles/packages/tasks/`, create a new file named `apt.yml` with the following content:

 - [apt.yml](./tasks/apt.yml)

4. Create a new file (if it doesn't exist) named `main.yml` in the `roles/packages/tasks/` directory with the following content:

```yaml
---
- import_tasks: apt.yml
```

5. Update the `site.yml` playbook to include the `packages` role:

```yaml
---
- name: Configure VPS
  hosts: vps
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: packages
```

6. Run the playbook to install the required packages on your VPS:

```bash
ansible-playbook -i inventory.yml site.yml
```
Running the playbook in this form **will fail**. The reason is that we attempt to install packages with our regular user, which does not have the necessary permissions. To fix this, we need to tell Ansible to run the tasks with elevated privileges. We can do this by enabling privilege escalation for our import role task.

7. Update the `site.yml` playbook to enable privilege escalation:

```yaml
---
- name: Configure VPS
  hosts: vps
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

Add the following lines to the `ansible.cfg` file:
```ini
[privilege_escalation]
become_ask_pass = true
```
After updating the configuration file, you can run the playbook without the `--ask-become-pass` flag:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, you should see the required packages installed on your VPS.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true
```

#### Docker Installation

Docker is a popular platform for developing, shipping, and running applications in containers. In this section, we will automate the installation of Docker on our VPS using Ansible.

1. Create a new file named `docker.yml` in the `roles/packages/tasks/` directory with the content from the following file:

- [docker.yml](./tasks/docker.yml)

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

This file contains the Docker daemon configuration settings. In this example, we define a default address pool for container networking and enable the BuildKit feature.

3. Create a new file `main.yml` in the `roles/packages/handlers/` directory with the following content:

```yaml
---
- name: restart_docker
  become: true
  ansible.builtin.systemd_service:
    name: docker
    state: restarted
```
This is an Ansible **handler** that restarts the Docker service after the configuration changes have been applied.

A handler is a task that is triggered by other tasks. Handlers are only executed once at the end of the play, after all the tasks have been completed.

4. Update the `site.yml` playbook to include the `docker` role:

```yaml
---
- name: Configure VPS
  hosts: vps
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true
```

Before running the playbook, we need to discuss a little bit how to handle sensitive data in Ansible. As you were able to see, in our docker tasks, we have a variable `{{ username }}` that is not defined anywhere. This is because we don't want to hardcode sensitive data in our playbooks. Instead, we can use Ansible Vault to encrypt sensitive data and store it securely.

Ansible Vault is a feature that allows you to encrypt sensitive data in your playbooks. You can use Ansible Vault to encrypt variables, files, and even entire playbooks. The encryption algorithm used by Ansible Vault is AES256. 

To create a new encrypted file using Ansible Vault, you can use the following command:

```bash
ansible-vault create secrets.yml
```

You will be prompted to enter a password to encrypt the file. Make sure to use a strong password and keep it secure.

Add the following content to the `secrets.yml` file:

```yaml
---
username: <your_vps_username>
```

Ansible will open the default text editor to enter the content of the file. After entering the content, save and close the file. The file will be encrypted using the password you provided.

**Note**: If you try to save the file without entering any content, you will get an error messsage.

To edit an existing encrypted file, you can use the `edit` command:

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

However, typing the vault password every time you run a playbook can be cumbersome. To avoid this, you can store the vault password in a file and reference it in the `ansible.cfg` file:

Add the `vault_password_file` option under `defaults` section with the path to your text file which contains the vault password. 

```ini
[defaults]
vault_password_file = ~/.vault-pass.txt
```

Make sure to set the correct permissions on the vault password file to keep it secure:

```bash
chmod 600 ~/.vault-pass.txt
```

Now, we need to reference the `secretes.yml` file in our `site.yml` playbook. All the variables defined in the `secrets.yml` file will be available to all the tasks in the playbook. 

Update the `site.yml` playbook to include the `secrets.yml` file:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true
```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, Docker will be installed on your VPS.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true
```

#### Caddy Installation

Caddy is a powerful, extensible web server that can be used to serve static websites, reverse proxy services, and more. In this section, we will use Ansible to install Caddy on our VPS.

1. Create a new file named `caddy.yml` in the `roles/packages/tasks/` directory with content from the following file:

- [caddy.yml](./tasks/caddy.yml)

2. Now, we will create a basic Caddy configuration file. Create a new file named `Caddyfile.j2` in the `roles/packages/templates/` directory with the following content:

```jinja
<your_domain> {
    root * /var/www/html
    file_server
}
```

This configuration file defines a simple Caddy server that serves files from the `/var/www/html` directory. 

3. Let's create a simple HTML file to serve using Caddy. Create a new file named `index.html` in the `roles/packages/files/` and copy the content from the following file: 

[index.html](./files/index.html)

4. Add to `main.yml` file in the `roles/packages/handlers/` directory with the following content:

```yaml
- name: restart_caddy
  become: true
  ansible.builtin.systemd_service:
    name: caddy
    state: reloaded
```

This is an Ansible handler that reloads the Caddy service after the configuration changes have been applied.

5. Update the `site.yml` playbook to include the `caddy` role:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true
```

6. Run the playbook to install Caddy on your VPS:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, Caddy will be installed on your VPS. You can access the Caddy server by visiting `https://<your_domain>` in your web browser and see the content of the `index.html` file.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - ansible.builtin.import_role:
        name: packages
        tasks_from: apt.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true
```

### Security Setup

Security is a critical aspect of any infrastructure setup. In this section, we will focus on setting up basic security measures on our VPS using Ansible.

#### SSH Configuration

The SSH configuration file is located at `/etc/ssh/sshd_config` and contains settings related to the SSH server. We will use Ansible to update the SSH configuration file to enhance security.

First, we will create a new role named `security` to handle all the tasks related to security setup.

1. Create a new role named `security`:

```bash
mkdir -p roles/security/tasks
mkdir -p roles/security/handlers
```

2. Inside `roles/security/tasks/`, create a new file named `ssh.yml` with the content from the following file:

- [ssh.yml](./tasks/ssh.yml)

This task hardens the SSH configuration by setting the following options:

- `Protocol 2`: Specifies that only SSH protocol version 2 should be used.
- `PermitRootLogin no`: Disables root login via SSH.
- `PasswordAuthentication no`: Disables password authentication.
- `AllowUsers {{ username }}`: Specifies the user allowed to log in via SSH.
- `Port {{ ssh_port }}`: Specifies the SSH port to use.
- `PubkeyAuthentication yes`: Enables public key authentication.
- `ClientAliveInterval 300`: Sends a null packet to the client every 300 seconds.
- `ClientAliveCountMax 0`: Disables client alive messages.
- `MaxAuthTries 3`: Limits the number of authentication attempts.
- `LogLevel VERBOSE`: Sets the log level to VERBOSE.
- `MaxStartups 10:30:60`: Limits the number of concurrent unauthenticated connections.

3. Create a new file `main.yml` in the `roles/security/handlers/` directory with the following content:

```yaml
---
- name: Restart SSH service
  ansible.builtin.systemd_service:
    name: ssh
    state: restarted
    enabled: yes
  listen: "restart_ssh"
```

4. Update the `site.yml` playbook to include the `security` role:

```yaml
---
- hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml
      become: true
```

Now, there is one more thing to do. As you noticed, in our `ssh.yml` tasks, we have a new sensitive variable called `ssh_port` that is not defined anywhere. We will define this variable in the `secrets.yml` file and use them in the `ssh.yml` tasks.

Use the `ansible-vault` command with `edit` to open the `secrets.yml` file and add the `ssh_port` variable:

```bash
ansible-vault edit secrets.yml
```
Add the following content to the `secrets.yml` file:

```yaml
---
ssh_port: 2222
```

Another important aspect related to Ansible handlers, is that they are triggered only at the end of the play. This means that if you have multiple tasks that require a handler, the handler will be triggered only after all the tasks in playbook have been executed. 

This can be useful when you want to restart a service only once, even if multiple tasks require it.

However, if a task in playbook fails before the handler is triggered, the handler will not be executed. 

In our scenario, we want to ensure that the handler is triggered right after the SSH configuration is updated. We do this because the SSH service will be restarted, and we want to ensure that the new configuration is applied. Thus, the remaining tasks in the playbook will use the new SSH port.

To ensure that the handler is always triggered, you have `meta: flush_handlers` directive in the `ssh.yml` tasks:

```yaml
---
- name: Force all notified handlers to run at this point
  ansible.builtin.meta: flush_handlers

- name: Update Ansible to use new SSH port
  ansible.builtin.set_fact:
    ansible_port: "{{ ssh_port }}"
```

The first task, `meta: flush_handlers`, forces all notified handlers to run at that point in the playbook, not waiting for the normal sync points. This ensures that the handler is triggered even if a task fails before it.

The second task updates the Ansible port to use the new SSH port defined in the `secrets.yml` file. This allows Ansible to use the new port for SSH connections in subsequent tasks.


Now, let's run the playbook to update the SSH configuration on your VPS:

```bash
ansible-playbook -i inventory.yml site.yml
```

At this point, the SSH port has been changed to `2222`. We need to update our SSH client configuration `~/.ssh/config` to use the new port when connecting to VPS.

Add the following content to the `~/.ssh/config` file:

```bash
Host mycloud.com
  HostName <vps_ip_or_domain>
  User <your_username>
  Port 2222
```

🎉 Congratulations! You have successfully updated the SSH configuration on your VPS.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml
      become: true
```

#### Firewall Configuration

A firewall is a network security system that monitors and controls incoming and outgoing network traffic based on predetermined security rules. In this section, we will use Ansible to configure the Uncomplicated Firewall (UFW) on our VPS.

1. Inside `roles/security/tasks/`, create a new file named `firewall.yml` with content from the following file:

- [firewall.yml](./tasks/firewall.yml)

2. Update the `site.yml` playbook to include the `firewall` role:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: security
        tasks_from: firewall.yml
      become: true
```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, the UFW firewall will be configured to allow SSH, HTTP, and HTTPS connections on your VPS.

The UFW configuration file is located at `/etc/ufw/ufw.conf`. This file contains the settings for the UFW firewall, including the default policy and logging options.

Below are some useful commands to manage UFW:

- `ufw status`: Displays the status of the UFW firewall.
- `ufw allow <port>/<protocol>`: Allows incoming traffic on a specific port and protocol.
- `ufw deny <port>/<protocol>`: Denies incoming traffic on a specific port and protocol.
- `ufw delete <rule_number>`: Deletes a specific rule from the UFW configuration.
- `ufw reload`: Reloads the UFW configuration.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: firewall.yml
      become: true
```

#### Fail2ban Configuration

Fail2ban is an intrusion prevention software framework that protects computer servers from brute-force attacks. In this section, we will use Ansible to install and configure Fail2ban on our VPS.

1. Inside `roles/security/tasks/`, create a new file named `fail2ban.yml` with content from the following file:

- [fail2ban.yml](./tasks/fail2ban.yml)

2. Append the following content to the `main.yml` file in the `roles/security/handlers/` directory:

```yaml
- name: Restart Fail2ban service
  ansible.builtin.systemd_service:
    name: fail2ban
    state: restarted
    enabled: yes
  listen: "restart_fail2ban"
```

This is an Ansible handler that restarts the Fail2ban service after the configuration changes have been applied.

3. Update the `site.yml` playbook to include the `fail2ban` role:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: security
        tasks_from: fail2ban.yml
      become: true
```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, Fail2ban will be installed and configured to protect your VPS from brute-force attacks.

Now, few things about fail2ban. Fail2ban is a service that monitors log files for failed login attempts and blocks the IP addresses of the attackers. The configuration file for Fail2ban is located at `/etc/fail2ban/jail.local`. This file contains the settings for the services that Fail2ban monitors and the actions to take when an attack is detected.

In our playbook, we copied a custom configuration for the SSH service. This configuration enables Fail2ban for the SSH service, sets the log file path to `/var/log/auth.log`, and specifies the maximum number of retries and the ban time.

Below are some useful commands to manage Fail2ban:

- `fail2ban-client status`: Displays the status of all jails.
- `fail2ban-client status <jail_name>`: Displays the status of a specific jail.
- `fail2ban-client set <jail_name> unbanip <ip_address>`: Unbans an IP address from a jail.
- `fail2ban-client reload`: Reloads the Fail2ban configuration.

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: firewall.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: fail2ban.yml
      become: true
```

### Service Configuration

In this section, we will focus on setting up different services running in Docker containers on our VPS. We will use Ansible to automate the service configuration process.

Before we start, we need to think about managing our docker containers configuration, and in order to not repeat ourselves, we can use Ansible variables to store the configuration of our containers. This way, we can easily update the configuration in one place and have it applied to all the containers.

1. Create a new folder named `group_vars` in your project directory:

```bash
mkdir group_vars
```
2. Inside the `group_vars` directory, create a new file named `all.yml` with the following content:

```yaml
---
docker_networks:
  - name: public
    driver: bridge
  - name: private
    driver: bridge
```

The `group_vars` folder is a special directory that contains variables that apply to all hosts in the inventory. In this case, we define a list of Docker networks that we will use in our services.

If you have multiple VPS hosts and want to define specific variables for each host, you can create a file with the host name in the `group_vars` directory. For example, if you have a host named `mycloud.com`, you can create a file named `mycloud.com.yml` in the `group_vars` directory with the host-specific variables. 

The variables defined in the host-specific file will override the variables defined in the `all.yml` file. The file `all.yml` is used to define variables that apply to all hosts in the inventory.

Now, let's move on to configuring the services.

#### Docker Networks

Docker networks allow containers to communicate with each other securely. In this section, we will use Ansible to create Docker networks on our VPS.

Why we want two networks? We will create a public network that will be used by services that need to be accessed from the internet, and a private network that will be used by services that should not be exposed to the internet. Also, using multiple networks allows us to isolate services and control the traffic between them.

2. Inside `roles/services/tasks/`, create a new file named `networks.yml` with the following content:

```yaml
---
- name: Create Docker networks
  ansible.builtin.docker_network:
    name: "{{ item.name }}"
    driver: "{{ item.driver }}"
  loop: "{{ docker_networks }}"
```

3. Update the `site.yml` playbook to import the `networks.yml` tasks:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml
```
As you noticed, this time we don't need to use the `become: true` directive because the `docker_network` module does not require elevated privileges.

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

🎉 If the playbook runs successfully, the Docker networks will be created on your VPS.

To check the Docker networks, you can use the following command:

```bash
docker network ls
```

|🎯 At this point, our `site.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

    - ansible.builtin.import_role:
        name: packages
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      become: true

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: firewall.yml
      become: true

    - ansible.builtin.import_role:
        name: security
        tasks_from: fail2ban.yml
      become: true

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml
```

#### PostgreSQL Installation

PostgreSQL is a powerful, open-source relational database management system. In this section, we will use Ansible to install and configure PostgreSQL in a Docker container on our VPS.

1. Inside `roles/services/tasks/`, create a new file named `postgresql.yml` with content from the following file:

- [postgresql.yml](./services/postgresql.yml)

2. Next step is to define the variables used in the `postgresql.yml` tasks. Update the `group_vars/all.yml` file with the following content:

```yaml
# PostgreSQL Container Configuration
postgres:
    data_volume: postgres_data
    container_name: postgres
    container_image: postgres:latest
    container_hostname: postgres
    network: private
```

For the `postgres_db_user` and `postgres_db_pass` variables, we will use the `secrets.yml` file to store the sensitive data.

Edit the `secrets.yml` file using `ansible-vault edit secrets.yml` and add the following content:

```yaml 
postgres_db_user: postgres
postgres_db_pass: mysecretpassword
```

3. Update the `site.yml` playbook to include the `postgresql` tasks:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: services
        tasks_from: postgresql.yml
```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

If the playbook runs successfully, PostgreSQL will be installed and configured in a Docker container on your VPS.

To check the PostgreSQL container, you can use the following command:

```bash
docker ps
```
As we can see, our main playbook is getting bigger and bigger. To avoid running all the tasks every time we want to update a service, we can split the tasks into separate playbooks and include them in the main playbook.

Let's create three new playbooks for each each type of configuration: `packages.yml`, `security.yml`, `services.yml`.

Create a new file named `packages.yml` in the root of your project directory with the following content:

```yaml
---
- name: Configure VPS Packages
  hosts: vps
  vars_files:
    - secrets.yml
  become: true
  tasks:

    - ansible.builtin.import_role:
        name: packages

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
```

Create a new file named `security.yml` in the root of your project directory with the following content:

```yaml
- name: Configure VPS Security
  hosts: vps
  vars_files:
    - secrets.yml
  become: true
  tasks:

    - ansible.builtin.import_role:
        name: security
        tasks_from: ssh.yml

    - name: Force all notified handlers to run at this point
      ansible.builtin.meta: flush_handlers

    - name: Update Ansible to use new SSH port
      ansible.builtin.set_fact:
        ansible_port: "{{ ssh_port }}"

    - ansible.builtin.import_role:
        name: security
        tasks_from: firewall.yml

    - ansible.builtin.import_role:
        name: security
        tasks_from: fail2ban.yml
```

Create a new file named `services.yml` in the root of your project directory with the following content:

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: postgresql.yml
```

Now, update the `site.yml` playbook to include the new playbooks:

```yaml
---
- name: Configure VPS
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - name: Print Hello World 
      ansible.builtin.debug:
        msg: "Hello, World!"

    - name: Ping
      ansible.builtin.ping:

- name: Install packages
  ansible.builtin.import_playbook: packages.yml

- name: Configure security
  ansible.builtin.import_playbook: security.yml

- name: Configure services
  ansible.builtin.import_playbook: services.yml

```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml site.yml
```

#### PgAdmin Installation

PgAdmin is a popular open-source administration and development platform for PostgreSQL. In this section, we will use Ansible to install and configure PgAdmin in a Docker container on our VPS.

1. Inside `roles/services/tasks/`, create a new file named `pgadmin.yml` with content from the following file:

- [pgadmin.yml](./tasks/pgadmin.yml)

2. Next step is to define the variables used in the `pgadmin.yml` tasks. Update the `group_vars/all.yml` file with the following content:

```yaml
# PgAdmin Container Configuration
pgadmin:
    data_volume: pgadmin_data
    container_image: dpage/pgadmin4:latest
    container_name: pgadmin
    container_hostname: pgadmin
    network: public
```

For the `pgadmin_email` and `pgadmin_password` variables, we will use the `secrets.yml` file to store the sensitive data.

Edit the `secrets.yml` file using `ansible-vault edit secrets.yml` and add the following content:

```yaml
pgadmin_email: your@email.com
pgadmin_password: secret
```

3. Update the `services.yml` playbook to include the `pgadmin` tasks:

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: services
        tasks_from: pgadmin.yml
```

After updating the playbook, run it using the following command:

```bash
ansible-playbook -i inventory.yml services.yml
```

If the playbook runs successfully, PgAdmin will be installed and configured in a Docker container on your VPS.

Now, we want to access the PgAdmin interface using. To do this, we need to configure Caddy to act as a reverse proxy for the PgAdmin container.

1. Update the `Caddyfile.j2` template file to include a reverse proxy configuration for PgAdmin:

```jinja
<your_domain> {
    root * /var/www/html
    file_server
}

pgadmin.<your_domain> {
    reverse_proxy localhost:8081 {
        header_up X-Scheme {scheme}
    }
}
```

This configuration file defines a reverse proxy for the PgAdmin container running on port 8081. The `header_up` directive is used to set the `X-Scheme` header to the scheme of the request.

To apply the changes we need to run the `packages.yml` playbook which includes the `caddy.yml` tasks:

```bash
ansible-playbook -i inventory.yml packages.yml
```

But if we want to be more specific and run only a specific task in the playbook, we can add tags to our tasks in the playbook and run only the tasks with the specified tags. Let's do this with the `caddy.yml` tasks.

In `packages.yml` playbook, add the `caddy` tag to the `caddy.yml` tasks:

```yaml
---
- name: Configure VPS Packages
  hosts: vps
  vars_files:
    - secrets.yml
  become: true
  tasks:

    - ansible.builtin.import_role:
        name: packages
      tags: packages

    - ansible.builtin.import_role:
        name: packages
        tasks_from: docker.yml
      tags: docker

    - ansible.builtin.import_role:
        name: packages
        tasks_from: caddy.yml
      tags: caddy
```

Now, you can run the `packages.yml` playbook with the `caddy` tag to apply the changes:

```bash
ansible-playbook -i inventory.yml packages.yml --tags caddy
```

After this, you should be able to login to PgAdmin using the following URL:

```bash
http://pgadmin.<your_domain>
```

|🎯 At this point, our `services.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: postgresql.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: pgadmin.yml
```

2. After updating the `Caddyfile.j2` template file, run the `site.yml` playbook to apply the changes:

```bash
ansible-playbook -i inventory.yml site.yml
```

If the playbook runs successfully, Caddy will be configured to act as a reverse proxy for the PgAdmin container.

To access PgAdmin using the domain name, you can use the following URL in your web browser:

```bash
http://pgadmin.<your_domain>
```


|🎯 At this point, our `service.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: postgresql.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: pgadmin.yml
```

#### Gitea Installation

Gitea is a self-hosted Git service that is similar to GitHub. In this section, we will use Ansible to install and configure Gitea in a Docker container on our VPS.

1. Inside `roles/services/tasks/`, create a new file named `gitea.yml` with content from the following file:

- [gitea.yml](./tasks/gitea.yml)

A lot of things are happening in this task. We are creating a Docker volume for Gitea, creating a Docker container for Gitea, setting environment variables for Gitea configuration, exposing ports for SSH and HTTP access, and copying custom templates for the Gitea interface.

Here is the list with the environment variables used in the Gitea container and what they do:

- `GITEA__database__DB_TYPE=postgres`: Specifies the database type (PostgreSQL).
- `GITEA__database__HOST=postgres`: Specifies the database host (PostgreSQL container).
- `GITEA__database__NAME={{ gitea_database_name }}`: Specifies the database name.
- `GITEA__database__USER={{ gitea_database_user }}`: Specifies the database user.
- `GITEA__database__PASSWD={{ gitea_database_pass }}`: Specifies the database password.
- `GITEA__service__DISABLE_REGISTRATION=true`: Disables user registration.
- `GITEA__service__EMAIL_DOMAIN_ALLOWLIST={{ gitea['domain'] }}`: Specifies the allowed email domain.
- `GITEA__service__DEFAULT_USER_VISIBILITY=private`: Sets the default user visibility to private.
- `GITEA__service__DEFAULT_ORG_VISIBILITY=private`: Sets the default organization visibility to private.
- `GITEA__repository__DEFAULT_PRIVATE=private`: Sets the default repository visibility to private.
- `GITEA__repository__FORCE_PRIVATE=true`: Forces repositories to be private.
- `GITEA__openid__ENABLE_OPENID_SIGNIN=false`: Disables OpenID sign-in.
- `GITEA__openid__ENABLE_OPENID_SIGNUP=false`: Disables OpenID sign-up.
- `GITEA__cors__ENABLED=true`: Enables CORS.
- `GITEA__cors__ALLOW_DOMAIN={{ gitea['domain'] }}`: Specifies the allowed domain for CORS.

2. Next step is to define the variables used in the `gitea.yml` tasks. Update the `group_vars/all.yml` file with the following content:

```yaml
# Gitea Container Configuration
gitea:
    data_volume: gitea_data
    container_image: gitea/gitea:latest
    container_name: gitea
    container_hostname: gitea
    network: public
    domain: gitea.<your_domain>
```

For the `gitea_database_name`, `gitea_database_user`, and `gitea_database_pass` variables, we will use the `secrets.yml` file to store the sensitive data.

Edit the `secrets.yml` file using `ansible-vault edit secrets.yml` and add the following content:

```yaml
gitea_database_name: gitea
gitea_database_user: gitea
gitea_database_pass: mysecretpassword
```

3. We can customize a little bit the Gitea interface. To do this we need to create two custom templates. Create a new folder named `files` in the `services` role directory and two files `home.tmpl` an `head_navbar.tmpl` with the content from the following files:

- [home.tmpl](./files/home.tmpl) 
- [head_navbar.tmpl](./files/head_navbar.tmpl)

4. Update the `services.yml` playbook to include the `gitea` tasks:

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    # The other tasks are above

    - ansible.builtin.import_role:
        name: services
        tasks_from: gitea.yml
```

5. Now, we need to expose the Gitea interface using Caddy as a reverse proxy. Update the `Caddyfile.j2` template file to include a reverse proxy configuration for Gitea:

```jinja
gitea.<your_domain> {
    reverse_proxy localhost:3000
}
```

6. After updating the `Caddyfile.j2` template file, run the `site.yml` playbook to apply the changes:

```bash
ansible-playbook -i inventory.yml packages.yml -t caddy
```

7. Before accessing Gitea, we need to initialize the database. To do this, we need to open our pgAdmin interface and create a new database, and user with the same values that we defined in the `gitea_database_name` and `gitea_database_user` variables.

```sql
CREATE ROLE your_gitea_username WITH LOGIN PASSWORD 'your_password';
CREATE DATABASE your_database_name WITH OWNER your_gitea_username TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
```

After creating the database and user, we can access the Gitea interface using the following URL:

```bash
http://gitea.<your_domain>
```
When we access Gitea for the first time, we need to configure the instance settings. You don't have to change anything in the database settings, because we already configured them in the `gitea.yml` tasks.


|🎯 At this point, our `service.yml` playbook should look like this|
|---------------------------------------------------------------|

```yaml
---
- name: Configure VPS Services
  hosts: vps
  vars_files:
    - secrets.yml
  tasks:

    - ansible.builtin.import_role:
        name: services
        tasks_from: networks.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: postgresql.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: pgadmin.yml

    - ansible.builtin.import_role:
        name: services
        tasks_from: gitea.yml
```
