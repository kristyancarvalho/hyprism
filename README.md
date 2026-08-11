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

The managed paths are `~/.config/hypr`, `~/.config/quickshell`, `~/.config/kitty/kitty.conf`, GTK/Qt settings, `~/.config/hyprism/user.json`, and `~/.local/share/hyprism`. The installer verifies the Hyprland and Quickshell links, requires `hyprland.lua` and `shell.qml`, rejects an installed `hyprland.conf`, and archives the obsolete generated theme fragment if an older release left one behind. Remove the managed symlinks (restoring the timestamped backup if wanted) to uninstall; user content under `~/Imagens` is deliberately retained.

## Architecture

```text
Hyprland bindings / IPC ─────┐
                              ├─ Quickshell ShellController ── morphological island
state-daemon + DBus CLIs ─────┤                              ├─ OSD + notifications
Matugen wallpaper pipeline ───┘                              └─ subtle desktop widgets
```

- `config/quickshell/` contains the state controller, independent services, panels, widgets, notification cards, and OSD. `ShellController` owns the single primary mode; transient OSDs do not close a panel.
- `config/hypr/hyprland.lua` is the small Hyprland 0.55+ entrypoint. It loads focused Lua modules for environment, programs, monitors, general behavior, input, appearance, animations, layouts, rules, workspaces, bindings, and autostart. There are no repository-managed Hyprland `.conf` fragments.
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
qs -p ~/.config/quickshell ipc call shell toggleControlCenter
qs -p ~/.config/quickshell ipc call app-launcher toggle
qs -p ~/.config/quickshell ipc call wallpaper-picker toggle
qs -p ~/.config/quickshell ipc call wallpaper random
qs -p ~/.config/quickshell ipc call clipboard toggle
qs -p ~/.config/quickshell ipc call window-switcher forward
qs -p ~/.config/quickshell ipc call window-switcher commit
qs -p ~/.config/quickshell ipc call power-menu toggle
qs -p ~/.config/quickshell ipc call osd volume 78
qs -p ~/.config/quickshell ipc call shell status
qs -p ~/.config/quickshell ipc call shell reload
```

When more than one Quickshell configuration is running, target Hyprism explicitly with `qs -p ~/.config/quickshell ipc call shell status`. The status response reports the PID, selected screen, theme source, island/widgets state, notification server, service stream, and active shell mode.

## Dependencies and reproduction

Official packages are one-per-line in [packages/pacman.txt](packages/pacman.txt); optional AUR packages belong in [packages/aur.txt](packages/aur.txt). The installer only invokes `paru`/`yay` if the AUR list has entries. Core backends are NetworkManager, BlueZ, PipeWire/WirePlumber, UPower, ClipHist, Awww, Matugen, and the small command-line tools documented in the package list.

## VirtualBox and troubleshooting

VirtualBox commonly exposes Ethernet with no battery, Bluetooth, Wi-Fi, GPU metric, or brightness device. Hyprism displays Ethernet and hides or disables unsupported controls; these cases are normal. On physical hardware, install/enable `NetworkManager` and `bluetooth`, then reload the shell.

Run `quickshell -p ~/.config/quickshell --no-duplicate` from a terminal to inspect shell errors. Use `qs -p ~/.config/quickshell log` for the selected instance and `qs -p ~/.config/quickshell ipc call shell status` for a compact health check. If no wallpaper appears, verify `awww-daemon` and run `hyprism-wallpaper set /path/to/image`. If the palette is stale, check `~/.cache/hyprism/theme/theme.json` and `matugen image … --dry-run --json hex`.

Hyprism does not hard-code output names. The shell follows Hyprland's focused monitor, then the optional `shell.primaryMonitor` name in `config/user.json`, then the first Quickshell screen. A missing generated palette leaves the built-in dark theme active. Missing battery, Bluetooth, Wi-Fi, brightness, GPU, MPRIS, weather, or clipboard data is represented as unavailable and cannot abort the QML tree.

For compositor diagnostics, run `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`, then inspect `hyprctl configerrors` and the current Hyprland log from inside the session. `Alt+P` uses the current Lua dispatcher `hl.dsp.window.pseudo({ action = "toggle" })`; the removed legacy `togglepseudo` dispatcher is not valid in the Lua configuration API.

### Blocking regression notes

The deprecated-format warning came from the installer linking a directory whose active entrypoint was `hyprland.conf`; that file also sourced a generated `~/.cache/hyprism/theme/hyprland.conf`. Both paths are now Lua, and the installer archives the obsolete generated fragment. The pseudotile error came from carrying the legacy `togglepseudo` dispatcher into a release whose Lua API exposes the typed `window.pseudo` action.

The missing widgets were first and foremost a startup/instance-selection failure: no process was running the repository's Quickshell configuration, while another unrelated Quickshell configuration was alive. The old shell also relied on implicit screen selection and a full-width panel to center the island. Autostart, bindings, OSD/theme helpers, reload, and health commands now all select `~/.config/quickshell` explicitly; surfaces receive a dynamically selected screen and concrete non-zero geometry. This distinction matters when diagnosing a future regression: a running `quickshell` process is not proof that the intended `shell.qml` is running.

## Repository layout

```text
config/hypr/  modular Hyprland Lua entrypoint and modules
config/quickshell/  shell root, services, panels, widgets, notifications, and OSD
config/       Kitty, GTK, Qt, and user defaults
scripts/      wallpaper/theme, state, network, Bluetooth, screenshot, OSD helpers
packages/     editable official and AUR package lists
wallpapers/   small original palette-test wallpapers
install.sh    safe Arch deployment
```
