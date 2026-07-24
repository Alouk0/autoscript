#!/bin/bash

BACKUP_DIR="/root/autoscript_backups"

clear
echo "========================================================"
echo "          AITECHNETWORKS - BACKUP & RESTORE             "
echo "========================================================"
echo ""
echo "  [1] Create System Backup"
echo "  [2] Restore From Backup"
echo "  [3] Delete Old Backups"
echo "  [0] Back to Main Menu"
echo ""
echo "========================================================"
read -p "Select an option [0-3]: " backup_option

case $backup_option in
    1)
        echo "[*] Creating backup directory..."
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        
        echo "[*] Compressing configuration files..."
        tar -czf "$BACKUP_FILE" /etc/hysteria /usr/local/etc/xray /etc/ufw 2>/dev/null
        
        echo "[+] Backup successfully created at:"
        echo "    $BACKUP_FILE"
        sleep 3
        bash /root/modules/backup.sh
        ;;
    2)
        echo "[*] Available Backups:"
        ls -lh "$BACKUP_DIR" 2>/dev/null
        echo ""
        read -p "Enter full file path to restore: " RESTORE_FILE
        
        if [ -f "$RESTORE_FILE" ]; then
            echo "[*] Restoring backup..."
            tar -xzf "$RESTORE_FILE" -C /
            echo "[+] Configurations successfully restored."
        else
            echo "[!] Error: File not found."
        fi
        sleep 2
        bash /root/modules/backup.sh
        ;;
    3)
        echo "[*] Removing all local backups..."
        rm -rf "$BACKUP_DIR"/*
        echo "[+] Backup directory cleared."
        sleep 2
        bash /root/modules/backup.sh
        ;;
    0)
        bash /root/menu.sh
        ;;
    *)
        echo "[!] Invalid selection."
        sleep 1
        bash /root/modules/backup.sh
        ;;
esac
