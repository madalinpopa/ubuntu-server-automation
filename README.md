# OmniOpenCon 2024

OmniOpenCon is a gathering of people, projects and communities involved in all things open: open source, open data, open science, open hardware, open education. We value openness, freedom and sharing and we want to bring together all who share these beliefs.

## Workshop: From Zero to DevOps Cloud: Ansible-Driven VPS Setup for Development

## Table of Contents

   * [Abstract](#abstract)
   * [Prerequisites](#prerequisites)
        * [VPS Setup](#vps-setup)
        * [Ansible Installation](#ansible-installation)
        * [Basic Linux Commands](#basic-linux-commands)
   * [Setup](#setup)
   * [Workshop Outline](#workshop-outline)
   * [Resources](#resources)
   * [Feedback](#feedback)

## Abstract

Welcome to OmniOpenCon 2024 and this workshop titled “From Zero to DevOps Cloud: Ansible-Driven VPS Setup for Development.”

In this hands-on session, you will learn how to automate the process of setting up a VPS from scratch using Ansible. We will focus on leveraging Ansible to handle all the configuration tasks that typically require manual intervention, including security setup, package installations, and service configurations. By the end of this workshop, you will:

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

