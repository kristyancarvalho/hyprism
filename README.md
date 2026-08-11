# Hyprism

Hyprism is a reproducible Arch Linux Hyprland shell built around Quickshell. Its visual core is a top-centre, wallpaper-derived island: it stays compact at rest, expands on hover, and morphs into the launcher, wallpaper picker, clipboard history, control centre, Wi-Fi/Bluetooth views, Alt-Tab carousel, power menu, and emoji picker.

No Waybar, AGS, Eww, Rofi, Dunst, SwayNC, or Wlogout UI is used. Quickshell owns the visible desktop layer and its native notification server replaces a standalone notification daemon.

## Screenshots

Screenshots have not been captured in this VM yet. The included raster `wallpapers/` assets are original small palette-test wallpapers, not third-party artwork.

## Install

Clone this repository, inspect `packages/pacman.txt`, then run:

```bash
sudo ./install.sh --user "$USER"
```

The installer is Arch-only and fails early on other distributions. It installs only the package lists, backs up conflicting target paths under `~/.local/state/hyprism/backups/`, and links repository-managed configuration rather than copying it. It never removes existing personal wallpapers or screenshots.

For development after dependencies are present:

```bash
./install.sh --no-packages
```

The managed paths are `~/.config/hypr`, `~/.config/quickshell`, `~/.config/kitty/kitty.conf`, GTK/Qt settings, `~/.config/hyprism/user.json`, and `~/.local/share/hyprism`. Remove those symlinks (restoring the timestamped backup if wanted) to uninstall; user content under `~/Imagens` is deliberately retained.

## Architecture

```text
Hyprland bindings / IPC ─────┐
                              ├─ Quickshell ShellController ── morphological island
state-daemon + DBus CLIs ─────┤                              ├─ OSD + notifications
Matugen wallpaper pipeline ───┘                              └─ subtle desktop widgets
```

- `config/quickshell/` contains the state controller, independent services, panels, widgets, notification cards, and OSD. `ShellController` owns the single primary mode; transient OSDs do not close a panel.
- Hyprland’s native IPC drives workspaces and toplevels. The switcher commits on `Alt_L`/`Alt_R` release, not Super release.
- `scripts/system/state-daemon.py` provides one low-frequency state stream for audio, network, Bluetooth, battery, brightness, CPU/RAM/GPU availability, and MPRIS metadata. Optional hardware is represented as unavailable instead of failing the shell.
- The notification server is Quickshell’s `NotificationServer`, with tracked history, dismiss/clear actions, replacement handling delegated to the daemon protocol, popup actions, and a notification section in the control centre.

## Keybindings

`ALT` is the main modifier. Former `SUPER+ALT` semantics become `ALT+SUPER`; this avoids impossible `ALT+ALT` bindings in the VM.

| Key | Action |
| --- | --- |
| `Alt+Return`, `Alt+E`, `Alt+B` | Kitty, file manager, browser |
| `Alt+R` | Quickshell application launcher |
| `Alt+K`, `Alt+Super+K` | Wallpaper picker, random local wallpaper |
| `Alt+Shift+V` | Clipboard history |
| `Alt+Tab`, `Alt+Shift+Tab`, release Alt | Window switcher forward/back/commit |
| `Alt+M` or `Alt+Shift+L` | Confirmed Quickshell power menu |
| `Alt+L` | Hyprlock |
| `Alt+Shift+N`, `Alt+Shift+I` | Network panel, power saver |
| `Alt+Shift+Up/Down/M`, `Alt+Super+M` | Volume, output mute, microphone mute with OSD |
| `Alt+Shift+S`, `Alt+Shift+F` | Area and focused-monitor screenshot (also copied) |
| `Alt+Ctrl+P` | Hyprpicker, copy, colour OSD |
| `Alt+1…0`, `Alt+Shift+1…0` | Workspaces 1–10, move window |
| `Alt+S`, `Alt+Shift+U` | Toggle/move to `special:magic` |
| `Alt+Arrow`, `Alt+Ctrl+Arrow` | Focus and move/swap; left/right use scrolling-layout column swap when that layout is active |
| `Alt+Super+Arrow` | Resize active window in 30px steps |
| `Alt+=`, `Alt+-` | Scrolling-layout column size |
| `Alt+Shift+E` | Reload Quickshell without exiting Hyprland |
| `Ctrl+.` | Quickshell emoji picker |

`Alt+Shift+A` and `Alt+Shift+G` are intentionally not bound: no local AGS LLM/GitHub implementation was found to port, and Hyprism does not fabricate panels with no backend.

## Wallpaper and colour pipeline

`~/Imagens/Wallpapers` is the source of truth. Select a thumbnail or run `hyprism-wallpaper random`; the helper avoids the active image when alternatives exist.

```text
wallpaper → awww transition → Matugen → contrast-correct semantic tokens
          → Quickshell FileView live update
          → ~/.cache/hyprism/theme/kitty.conf → kitten @ set-colors
          → generated Hyprland border colours + persisted kitty theme
```

`scripts/theme/generate-theme.py` is the sole palette generator. It uses Matugen’s dark content scheme and contrast-corrects semantic tokens, with a safe fallback palette if Matugen or an image fails. GTK stays `Adwaita-dark`; Qt uses `qt6ct`/Fusion. Set weather coordinates and all user-facing program/path/island/widget settings in `config/user.json` (installed as `~/.config/hyprism/user.json`). Leave weather coordinates unset to disable requests safely.

## Quickshell IPC

```bash
qs ipc call shell toggleControlCenter
qs ipc call app-launcher toggle
qs ipc call wallpaper-picker toggle
qs ipc call wallpaper random
qs ipc call clipboard toggle
qs ipc call window-switcher forward
qs ipc call window-switcher commit
qs ipc call power-menu toggle
qs ipc call osd volume 78
```

## Dependencies and reproduction

Official packages are one-per-line in [packages/pacman.txt](packages/pacman.txt); optional AUR packages belong in [packages/aur.txt](packages/aur.txt). The installer only invokes `paru`/`yay` if the AUR list has entries. Core backends are NetworkManager, BlueZ, PipeWire/WirePlumber, UPower, ClipHist, Awww, Matugen, and the small command-line tools documented in the package list.

## VirtualBox and troubleshooting

VirtualBox commonly exposes Ethernet with no battery, Bluetooth, Wi-Fi, GPU metric, or brightness device. Hyprism displays Ethernet and hides or disables unsupported controls; these cases are normal. On physical hardware, install/enable `NetworkManager` and `bluetooth`, then reload the shell.

Run `quickshell -p ~/.config/quickshell` from a terminal to inspect shell errors. Quickshell logs are in its runtime directory. If no wallpaper appears, verify `awww-daemon` and run `hyprism-wallpaper set /path/to/image`. If the palette is stale, check `~/.cache/hyprism/theme/theme.json` and `matugen image … --dry-run --json hex`.

## Repository layout

```text
config/       Hyprland, Quickshell, Kitty, GTK, Qt, and user defaults
scripts/      wallpaper/theme, state, network, Bluetooth, screenshot, OSD helpers
packages/     editable official and AUR package lists
wallpapers/   small original palette-test wallpapers
install.sh    safe Arch deployment
```
