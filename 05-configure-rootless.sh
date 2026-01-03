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


# Script: Setup Port Forwarding
# Description: Configures nftables to forward privileged ports 80/443 to unprivileged ports 8080/8443
# This is necessary because rootless Docker cannot bind to ports below 1024

echo "==> Setting up port forwarding with nftables..."

# Check if nftables is available
if ! command -v nft &>/dev/null; then
    echo "    Installing nftables..."
    apt-get update
    apt-get install -y nftables
fi

# Add NAT table
echo "    Creating NAT table..."
nft add table ip nat 2>/dev/null || echo "    NAT table already exists"

# Add prerouting chain
echo "    Creating prerouting chain..."
nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; }' 2>/dev/null || echo "    Prerouting chain already exists"

# Add port forwarding rules
echo "    Adding port forwarding rules..."
nft add rule ip nat prerouting tcp dport 80 redirect to :8080 2>/dev/null || echo "    Port 80 rule already exists"
nft add rule ip nat prerouting tcp dport 443 redirect to :8443 2>/dev/null || echo "    Port 443 rule already exists"

# Verify rules
echo "==> Current nftables ruleset:"
nft list ruleset

# Make rules persistent
echo "==> Making rules persistent..."
nft list ruleset | tee /etc/nftables.conf > /dev/null

# Enable nftables service
systemctl enable nftables
systemctl restart nftables

echo "==> Port forwarding configured successfully!"
echo "    Port 80 -> 8080"
echo "    Port 443 -> 8443"

echo "==> Rootless Docker setup complete for user '${DOCKER_USER}'!"
