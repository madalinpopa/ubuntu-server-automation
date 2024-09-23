## SSH Key Pair Generation Guide

In this guide, we will walk you through the process of generating an SSH key pair for secure access to your VPS. SSH keys provide a secure way to authenticate your identity when connecting to remote servers. By using SSH keys, you can establish a secure connection without the need to enter a password each time.

## Table of Contents

- [What is an SSH Key Pair?](#what-is-an-ssh-key-pair)
- [Generating an SSH Key Pair](#generating-an-ssh-key-pair)
- [Copying the Public Key to Your VPS](#copying-the-public-key-to-your-vps)
- [Testing the SSH Connection](#testing-the-ssh-connection)
- [Conclusion](#conclusion)

## What is an SSH Key Pair?

An SSH key pair consists of two keys: a public key and a private key. The public key is shared with remote servers, while the private key is kept secure on your local machine. When you connect to a server using SSH, the server verifies your identity by checking if your public key matches the private key stored on your local machine.

## Generating an SSH Key Pair

To generate an SSH key pair, follow these steps:

1. Open a terminal on your local machine.

2. Run the following command to generate a new SSH key pair. You can specify an email address as a label for the key:

   ```bash
    ssh-keygen -t ed25519 -C "your_email@example.com"
    ```

3. You will be prompted to choose a location to save the key pair. Press `Enter` to save the key pair in the default location (`~/.ssh/ed25519`).

4. You will also be prompted to enter a passphrase to secure your private key. You can choose to set a passphrase or leave it empty for no passphrase.

5. Once the key pair is generated, you will see a message confirming the creation of the key pair.

## Create SSH config file

Create a `config` file in the `~/.ssh` directory to store the SSH key configuration. This file allows you to define the SSH key to use for specific hosts.

1. Open the `config` file in the `~/.ssh` directory:

   ```bash
   nano ~/.ssh/config
   ```

2. Add the following configuration to the `config` file:

   ```
    Host mycloud.com
         HostName <vps_ip>
         IdentityFile ~/.ssh/ed25519
         IdentitiesOnly yes
         User <username>
    ```

## Copying the Public Key to Your VPS

To copy the public key to your VPS, follow these steps:

1. Run the following command to display the contents of your public key:

   ```bash
   cat ~/.ssh/ed25519.pub
   ```

2. Copy the output of the command.

3. Log in to your VPS using SSH.

4. Create a `.ssh` directory in your home directory if it doesn't already exist:

   ```bash
   mkdir -p ~/.ssh
   ```

5. Open the `authorized_keys` file in the `.ssh` directory:

   ```bash
    nano ~/.ssh/authorized_keys
    ```

6. Paste the public key into the `authorized_keys` file.

7. Save and close the file.

8. Set the correct permissions for the `.ssh` directory and the `authorized_keys` file:

   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
    ```

Also, you can use `ssh-copy-id` to copy the public key to your VPS. Run the following command:

```bash
ssh-copy-id -i ~/.ssh/ed25519.pub <username>@<vps_ip>
```

## Testing the SSH Connection

To test the SSH connection using the SSH key pair, run the following command:

```bash

ssh -i ~/.ssh/ed25519 <username>@<vps_ip>
```

Replace `<username>` with your username on the VPS and `<vps_ip>` with the IP address of your VPS.

## Conclusion

In this guide, you learned how to generate an SSH key pair for secure access to your VPS. By using SSH keys, you can establish a secure connection to your VPS without the need to enter a password each time. This method provides an additional layer of security and convenience when connecting to remote servers.

Now that you have generated an SSH key pair, you can use it to securely connect to your VPS and automate the setup process using Ansible playbooks.

