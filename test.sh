#!/bin/bash

set -e

CONFIG="/etc/ssh/sshd_config"

# -------------------------------
# Check root
# -------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Run this script with sudo."
    exit 1
fi

# -------------------------------
# Check argument
# -------------------------------

if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  sudo $0 secure"
    echo "  sudo $0 insecure"
    exit 1
fi

MODE="$1"

if [[ "$MODE" != "secure" && "$MODE" != "insecure" ]]; then
    echo "[ERROR] Mode must be 'secure' or 'insecure'."
    exit 1
fi

# -------------------------------
# Detect SSH service
# -------------------------------

if systemctl list-unit-files | grep -q "^sshd.service"; then
    SSH_SERVICE="sshd"
elif systemctl list-unit-files | grep -q "^ssh.service"; then
    SSH_SERVICE="ssh"
else
    echo "[ERROR] SSH service not found."
    exit 1
fi

echo "[+] SSH service: $SSH_SERVICE"

# -------------------------------
# Backup before changing
# -------------------------------

BACKUP="/etc/ssh/sshd_config.demo-backup"

if [ ! -f "$BACKUP" ]; then
    cp "$CONFIG" "$BACKUP"
    echo "[+] Original configuration backed up to:"
    echo "    $BACKUP"
else
    echo "[+] Existing demo backup found."
fi

# -------------------------------
# Remove settings controlled
# by this script
# -------------------------------

echo "[+] Removing existing SSH settings..."

sed -i '/^[[:space:]]*PubkeyAuthentication[[:space:]]/Id' "$CONFIG"
sed -i '/^[[:space:]]*PasswordAuthentication[[:space:]]/Id' "$CONFIG"
sed -i '/^[[:space:]]*PermitRootLogin[[:space:]]/Id' "$CONFIG"
sed -i '/^[[:space:]]*MaxAuthTries[[:space:]]/Id' "$CONFIG"

# -------------------------------
# SECURE MODE
# -------------------------------

if [ "$MODE" = "secure" ]; then

    echo
    echo "================================="
    echo "      APPLYING SECURE MODE"
    echo "================================="

    cat >> "$CONFIG" <<'EOF'

# ===== SSH DEMO - SECURE MODE =====

PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3

# ===== END SSH DEMO =====
EOF

# -------------------------------
# INSECURE MODE
# -------------------------------

else

    echo
    echo "================================="
    echo "    APPLYING INSECURE MODE"
    echo "================================="

    cat >> "$CONFIG" <<'EOF'

# ===== SSH DEMO - INSECURE MODE =====

PubkeyAuthentication no
PasswordAuthentication yes
PermitRootLogin yes
MaxAuthTries 10

# ===== END SSH DEMO =====
EOF

fi

# -------------------------------
# Validate
# -------------------------------

echo
echo "[+] Testing SSH configuration..."

if sshd -t; then
    echo "[OK] Configuration is valid."
else
    echo "[ERROR] Configuration is invalid!"
    echo "[+] Restoring backup..."

    cp "$BACKUP" "$CONFIG"
    exit 1
fi

# -------------------------------
# Reload SSH
# -------------------------------

echo "[+] Reloading SSH..."

systemctl reload "$SSH_SERVICE"

# -------------------------------
# Show effective settings
# -------------------------------

echo
echo "================================="
echo "       EFFECTIVE SETTINGS"
echo "================================="

sshd -T | grep -E \
'^(pubkeyauthentication|passwordauthentication|permitrootlogin|maxauthtries) '

echo
echo "================================="

if [ "$MODE" = "secure" ]; then
    echo "       SSH IS NOW SECURED"
else
    echo "      SSH IS NOW INSECURE"
fi

echo "================================="
