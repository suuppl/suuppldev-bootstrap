#!/bin/bash
set -e

# Script: Install Common CLI Tools
# Description: Installs extra utilities used by deployment and maintenance scripts.

echo "==> Installing common CLI tools..."

apt-get update
apt-get install -y jq sudo git wget curl unzip btop rsync


read -p "Do you want to install Tailscale? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "==> Skipping Tailscale installation"
else
    # Description: Installs Tailscale VPN for secure remote access
    # Reference: https://tailscale.com/kb/1031/install-linux

    echo "==> Installing Tailscale..."

    # Check if Tailscale is already installed
    if command -v tailscale &>/dev/null; then
        version=$(tailscale version | head -n1)
        echo "    Tailscale is already installed (version: ${version})"
    else
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
    fi
fi

read -p "Do you want to install Doppler CLI? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "==> Skipping Doppler CLI installation"
else

    echo "==> Installing Doppler CLI..."

    # Check if Doppler is already installed
    if command -v doppler &>/dev/null; then
        echo "    Doppler is already installed (version: $(doppler --version))"
    else
        # Install Doppler CLI using their installation script
        echo "    Downloading and running Doppler installation script..."
        curl -Ls https://cli.doppler.com/install.sh | sh

        # echo "==> Doppler CLI installed successfully!"
    fi
    echo ""
    echo "  For production environment, run as docker user:"
    echo "     export HISTIGNORE=\"doppler*\""
    echo "     echo 'dp.st.prd.xxxxx' | doppler configure set token --scope <target-path>"

fi