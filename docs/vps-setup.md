## VPS Setup Guide

In this guide, we will walk you through the process of setting up a Virtual Private Server (VPS) for the workshop. If you already have a VPS, you can skip this section and proceed to the [Ansible Installation Guide](./ansible-installation.md).

### Table of Contents
* [Picking a VPS Provider](#picking-a-vps-provider)
* [VPS Disk Encryption](#vps-disk-encryption)
* [Global VPS Providers](#global-vps-providers)
* [Official Linux Distribution Websites](#official-linux-distribution-websites)
* [Install Ubuntu 24.04 LTS on Chroot.ro](#install-ubuntu-24.04-lts-on-chroot.ro)

## Picking a VPS Provider

Before you begin, you need to select a VPS provider that meets the following criteria:

1. Ability to mount installation ISOs: This allows you to load custom operating systems or recovery tools.

2. Console access outside of SSH (VNC or serial): In case of network issues or SSH misconfigurations, console access lets you troubleshoot your VPS directly.

3. Support for full disk encryption on virtual disks: Ensures that your data is encrypted at rest.

4. Good network connectivity: Ensure that the provider has good network connectivity and low latency to your location.

5. Data center locations: Choose a provider with data centers in regions that are close to your target audience or have good connectivity to your location.


## VPS Disk Encryption

When setting up a VPS, it's important to consider disk encryption, especially if you are handling sensitive data. Full disk encryption adds an additional layer of security, making unauthorized access more difficult. However, it’s important to understand the limitations:

1. **Full disk encryption** protects your data at rest, but while your VPS is running, data must be decrypted for the system to use it.

2. The **decryption key** is stored in the server's RAM while it’s running, which could be stolen by someone with access to the system memory.

3. Disk encryption is **not foolproof**, but it helps to make unauthorized access more difficult and time-consuming for potential attackers.

4. The goal here is **risk mitigation**, not absolute security. If you are handling highly sensitive data, consider additional security measures.


## Global VPS Providers

Here are some popular VPS providers that offer a wide range of services and features:

1. **Chroot.ro**: chroot.ro offers VPS hosting with full root access and a variety of operating systems to choose from. This will be the provider we use for the workshop.

2. **DigitalOcean**: Known for its simplicity and user-friendly interface, DigitalOcean offers a variety of droplet plans to suit different needs.

3. **Linode**: Linode provides high-performance SSD Linux servers with a simple pricing model and excellent customer support.

4. **Vultr**: Vultr offers high-performance cloud compute instances with SSD storage and a global network of data centers.

5. **hostinger**: hostinger provides affordable VPS hosting with dedicated resources and a user-friendly control panel.


## Official Linux Distribution Websites

If you prefer to install a specific Linux distribution on your VPS, you can download the ISO image from the official distribution website. Here are some popular Linux distributions:

1. **Ubuntu**: [Download Ubuntu ISO](https://releases.ubuntu.com/)

2. **Debian**: [Download Debian ISO](https://www.debian.org/distrib/)

3. **CentOS**: [Download CentOS ISO](https://www.centos.org/download/)

For this workshop, we recommend using the Ubuntu 24.04 LTS (Long Term Support) release. You can download the ISO image from the following link:

https://releases.ubuntu.com/24.04/ubuntu-24.04.1-live-server-amd64.iso

## Install Ubuntu 24.04 LTS on Chroot.ro

In this section, we will guide you through the process of installing Ubuntu 24.04 LTS on a VPS provided by chroot.ro. If you are using a different VPS provider, the process for creating a VPS instance may vary.

Once the VPS is created, you will need to mount the Ubuntu 24.04 LTS ISO image to the VPS and boot from it to start the installation process.

1. **Boot to Ubuntu 24.04 LTS ISO**: Log in to your chroot.ro account and navigate to the VPS management panel. Find the option to mount an ISO image and select the Ubuntu 24.04 LTS ISO file.

2. **Start the VPS**: Once the ISO image is mounted, start the VPS and access the console. You should see the Ubuntu installer booting up.

3. **Follow the Installation Steps**: Proceed with the installation steps as guided by the Ubuntu installer. You will need to select the language, keyboard layout, timezone, and disk partitioning options.

4. **Set Up User Account**: Create a user account with sudo privileges and set a strong password. This account will be used to log in to the VPS.

5. **Complete the Installation**: Once the installation is complete, reboot the VPS and log in using the user account you created.

Congratulations! You have successfully installed Ubuntu 24.04 LTS on your VPS. You can now proceed to the [Ansible Installation Guide](./ansible-installation.md) to set up Ansible on your local machine.


