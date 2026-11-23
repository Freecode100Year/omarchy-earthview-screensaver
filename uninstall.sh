#!/usr/bin/env bash
# Uninstaller for omarchy-earthview-screensaver

set -euo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 && -z ${EARTHVIEW_ALLOW_ROOT:-} ]]; then
    echo "Error: run this uninstaller as the Omarchy user who installed the screensaver, without sudo." >&2
    exit 1
fi

BIN_FILE="$HOME/.local/bin/omarchy-earthview-update"
SCREENSAVER_FILE="$HOME/.local/bin/omarchy-launch-screensaver"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview"
APP_DIR="$CACHE_DIR/screensaver"

echo "==> Uninstalling omarchy-earthview-screensaver..."

systemctl --user disable --now omarchy-earthview.timer 2>/dev/null || true
rm -f "$SYSTEMD_DIR/omarchy-earthview.timer" "$SYSTEMD_DIR/omarchy-earthview.service"
systemctl --user daemon-reload

rm -f "$BIN_FILE" "$SCREENSAVER_FILE"
rm -rf "$APP_DIR"

for PROFILE in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    [[ -f "$PROFILE" ]] || continue
    PROFILE_TARGET="$PROFILE"
    [[ -L "$PROFILE_TARGET" ]] && PROFILE_TARGET="$(readlink -f "$PROFILE_TARGET")"
    if grep -qF '# >>> omarchy-earthview-screensaver PATH >>>' "$PROFILE_TARGET"; then
        TMP_PROFILE="$(mktemp "${PROFILE_TARGET}.XXXXXX")"
        awk '
            /# >>> omarchy-earthview-screensaver PATH >>>/ { skip = 1; next }
            /# <<< omarchy-earthview-screensaver PATH <<</ { skip = 0; next }
            !skip { print }
        ' "$PROFILE_TARGET" > "$TMP_PROFILE"
        cat "$TMP_PROFILE" > "$PROFILE_TARGET"
        rm -f "$TMP_PROFILE"
    fi
done

# No terminal to ask (e.g. piped from curl): keep the images.
ans=""
read -rp "Remove cached Earth View images at $CACHE_DIR? [y/N]: " ans </dev/tty 2>/dev/null || true
if [[ "${ans,,}" == "y" ]]; then
    rm -rf "$CACHE_DIR"
    echo "==> Removed image cache."
fi

echo "==> Uninstalled. Omarchy's own screensaver is back (start a new session if it is not picked up at once)."
