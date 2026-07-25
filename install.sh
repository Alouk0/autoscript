#!/usr/bin/env bash
#
# install.sh — Core installer for the VPN autoscript panel
#
# Sets up:
#   - Base VPS hardening (firewall, fail2ban)
#   - Xray-core with VMess / VLESS / Trojan (WebSocket + TLS via Nginx)
#     and Shadowsocks (direct AEAD)
#   - Nginx as TLS-terminating reverse proxy
#   - acme.sh for SSL issuance + auto-renewal
#
# Tested target: Ubuntu 22.04 / 24.04, Debian 11 / 12
# Usage: sudo bash install.sh <domain> <email>
#        (or run with no args and answer the prompts)

set -euo pipefail
trap 'echo -e "\n[FAIL] Line $LINENO: command failed. Aborting." >&2' ERR

# ---------------------------------------------------------------------------
# Constants / paths
# ---------------------------------------------------------------------------
PANEL_DIR="/etc/xray-panel"
XRAY_CONF_DIR="/usr/local/etc/xray"
XRAY_CONF="${XRAY_CONF_DIR}/config.json"
NGINX_SITE="/etc/nginx/sites-available/xray-panel.conf"
NGINX_SITE_LINK="/etc/nginx/sites-enabled/xray-panel.conf"
CERT_DIR="${PANEL_DIR}/cert"
CRED_FILE="${PANEL_DIR}/credentials.json"

VMESS_PORT=10001
VLESS_PORT=10002
TROJAN_PORT=10003
SS_PORT=8388   # public, direct (not proxied through Nginx)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
die()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Run this script as root (sudo bash install.sh ...)."
}

detect_os() {
  [[ -f /etc/os-release ]] || die "Cannot detect OS (missing /etc/os-release)."
  . /etc/os-release
  OS_ID="${ID}"
  OS_VER="${VERSION_ID}"
  case "${OS_ID}" in
    ubuntu|debian) log "Detected ${PRETTY_NAME}" ;;
    *) die "Unsupported OS: ${PRETTY_NAME:-$OS_ID}. This script targets Ubuntu/Debian." ;;
  esac
}

random_path() { echo "/$(openssl rand -hex 8)"; }
gen_uuid()    { cat /proc/sys/kernel/random/uuid; }
gen_password(){ openssl rand -base64 18 | tr -d '=+/' | cut -c1-20; }

get_inputs() {
  DOMAIN="${1:-}"
  EMAIL="${2:-}"
  if [[ -z "${DOMAIN}" ]]; then
    read -rp "Enter the domain pointed at this server (A record already set): " DOMAIN
  fi
  [[ -n "${DOMAIN}" ]] || die "A domain is required."
  if [[ -z "${EMAIL}" ]]; then
    read -rp "Enter an email for SSL registration/renewal notices: " EMAIL
  fi
  [[ -n "${EMAIL}" ]] || die "An email is required for acme.sh registration."
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
install_dependencies() {
  log "Updating packages and installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y curl wget unzip socat cron jq sqlite3 uuid-runtime \
    qrencode ufw fail2ban nginx openssl ca-certificates
}

install_xray() {
  log "Installing Xray-core (official installer)..."
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
  mkdir -p "${XRAY_CONF_DIR}"
}

install_acme() {
  log "Installing acme.sh..."
  if [[ ! -d "${HOME}/.acme.sh" ]]; then
    curl https://get.acme.sh | sh -s email="${EMAIL}"
  fi
  ACME="${HOME}/.acme.sh/acme.sh"
  "${ACME}" --set-default-ca --server letsencrypt

  mkdir -p "${CERT_DIR}"
  log "Issuing certificate for ${DOMAIN} (standalone mode, needs port 80 free)..."
  systemctl stop nginx 2>/dev/null || true
  "${ACME}" --issue --standalone -d "${DOMAIN}" --keylength ec-256 || \
    die "Certificate issuance failed. Check that ${DOMAIN} resolves to this server and port 80 is reachable."

  "${ACME}" --install-cert -d "${DOMAIN}" --ecc \
    --fullchain-file "${CERT_DIR}/fullchain.pem" \
    --key-file "${CERT_DIR}/privkey.pem" \
    --reloadcmd "systemctl reload nginx || systemctl start nginx || true"
}

configure_xray() {
  log "Generating credentials and writing Xray config..."
  mkdir -p "${PANEL_DIR}"

  VMESS_UUID=$(gen_uuid)
  VLESS_UUID=$(gen_uuid)
  TROJAN_PASS=$(gen_password)
  SS_PASS=$(gen_password)

  VMESS_PATH=$(random_path)
  VLESS_PATH=$(random_path)
  TROJAN_PATH=$(random_path)

  cat > "${XRAY_CONF}" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": ${VMESS_PORT},
      "protocol": "vmess",
      "settings": { "clients": [ { "id": "${VMESS_UUID}", "alterId": 0 } ] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "${VMESS_PATH}" }
      }
    },
    {
      "listen": "127.0.0.1",
      "port": ${VLESS_PORT},
      "protocol": "vless",
      "settings": { "clients": [ { "id": "${VLESS_UUID}" } ], "decryption": "none" },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "${VLESS_PATH}" }
      }
    },
    {
      "listen": "127.0.0.1",
      "port": ${TROJAN_PORT},
      "protocol": "trojan",
      "settings": { "clients": [ { "password": "${TROJAN_PASS}" } ] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "${TROJAN_PATH}" }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": ${SS_PORT},
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "${SS_PASS}",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

  # Save credentials for the next component (user/DB management) to pick up
  cat > "${CRED_FILE}" <<EOF
{
  "domain": "${DOMAIN}",
  "vmess":  { "uuid": "${VMESS_UUID}",  "path": "${VMESS_PATH}",  "port": 443 },
  "vless":  { "uuid": "${VLESS_UUID}",  "path": "${VLESS_PATH}",  "port": 443 },
  "trojan": { "password": "${TROJAN_PASS}", "path": "${TROJAN_PATH}", "port": 443 },
  "shadowsocks": { "password": "${SS_PASS}", "method": "aes-128-gcm", "port": ${SS_PORT} }
}
EOF
  chmod 600 "${CRED_FILE}"

  systemctl enable xray
  systemctl restart xray
}

configure_nginx() {
  log "Writing Nginx reverse proxy config..."
  cat > "${NGINX_SITE}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate     ${CERT_DIR}/fullchain.pem;
    ssl_certificate_key ${CERT_DIR}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location ${VMESS_PATH} {
        proxy_pass http://127.0.0.1:${VMESS_PORT};
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location ${VLESS_PATH} {
        proxy_pass http://127.0.0.1:${VLESS_PORT};
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location ${TROJAN_PATH} {
        proxy_pass http://127.0.0.1:${TROJAN_PORT};
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location / {
        return 404;
    }
}
EOF

  rm -f /etc/nginx/sites-enabled/default
  ln -sf "${NGINX_SITE}" "${NGINX_SITE_LINK}"
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

configure_firewall() {
  log "Configuring UFW..."
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow "${SS_PORT}/tcp"
  ufw allow "${SS_PORT}/udp"
  ufw --force enable
}

configure_fail2ban() {
  log "Configuring fail2ban for sshd..."
  cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
port    = 22
maxretry = 5
bantime  = 3600
findtime = 600
EOF
  systemctl enable fail2ban
  systemctl restart fail2ban
}

print_summary() {
  echo
  echo "=================================================================="
  echo " Core install complete"
  echo "=================================================================="
  echo " Domain:        ${DOMAIN}"
  echo " VMess:         wss://${DOMAIN}${VMESS_PATH}  (uuid: ${VMESS_UUID})"
  echo " VLESS:         wss://${DOMAIN}${VLESS_PATH}  (uuid: ${VLESS_UUID})"
  echo " Trojan:        wss://${DOMAIN}${TROJAN_PATH}  (pass: ${TROJAN_PASS})"
  echo " Shadowsocks:   ${DOMAIN}:${SS_PORT}  (aes-128-gcm, pass: ${SS_PASS})"
  echo
  echo " Credentials saved to: ${CRED_FILE}"
  echo " Xray config:          ${XRAY_CONF}"
  echo " Nginx site:           ${NGINX_SITE}"
  echo
  echo " Next: user & DB management layer will read ${CRED_FILE} and"
  echo " ${XRAY_CONF} to add/expire/limit individual users."
  echo "=================================================================="
}

main() {
  require_root
  detect_os
  get_inputs "${1:-}" "${2:-}"
  install_dependencies
  install_xray
  install_acme
  configure_xray
  configure_nginx
  configure_firewall
  configure_fail2ban
  print_summary
}

main "$@"
