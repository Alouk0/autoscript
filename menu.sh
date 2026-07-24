#!/bin/bash

# Fetch Server IP
SERVER_IP=$(curl -s ifconfig.me)

clear
echo "========================================================"
echo "           AITECHNETWORKS MANAGEMENT MENU               "
echo "========================================================"
echo "Server IP  : $SERVER_IP"
echo "Status     : ACTIVE"
echo "========================================================"
echo ""
echo "  [1] Install Hysteria 2 (Coming Soon)"
echo "  [2] Install Xray (Coming Soon)"
echo "  [0] Exit"
echo ""
echo "========================================================"
read -p "Select an option [0-2]: " menu_option

case $menu_option in
    1) echo "[*] Module pending..."; sleep 2; bash /root/menu.sh;;
    2) echo "[*] Module pending..."; sleep 2; bash /root/menu.sh;;
    0) clear; exit 0;;
    *) echo "[!] Invalid option."; sleep 2; bash /root/menu.sh;;
esac
