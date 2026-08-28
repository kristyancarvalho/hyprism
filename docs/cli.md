# hyprism-shell

`hyprism-shell` is Hyprism's stable user-facing command interface. Query commands print plain values, mutations return a non-zero status for invalid input, and configuration changes are written atomically to `~/.config/hyprism/user.json`.

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
hyprism-shell theme temperature get
hyprism-shell theme temperature set 0
hyprism-shell theme temperature set 1
hyprism-shell theme temperature set 2
hyprism-shell theme temperature set 3
hyprism-shell theme schedule set 07:00 18:30
hyprism-shell theme schedule get
hyprism-shell theme schedule enable
hyprism-shell theme schedule disable
```

`keyboard setup` is an arrow-key interface for selecting a detected physical keyboard, previewing a layout live, and saving it only after confirmation. `Esc` restores the previous layout. Composite HID interfaces are grouped, and pointer receivers that expose auxiliary keyboard endpoints are omitted from the setup; `devices --all` includes them for diagnostics. Hyprism preserves detected system behavior by default and does not infer a layout from whether a keyboard is built in or external. Overrides are stored per Hyprland device identifier. Common presets are `system`, `us`, `us-intl`, `br-abnt2`, `pt`, `es`, `de`, and `fr`; any installed layout is available as `xkb:LAYOUT`.

Weather locations are resolved through Open-Meteo's geocoding service. Hyprism stores the resolved display name, coordinates, and timezone, then refreshes the running weather service.

Desktop widget names are `clock`, `weather`, `media`, `system`, `network`, `storage`, `sensors`, `uptime`, `services`, `tasks`, and `processes`. All-widget operations affect only these desktop widgets.

Temperature levels range from neutral (`0`) to amber (`3`) and affect only light mode. The theme schedule treats the first boundary as the start of the light interval and the second as the start of the dark interval. Intervals may cross midnight. Scheduling is opt-in, is reconciled when Quickshell starts, and waits efficiently until the next boundary. A manual Hub toggle, `theme set`, or `theme toggle` disables scheduling and returns appearance control to manual mode.

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
hyprism-shell screenshot monitor
hyprism-shell recording
hyprism-shell color
hyprism-shell night-mode on
hyprism-shell night-mode off
hyprism-shell night-mode toggle
hyprism-shell lock
hyprism-shell reload
```

The `open` and `recording` commands require a running Quickshell instance. Screenshot and color-picker commands are interactive. `lock` locks the current session, and `reload` reloads only Quickshell.
