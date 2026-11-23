#!/usr/bin/env bash
# Installer for omarchy-earthview-screensaver

set -euo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 && -z ${EARTHVIEW_ALLOW_ROOT:-} ]]; then
    echo "Error: run this installer as your logged-in Omarchy user, without sudo. It installs a systemd user timer and needs that user's session bus." >&2
    exit 1
fi

if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "bash" || "${BASH_SOURCE[0]}" == "/dev/stdin" ]]; then
    BOOTSTRAP_DIR="$(mktemp -d)"
    trap 'rm -rf "$BOOTSTRAP_DIR"' EXIT
    # GitHub first, GitLab mirror if GitHub cannot be reached.
    ARCHIVE_URLS=(
        "https://codeload.github.com/Freecode100Year/omarchy-earthview-screensaver/tar.gz/refs/heads/main"
        "https://gitlab.com/sj9292008133/omarchy-earthview-screensaver/-/archive/main/omarchy-earthview-screensaver-main.tar.gz"
    )

    echo "==> Downloading omarchy-earthview-screensaver..."
    ok=0
    for url in "${ARCHIVE_URLS[@]}"; do
        if curl -fsSL --connect-timeout 15 "$url" -o "$BOOTSTRAP_DIR/src.tar.gz" &&
            tar -xzf "$BOOTSTRAP_DIR/src.tar.gz" --strip-components=1 -C "$BOOTSTRAP_DIR"; then
            ok=1
            break
        fi
    done
    [[ $ok == 1 ]] || { echo "Error: could not download the project from GitHub or GitLab." >&2; exit 1; }
    bash "$BOOTSTRAP_DIR/install.sh" "$@"
    exit $?
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview/screensaver"

if ! command -v quickshell >/dev/null 2>&1; then
    echo "Error: this Omarchy screensaver replacement requires quickshell." >&2
    exit 1
fi

echo "==> Installing omarchy-earthview-screensaver..."

mkdir -p "$BIN_DIR" "$SYSTEMD_DIR" "$CACHE_DIR" "$APP_DIR"

# Install updater, Omarchy screensaver override, and its Quickshell UI.
install -m 755 "$REPO_DIR/bin/omarchy-earthview-update" "$BIN_DIR/omarchy-earthview-update"
install -m 755 "$REPO_DIR/bin/omarchy-launch-screensaver" "$BIN_DIR/omarchy-launch-screensaver"
install -m 644 "$REPO_DIR/screensaver/shell.qml" "$APP_DIR/shell.qml"

# Install systemd user units
install -m 644 "$REPO_DIR/systemd/omarchy-earthview.service" "$SYSTEMD_DIR/omarchy-earthview.service"
install -m 644 "$REPO_DIR/systemd/omarchy-earthview.timer" "$SYSTEMD_DIR/omarchy-earthview.timer"

# Fetch initial image
echo "==> Fetching initial Google Earth View image..."
"$BIN_DIR/omarchy-earthview-update" || echo "Warning: Initial download failed. Will retry automatically via timer."

# Enable systemd timer
systemctl --user daemon-reload
systemctl --user enable --now omarchy-earthview.timer

# Omarchy starts this command from a login Bash shell on idle. Put the
# per-user override ahead of /usr/share/omarchy/bin without editing system files.
PROFILE="$HOME/.bash_profile"
if [[ ! -e "$PROFILE" && ! -L "$PROFILE" ]]; then
    if [[ -e "$HOME/.bash_login" || -L "$HOME/.bash_login" ]]; then
        PROFILE="$HOME/.bash_login"
    elif [[ -e "$HOME/.profile" || -L "$HOME/.profile" ]]; then
        PROFILE="$HOME/.profile"
    fi
fi
if [[ -L "$PROFILE" ]]; then
    PROFILE="$(readlink -f "$PROFILE")"
fi
touch "$PROFILE"
if ! grep -qF '# >>> omarchy-earthview-screensaver PATH >>>' "$PROFILE"; then
    cat >>"$PROFILE" <<'EOF'

# >>> omarchy-earthview-screensaver PATH >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< omarchy-earthview-screensaver PATH <<<
EOF
fi

echo "==> Omarchy idle screensaver now uses Earth View images."
echo "==> Test it with: omarchy-launch-screensaver force"
echo "==> Installation complete."
