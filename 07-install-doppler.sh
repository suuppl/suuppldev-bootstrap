#!/bin/bash
set -e

# Script: Install Doppler CLI
# Description: Installs Doppler CLI for secure secret management
# Reference: https://docs.doppler.com/docs/install-cli

echo "==> Installing Doppler CLI..."

# Check if Doppler is already installed
if command -v doppler &>/dev/null; then
    echo "    Doppler is already installed (version: $(doppler --version))"
    exit 0
fi

# Install required dependencies
echo "    Installing dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add Doppler GPG key
echo "    Adding Doppler GPG key..."
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | \
    sudo gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg

# Add Doppler repository
echo "    Adding Doppler repository..."
echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | \
    sudo tee /etc/apt/sources.list.d/doppler-cli.list

# Install Doppler
echo "    Installing Doppler..."
sudo apt-get update
sudo apt-get install -y doppler

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
