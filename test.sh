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
