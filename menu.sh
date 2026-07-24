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
echo "  [1] Manage Hysteria 2"
echo "  [2] Install Xray (Coming Soon)"
echo "  [0] Exit"
echo ""
echo "========================================================"
read -p "Select an option [0-2]: " menu_option

case $menu_option in
    1)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/hysteria.sh -o /root/modules/hysteria.sh
        chmod +x /root/modules/hysteria.sh
        bash /root/modules/hysteria.sh
        ;;
    2)
        echo "[*] Module pending..."; sleep 2; bash /root/menu.sh;;
    0)
        clear; exit 0;;
    *)
        echo "[!] Invalid option."; sleep 2; bash /root/menu.sh;;
esac
