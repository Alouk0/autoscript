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
        MASTER_IP="107.175.212.124"
        
        echo "[*] Contacting Master License Server..."
        
        # Fetch data from your live PHP API
        API_RESPONSE=$(curl -s --max-time 5 "http://$MASTER_IP:7778/verify.php?key=$KEY")
        
        # Parse the JSON response
        STATUS=$(echo "$API_RESPONSE" | grep -o '"status": *"[^"]*"' | cut -d'"' -f4)
        MESSAGE=$(echo "$API_RESPONSE" | grep -o '"message": *"[^"]*"' | cut -d'"' -f4)
        EXPIRY=$(echo "$API_RESPONSE" | grep -o '"expiry": *"[^"]*"' | cut -d'"' -f4)
        
        if [ "$STATUS" == "success" ]; then
            echo "========================================================"
            echo " [ SERVER LICENSE STATUS ]"
            echo " Key    : $KEY"
            echo " Status : ACTIVE"
            echo " Expiry : $EXPIRY"
            echo "========================================================"
            read -p "Press Enter to return..."
            bash /root/modules/license.sh
        else
            # TRIGGER SYSTEM LOCKDOWN
            echo -e "\e[31m  ⚠️ SYSTEM LOCKDOWN: LICENSE EXPIRED/INVALID ⚠️ \e[0m"
            echo "========================================================"
            echo "Your AITECHNETWORKS Autoscript license is currently inactive."
            echo "Server IP  : $(curl -s ifconfig.me)"
            echo "API Status : ${MESSAGE:-CONNECTION FAILED}"
            echo ""
            echo "[ SERVICE INFRASTRUCTURE STATUS ]"
            echo "❌ Hysteria Engine & Routing Nodes: OFFLINE"
            echo "❌ Client Internet Access & Routing : SUSPENDED"
            echo "✅ Base Admin SSH Access (Port 22)  : ACTIVE"
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
