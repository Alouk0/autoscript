#!/bin/bash

clear
echo "========================================================"
echo "          AITECHNETWORKS - SECURITY & FIREWALL          "
echo "========================================================"
echo ""
echo "  [1] Enable UFW Firewall (Auto-Configured)"
echo "  [2] Disable UFW Firewall"
echo "  [3] Check Firewall Status"
echo "  [0] Back to Main Menu"
echo ""
echo "========================================================"
read -p "Select an option [0-3]: " fw_option

case $fw_option in
    1)
        echo "[*] Configuring UFW Firewall..."
        # Prevent SSH lockout
        ufw allow ssh > /dev/null 2>&1
        ufw allow 22/tcp > /dev/null 2>&1
        
        # Standard web ports
        ufw allow 80/tcp > /dev/null 2>&1
        ufw allow 443/tcp > /dev/null 2>&1
        
        # Proxy standard ports
        ufw allow 443/udp > /dev/null 2>&1
        
        echo "y" | ufw enable
        echo "[+] Firewall is now ENABLED and SECURED."
        sleep 2
        bash /root/modules/firewall.sh
        ;;
    2)
        echo "[*] Disabling UFW Firewall..."
        ufw disable
        echo "[+] Firewall is now DISABLED."
        sleep 2
        bash /root/modules/firewall.sh
        ;;
    3)
        clear
        echo "[ UFW FIREWALL STATUS ]"
        ufw status verbose
        echo ""
        read -p "Press Enter to return..."
        bash /root/modules/firewall.sh
        ;;
    0)
        bash /root/menu.sh
        ;;
    *)
        echo "[!] Invalid selection."
        sleep 1
        bash /root/modules/firewall.sh
        ;;
esac
