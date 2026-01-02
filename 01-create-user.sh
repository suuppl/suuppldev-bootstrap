#!/bin/bash
set -e

# Script: Create docker user
# Description: Creates a dedicated 'docker' user for running Docker in rootless mode

echo "==> Creating docker user..."

# Check if user already exists
if id "docker" &>/dev/null; then
    echo "    User 'docker' already exists, skipping..."
    exit 0
fi

# Create user with home directory
adduser docker

echo "==> Docker user created successfully!"
