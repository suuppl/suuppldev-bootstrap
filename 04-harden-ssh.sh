#!/bin/bash
set -euo pipefail

# 04-harden-ssh.sh
# Apply conservative SSH hardening to /etc/ssh/sshd_config
# Usage: sudo ./04-harden-ssh.sh [allowuser]

echo "==> Applying SSH hardening..."
echo "This will:"
echo " - Disable root login"
echo " - Disable password authentication"
echo " - Enforce public key authentication"
echo " - Optionally restrict login to a specific user"

read -p "Do you want to continue? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "==> Skipping SSH hardening"
else

    SSHD_CONF=/etc/ssh/sshd_config
    ALLOW_USER="${1:-}"

    if [ ! -w "${SSHD_CONF}" ]; then
        echo "Cannot write ${SSHD_CONF}; run as root to apply changes." >&2
        exit 2
    fi

    TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
    cp "${SSHD_CONF}" "${SSHD_CONF}.bak.${TIMESTAMP}"
    echo "Backup saved to ${SSHD_CONF}.bak.${TIMESTAMP}"

    set_config() {
        local key="$1" value="$2"
        if grep -qE "^\s*${key}" "${SSHD_CONF}"; then
            sed -ri "s|^\s*${key}.*|${key} ${value}|" "${SSHD_CONF}"
        else
            echo "${key} ${value}" >> "${SSHD_CONF}"
        fi
    }

    set_config PermitRootLogin no
    set_config PasswordAuthentication no
    set_config ChallengeResponseAuthentication no
    set_config PubkeyAuthentication yes
    set_config PermitEmptyPasswords no
    set_config UsePAM yes

    if [ -n "${ALLOW_USER}" ]; then
        if grep -qE "^\s*AllowUsers" "${SSHD_CONF}"; then
            sed -ri "s|^\s*AllowUsers.*|AllowUsers ${ALLOW_USER}|" "${SSHD_CONF}"
        else
            echo "AllowUsers ${ALLOW_USER}" >> "${SSHD_CONF}"
        fi
    fi

    # Try to reload sshd (support both service names)
    if systemctl list-units --type=service --all | grep -q "sshd.service"; then
        systemctl reload sshd || systemctl restart sshd || echo "Failed to reload sshd; restart manually." >&2
    elif systemctl list-units --type=service --all | grep -q "ssh.service"; then
        systemctl reload ssh || systemctl restart ssh || echo "Failed to reload ssh; restart manually." >&2
    else
        echo "systemd-managed ssh service not found; please restart sshd manually." >&2
    fi

    cat <<EOF
    SSH hardening applied. To restore previous config:
    sudo cp ${SSHD_CONF}.bak.${TIMESTAMP} ${SSHD_CONF} && sudo systemctl reload sshd || sudo systemctl reload ssh
    EOF

fi