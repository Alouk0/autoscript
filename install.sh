#!/bin/bash

clear
echo "========================================================"
echo "         AITECHNETWORKS AUTOSCRIPT INSTALLER            "
echo "========================================================"
echo "[*] Checking system..."
sleep 1

# Check if the user is running as root
if [ "${EUID}" -ne 0 ]; then
    echo "[!] Error: Please run this script as root."
    exit 1
fi

echo "[+] System check passed!"
echo "[*] Installing basic required tools (curl, wget)..."
apt-get update -y > /dev/null 2>&1
apt-get install -y curl wget jq > /dev/null 2>&1

echo "[+] Installation complete!"
echo "========================================================"
echo "Next step: We will link your menu here soon!"
