#!/bin/bash

# Configuration paths
CONFIG_FILE="/etc/hysteria/config.yaml"
DB_FILE="/etc/hysteria/users.db"
SERVER_IP=$(curl -s ifconfig.me)

# Start building the Hysteria 2 YAML config base
cat << EOF > $CONFIG_FILE
listen: :53

tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/cert.key

obfs:
  type: salamander
  password: da934c5dc5463a7e

auth:
  type: password
  users:
EOF

# Read the local database and append each active user
if [ -f "$DB_FILE" ]; then
    while IFS='|' read -r user pass expiry maxip; do
        if [ -n "$user" ]; then
            echo "    $pass: $user" >> $CONFIG_FILE
        fi
    done < "$DB_FILE"
fi

# Restart Hysteria service to apply changes
systemctl restart hysteria-server.service 2>/dev/null
