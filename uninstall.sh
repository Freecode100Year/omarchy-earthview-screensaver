#!/usr/bin/env bash
# Uninstaller for omarchy-earthview-screensaver

set -euo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "Error: run this uninstaller as the Omarchy user who installed the screensaver, without sudo." >&2
    exit 1
fi

BIN_FILE="$HOME/.local/bin/omarchy-earthview-update"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview"

echo "==> Uninstalling omarchy-earthview-screensaver..."

systemctl --user disable --now omarchy-earthview.timer 2>/dev/null || true
rm -f "$SYSTEMD_DIR/omarchy-earthview.timer" "$SYSTEMD_DIR/omarchy-earthview.service"
systemctl --user daemon-reload

rm -f "$BIN_FILE"

read -rp "Remove cached Earth View images at $CACHE_DIR? [y/N]: " ans
if [[ "${ans,,}" == "y" ]]; then
    rm -rf "$CACHE_DIR"
    echo "==> Removed image cache."
fi

echo "==> Uninstalled. Remember to restore your ~/.config/hypr/hyprlock.conf backup if needed."
