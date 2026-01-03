#!/bin/bash
set -euo pipefail

echo "==> Creating user..."

if [ "${EUID}" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

read -rp "Enter username to create [user]: " BOOTSTRAP_USER
BOOTSTRAP_USER=${BOOTSTRAP_USER:-user}

if id "${BOOTSTRAP_USER}" &>/dev/null; then
    echo "    User '${BOOTSTRAP_USER}' already exists, ensuring configuration..."
else
    adduser --gecos "" "${BOOTSTRAP_USER}"
    echo "    User '${BOOTSTRAP_USER}' created."
fi

usermod -aG sudo "${BOOTSTRAP_USER}"
echo "    Added '${BOOTSTRAP_USER}' to sudo group."

read -rp "Paste public SSH key for ${BOOTSTRAP_USER} (leave blank to skip): " BOOTSTRAP_PUBKEY

USER_HOME=$(getent passwd "${BOOTSTRAP_USER}" | cut -d: -f6)
install -d -m 700 -o "${BOOTSTRAP_USER}" -g "${BOOTSTRAP_USER}" "${USER_HOME}/.ssh"

if [ -n "${BOOTSTRAP_PUBKEY}" ]; then
    echo "${BOOTSTRAP_PUBKEY}" > "${USER_HOME}/.ssh/authorized_keys"
    chown "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${USER_HOME}/.ssh/authorized_keys"
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    echo "    SSH key added to ${USER_HOME}/.ssh/authorized_keys."
else
    echo "    No SSH key provided; authorized_keys not created."
fi

echo "==> Docker user setup complete!"
