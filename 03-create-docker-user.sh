#!/bin/bash
set -euo pipefail

# Create or configure the dedicated docker user for rootless Docker.
# - Password remains disabled.
# - SSH pubkey can be provided interactively and is not stored in the repo.

if [ "${EUID}" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

echo "==> Creating docker service user..."

DOCKER_USER="docker"

if id "${DOCKER_USER}" &>/dev/null; then
    echo "    User '${DOCKER_USER}' already exists, ensuring configuration..."
else
    adduser --gecos "" --disabled-password "${DOCKER_USER}"
    echo "    User '${DOCKER_USER}' created (password disabled)."
fi

USER_HOME=$(getent passwd "${DOCKER_USER}" | cut -d: -f6)
install -d -m 700 -o "${DOCKER_USER}" -g "${DOCKER_USER}" "${USER_HOME}/.ssh"

read -rp "Paste public SSH key for ${DOCKER_USER} (leave blank to skip): " DOCKER_PUBKEY

if [ -n "${DOCKER_PUBKEY}" ]; then
    printf '%s\n' "${DOCKER_PUBKEY}" > "${USER_HOME}/.ssh/authorized_keys"
    chown "${DOCKER_USER}:${DOCKER_USER}" "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    echo "    SSH key added to ${USER_HOME}/.ssh/authorized_keys."
fi

# Add GitHub Actions autodeploy key
echo ""
echo "==> GitHub Actions autodeploy key setup"
echo "    This public key allows GitHub Actions to deploy to this server."
echo "    The corresponding private key should be stored in GitHub repository secrets"
echo "    as 'DEPLOY_KEY' for use in automated deployments."
echo ""

read -rp "Paste GitHub Actions autodeploy public SSH key (leave blank to generate new): " GITHUB_ACTIONS_KEY

if [ -n "${GITHUB_ACTIONS_KEY}" ]; then
    if [ -f "${USER_HOME}/.ssh/authorized_keys" ] && grep -qF "${GITHUB_ACTIONS_KEY}" "${USER_HOME}/.ssh/authorized_keys"; then
        echo "    GitHub Actions key already present."
    else
        printf '%s\n' "${GITHUB_ACTIONS_KEY}" >> "${USER_HOME}/.ssh/authorized_keys"
        chown "${DOCKER_USER}:${DOCKER_USER}" "${USER_HOME}/.ssh/authorized_keys"
        chmod 600 "${USER_HOME}/.ssh/authorized_keys"
        echo "    GitHub Actions autodeploy key added."
    fi
else
    echo "    Generating new GitHub Actions deploy key..."
    DEPLOY_KEY_PATH="/tmp/github-deploy-key"
    
    # Generate new Ed25519 key pair
    ssh-keygen -t ed25519 -f "${DEPLOY_KEY_PATH}" -N "" -C "github action autodeploy" >/dev/null 2>&1
    
    # Add public key to authorized_keys
    DEPLOY_PUBKEY=$(cat "${DEPLOY_KEY_PATH}.pub")
    printf '%s\n' "${DEPLOY_PUBKEY}" >> "${USER_HOME}/.ssh/authorized_keys"
    chown "${DOCKER_USER}:${DOCKER_USER}" "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    
    echo ""
    echo "    ✓ Generated new SSH key pair."
    echo ""
    echo "    📋 PUBLIC KEY (added to authorized_keys):"
    echo "    ${DEPLOY_PUBKEY}"
    echo ""
    echo "    🔐 PRIVATE KEY (store in GitHub repository secrets):"
    echo "    Add this as 'DEPLOY_KEY' in GitHub Settings > Secrets and variables > Actions"
    echo ""
    cat "${DEPLOY_KEY_PATH}"
    echo ""
    echo "    Alternatively, store in Doppler:"
    echo "    doppler secrets set DEPLOY_KEY < ${DEPLOY_KEY_PATH}"
    echo ""
    echo "    ⚠️  Keep the private key secure! Never commit it to version control."
    echo ""
    
    # Clean up temp key file from /tmp (but keep it if user wants to copy manually)
    rm "${DEPLOY_KEY_PATH}"
fi

echo "==> Docker user ready."
