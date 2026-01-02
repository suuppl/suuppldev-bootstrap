#!/bin/bash
set -e

# Script: Setup Port Forwarding
# Description: Configures nftables to forward privileged ports 80/443 to unprivileged ports 8080/8443
# This is necessary because rootless Docker cannot bind to ports below 1024

echo "==> Setting up port forwarding with nftables..."

# Check if nftables is available
if ! command -v nft &>/dev/null; then
    echo "    Installing nftables..."
    sudo apt-get update
    sudo apt-get install -y nftables
fi

# Add NAT table
echo "    Creating NAT table..."
sudo nft add table ip nat 2>/dev/null || echo "    NAT table already exists"

# Add prerouting chain
echo "    Creating prerouting chain..."
sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; }' 2>/dev/null || echo "    Prerouting chain already exists"

# Add port forwarding rules
echo "    Adding port forwarding rules..."
sudo nft add rule ip nat prerouting tcp dport 80 redirect to :8080 2>/dev/null || echo "    Port 80 rule already exists"
sudo nft add rule ip nat prerouting tcp dport 443 redirect to :8443 2>/dev/null || echo "    Port 443 rule already exists"

# Verify rules
echo "==> Current nftables ruleset:"
sudo nft list ruleset

# Make rules persistent
echo "==> Making rules persistent..."
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null

# Enable nftables service
sudo systemctl enable nftables
sudo systemctl restart nftables

echo "==> Port forwarding configured successfully!"
echo "    Port 80 -> 8080"
echo "    Port 443 -> 8443"
