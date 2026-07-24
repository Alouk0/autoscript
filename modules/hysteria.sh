#!/bin/bash

# Ensure database directory exists
mkdir -p /etc/hysteria
touch /etc/hysteria/users.db

clear
echo "========================================================"
echo "               HYSTERIA 2 MANAGEMENT                    "
echo "========================================================"
echo "  [1] Install & Configure Hysteria 2 Server"
echo "  [2] Create User Account"
echo "  [3] Delete User Account"
echo "  [4] Uninstall Hysteria 2"
echo "  [0] Back to Main Menu"
echo "========================================================"
read -p "Select an option [0-4]: " hys_option

case $hys_option in
    1)
        clear
        echo "[*] Initializing Hysteria 2 Installation..."
        bash <(curl -fsSL https://app.hysteria.network/app/install-ubuntu.sh)
        mkdir -p /etc/hysteria
        echo "[+] Hysteria 2 core installed successfully!"
        read -p "Press Enter to return to the Hysteria menu..."
        bash /root/modules/hysteria.sh
        ;;
    2)
        clear
        echo "========================================================"
        echo "              CREATE HYSTERIA 2 ACCOUNT                 "
        echo "========================================================"
        read -p "Enter Username : " USER
        read -p "Duration (Days): " DAYS
        
        # Generate random 8-character password & calculate expiry
        PASS=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
        EXPIRY=$(date -d "+${DAYS} days" +"%b %d, %Y")
        SERVER_IP=$(curl -s ifconfig.me)
        
        # Default Server Settings (Will be dynamic in final install script)
        PORT=53
        SNI="microsoft.com"
        OBFS="salamander"
        OBFS_PASS="da934c5dc5463a7e"
        
        # Save to local database (Format: Username | Password | Expiry | MaxIP)
        echo "$USER|$PASS|$EXPIRY|1" >> /etc/hysteria/users.db
        
        clear
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "        HYSTERIA 2 ACCOUNT CREATED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo " Username    : $USER"
        echo " Password    : $PASS"
        echo " Expired On  : $EXPIRY"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo " Server IP   : $SERVER_IP"
        echo " SNI / Host  : $SNI"
        echo " Port        : $PORT"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo " COPY CONFIG URI:"
        echo "hy2://${PASS}@${SERVER_IP}:${PORT}/?insecure=1&sni=${SNI}&obfs=${OBFS}&obfs-password=${OBFS_PASS}#${USER}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        read -p "Press Enter to return to the Hysteria menu..."
        bash /root/modules/hysteria.sh
        ;;
    3)
        clear
        echo "========================================================"
        echo "              DELETE HYSTERIA 2 ACCOUNT                 "
        echo "========================================================"
        read -p "Enter Username to delete: " DEL_USER
        
        # Remove user from database
        sed -i "/^$DEL_USER|/d" /etc/hysteria/users.db
        
        echo "[+] Account $DEL_USER has been removed."
        read -p "Press Enter to return..."
        bash /root/modules/hysteria.sh
        ;;
    4)
        clear
        echo "[*] Removing Hysteria 2..."
        systemctl stop hysteria-server.service 2>/dev/null
        systemctl disable hysteria-server.service 2>/dev/null
        apt-get remove -y hysteria
        rm -rf /etc/hysteria
        echo "[+] Hysteria 2 has been completely removed."
        read -p "Press Enter to return..."
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
