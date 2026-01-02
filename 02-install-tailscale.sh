#!/bin/bash
set -e

# Script: Install Tailscale
# Description: Installs Tailscale VPN for secure remote access
# Reference: https://tailscale.com/kb/1031/install-linux

echo "==> Installing Tailscale..."

# Check if Tailscale is already installed
if command -v tailscale &>/dev/null; then
    echo "    Tailscale is already installed (version: $(tailscale version))"
    exit 0
fi

# Install Tailscale using their installation script
echo "    Downloading and running Tailscale installation script..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "==> Tailscale installed successfully!"

# Check if already connected
if tailscale status --self &>/dev/null && tailscale status | grep -q "Logged in"; then
    echo "    Tailscale is already connected."
    echo "    Check status: tailscale status"
else
    echo "==> Connecting to Tailscale network..."
    tailscale up
    
    echo "==> Tailscale is now connected!"
    echo "    Check status: tailscale status"
fi

