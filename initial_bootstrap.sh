#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE=~/initial_bootstrap.log
echo "=== Initial bootstrap log started at $(date) ===" > "$LOG_FILE"

cd ~

echo "Please select repo..."
termux-change-repo

export DEBIAN_FRONTEND=noninteractive

# Add TUR repo
pkg install -y tur-repo

# Update all repos
pkg update -y
pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

SUCCESS=()
FAIL=()

log_install() {
    PKG="$1"

    if dpkg -s "$PKG" >/dev/null 2>&1; then
        echo -e "${GREEN}[ALREADY INSTALLED] $PKG${NC}"
        SUCCESS+=("$PKG")
        return
    fi

    echo "Installing $PKG..."
    if pkg install -y "$PKG"; then
        echo -e "${GREEN}[SUCCESS] $PKG${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $PKG" >> "$LOG_FILE"
        SUCCESS+=("$PKG")
    else
        echo -e "${RED}[FAILED] $PKG${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [FAILED] $PKG" >> "$LOG_FILE"
        FAIL+=("$PKG")
    fi
}

# Core Packages
log_install tree
log_install git
log_install tsu
log_install patchelf
log_install ncurses-utils
log_install hashdeep
log_install wget
log_install make
log_install cmake
log_install clang
log_install binutils
log_install python
log_install p7zip
log_install ndk-sysroot
log_install android-tools
log_install openssh
log_install samba
log_install termux-api

# Install Textual
if command -v pip >/dev/null 2>&1; then
    pip install --user textual || true
fi

# Android Storage Symlinks
echo "Configuring standard user folders..."

mkdir -p ~/storage/shared

rm -rf ~/Downloads ~/Documents ~/Pictures ~/Music ~/Movies 2>/dev/null

ln -s ~/storage/shared/Download  ~/Downloads
ln -s ~/storage/shared/Documents ~/Documents
ln -s ~/storage/shared/Pictures  ~/Pictures
ln -s ~/storage/shared/Music     ~/Music
ln -s ~/storage/shared/Movies    ~/Movies

# Termai Install
echo "Installing Termai..."
TEMP_TERMAI_PARENT=$(mktemp -d)
TEMP_TERMAI_DIR="$TEMP_TERMAI_PARENT/termai"

if git clone https://github.com/estiaksoyeb/termai.git "$TEMP_TERMAI_DIR"; then
    cd "$TEMP_TERMAI_DIR"
    bash install.sh
    cd ~
    rm -rf "$TEMP_TERMAI_PARENT"
fi

# Credential Setup
echo ""
echo "=========================================="
echo " Credential Setup"
echo "=========================================="

# SSH Password
while true; do
    read -s -p "Enter SSH password: " SSH_PASS
    echo ""
    read -s -p "Confirm SSH password: " SSH_PASS_CONFIRM
    echo ""

    if [ "$SSH_PASS" = "$SSH_PASS_CONFIRM" ] && [ -n "$SSH_PASS" ]; then
        break
    else
        echo "Passwords do not match or empty. Try again."
    fi
done

echo -e "${SSH_PASS}\n${SSH_PASS}" | passwd >/dev/null 2>&1
sshd

# Code Server
read -p "Install and configure Code Server? [y/N]: " INSTALL_CODE

if [[ "$INSTALL_CODE" =~ ^[Yy]$ ]]; then
    INSTALL_CODE_SERVER=true
    log_install code-server

    while true; do
        read -s -p "Enter Code-Server password: " CODE_PASS
        echo ""
        read -s -p "Confirm Code-Server password: " CODE_PASS_CONFIRM
        echo ""

        if [ "$CODE_PASS" = "$CODE_PASS_CONFIRM" ] && [ -n "$CODE_PASS" ]; then
            break
        else
            echo "Passwords do not match or empty. Try again."
        fi
    done

    mkdir -p ~/.config/code-server
    cat > ~/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:8080
auth: password
password: ${CODE_PASS}
cert: false
EOF
else
    INSTALL_CODE_SERVER=false
    CODE_PASS=""
fi

# Configuration Credentials
mkdir -p ~/.rdex

cat > ~/.rdex/credentials.conf <<EOF
SSH_PASS="${SSH_PASS}"
CODE_PASS="${CODE_PASS}"
CODE_ENABLED="${INSTALL_CODE_SERVER}"
EOF

chmod 600 ~/.rdex/credentials.conf

# Samba Setup
mkdir -p "$PREFIX/etc/samba"

if [ -f ~/storage/shared/RDeX/smb.conf ]; then
    cp ~/storage/shared/RDeX/smb.conf "$PREFIX/etc/samba/smb.conf"

    # Update smb.conf with current termux username
    GUEST=$(whoami)
    sed -i "s/^\s*guest account = .*$/   guest account = ${GUEST}/" \
        "$PREFIX/etc/samba/smb.conf" 2>/dev/null || true
fi

mkdir -p "$PREFIX/var/lib/samba/private"
mkdir -p "$PREFIX/var/log/samba"
mkdir -p "$PREFIX/var/run/samba"
mkdir -p "$PREFIX/var/lock/samba"
mkdir -p "$PREFIX/var/cache/samba"

# Shortcuts
mkdir -p ~/.shortcuts
if [ -d ~/storage/shared/RDeX/shortcuts ]; then
    cp -r ~/storage/shared/RDeX/shortcuts/* ~/.shortcuts/ 2>/dev/null
fi

# Ensure shortcut scripts are executable
if [ -d ~/.shortcuts ]; then
    cd ~/.shortcuts || exit
    chmod +x *.sh *.py 2>/dev/null
fi

# Aliases
add_alias() {
    grep -qxF "$1" ~/.bashrc || echo "$1" >> ~/.bashrc
}

add_alias "alias stop-smb='pkill -9 smbd && echo SMB Stopped'"
add_alias "alias start-smb='smbd -D && echo SMB Started'"
add_alias "alias sdcard='cd ~/storage/shared && pwd'"
add_alias "alias setup-scripts='cd ~/storage/shared/RDeX && pwd'"
add_alias "alias shortcuts='cd ~/.shortcuts && pwd'"
add_alias "alias rdex='bash ~/.shortcuts/launch_rdex.sh'"
add_alias "alias config-recap='bash ~/.shortcuts/status.sh'"

# Optional RDeX Install
read -p "Install RDeX (XFCE4 Desktop Environment) now? [y/N]: " INSTALL_RDeX

if [[ "$INSTALL_RDeX" =~ ^[Yy]$ ]]; then
    if [ -f ~/storage/shared/RDeX/install_RDeX.sh ]; then
        bash ~/storage/shared/RDeX/install_RDeX.sh
    fi
fi

# Final Summary
USER_NAME=$(whoami)

temp_file=$(mktemp)
ifconfig 2>/dev/null > "$temp_file"
IP_ADDR=$(awk '/^wlan0:/ {p=1} p && /inet / {print $2; exit}' "$temp_file")
rm -f "$temp_file"

[ -z "$IP_ADDR" ] && IP_ADDR="<wifi-off>"

SMB_PORT=$(grep -i "smb ports" "$PREFIX/etc/samba/smb.conf" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
[ -z "$SMB_PORT" ] && SMB_PORT="445"

echo "=========== Installation Summary ==========="

if [ ${#SUCCESS[@]} -ne 0 ]; then
    echo -e "${GREEN}Packages Ready:${NC}"
    for pkg in "${SUCCESS[@]}"; do
        echo "  - $pkg"
    done
fi

if [ ${#FAIL[@]} -ne 0 ]; then
    echo -e "${RED}Failed:${NC}"
    for pkg in "${FAIL[@]}"; do
        echo "  - $pkg"
    done
fi

echo "=========================================="

echo ""
echo "=========================================="
echo " Connection Information" 
echo "=========================================="
echo ""
echo "Use 'config-recap' to see this info"
echo ""
echo "SSH:"
echo "  ssh ${USER_NAME}@${IP_ADDR} -p 8022"
echo "  Password: ${SSH_PASS}"
echo ""
echo "SMB:"
echo "  smb://${IP_ADDR}:${SMB_PORT}"
echo ""

if [[ "$INSTALL_CODE_SERVER" == true ]]; then
    echo "Code Server:"
    echo "  http://${IP_ADDR}:8080"
    echo "  Password: ${CODE_PASS}"
    echo ""
fi

echo "=========================================="
echo " New Available Aliases"
echo "=========================================="
echo "shortcuts      -> Go to Termux Widget Shortcuts folder"
echo "rdex           -> Launch RDeX desktop"
echo "config-recap   -> Show connection & service status"
echo "start-smb      -> Start Samba service"
echo "stop-smb       -> Stop Samba service"
echo "sdcard         -> Go to shared storage"
echo "ai             -> Invoke CLI AI Assist (termai)"
echo "=========================================="

echo ""
echo "Use 'source ~/.bashrc' to reload and apply aliases."
echo "Or restart Termux to apply all changes."
echo ""
