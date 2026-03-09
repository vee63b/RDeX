#!/data/data/com.termux/files/usr/bin/bash

# ------------------------------------------------------------------
# RDeX Provisioning Script (Termux / Android)
# Deterministic hard-reset XFCE restore pipeline
# ------------------------------------------------------------------

set -eE

trap 'echo; echo "[RDeX] ERROR at line $LINENO"; read -p "Press Enter to exit..."' ERR

echo "=========================================="
echo "RDeX Provisioning (Termux Native)"
echo "=========================================="

# ---- Helper: install only if missing ----
install_pkg() {
    if ! pkg list-installed | grep -q "^$1/"; then
        echo "[RDeX] Installing $1"
        pkg install -y "$1"
    fi
}

# ---- System Update ----
echo "[RDeX] Updating system..."

for attempt in 1 2 3; do
    if pkg update -y; then
        break
    else
        echo "[RDeX] Update failed (attempt $attempt). Retrying..."
        sleep 5
    fi
done

pkg upgrade -y || true
install_pkg x11-repo

# ---- Runtime Packages ----
echo "[RDeX] Installing runtime packages..."

for p in \
    termux-x11-nightly \
    dbus pulseaudio \
    xfce4 xfce4-goodies xfce4-terminal \
    thunar thunar-archive-plugin \
    firefox chromium pavucontrol \
    xorg-xrandr xorg-xsetroot xorg-xev \
    xdotool xorg-xdpyinfo \
    zenity unzip; do
    install_pkg "$p"
done

# ---- Paths ----
BASE_DIR="$HOME/storage/shared/RDeX/assets/base_state"
BASE_ZIP="$BASE_DIR/rdex-base.zip"
PKG_LIST="$BASE_DIR/rdex-packages.txt"

# Wallpaper path (deterministic lock)
WALLPAPER="/data/data/com.termux/files/usr/share/background/xfce/xfce-light.svg"

# ---- Hard Reset Restore ----
if [ -f "$BASE_ZIP" ]; then
    echo "[RDeX] Applying base state..."

    echo "[RDeX] Stopping XFCE daemons..."
    pkill -9 xfce4-session 2>/dev/null || true
    pkill -9 xfconfd 2>/dev/null || true
    pkill -9 xfdesktop 2>/dev/null || true
    pkill -9 xfce4-panel 2>/dev/null || true

    echo "[RDeX] Clearing runtime cache..."
    rm -rf "$HOME/.cache/sessions" 2>/dev/null || true
    rm -rf "$HOME/.cache/xfce4" 2>/dev/null || true
    rm -rf "$HOME/.cache/menus" 2>/dev/null || true

    echo "[RDeX] Removing active XFCE config state..."
    rm -rf "$HOME/.config/xfce4/xfconf" 2>/dev/null || true

    echo "========== ZIP OVERWRITE OUTPUT =========="
    unzip -o "$BASE_ZIP" -d "$HOME"
    echo "==========================================="

    echo "[RDeX] Fixing permissions..."
    chmod -R u+rwX "$HOME/.config/xfce4" 2>/dev/null || true
    chmod -R u+rwX "$HOME/.local/share" 2>/dev/null || true

    [ -d "$HOME/.icons" ] && chmod -R 700 "$HOME/.icons"
    [ -d "$HOME/.themes" ] && chmod -R 700 "$HOME/.themes"

    # ---- Desktop Database ----
    echo "[RDeX] Rebuilding desktop database..."
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

    pkill -9 xfdesktop xfconfd 2>/dev/null || true

    echo "[RDeX] Base state restored cleanly."

else
    echo "[RDeX] No base_state ZIP found. Skipping restore."
fi

# ---- Package Parity ----
if [ -f "$PKG_LIST" ]; then
    echo "[RDeX] Ensuring package parity..."
    pkg install -y $(cat "$PKG_LIST")
else
    echo "[RDeX] No additional package list found."
fi

echo "=========================================="
echo "RDeX Provisioning Complete"
echo "Launch XFCE manually using:rdex"
echo "=========================================="

read -p "Press Enter to exit..."