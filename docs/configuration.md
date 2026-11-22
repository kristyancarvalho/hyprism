# Configuration

User preferences are stored in `~/.config/hyprism/user.json`. The installer migrates existing settings conservatively, while CLI mutations preserve unrelated values and replace the JSON atomically.

| Area | Important fields |
| --- | --- |
| Language | `language` |
| Appearance | `appearance.mode`, `appearance.whiteTemperature`, `appearance.schedule` |
| Keyboard | `keyboard.default`, `keyboard.devices.<identifier>` |
| User paths | `paths.wallpapers`, `paths.screenshots` |
| Shell placement | `shell.primaryMonitor`, `shell.widgetLayout` |
| Shell geometry | `shell.islandWidth`, `shell.compactHeight`, `shell.topMargin`, `shell.reserveGap` |
| Desktop widgets | `shell.widgets.<name>.enabled` and widget-specific options |
| Monitored units | `shell.widgets.services.items` |
| Weather | `weather.location`, coordinates, timezone, and refresh interval |

Most routine changes are safer and easier through `hyprism-shell`; edit `user.json` directly only when configuring options not exposed by the CLI.
