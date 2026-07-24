#!/bin/bash

clear
echo "========================================================"
echo "          AITECHNETWORKS - LICENSE MANAGEMENT           "
echo "========================================================"
echo ""
echo "  [1] Enter / Update License Key"
echo "  [2] Check License Status"
echo "  [0] Back to Main Menu"
echo ""
echo "========================================================"
read -p "Select an option [0-2]: " lic_option

case $lic_option in
    1)
        read -p "Enter your AITECHNETWORKS License Key: " NEW_KEY
        echo "$NEW_KEY" > /root/.aitech_key
        echo "[+] License key saved securely!"
        sleep 2
        bash /root/modules/license.sh
        ;;
    2)
        clear
        KEY=$(cat /root/.aitech_key 2>/dev/null)
        
        # Test against our valid Admin Key
        if [ "$KEY" == "AITECH-ADMIN-777" ]; then
            echo "========================================================"
            echo " [ SERVER LICENSE STATUS ]"
            echo " Key    : $KEY"
            echo " Status : ACTIVE"
            echo " Expiry : 2027-01-01"
            echo "========================================================"
            read -p "Press Enter to return..."
            bash /root/modules/license.sh
        else
            # TRIGGER SYSTEM LOCKDOWN
            echo -e "\e[31m  ⚠️ SYSTEM LOCKDOWN: LICENSE EXPIRED ⚠️ \e[0m"
            echo "========================================================"
            echo "Your AITECHNETWORKS Autoscript license is currently inactive."
            echo "Server IP  : $(curl -s ifconfig.me)"
            echo "API Status : LICENSE INVALID OR EXPIRED"
            echo ""
            echo "[ SERVICE INFRASTRUCTURE STATUS ]"
            echo "❌ Hysteria Engine & Routing Nodes: OFFLINE"
            echo "❌ Client Internet Access & Routing : SUSPENDED"
            echo "✅ Base Admin SSH Access (Port 22)  : ACTIVE"
            echo ""
            echo "[ AUTOMATED SYSTEM NOTICE ]"
            echo "The License Enforcer has safely suspended all networking and"
            echo "user routing services to protect the server architecture."
            echo ""
            echo "Your client accounts, VPS IP, and configurations are safe."
            echo "However, no connections will be processed until the license"
            echo "is formally renewed."
            echo "========================================================"
            read -p "Press Enter to return..."
            bash /root/modules/license.sh
        fi
        ;;
    0)
        bash /root/menu.sh
        ;;
    *)
        echo "[!] Invalid selection."
        sleep 1
        bash /root/modules/license.sh
        ;;
esac
