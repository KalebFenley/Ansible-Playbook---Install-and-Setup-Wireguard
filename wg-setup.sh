#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Prompt for client name
read -p "Enter affiliates name, this will also be the new wireguard interface name: " client

# Generate Local public and private keys for the new wg tunnel
local_private_key=$(wg genkey)
local_pub_key=$(echo "$local_private_key" | wg pubkey)

# Generate remote public and private keys
remote_private_key=$(wg genkey)
remote_pub_key=$(echo "$remote_private_key" | wg pubkey)

# Prompt for Allowed IP's
read -p "Enter the private IP's we need to access from the radbox (comma-separated CIDR): " allowed_ips

base_private_ip="192.168.137."
wireguard_conf_dir="/etc/wireguard/"

# Calculate local and remote private IPs
conf_file_count=$(ls -1 "$wireguard_conf_dir" | grep -E "\.conf$" | wc -l)
local_private_ip="${base_private_ip}$((conf_file_count + 3))/32"
remote_private_ip="${base_private_ip}$((conf_file_count + 4))/32"

# Prompt for the remote IP address
read -p "Enter the remote WireGuard server's IP address: " remote_ip

# Generate local config file
echo "
[Interface]
Address = $local_private_ip
PrivateKey = $local_private_key

[Peer]
PublicKey = $remote_pub_key
AllowedIPs = $remote_private_ip, $allowed_ips
Endpoint = $remote_ip:62548
PersistentKeepalive = 25
" > "$wireguard_conf_dir$client.conf"

# Build VPN daemon to start on interface on boot
systemctl enable "wg-quick@$client.service"
systemctl daemon-reload
systemctl start "wg-quick@$client"



# Build Radbox config file

echo "
Save this to /etc/wireguard/ncm-vpn.conf on the radbox
######################################################
[Interface]
Address = $remote_private_ip
ListenPort = 62548
PrivateKey = $remote_private_key

[Peer]
PublicKey = $local_pub_key
AllowedIPs = $local_private_ip
PersistentKeepalive = 25
######################################################

You will also need to:
- open port 62548 through the firewall
  Firewalld:
    'sudo firewall-cmd --zone=public --add-port=62548/udp --permanent'

systemctl enable "wg-quick@ncm-vpn.service"
systemctl daemon-reload
systemctl start "wg-quick@ncm"
"