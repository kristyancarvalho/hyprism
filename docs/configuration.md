---
title: Configuration
description: "Every user.json field with its default, how changes are applied, and the environment variables Hyprism reads."
category: Guides
order: 5
icon: sliders-horizontal
---

Every personal preference lives in one JSON file, `~/.config/hyprism/user.json`. `hyprism-shell init` creates it from the defaults in `config/user.json` and later merges new defaults without replacing values you set. The repository installer does the same during `make install` and `make update`.

## How changes are applied

`hyprism-shell` validates every change, preserves unrelated values, and replaces the file atomically. The running shell watches the file and applies new preferences without a restart. Commands that also affect Hyprland, such as `layout`, `theme radius`, and `theme blur`, apply the value to the running compositor too, and palette or appearance changes regenerate the theme files. Prefer the CLI for anything it exposes; edit the file by hand only for options it does not cover, such as storage mounts or widget limits.

## Reference

### General

| Field | Default | Meaning |
| --- | --- | --- |
| `language` | `"en"` | Interface language, `en` or `pt-BR`; see [Localization](localization.md) |
| `paths.wallpapers` | `~/Pictures/Wallpapers` | Folder listed by the wallpaper picker and `wallpaper random` |
| `paths.screenshots` | `~/Pictures/Screenshots` | Default save folder for screenshots; the installer localizes it from your XDG Pictures directory |
| `paths.recordings` | `~/Videos/Recordings` | Folder for screen recordings |
| `hyprland.layout` | `"dwindle"` | Layout of normal workspaces, `dwindle` or `scrolling` |
| `keyboard.default` | `null` | Layout override for all keyboards; `null` keeps the detected system layout |
| `keyboard.devices` | `{}` | Per-device layout overrides set by `hyprism-shell keyboard set` |

### Appearance

| Field | Default | Meaning |
| --- | --- | --- |
| `appearance.mode` | `"dark"` | `dark` or `light` |
| `appearance.palette` | `"wallpaper"` | `wallpaper` or a preset: `nord`, `tokyo-night`, `catppuccin`, `gruvbox`, `everforest`, `rose-pine`, `monochrome` |
| `appearance.whiteTemperature` | `0` | Warmth of the light wallpaper theme, `0` (neutral) to `3` (amber) |
| `appearance.schedule.enabled` | `false` | Switch between light and dark automatically |
| `appearance.schedule.lightStart`, `darkStart` | `"07:00"`, `"18:00"` | Start of the light and dark intervals |
| `shell.surfaceOpacity` | `0.9` | Opacity of shell surfaces; `theme surface-opacity set 0..3` picks 1.0, 0.96, 0.9, or 0.78 |
| `shell.cornerRadiusPreset` | `1` | Corner radius preset `0..3`, also applied to windows (8 to 24 px) |
| `shell.blurPreset` | `2` | Compositor blur preset `0..3`; `0` disables blur |

See [Theming](theming.md) for how these values reach each application.

### Shell geometry

| Field | Default | Meaning |
| --- | --- | --- |
| `shell.primaryMonitor` | `""` | Fallback output for panels when Hyprland reports no focused monitor; panels otherwise open on the focused monitor |
| `shell.islandWidth` | `620` | Width of the expanded island in pixels |
| `shell.compactHeight` | `44` | Height of the compact bar |
| `shell.topMargin` | `8` | Gap above the bar |
| `shell.reserveGap` | `4` | Gap between the compact bar and the space reserved for windows |
| `shell.animationFast`, `shell.animationNormal` | `110`, `150` | Animation durations in milliseconds |
| `shell.widgetLayout.position` | `"center"` | Desktop widget board position: `center`, `top-left`, `top-right`, `bottom-left`, `bottom-right` |

### Desktop widgets

Each widget has `shell.widgets.<name>.enabled`. Some accept extra options:

| Widget | Option | Default | Meaning |
| --- | --- | --- | --- |
| `network` | `historySamples` | `60` | Points in the traffic graph, 15 to 180 |
| `network` | `interface` | `"auto"` | Interface to measure, or `auto` |
| `storage` | `mounts` | `["/", "/home"]` | Mount points to show |
| `services` | `items` | NetworkManager, Bluetooth, PipeWire | Units to monitor; manage with `hyprism-shell services` |
| `services` | `problemOnly` | `false` | Show the card only when a unit is unhealthy |
| `tasks` | `limit` | `3` | Number of tasks shown |
| `processes` | `limit` | `3` | Processes per list, 1 to 6 |

The [desktop widgets guide](desktop-widgets.md) describes each card.

### Lock screen

| Field | Default | Meaning |
| --- | --- | --- |
| `lockscreen.widgets.weather` | `true` | Show the weather widget on the lock screen |
| `lockscreen.widgets.media` | `true` | Show the media strip on the lock screen |

These are independent of the desktop widgets. See [Lock screen](lockscreen.md).

### Weather

| Field | Default | Meaning |
| --- | --- | --- |
| `weather.enabled` | `true` | Fetch weather at all |
| `weather.location` | `"São Paulo"` | Display name; set with `hyprism-shell weather location NAME` |
| `weather.latitude`, `weather.longitude`, `weather.timezone` | São Paulo | Resolved by the CLI through Open-Meteo geocoding |
| `weather.refreshMinutes` | `30` | Refresh interval |

## Environment variables

These variables are read by the scripts and the shell. They are mostly useful for development and testing.

| Variable | Effect |
| --- | --- |
| `HYPRISM_ROOT` | Runtime root for scripts, QML, and wallpapers; overrides `~/.local/share/hyprism` and `/usr/share/hyprism` |
| `HYPRISM_CONFIG` | Path of `user.json` used by the CLI and scripts |
| `HYPRISM_CACHE_DIR` | Cache folder for wallpaper state and generated theme files |
| `HYPRISM_WALLPAPER_DIR` | Wallpaper folder, overriding `paths.wallpapers` |
| `HYPRISM_QS_PATH` | Start Quickshell from this `shell.qml` instead of the named configuration |

The shell reads `user.json` from `$XDG_CONFIG_HOME/hyprism/`, so when `HYPRISM_CONFIG` points elsewhere, set `XDG_CONFIG_HOME` to match, as the development session does.
