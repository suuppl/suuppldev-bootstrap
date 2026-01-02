#!/bin/bash
set -e

# Script: Install Common CLI Tools
# Description: Installs extra utilities used by deployment and maintenance scripts.

echo "==> Installing common CLI tools..."

sudo apt-get update
sudo apt-get install -y jq

echo "==> Tool installation complete!"
