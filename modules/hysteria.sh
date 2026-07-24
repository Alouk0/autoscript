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
        echo "========================================================"
        echo "          HYSTERIA 2 ADVANCED INSTALLATION              "
        echo "========================================================"
        read -p "Enter your Domain/SNI (e.g., vpn.yourdomain.com): " USER_DOMAIN
        read -p "Enter Port (Default: 53): " USER_PORT
        USER_PORT=${USER_PORT:-53}
        read -p "Enter your Email (for SSL registration): " USER_EMAIL
        
        echo "[*] Installing dependencies & Certbot..."
        apt-get update -y
        apt-get install -y curl socat certbot
        
        echo "[*] Downloading Hysteria 2 core..."
        curl -sSL https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64 -o /usr/local/bin/hysteria
        chmod +x /usr/local/bin/hysteria
        
        mkdir -p /etc/hysteria
        
        echo "[*] Stopping any service using port 80 for SSL generation..."
        systemctl stop apache2 nginx 2>/dev/null
        
        echo "[*] Obtaining Free SSL/TLS Certificate via Let's Encrypt..."
        certbot certonly --standalone --preferred-challenges http --agree-tos --register-unsafely-without-email -d "$USER_DOMAIN"
        
        if [ -d "/etc/letsencrypt/live/$USER_DOMAIN" ]; then
            cp /etc/letsencrypt/live/$USER_DOMAIN/fullchain.pem /etc/hysteria/cert.crt
            cp /etc/letsencrypt/live/$USER_DOMAIN/privkey.pem /etc/hysteria/cert.key
            echo "[+] SSL Certificates configured successfully!"
        else
            echo "[!] Warning: Certbot failed to generate certificate. Using self-signed fallback."
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/hysteria/cert.key -out /etc/hysteria/cert.crt -subj "/CN=$USER_DOMAIN"
        fi
        
        echo "DOMAIN=$USER_DOMAIN" > /etc/hysteria/settings.conf
        echo "PORT=$USER_PORT" >> /etc/hysteria/settings.conf
        
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
        
        echo "[+] Hysteria 2 fully configured with domain $USER_DOMAIN on port $USER_PORT!"
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
        
        PASS=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
        EXPIRY=$(date -d "+${DAYS} days" +"%b %d, %Y")
        SERVER_IP=$(curl -s ifconfig.me)
        
        # Load custom settings if available
        if [ -f "/etc/hysteria/settings.conf" ]; then
            source "/etc/hysteria/settings.conf"
        fi
        
        SNI=${DOMAIN:-microsoft.com}
        PORT=${PORT:-53}
        OBFS="salamander"
        OBFS_PASS="secureobfspass123"
        
        echo "$USER|$PASS|$EXPIRY|1" >> /etc/hysteria/users.db
        
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
        
        sed -i "/^$DEL_USER|/d" /etc/hysteria/users.db
        
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
        rm -f /usr/local/bin/hysteria
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
