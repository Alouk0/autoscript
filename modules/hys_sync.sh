#!/bin/bash

CONFIG_FILE="/etc/hysteria/config.yaml"
DB_FILE="/etc/hysteria/users.db"
SETTINGS_FILE="/etc/hysteria/settings.conf"

PORT=443
if [ -f "$SETTINGS_FILE" ]; then
    source "$SETTINGS_FILE"
fi

cat << EOF > $CONFIG_FILE
listen: :$PORT

tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/cert.key

obfs:
  type: salamander
  password: secureobfspass123

auth:
  type: password
  users:
EOF

if [ -f "$DB_FILE" ]; then
    while IFS='|' read -r user pass expiry maxip; do
        if [ -n "$user" ] && [ -n "$pass" ]; then
            echo "    $pass: $user" >> $CONFIG_FILE
        fi
    done < "$DB_FILE"
fi

systemctl restart hysteria-server.service
