#!/bin/bash

clear
echo "========================================================"
echo "            AITECHNETWORKS - XRAY MODULE                "
echo "========================================================"
echo ""
echo "  [1] Install Xray Core"
echo "  [2] Check Xray Service Status"
echo "  [3] Uninstall Xray"
echo "  [0] Back to Main Menu"
echo ""
echo "========================================================"
read -p "Select an option [0-3]: " xray_option

case $xray_option in
    1)
        echo "[*] Installing Xray Core..."
        bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
        echo "[+] Xray installation complete."
        sleep 2
        bash /root/modules/xray.sh
        ;;
    2)
        echo "[*] Checking Xray status..."
        systemctl status xray --no-pager
        read -p "Press Enter to return..."
        bash /root/modules/xray.sh
        ;;
    3)
        echo "[*] Removing Xray..."
        bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) remove
        echo "[+] Xray uninstalled."
        sleep 2
        bash /root/modules/xray.sh
        ;;
    0)
        bash /root/menu.sh
        ;;
    *)
        echo "[!] Invalid selection."
        sleep 1
        bash /root/modules/xray.sh
        ;;
esac
