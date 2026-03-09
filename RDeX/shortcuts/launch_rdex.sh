#!/data/data/com.termux/files/usr/bin/bash

export DISPLAY=:0

# Clean runtime dir
mkdir -p "$TMPDIR/runtime"
chmod 700 "$TMPDIR/runtime"
export XDG_RUNTIME_DIR="$TMPDIR/runtime"

# Start X11 if not running
pgrep -f termux.x11 >/dev/null || termux-x11 :0 &

# Wait for X socket
while [ ! -S /data/data/com.termux/files/usr/tmp/.X11-unix/X0 ]; do
    sleep 0.2
done

# Audio (safe start)
pulseaudio --check 2>/dev/null || pulseaudio --start --exit-idle-time=-1

# Optional: ensure code-server is running
if command -v code-server >/dev/null 2>&1; then
    pgrep -x code-server >/dev/null || code-server >/dev/null 2>&1 &
fi

# Start XFCE
startxfce4 &

# Wait until XFCE session appears
while ! pgrep -x xfce4-session >/dev/null; do
    sleep 0.2
done

echo "[RDeX] XFCE session started"

# Monitor session
while pgrep -x xfce4-session >/dev/null; do
    sleep 1
done

echo "[RDeX] XFCE session ended"

# Cleanup remaining XFCE processes
pkill -f xfce4-panel 2>/dev/null
pkill -f xfconfd 2>/dev/null
pkill -f xfdesktop 2>/dev/null

# QoL additions
pkill -f termux.x11 2>/dev/null

echo "[RDeX] X11 stopped"

exit