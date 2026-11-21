# Omarchy Earth View Screensaver

Refresh your Hyprlock background with satellite imagery from Google Earth View. This small Bash utility runs on Omarchy (Arch Linux with Hyprland and Hyprlock), keeps a local image cache, and updates it in the background with a systemd user timer.

## Features

- Downloads a randomly selected image indexed by [limhenry/earthview](https://github.com/limhenry/earthview).
- Updates the background at boot and every 30 minutes through a systemd user timer.
- Keeps up to 20 downloaded images and uses a cached image when a refresh cannot download a new one.
- Installs a Hyprlock background path and creates a timestamped backup of the existing configuration before editing it.

## Requirements

- Omarchy or a compatible Arch Linux setup
- Bash, `curl`, `grep`, `shuf`, `systemd` user services, and Hyprlock
- A Hyprlock configuration at `~/.config/hypr/hyprlock.conf` for automatic configuration

## Install

```bash
git clone https://github.com/Freecode100Year/omarchy-earthview-screensaver.git
cd omarchy-earthview-screensaver
./install.sh
```

The installer places the updater in `~/.local/bin`, installs and enables the user timer, attempts an initial image download, and configures the Hyprlock background. If the config has no existing `path =` setting, add the snippet in [`config/hyprlock.snippet.conf`](config/hyprlock.snippet.conf) manually. The image is stored at `~/.local/share/omarchy/earthview/current.jpg` (or under `$XDG_DATA_HOME` when set).

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

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
