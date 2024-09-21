## Linux Basics for the Workshop

In this section, we will cover some basic Linux commands that you will need to follow along with the workshop. If you are new to Linux, don't worry! We will guide you through the essential commands that will help you navigate and interact with your VPS.

## Table of Contents

* [File and Directory Management](#file-and-directory-management)
* [User and Permissions](#user-and-permissions)
* [Network and SSH](#network-and-ssh)
* [Process Management](#process-management)
* [System Management](#system-management)
* [Conclusion](#conclusion)

## File and Directory Management

1. **`ls`**: List files and directories in the current directory.
   ```bash
   ls
   ```

2. **`cd`**: Change directory.
   ```bash

3. **`pwd`**: Print the current working directory.
   ```bash
   pwd
   ```

4. **`mkdir`**: Create a new directory.
   ```bash
    mkdir my_directory
    ```

5. **`touch`**: Create a new file.
    ```bash
    touch my_file.txt
    ``` 

6. **`cp`**: Copy files and directories.
    ```bash
    cp file1 file2
    ```

7. **`mv`**: Move or rename files and directories.
    ```bash
    mv file1 file2
    ```

8. **`rm`**: Remove files and directories.
    ```bash
    rm file1
    ```

9. **`cat`**: Display the contents of a file.
    ```bash
    cat file1
    ```

10. **`less`**: View the contents of a file one page at a time.
    ```bash
    less file1
    ```

## User and Permissions

1. **`whoami`**: Print the current user.
   ```bash
   whoami
   ```

2. **`sudo`**: Execute a command with superuser privileges.
   ```bash
    sudo command
    ```

3. **`chown`**: Change the owner of a file or directory.
    ```bash
    chown user:group file
    ```

4. **`chmod`**: Change the permissions of a file or directory.
    ```bash
    chmod permissions file
    ```

5. Add user to the sudoers group to grant superuser privileges.
    ```bash
    sudo usermod -aG sudo username
    ```

## Network and SSH

1. Connect to a remote server using SSH.
    ```bash
    ssh user@hostname
    ```

2. Copy files between local and remote systems using `scp`.
    ```bash
    scp file user@hostname:/path/to/destination
    ```
    Example: `scp myfile.txt devuser@123.45.67.89:/home/devuser/` copies myfile.txt to the devuser home directory on the remote server.


## Process Management

1. **`ps`**: Display information about running processes.
   ```bash
   ps
   ```

2. **`kill`**: Terminate a process.
   ```bash
   kill process_id
   ```

3. **`top`**: Display real-time system information.
   ```bash
   top
   ```

4. **`htop`**: Interactive process viewer.
   ```bash
   htop
   ```

## System Management

1. **`uname`**: Print system information.
   ```bash
   uname -a
   ```

2. **`df`**: Display disk space usage.
   ```bash
   df -h
    ```
3. **`free`**: Display memory usage.
    ```bash
    free -h
    ```
4. **`uptime`**: Display system uptime.
    ```bash
    uptime
    ```
5. **`reboot`**: Reboot the system.
    ```bash
    sudo reboot
    ```
6. **`shutdown`**: Shutdown the system.
    ```bash
    sudo shutdown now
    ```
7. **`journalctl`**: View system logs.
    ```bash
    journalctl
    ```
8. **`systemctl`**: Manage system services.
    ```bash
    systemctl status service_name
    systemctl start service_name
    systemctl stop service_name
    systemctl restart service_name
    ```
9. **`ifconfig`**: Display network interface configuration.
    ```bash
    ifconfig
    ```

## Conclusion

These commands will help you navigate the VPS, manage users and files, and interact with services as you set up your development environment using Ansible. As you go through the workshop, you’ll find yourself using these commands regularly to verify configurations and troubleshoot issues.
