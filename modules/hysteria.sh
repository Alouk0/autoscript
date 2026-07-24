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
        echo "[*] Installing Hysteria 2 directly from GitHub..."
        
        # Download latest Hysteria 2 Linux AMD64 binary
        curl -sSL https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64 -o /usr/local/bin/hysteria
        chmod +x /usr/local/bin/hysteria
        
        # Create necessary directories
        mkdir -p /etc/hysteria
        
        # Create a basic systemd service for Hysteria 2
        cat << 'EOF' > /etc/systemd/system/hysteria-server.service
[Unit]
Description=Hysteria 2 Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable hysteria-server.service
        
        echo "[+] Hysteria 2 core and system service installed successfully!"
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
        
        PORT=53
        SNI="microsoft.com"
        OBFS="salamander"
        OBFS_PASS="da934c5dc5463a7e"
        
        # Save to local database
        echo "$USER|$PASS|$EXPIRY|1" >> /etc/hysteria/users.db
        
        # Pull and run the backend sync script to activate the user live
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/hys_sync.sh -o /root/modules/hys_sync.sh
        bash /root/modules/hys_sync.sh
        
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
        
        # Sync backend to revoke access immediately
        curl -sSL https://raw.githubusercontent.com/Alouk0/autoscript/main/modules/hys_sync.sh -o /root/modules/hys_sync.sh
        bash /root/modules/hys_sync.sh
        
        echo "[+] Account $DEL_USER has been removed and revoked."
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
