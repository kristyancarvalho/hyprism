---
title: Command line
description: "Use hyprism-shell to manage widgets, themes, keyboard preferences, and desktop actions."
category: Guides
order: 6
icon: terminal
---

# hyprism-shell

`hyprism-shell` is Hyprism's stable user-facing command interface. Query commands print plain values, mutations return a non-zero status for invalid input, and configuration changes are written atomically to `~/.config/hyprism/user.json`.

## Command index

| Command | Purpose |
| --- | --- |
| `init [--lang en\|pt-BR]` | Create or merge `user.json`, link configuration, and copy bundled wallpapers |
| `language [set en\|pt-BR]` | Show or change the interface language |
| `widgets list\|enable\|disable\|toggle NAME\|--all` | Desktop widget visibility |
| `lockscreen lock\|status` | Lock the session or report the lock state |
| `lockscreen widgets list\|enable\|disable\|reset` | Lock screen widget visibility |
| `weather location [NAME]` | Show or resolve the weather location |
| `theme get\|set\|toggle` | Dark or light appearance |
| `theme palette get\|set NAME` | Wallpaper colors or a preset palette |
| `theme temperature get\|set 0-3` | Warmth of the light wallpaper theme |
| `theme surface-opacity set 0-3` | Shell surface opacity: 1.0, 0.96, 0.9, 0.78 |
| `theme radius set 0-3` | Corner radius of shell surfaces and windows |
| `theme blur set 0-3` | Compositor blur; `0` turns it off |
| `theme sync` | Apply the saved compositor appearance to the running Hyprland |
| `theme reset` | Restore every theme setting to its default |
| `theme schedule get\|set\|enable\|disable` | Automatic light and dark switching |
| `layout get\|set\|toggle` | Workspace layout, `dwindle` or `scrolling` |
| `keyboard setup\|devices\|get\|set` | Keyboard layout overrides |
| `services list\|add\|remove` | Units watched by the Services widget |
| `wallpaper set\|random\|current\|list` | Wallpaper management |
| `screenshot region\|window\|monitor\|full` | Capture and open in Satty |
| `recording` | Open the recording selector, or stop a recording |
| `color` | Pick a color from the screen |
| `night-mode [on\|off\|toggle]` | Warm screen filter through hyprsunset |
| `lock [--hyprlock]` | Lock with the Quickshell lock screen, or Hyprlock |
| `reload` | Reload the running shell |
| `open PANEL` | Open `hub`, `launcher`, `clipboard`, `wallpapers`, `network`, `bluetooth`, `power`, `emoji`, or `recording` |

Run `hyprism-shell COMMAND --help` for the exact arguments of any command.

## Configuration

Initialize a packaged installation once after installing either AUR package:

```bash
hyprism-shell init
hyprism-shell init --lang pt-BR
```

The command merges system defaults into `~/.config/hyprism/user.json`, keeps explicit user values such as disabled widgets, copies bundled wallpapers only when missing, and leaves unrelated existing paths untouched. It is safe to run again after an update.

```bash
hyprism-shell language
hyprism-shell language set en
hyprism-shell language set pt-BR

hyprism-shell keyboard setup
hyprism-shell keyboard devices
hyprism-shell keyboard devices --json
hyprism-shell keyboard devices --all
hyprism-shell keyboard get
hyprism-shell keyboard set built-in br-abnt2
hyprism-shell keyboard set external us-intl
hyprism-shell keyboard set default system

hyprism-shell services list
hyprism-shell services list --json
hyprism-shell services add bluetooth
hyprism-shell services add pipewire.service --user
hyprism-shell services remove bluetooth.service
hyprism-shell services remove pipewire.service --user

hyprism-shell widgets list
hyprism-shell widgets enable clock
hyprism-shell widgets disable weather
hyprism-shell widgets toggle system
hyprism-shell widgets enable --all
hyprism-shell widgets disable --all
hyprism-shell widgets toggle --all

hyprism-shell weather location
hyprism-shell weather location "São Paulo"

hyprism-shell theme get
hyprism-shell theme set light
hyprism-shell theme set dark
hyprism-shell theme toggle
hyprism-shell theme palette get
hyprism-shell theme palette set nord
hyprism-shell theme palette set wallpaper
hyprism-shell theme temperature get
hyprism-shell theme temperature set 0
hyprism-shell theme temperature set 1
hyprism-shell theme temperature set 2
hyprism-shell theme temperature set 3
hyprism-shell theme surface-opacity set 2
hyprism-shell theme radius set 1
hyprism-shell theme blur set 0
hyprism-shell theme sync
hyprism-shell theme reset
hyprism-shell theme schedule set 07:00 18:30
hyprism-shell theme schedule get
hyprism-shell theme schedule enable
hyprism-shell theme schedule disable

hyprism-shell layout get
hyprism-shell layout set scrolling
hyprism-shell layout set dwindle
hyprism-shell layout toggle
```

`keyboard setup` is an arrow-key interface for selecting a detected physical keyboard, previewing a layout live, and saving it only after confirmation. `Esc` restores the previous layout. Composite HID interfaces are grouped, and pointer receivers that expose auxiliary keyboard endpoints are omitted from the setup; `devices --all` includes them for diagnostics. Hyprism preserves detected system behavior by default and does not infer a layout from whether a keyboard is built in or external. Overrides are stored per Hyprland device identifier. Common presets are `system`, `us`, `us-intl`, `br-abnt2`, `pt`, `es`, `de`, and `fr`; any installed layout is available as `xkb:LAYOUT`.

`services list` reports the scope, unit, and current state of everything observed by the Services desktop widget. `add` and `remove` use the system manager by default; pass `--user` for a user unit. A name without a suffix is normalized to `.service`, while explicit unit types such as `.timer` and `.socket` are preserved. Adding validates that the unit exists but does not require it to be active. These commands only configure monitoring and never start, stop, enable, or disable units. Removing every entry leaves an explicit empty list and hides the Services card.

Weather locations are resolved through Open-Meteo's geocoding service. Hyprism stores the resolved display name, coordinates, and timezone, then refreshes the running weather service.

Desktop widget names are `clock`, `weather`, `media`, `system`, `network`, `storage`, `sensors`, `uptime`, `services`, `tasks`, and `processes`. All-widget operations affect only these desktop widgets.

Temperature levels range from neutral (`0`) to amber (`3`) and affect only light mode. The theme schedule treats the first boundary as the start of the light interval and the second as the start of the dark interval. Intervals may cross midnight. Scheduling is opt-in, is reconciled when Quickshell starts, and waits efficiently until the next boundary. A manual Hub toggle, `theme set`, or `theme toggle` disables scheduling and returns appearance control to manual mode.

`layout` selects the tiling layout of normal workspaces and is shared by `Super+Shift+Space` and the Layout selector in Theme Settings. The choice is stored as `hyprland.layout` in `user.json`, applied to the running Hyprland session immediately, and restored on configuration reloads and new sessions. The `special:magic` workspace always uses scrolling regardless of this setting. A real layout change shows a brief on-screen indicator unless the Hub is open. In the scrolling layout, each column takes 95% of the usable workspace width so the neighboring column stays partly visible; a lone window still fills the workspace.

`theme palette` selects `wallpaper` (Matugen, the default) or one of the presets `nord`, `tokyo-night`, `catppuccin`, `gruvbox`, `everforest`, `rose-pine`, and `monochrome`. The light or dark variant follows the appearance mode, and presets ignore wallpaper changes.

## Shell actions

```bash
hyprism-shell open hub
hyprism-shell open launcher
hyprism-shell open clipboard
hyprism-shell open wallpapers
hyprism-shell open network
hyprism-shell open bluetooth
hyprism-shell open power
hyprism-shell open emoji
hyprism-shell open recording

hyprism-shell wallpaper set IMAGE
hyprism-shell wallpaper random
hyprism-shell wallpaper current
hyprism-shell wallpaper list

hyprism-shell screenshot region
hyprism-shell screenshot window
hyprism-shell screenshot monitor
hyprism-shell screenshot full
hyprism-shell recording
hyprism-shell color
hyprism-shell night-mode on
hyprism-shell night-mode off
hyprism-shell night-mode toggle
hyprism-shell lock
hyprism-shell lock --hyprlock
hyprism-shell lockscreen lock
hyprism-shell lockscreen status
hyprism-shell lockscreen widgets list
hyprism-shell lockscreen widgets enable system
hyprism-shell lockscreen widgets disable weather
hyprism-shell lockscreen widgets enable --all
hyprism-shell lockscreen widgets reset
hyprism-shell lockscreen widgets disable --all
hyprism-shell lockscreen widgets reset
hyprism-shell reload
```

The `open` and `recording` commands require a running Quickshell instance. Screenshot modes capture a selected region, active window, focused monitor, or complete desktop with Grim and open the result directly in a floating Satty window. Satty provides drawing, annotations, crop, undo, clipboard copy, direct save, and Save As. Direct save defaults to `paths.screenshots` from `~/.config/hyprism/user.json`; Save As selects a one-time destination, and the next editor starts from the configured default again. No unedited intermediate image is stored. Color-picker commands are interactive. `lock` locks the current session with the Quickshell lock screen (`--hyprlock` selects the legacy fallback), and `reload` reloads only Quickshell.

## Lock screen

`lockscreen widgets` manages the two optional lock screen widgets, `weather` and `media`; the clock, date and battery are fixed. `enable` and `disable` take one identifier or `--all`, and `reset` restores the defaults. It only edits `lockscreen.widgets` in `user.json` and never changes desktop widgets. There is deliberately no unlock command. See [the lock screen guide](lockscreen.md).
