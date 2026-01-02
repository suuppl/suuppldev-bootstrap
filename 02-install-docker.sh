#!/bin/bash
set -e

# Script: Install Docker
# Description: Installs Docker using the official convenience script and prepares for rootless setup

echo "==> Installing Docker..."

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo "    Docker is already installed (version: $(docker --version))"
    echo "    Continuing with preparation for rootless install..."
fi

# Install Docker using convenience script
if ! command -v docker &>/dev/null; then
    echo "    Downloading and running Docker installation script..."
    curl -fsSL https://get.docker.com | sh
fi

echo "==> Preparing for rootless Docker installation..."

# Disable system-wide Docker service
if systemctl is-active --quiet docker.service; then
    echo "    Stopping and disabling system Docker service..."
    sudo systemctl disable --now docker.service || true
fi

if systemctl is-active --quiet docker.socket; then
    echo "    Stopping and disabling Docker socket..."
    sudo systemctl disable --now docker.socket || true
fi

# Remove system Docker socket if it exists
if [ -e /var/run/docker.sock ]; then
    echo "    Removing system Docker socket..."
    sudo rm /var/run/docker.sock
fi

# Add docker user to docker group
echo "==> Adding docker user to docker group..."
sudo usermod -aG docker docker

echo "==> Docker installation and preparation completed successfully!"
echo "    Next step: Run 03-configure-rootless.sh as the docker user"
