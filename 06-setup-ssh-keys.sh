#!/bin/bash
set -e

# Script: Setup SSH Keys
# Description: Configures SSH authorized keys for GitHub Actions autodeploy

echo "==> Setting up SSH authorized keys for docker user..."

# Create .ssh directory if it doesn't exist
mkdir -p /home/docker/.ssh
chmod 700 /home/docker/.ssh

# GitHub Actions autodeploy key
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6Pnyn1s1X9WagnNRkJ4d8DPa2vfkg3MCakT3uRlEX4 github action autodeploy"

# Check if key already exists
if grep -q "$SSH_KEY" /home/docker/.ssh/authorized_keys 2>/dev/null; then
    echo "    SSH key already exists in authorized_keys, skipping..."
    exit 0
fi

# Add key to authorized_keys
echo "$SSH_KEY" >> /home/docker/.ssh/authorized_keys
chmod 600 /home/docker/.ssh/authorized_keys
chown -R docker:docker /home/docker/.ssh

echo "==> SSH key added successfully!"
echo "    GitHub Actions can now deploy to this server"
