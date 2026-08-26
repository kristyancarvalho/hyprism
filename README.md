<div align="center">

# Hyprism

**Automated dotfiles for a cohesive, dynamic Hyprland desktop.**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58E1FF?style=flat-square)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-41CD52?style=flat-square&logo=qt&logoColor=white)](https://quickshell.org/)
[![Matugen](https://img.shields.io/badge/Matugen-dynamic_color-8B5CF6?style=flat-square)](https://github.com/InioX/matugen)

</div>

> Hyprism is an automated dotfiles setup for a personalized Hyprland experience. Quickshell provides the island, panels, and widgets, while Matugen propagates wallpaper colors throughout the session.

## Demo

[![Automated Hyprism tour](assets/demo/hyprism-tour.webp)](assets/demo/hyprism-tour.mp4)

| Desktop and compact island | Expanded island |
| --- | --- |
| ![Dark and light desktop with compact island](assets/screenshots/desktop.webp) | ![Dark and light expanded island](assets/screenshots/island-expanded.webp) |
| **Desktop widgets** | **Launcher** |
| ![Dark and light desktop widgets](assets/screenshots/desktop-widgets.webp) | ![Dark and light launcher](assets/screenshots/launcher.webp) |
| **Control center** | **Notification history** |
| ![Dark and light control center](assets/screenshots/control-center.webp) | ![Dark and light notification history](assets/screenshots/notifications.webp) |
| **Network** | **Bluetooth** |
| ![Dark and light network panel](assets/screenshots/network.webp) | ![Dark and light Bluetooth panel](assets/screenshots/bluetooth.webp) |
| **Clipboard** | **Emoji picker** |
| ![Dark and light clipboard](assets/screenshots/clipboard.webp) | ![Dark and light emoji picker](assets/screenshots/emoji-picker.webp) |
| **Power** | **Recording** |
| ![Dark and light power menu](assets/screenshots/power-menu.webp) | ![Dark and light recording selector](assets/screenshots/recording.webp) |
| **Wallpapers** | **Light theme options** |
| ![Dark and light wallpaper picker](assets/screenshots/wallpaper-picker.webp) | ![Dark and light theme options](assets/screenshots/theme-options.webp) |

## What it configures

- Hyprland in Lua: monitors, workspaces, gestures, rules, environment, keybindings, and autostart.
- Quickshell: morphing island, launcher, window switcher, controls, notifications, OSD, and monitoring widgets.
- Matugen themes for Hyprland, Hyprlock, SDDM, GTK, Kvantum, Kitty, Foot, Starship, tmux, Neovim, Fastfetch, Zathura, and hyprtoolkit.
- Live native and Flatpak application indexing with integrated Wayland portals.
- Screenshots, region or monitor recording, clipboard history, night mode, and audio, brightness, network, and Bluetooth controls.
- English and Brazilian Portuguese interfaces with live language switching.

## Requirements

- Arch Linux with internet access during provisioning.
- A regular user with `sudo`; installation needs root access for packages, fonts, and SDDM.
- Hardware and drivers compatible with a current Hyprland/Wayland session.

## Installation

English is the default for new installations:

```bash
git clone https://github.com/kristyancarvalho/hyprism.git
cd hyprism
make install
```

Install in Brazilian Portuguese explicitly:

```bash
make install-ptbr
```

The equivalent variable form is `make install LANG=pt-BR`. Updates preserve an existing language and user configuration:

```bash
make update
```

> [!WARNING]
> Installation updates packages and replaces user paths managed by Hyprism. Conflicts are moved to `~/.local/state/hyprism/backups/` before links are created.

Use `make help` to list maintenance targets. Use `make uninstall` to remove Hyprism-managed paths; the uninstaller archives the runtime and `user.json` under `~/.local/state/hyprism/uninstalled/`.

## Command line

`hyprism-shell` is installed in `~/.local/bin` and provides the stable interface for common actions:

```bash
hyprism-shell --help
hyprism-shell widgets list
hyprism-shell widgets toggle weather
hyprism-shell widgets disable --all
hyprism-shell weather location "São Paulo"
hyprism-shell language set pt-BR
hyprism-shell wallpaper random
hyprism-shell screenshot region
```

See [the CLI guide](docs/cli.md) for the complete command inventory.

## Essential keybindings

| Keybinding | Action |
| --- | --- |
| `Super+Return` | Open Kitty |
| `Super+R` | Open the launcher |
| `Super+Tab` / `Super+Shift+Tab` | Navigate windows; releasing `Super` confirms |
| `Super+K` / `Super+Alt+K` | Choose / randomize wallpaper |
| `Super+Shift+V` | Open the clipboard |
| `Super+Shift+N` | Open the network panel |
| `Ctrl+.` | Open the emoji picker |
| `Super+Shift+R` | Select or stop a recording |
| `Super+Shift+S` / `Super+Shift+F` | Capture a region / focused monitor |
| `Super+L` | Lock with Hyprlock |
| `Super+Ctrl+S` | Toggle night mode |
| `Super+B` | Open Zen Browser |
| `Super+1…0` | Go to workspaces 1–10 |

## Credits and licenses

Hyprism integrates projects including [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.org/), [Matugen](https://github.com/InioX/matugen), [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme), and [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme). Vendored components retain their attribution and licenses in their respective directories, including [KSDDM](themes/ksddm-hyprism/LICENSE) and [NvChad](config/nvim/LICENSE).
