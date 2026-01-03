#!/bin/bash
set -e

# Script: Install Common CLI Tools
# Description: Installs extra utilities used by deployment and maintenance scripts.

echo "==> Installing common CLI tools..."

apt-get update
apt-get install -y jq sudo

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

echo "==> Installing Doppler CLI..."

# Check if Doppler is already installed
if command -v doppler &>/dev/null; then
    echo "    Doppler is already installed (version: $(doppler --version))"
    exit 0
fi

# Install required dependencies
echo "    Installing dependencies..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add Doppler GPG key
echo "    Adding Doppler GPG key..."
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | \
    gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg

# Add Doppler repository
echo "    Adding Doppler repository..."
echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | \
    tee /etc/apt/sources.list.d/doppler-cli.list

# Install Doppler
echo "    Installing Doppler..."
apt-get update
apt-get install -y doppler

# Prevent doppler commands from appearing in bash history
export HISTIGNORE="doppler*"

echo "==> Doppler CLI installed successfully!"
echo ""
echo "Configuration steps:"
echo "  1. For development environment, run as docker user:"
echo "     echo 'dp.st.dev.xxxxx' | doppler configure set token --scope /home/docker/autodeploy"
echo ""
echo "  2. For production environment, run as docker user:"
echo "     echo 'dp.st.prd.xxxxx' | doppler configure set token --scope /home/docker/autodeploy"

