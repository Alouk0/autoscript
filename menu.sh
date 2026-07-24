#!/bin/bash

# ========================================================
# AUTO-ENFORCER: INVISIBLE LICENSE CHECK
# ========================================================
MASTER_IP="107.175.212.124"
KEY=$(cat /root/.aitech_key 2>/dev/null)

# Fetch data from live PHP API silently (5-second timeout)
API_RESPONSE=$(curl -s --max-time 5 "http://$MASTER_IP:7778/verify.php?key=$KEY")

# Parse the JSON response
STATUS=$(echo "$API_RESPONSE" | grep -o '"status": *"[^"]*"' | cut -d'"' -f4)
MESSAGE=$(echo "$API_RESPONSE" | grep -o '"message": *"[^"]*"' | cut -d'"' -f4)

# Trigger Lockdown if not successful
if [ "$STATUS" != "success" ]; then
    clear
    echo -e "\e[31m  ⚠️ SYSTEM LOCKDOWN: LICENSE EXPIRED/INVALID ⚠️ \e[0m"
    echo "========================================================"
    echo "Your AITECHNETWORKS Autoscript license is currently inactive."
    echo "Server IP  : $(curl -s ifconfig.me)"
    echo "API Status : ${MESSAGE:-CONNECTION FAILED OR NO KEY FOUND}"
    echo ""
    echo "[ SERVICE INFRASTRUCTURE STATUS ]"
    echo "❌ Hysteria Engine & Routing Nodes: OFFLINE"
    echo "❌ Client Internet Access & Routing : SUSPENDED"
    echo "✅ Base Admin SSH Access (Port 22)  : ACTIVE"
    echo "========================================================"
    echo "Run your installation script again and select Option [5]"
    echo "to enter a valid license key."
    echo ""
    exit 1
fi
# ========================================================
# END OF ENFORCER - START NORMAL MENU
# ========================================================

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
echo "  [2] Manage Xray (VMess/VLESS/Trojan)"
echo "  [3] Security & Firewall Settings"
echo "  [4] Backup & Restore"
echo "  [5] License Management"
echo "  [0] Exit"
echo ""
echo "========================================================"
read -p "Select an option [0-5]: " menu_option

case $menu_option in
    1)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/hysteria.sh -o /root/modules/hysteria.sh
        chmod +x /root/modules/hysteria.sh
        bash /root/modules/hysteria.sh
        ;;
    2)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/xray.sh -o /root/modules/xray.sh
        chmod +x /root/modules/xray.sh
        bash /root/modules/xray.sh
        ;;
    3)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/firewall.sh -o /root/modules/firewall.sh
        chmod +x /root/modules/firewall.sh
        bash /root/modules/firewall.sh
        ;;
    4)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/backup.sh -o /root/modules/backup.sh
        chmod +x /root/modules/backup.sh
        bash /root/modules/backup.sh
        ;;
    5)
        mkdir -p /root/modules
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/license.sh -o /root/modules/license.sh
        chmod +x /root/modules/license.sh
        bash /root/modules/license.sh
        ;;
    0)
        clear; exit 0;;
    *)
        echo "[!] Invalid option."; sleep 2; bash /root/menu.sh;;
esac
