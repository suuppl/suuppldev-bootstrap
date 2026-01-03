#!/bin/bash
set -euo pipefail

# Script: Configure Rootless Docker
# Description: Sets up Docker to run in rootless mode for the docker user
# Part 1 runs as root, Part 2 runs as docker user automatically

DOCKER_USER="${1:-docker}"

# ============================================================================
# PART 1: Root-level preparation
# ============================================================================

if [ "${EUID}" -ne 0 ]; then
    echo "This script must be run as root (with sudo)." >&2
    exit 1
fi

echo "==> Preparing for rootless Docker installation..."

# Disable system-wide Docker service
if systemctl is-active --quiet docker.service; then
    echo "    Stopping and disabling system Docker service..."
    systemctl disable --now docker.service || true
fi

if systemctl is-active --quiet docker.socket; then
    echo "    Stopping and disabling Docker socket..."
    systemctl disable --now docker.socket || true
fi

# Remove system Docker socket if it exists
if [ -e /var/run/docker.sock ]; then
    echo "    Removing system Docker socket..."
    rm /var/run/docker.sock
fi

echo "    Root preparation complete."

# ============================================================================
# PART 2: User-level rootless Docker setup (as docker user)
# ============================================================================

echo "==> Configuring rootless Docker as user '${DOCKER_USER}'..."

# Switch to docker user and run the rootless setup
su - "${DOCKER_USER}" << 'EOF'
set -euo pipefail

# Check if rootless Docker is already configured
if [ -S "${XDG_RUNTIME_DIR:-}/docker.sock" ] || [ -S "$HOME/.docker/run/docker.sock" ]; then
    echo "    Rootless Docker appears to be already configured"
    exit 0
fi

# Install rootless Docker
echo "    Running dockerd-rootless-setuptool.sh..."
dockerd-rootless-setuptool.sh install

echo "==> Rootless Docker configured successfully!"
echo "    Docker socket: \$XDG_RUNTIME_DIR/docker.sock"
EOF


# configuring source IP propagation for rootless docker
mkdir -p $HOME/.config/systemd/user/docker.service.d
cat <<EOL > $HOME/.config/systemd/user/docker.service.d/override.conf
[Service]
Environment="DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns"
EOL
# Reload systemd user daemon and restart docker
systemctl --user daemon-reload
systemctl --user restart docker


echo "==> Rootless Docker setup complete for user '${DOCKER_USER}'!"
