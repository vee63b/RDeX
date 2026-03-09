#!/bin/bash

PORT="8022"
USER_NAME=$(whoami)

# ==========================================
# Load Credentials
# ==========================================

CRED_FILE="$HOME/.rdex/credentials.conf"

if [ -f "$CRED_FILE" ]; then
    source "$CRED_FILE"
else
    SSH_PASS="<not-set>"
    CODE_PASS="<not-set>"
    CODE_ENABLED="false"
fi

# ==========================================
# Get wlan0 IP
# ==========================================

temp_file=$(mktemp)
ifconfig 2>/dev/null > "$temp_file"
IP_ADDR=$(awk '/^wlan0:/ {p=1} p && /inet / {print $2; exit}' "$temp_file")
rm -f "$temp_file"

[ -z "$IP_ADDR" ] && IP_ADDR="<wifi-off>"

# ==========================================
# Get SMB Port
# ==========================================

SMB_CONF="$PREFIX/etc/samba/smb.conf"
SMB_PORT=$(grep -i "smb ports" "$SMB_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
[ -z "$SMB_PORT" ] && SMB_PORT="445"

# ==========================================
# Service Status Checks
# ==========================================

check_service() {
    pgrep -f "$1" >/dev/null 2>&1 && echo "RUNNING" || echo "STOPPED"
}

SSHD_STATUS=$(check_service sshd)
SMB_STATUS=$(check_service smbd)

if [[ "$CODE_ENABLED" == "true" ]]; then
    CODE_STATUS=$(check_service code-server)
fi

# ==========================================
# Output
# ==========================================

echo ""
echo "=========================================="
echo " Current RDeXServer Status"
echo "=========================================="
echo ""

echo "SSH:"
echo "  Command : ssh ${USER_NAME}@${IP_ADDR} -p ${PORT}"
echo "  Password: ${SSH_PASS}"
echo "  Status  : ${SSHD_STATUS}"
echo ""

echo "SMB:"
echo "  Address : smb://${IP_ADDR}:${SMB_PORT}"
echo "  Status  : ${SMB_STATUS}"
echo ""

if [[ "$CODE_ENABLED" == "true" ]]; then
    echo "Code Server:"
    echo "  URL      : http://${IP_ADDR}:8080"
    echo "  Password : ${CODE_PASS}"
    echo "  Status   : ${CODE_STATUS}"
    echo ""
fi

echo "=========================================="