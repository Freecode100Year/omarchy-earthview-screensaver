# Omarchy Earth View Screensaver

Replace Omarchy's idle ASCII screensaver with a full-screen Google Earth View photo. The image updates in the background every 30 minutes. Keyboard or mouse activity dismisses the photo, and Omarchy's existing lock timer continues to work.

## Features

- Shows the current Earth View image full-screen on each display using Omarchy's bundled Quickshell.
- Starts through Omarchy's normal idle screensaver command, including its on-demand screensaver menu.
- Closes on keyboard, mouse movement, click, or scroll, and is stopped before Omarchy locks the session.
- Downloads a new image every 30 minutes and keeps up to 20 cached images for offline use.
- Uses a user-level command override and does not replace Omarchy's system-managed screensaver files.

## Requirements

- Omarchy Linux with its bundled Quickshell and idle service
- Bash, `curl`, `tar`, `grep`, `shuf`, and systemd user services

## Install

Run this from your normal logged-in Omarchy user account, without `sudo` or a root shell:

```bash
curl -fsSL https://raw.githubusercontent.com/Freecode100Year/omarchy-earthview-screensaver/main/install.sh | bash
```

The installer downloads the project to a temporary directory, installs the image updater and Quickshell screensaver, enables the 30-minute user timer, and places the user command before Omarchy's system command in Bash login shells. It does not edit the system package files. Start a new terminal or session after installation if Omarchy's idle service does not pick up the command override immediately.

## Test

Check that the shell resolves the user override and the image cache exists:

```bash
command -v omarchy-launch-screensaver
test -s "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview/current.jpg" && echo "Earth View image is present"
systemctl --user is-active omarchy-earthview.timer
systemctl --user list-timers omarchy-earthview.timer
```

`command -v` should point to `~/.local/bin/omarchy-launch-screensaver`, the image check should print `Earth View image is present`, and the timer status should be `active`.

Launch the replacement manually:

```bash
omarchy-launch-screensaver force
```

Move the mouse or press a key to dismiss it. To check the idle flow, run `omarchy toggle screensaver` to disable the idle screen saver and run it again to re-enable it; Omarchy's configured lock timer is unchanged.

## Update interval

Edit `~/.config/systemd/user/omarchy-earthview.timer`, then reload and restart the timer:

```bash
systemctl --user daemon-reload
systemctl --user restart omarchy-earthview.timer
```

## Uninstall

From the project checkout, run:

```bash
./uninstall.sh
```

The uninstaller disables and removes the user timer and service, removes the command override and its Bash login PATH block, and asks whether to remove the cached Earth View images. Omarchy's original system screensaver remains installed.

## Troubleshooting

If Omarchy still starts its stock ASCII screensaver, confirm command resolution:

```bash
command -v omarchy-launch-screensaver
bash -lc 'command -v omarchy-launch-screensaver'
```

Both should resolve to `~/.local/bin/omarchy-launch-screensaver`. If the second command does not, start a new login session and check that the installer added its PATH block to `~/.bash_profile`, `~/.bash_login`, or `~/.profile`.

If the screen is black, check that the current image exists and that Quickshell can load the app:

```bash
test -s "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview/current.jpg"
quickshell --no-color -p "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-earthview/screensaver"
```

## Credits and license

Earth View image URLs are indexed by [limhenry/earthview](https://github.com/limhenry/earthview). This project is licensed under the MIT License; see [LICENSE](LICENSE).
