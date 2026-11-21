# Omarchy Earth View Screensaver

Refresh your Hyprlock background with satellite imagery from Google Earth View. This small Bash utility runs on Omarchy (Arch Linux with Hyprland and Hyprlock), keeps a local image cache, and updates it in the background with a systemd user timer.

## Features

- Downloads a randomly selected image indexed by [limhenry/earthview](https://github.com/limhenry/earthview).
- Updates the background at boot and every 30 minutes through a systemd user timer.
- Keeps up to 20 downloaded images and uses a cached image when a refresh cannot download a new one.
- Installs a Hyprlock background path and creates a timestamped backup of the existing configuration before editing it.

## Requirements

- Omarchy or a compatible Arch Linux setup
- Bash, `curl`, `tar`, `grep`, `shuf`, `systemd` user services, and Hyprlock
- A Hyprlock configuration at `~/.config/hypr/hyprlock.conf` for automatic configuration

Run installation and removal from your normal logged-in Omarchy user account, without `sudo` or a root shell. The timer is a user service and requires that user's session bus.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Freecode100Year/omarchy-earthview-screensaver/main/install.sh | bash
```

The one-line command downloads the current `main` branch archive and runs the full installer from a temporary directory. To keep a local checkout instead, clone the repository and run `./install.sh` from it.

The installer places the updater in `~/.local/bin`, installs and enables the user timer, attempts an initial image download, and configures the Hyprlock background. If the config has no existing `path =` setting, add the snippet in [`config/hyprlock.snippet.conf`](config/hyprlock.snippet.conf) manually. The image is stored at `~/.local/share/omarchy-earthview/current.jpg` (or under `$XDG_DATA_HOME` when set). This separate directory avoids Omarchy's `~/.local/share/omarchy` symlink to the system-owned `/usr/share/omarchy` directory.

If `~/.config/hypr/hyprlock.conf` does not exist, the installer leaves Hyprlock configuration to you. When the file is a symlink, installation replaces the symlink with a standalone copy before making changes. Review the timestamped `.bak.*` file if you need to restore the previous configuration.

## Use

Refresh the image immediately:

```bash
omarchy-earthview-update
```

Check or run the timer:

```bash
systemctl --user status omarchy-earthview.timer
systemctl --user start omarchy-earthview.service
```

Lock the screen to see the background:

```bash
hyprlock
```

If `~/.config/hypr/hyprlock.conf` does not exist, create a minimal config for this background and test it with:

```bash
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprlock.conf <<EOF
background {
    monitor =
    path = $HOME/.local/share/omarchy-earthview/current.jpg
    blur_passes = 0
}
EOF
hyprlock
```

To change the refresh interval, edit `~/.config/systemd/user/omarchy-earthview.timer`, then reload the user units and restart the timer:

```bash
systemctl --user daemon-reload
systemctl --user restart omarchy-earthview.timer
```

## Uninstall

Run the uninstaller from the project directory:

```bash
./uninstall.sh
```

It disables and removes the timer and service, removes the updater, and asks whether to delete the cached images. Restore your Hyprlock configuration from the backup manually if desired.

## Troubleshooting

If installation reports `Permission denied` while creating the Earth View cache, inspect the current user and each directory in the cache path:

```bash
id
printf 'HOME=%s\n' "$HOME"
namei -l "$HOME/.local/share/omarchy-earthview"
```

If cloning reports that `omarchy-earthview-screensaver` already exists, the clone did not run. Check the existing checkout and its version before installing:

```bash
git -C "$HOME/omarchy-earthview-screensaver" status --short --branch
git -C "$HOME/omarchy-earthview-screensaver" log -1 --oneline
```

Run these commands and the installer as your normal logged-in Omarchy user, without `sudo`. Use `&&` between setup commands so later steps stop if cloning or changing directories fails:

```bash
git clone https://github.com/Freecode100Year/omarchy-earthview-screensaver.git && \
cd omarchy-earthview-screensaver && \
./install.sh
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
