## Ansible Installation

Ansible is an open-source automation tool that simplifies the process of managing and configuring servers. It allows you to define your infrastructure as code and automate tasks such as package installation, configuration management, and application deployment.

In this guide, we will walk you through the steps to install Ansible on your local machine. Once installed, you can use Ansible to automate the setup of your VPS and streamline your development workflow.

More information about Ansible can be found on the official [Ansible website](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

## Table of Contents

* [Installing Ansible on Ubuntu](#installing-ansible-on-ubuntu)
* [Install Ansible Using `pipx`](#install-ansible-using-pipx)
* [Install Ansible on MacOS](#install-ansible-on-macos)
* [Install Ansible on Windows](#install-ansible-on-windows)


There are multiple ways to install Ansible, depending on your operating system. In this guide, we will focus on installing Ansible on Ubuntu, one of the most popular Linux distributions.

## Installing Ansible on Ubuntu

1. Before installing Ansible, it's a good practice to update the package repository to ensure you have the latest version of the software available. Run the following command to update the package repository:

```bash
sudo apt update
```

2. Once the package repository is updated, you can proceed to install Ansible. Run the following command to install Ansible on your local machine:

```bash
sudo apt install ansible
```

3. To verify that Ansible has been successfully installed, you can check the version of Ansible by running the following command:

```bash
ansible --version
```

## Install Ansible Using `pipx`

`pipx` is a tool that allows you to install and run Python applications in isolated environments. To install Ansible using `pipx`, follow these steps:

1. Install `pipx` if you don't already have it installed:

```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

2. Use `pipx` to install Ansible:

```bash
pipx install ansible
```

3. Verify the installation by running:

```bash
ansible --version
```

If the installation was successful, you should see the version of Ansible installed on your machine.

Congratulations! You have successfully installed Ansible on your local machine. You are now ready to start automating your infrastructure setup using Ansible playbooks.

## Install Ansible on MacOS

To install Ansible on MacOS, you can use `pip` or `Homebrew`. Here are the steps to install Ansible using `pip`:

1. Install Ansible using `pip`:

```bash
pip install ansible
```

2. Verify the installation by running:

```bash
ansible --version
```

Alternatively, you can use `Homebrew` to install Ansible on MacOS:

1. Install Homebrew if you don't already have it installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Use Homebrew to install Ansible:

```bash
brew install ansible
```

3. Verify the installation by running:

```bash
ansible --version
```


## Install Ansible on Windows

To install Ansible on Windows, you can use the Windows Subsystem for Linux (WSL) or a virtual machine running a Linux distribution. Here are the steps to install Ansible using WSL:

1. Install WSL on your Windows machine by following the instructions in the [WSL documentation](https://docs.microsoft.com/en-us/windows/wsl/install).
2. Once WSL is installed, you can follow the steps outlined in the "Installing Ansible on Ubuntu" section above to install Ansible on your WSL instance.
3. Verify the installation by running:

```bash
ansible --version
```

