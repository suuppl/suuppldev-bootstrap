#!/bin/bash
set -e

# Script: Configure Rootless Docker
# Description: Sets up Docker to run in rootless mode for the docker user
# NOTE: This script should be run as the 'docker' user

echo "==> Configuring rootless Docker..."

# Check if running as docker user
if [ "$(whoami)" != "docker" ]; then
    echo "ERROR: This script must be run as the 'docker' user"
    echo "       Run: sudo su - docker"
    echo "       Then: ./bootstrap/03-configure-rootless.sh"
    exit 1
fi

# Check if rootless Docker is already configured
if [ -S "$XDG_RUNTIME_DIR/docker.sock" ] || [ -S "$HOME/.docker/run/docker.sock" ]; then
    echo "    Rootless Docker appears to be already configured"
    exit 0
fi

# Install rootless Docker
echo "    Running dockerd-rootless-setuptool.sh..."
dockerd-rootless-setuptool.sh install

echo "==> Rootless Docker configured successfully!"
echo "    Docker socket: \$XDG_RUNTIME_DIR/docker.sock"
