#!/data/data/com.termux/files/usr/bin/bash

# -------------------------------------------------
# Force Dark Mode for Zenity
# -------------------------------------------------
export GTK_THEME=KDE-Story
export GTK_APPLICATION_PREFER_DARK_THEME=1

APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
TMP_DIR="$HOME/.cache/rdex"

mkdir -p "$APP_DIR"
mkdir -p "$ICON_DIR"
mkdir -p "$TMP_DIR"

# -------------------------------------------------
# App Name
# -------------------------------------------------
NAME=$(zenity --entry \
    --title="RDeX - Create App" \
    --text="Enter Application Name:")

[ $? -ne 0 ] && exit 0
[ -z "$NAME" ] && exit 0

FILE_NAME=$(echo "$NAME" | tr ' ' '_' | tr -cd '[:alnum:]_' | sed 's/^$/app/')

ICON_PATH=""

# -------------------------------------------------
# Launch Type
# -------------------------------------------------
LAUNCH_TYPE=$(zenity --list \
    --title="Select Launch Type" \
    --column="Type" \
    "Web App (Chromium)" \
    "Android App" \
    "Custom Script")

[ $? -ne 0 ] && exit 0

# -------------------------------------------------
# Web App
# -------------------------------------------------
if [[ "$LAUNCH_TYPE" == "Web App (Chromium)" ]]; then

    URL=$(zenity --entry \
        --title="Enter URL" \
        --text="Enter URL:")

    [ $? -ne 0 ] && exit 0
    [ -z "$URL" ] && exit 0

    EXEC_CMD="chromium-browser --app=$URL"

    # Auto-fetch favicon
    DOMAIN=$(echo "$URL" | sed -E 's#https?://([^/]+).*#\1#')
    FAVICON_URL="https://$DOMAIN/favicon.ico"

    ICON_TMP="$TMP_DIR/${FILE_NAME}.png"

    curl -Ls "$FAVICON_URL" -o "$ICON_TMP" 2>/dev/null

    if [ -f "$ICON_TMP" ]; then
        ICON_PATH="$ICON_TMP"
    fi

# -------------------------------------------------
# Android App
# -------------------------------------------------
elif [[ "$LAUNCH_TYPE" == "Android App" ]]; then

    SEARCH=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')

    MATCHES=$(cmd package list packages \
        | sed 's/package://' \
        | grep -i "$SEARCH")

    COUNT=$(echo "$MATCHES" | sed '/^$/d' | wc -l)

    if [ "$COUNT" -eq 1 ]; then

        PACKAGE="$MATCHES"

    elif [ "$COUNT" -gt 1 ]; then

        PACKAGE=$(echo "$MATCHES" | sort | zenity --list \
            --title="Select Matching Android Package" \
            --column="Package" \
            --height=600 \
            --width=600)

    else

        PACKAGE=$(cmd package list packages \
            | sed 's/package://' \
            | sort \
            | zenity --list \
                --title="Select Android Package" \
                --column="Package" \
                --height=600 \
                --width=600)

    fi

    [ $? -ne 0 ] && exit 0
    [ -z "$PACKAGE" ] && exit 0

    EXEC_CMD="am start $PACKAGE"

# -------------------------------------------------
# Custom Script / Executable
# -------------------------------------------------
elif [[ "$LAUNCH_TYPE" == "Custom Script" ]]; then

    SCRIPT=$(zenity --file-selection \
        --title="Select Script or Executable")

    [ $? -ne 0 ] && exit 0
    [ -z "$SCRIPT" ] && exit 0

    chmod +x "$SCRIPT"

    EXEC_CMD="$SCRIPT"

fi

# -------------------------------------------------
# Category
# -------------------------------------------------
CATEGORY=$(zenity --list \
    --title="Select Category" \
    --column="Category" \
    "Accessories" \
    "Development" \
    "Graphics" \
    "Internet" \
    "Multimedia" \
    "Office" \
    "Settings" \
    "System")

[ $? -ne 0 ] && exit 0
[ -z "$CATEGORY" ] && exit 0

# -------------------------------------------------
# Optional Icon Override
# -------------------------------------------------
MANUAL_ICON=$(zenity --file-selection \
    --title="Select Icon (Optional)" \
    --file-filter="*.png")

if [ $? -eq 0 ] && [ -n "$MANUAL_ICON" ]; then
    ICON_PATH="$MANUAL_ICON"
fi

# -------------------------------------------------
# Desktop File Path
# -------------------------------------------------
DESKTOP_FILE="$APP_DIR/rdex-$FILE_NAME.desktop"

# -------------------------------------------------
# Icon Handling
# -------------------------------------------------
if [ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then

    ICON_DEST="$ICON_DIR/${FILE_NAME}.png"

    cp -f "$ICON_PATH" "$ICON_DEST"

    ICON_ENTRY="$ICON_DEST"

else

    ICON_ENTRY="applications-other"

fi

# -------------------------------------------------
# Create Desktop Entry
# -------------------------------------------------
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$NAME
Exec=$EXEC_CMD
Icon=$ICON_ENTRY
Terminal=false
Categories=$CATEGORY;
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"

# -------------------------------------------------
# Refresh XFCE Menu
# -------------------------------------------------
xfce4-panel -r 2>/dev/null || true
xfdesktop --reload 2>/dev/null || true

# -------------------------------------------------
# Success Message
# -------------------------------------------------
zenity --info \
    --title="RDeX" \
    --text="Application created successfully!"