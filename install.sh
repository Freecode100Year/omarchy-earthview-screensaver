#!/usr/bin/env bash
# Installer for omarchy-earthview-screensaver

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy/earthview"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

echo "==> Installing omarchy-earthview-screensaver..."

mkdir -p "$BIN_DIR" "$SYSTEMD_DIR" "$CACHE_DIR"

# Install binary
install -m 755 "$REPO_DIR/bin/omarchy-earthview-update" "$BIN_DIR/omarchy-earthview-update"

# Install systemd user units
install -m 644 "$REPO_DIR/systemd/omarchy-earthview.service" "$SYSTEMD_DIR/omarchy-earthview.service"
install -m 644 "$REPO_DIR/systemd/omarchy-earthview.timer" "$SYSTEMD_DIR/omarchy-earthview.timer"

# Fetch initial image
echo "==> Fetching initial Google Earth View image..."
"$BIN_DIR/omarchy-earthview-update" || echo "Warning: Initial download failed. Will retry automatically via timer."

# Enable systemd timer
systemctl --user daemon-reload
systemctl --user enable --now omarchy-earthview.timer

# Configure Hyprlock
if [[ -f "$HYPRLOCK_CONF" ]]; then
    if [[ -L "$HYPRLOCK_CONF" ]]; then
        cp --remove-destination "$(readlink -f "$HYPRLOCK_CONF")" "$HYPRLOCK_CONF"
        echo "==> Converted symlinked hyprlock.conf to a standalone user config."
    fi

    BACKUP_FILE="${HYPRLOCK_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$HYPRLOCK_CONF" "$BACKUP_FILE"
    echo "==> Backed up existing hyprlock.conf to $BACKUP_FILE"

    if grep -qE '^[[:space:]]*path[[:space:]]*=' "$HYPRLOCK_CONF"; then
        sed -i "s|^[[:space:]]*path[[:space:]]*=.*|    path = $CACHE_DIR/current.jpg|g" "$HYPRLOCK_CONF"
        sed -i "s|^[[:space:]]*blur_passes[[:space:]]*=.*|    blur_passes = 0|g" "$HYPRLOCK_CONF"
        echo "==> Updated $HYPRLOCK_CONF with Earth View background."
    else
        echo "==> Note: Could not find 'path =' in $HYPRLOCK_CONF. Please merge config/hyprlock.snippet.conf manually."
    fi
else
    echo "==> Note: $HYPRLOCK_CONF not found. Please configure your lockscreen to use $CACHE_DIR/current.jpg."
fi

echo "==> Installation complete! Run 'hyprlock' to test your new screensaver."
