#!/usr/bin/env bash
# Offline tests: a throwaway HOME, stub curl/systemctl/quickshell on PATH.
#   bash tests/test.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home" XDG_DATA_HOME="$T/home/.local/share"
mkdir -p "$HOME" "$T/bin" "$T/net"
export PATH="$T/bin:$PATH" EARTHVIEW_ALLOW_ROOT=1  # tests may run as root in CI
C="$XDG_DATA_HOME/omarchy-earthview"
fails=0
check() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }
stub() { printf '#!/usr/bin/env bash\n%s\n' "$2" >"$T/bin/$1"; chmod +x "$T/bin/$1"; }

# Fake network: $T/net/mode = ok | html | down. The index lists 3 images.
printf '\xff\xd8\xff\xe0fake-jpeg' >"$T/net/img.jpg"
printf '[{"image":"https://www.gstatic.com/prettyearth/assets/full/1003.jpg"},{"image":"https://www.gstatic.com/prettyearth/assets/full/1004.jpg"},{"image":"https://www.gstatic.com/prettyearth/assets/full/1005.jpg"}]' >"$T/net/index.json"
echo ok >"$T/net/mode"
stub curl "mode=\$(cat $T/net/mode); out=''; url=''
while [[ \$# -gt 0 ]]; do case \$1 in -o) out=\$2; shift ;; http*) url=\$1 ;; esac; shift; done
[[ \$mode == down ]] && exit 6
if [[ \$url == *earthview.json ]]; then body=$T/net/index.json
elif [[ \$mode == html ]]; then body=$T/net/portal.html; echo '<html>login</html>' >\$body
else body=$T/net/img.jpg; fi
if [[ -n \$out ]]; then cp \$body \$out; else cat \$body; fi"
stub systemctl "echo \"\$*\" >>$T/systemctl.log"
stub quickshell "echo \"quickshell \$*\" >$T/launched"

U="$ROOT/bin/omarchy-earthview-update"
echo "updater"
bash "$U"
check "downloads an image and makes it current" "[[ -s $C/current.jpg ]] && ls $C/100[345].jpg >/dev/null 2>&1"
check "no temp files left" "! ls $C/*.tmp >/dev/null 2>&1"
rm -f "$C"/*.jpg; echo html >"$T/net/mode"
bash "$U"
check "a non-JPEG answer (captive portal) is not used" "[[ ! -e $C/current.jpg ]] && ! ls $C/[0-9]*.jpg >/dev/null 2>&1"
echo ok >"$T/net/mode"
for i in $(seq 1 25); do printf '\xff\xd8\xff' >"$C/$((2000 + i)).jpg"; touch -d "-$((100 - i)) min" "$C/$((2000 + i)).jpg"; done
bash "$U"
check "cache pruned to the newest 20" "[[ \$(ls $C/[0-9]*.jpg | wc -l) -eq 20 ]] && [[ ! -e $C/2001.jpg ]] && [[ -e $C/2025.jpg ]]"
rm -f "$C/current.jpg"; echo down >"$T/net/mode"
bash "$U"; rc=$?
check "offline: exits 0 and shows a cached image" "[[ $rc -eq 0 && -s $C/current.jpg ]]"

echo "installer"
echo ok >"$T/net/mode"; rm -rf "$C"
printf '# my profile\n' >"$HOME/.bash_profile"
bash "$ROOT/install.sh" >"$T/install.log" 2>&1
check "installs commands, screensaver and timer" "[[ -x $HOME/.local/bin/omarchy-launch-screensaver && -x $HOME/.local/bin/omarchy-earthview-update && -f $C/screensaver/shell.qml && -f $HOME/.config/systemd/user/omarchy-earthview.timer ]] && grep -q 'enable --now omarchy-earthview.timer' $T/systemctl.log"
check "PATH block added to the login profile once" "bash $ROOT/install.sh >/dev/null 2>&1; [[ \$(grep -c '>>> omarchy-earthview-screensaver PATH' $HOME/.bash_profile) -eq 1 ]] && grep -q '# my profile' $HOME/.bash_profile"
check "login shell finds the override first" "[[ \$(env -i HOME=$HOME PATH=/usr/bin:/bin bash -lc 'command -v omarchy-launch-screensaver') == $HOME/.local/bin/omarchy-launch-screensaver ]]"

echo "launcher"
L="$HOME/.local/bin/omarchy-launch-screensaver"
bash "$L" force
check "starts the Quickshell screensaver" "grep -q -- '-p $C/screensaver' $T/launched"
check "process name matches what Omarchy stops before locking" "grep -q 'exec -a \"\$STOCK\" quickshell' $L && grep -q '^STOCK=/usr/lib/omarchy-screensaver/omarchy-screensaver' $L"
rm -f "$T/launched" "$C"/*.jpg; echo down >"$T/net/mode"
bash "$L" force >"$T/l.log" 2>&1
check "no image and offline: no black screen (falls back, never runs Quickshell)" "[[ ! -e $T/launched ]]"

echo "uninstaller"
bash "$ROOT/uninstall.sh" </dev/null >"$T/un.log" 2>&1; rc=$?
check "removes commands and units, keeps the profile, works without a terminal" "[[ $rc -eq 0 && ! -e $L && ! -e $HOME/.config/systemd/user/omarchy-earthview.timer ]] && ! grep -q omarchy-earthview $HOME/.bash_profile && grep -q '# my profile' $HOME/.bash_profile"

echo "shellcheck"
if command -v shellcheck >/dev/null; then
    check "scripts are shellcheck-clean" "shellcheck -x $ROOT/bin/* $ROOT/install.sh $ROOT/uninstall.sh $ROOT/tests/test.sh"
fi

if ((fails == 0)); then echo "all passed"; else echo "$fails failed"; exit 1; fi
