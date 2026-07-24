#!/bin/bash

clear
echo "========================================================"
echo "          AITECHNETWORKS - HYSTERIA 2 MODULE            "
echo "========================================================"
echo ""
echo "  [1] Install Hysteria 2"
echo "  [2] Check Hysteria Service Status"
echo "  [3] Uninstall Hysteria 2"
echo "  [0] Back to Main Menu"
echo ""
echo "========================================================"
read -p "Select an option [0-3]: " h2_option

case $h2_option in
    1)
        echo "[*] Installing Hysteria 2..."
        bash <(curl -fsSL https://get.hy2.sh/)
        echo "[+] Hysteria 2 installation complete."
        sleep 2
        bash /root/modules/hysteria.sh
        ;;
    2)
        echo "[*] Checking status..."
        systemctl status hysteria --no-pager
        read -p "Press Enter to return..."
        bash /root/modules/hysteria.sh
        ;;
    3)
        echo "[*] Stopping and removing Hysteria 2..."
        systemctl stop hysteria > /dev/null 2>&1
        systemctl disable hysteria > /dev/null 2>&1
        rm -rf /etc/hysteria
        echo "[+] Hysteria 2 uninstalled."
        sleep 2
        bash /root/modules/hysteria.sh
        ;;
    0)
        bash /root/menu.sh
        ;;
    *)
        echo "[!] Invalid selection."
        sleep 1
        bash /root/modules/hysteria.sh
        ;;
esac
