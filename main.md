# Ansible playbook to install and configure Wireguard

## Setup

Add NCM, and the radbox you want a tunnel setup between into the hosts file.

## Playbook Tasks

- It will prompt user for inputs:
  - Affiliate name (used for naming tunnel interface)
  - Radbox public IP (tunnel endpoint)
  - The private IP space we need to access via tunnel

- Check if wireguard is installed on the radbox
  - If not it will attempt to install it (Centos7, I need to rework the ubuntu installer).
- Generate private, and public wg keys for NCM
- Generate private, and public wg keys for Radbox
- Count the number of "*.conf" files in /etc/wireguard on NCM
  - It uses this count to find the next available IP ( a dumb way, but it works currently ) assuming 2 private IP's for the tunnel of each .conf file.
- Use the provided .j2 templates to build the wireguard configuration for each side.
- Enable, and start the system service so the tunnel will start on reboot
