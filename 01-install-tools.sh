#!/bin/bash
set -e

# Script: Install Common CLI Tools
# Description: Installs extra utilities used by deployment and maintenance scripts.

echo "==> Installing common CLI tools..."

apt-get update
apt-get install -y jq sudo

echo "==> Tool installation complete!"
