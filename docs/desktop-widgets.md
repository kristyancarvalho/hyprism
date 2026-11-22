---
title: Desktop widgets
description: "The eleven desktop cards, where their data comes from, how to show or hide them, and how media players are selected."
category: Features
order: 10
icon: panels-top-left
---

Desktop widgets are optional cards on the desktop, behind your windows. They are separate from the core shell (island, Hub, launcher, notifications), and their visibility is stored under `shell.widgets` in `user.json`. The lock screen has its own, much smaller widget set with separate settings; see [Lock screen widgets](#lock-screen-widgets).

## Catalog

| Identifier | Shows | Data source |
| --- | --- | --- |
| `clock` | Time and date | Quickshell system clock |
| `weather` | Current conditions for the configured location | `weather.py`, querying Open-Meteo |
| `media` | Track, artist, artwork, seek bar, and playback controls | MPRIS players through Quickshell |
| `system` | CPU, memory, and GPU usage | `state-daemon.py` (`/proc`, `nvidia-smi` when present) |
| `network` | Connection name and a traffic graph | NetworkManager (`nmcli`) and `/proc/net/dev` |
| `storage` | Usage of the configured mount points | `statvfs` in `monitoring-daemon.py` |
| `sensors` | Up to four temperatures, CPU and GPU first | `/sys/class/hwmon` and thermal zones |
| `uptime` | Uptime, process count, and system identity such as the kernel | `/proc` and `monitoring-daemon.py` |
| `services` | Health of monitored systemd units | `systemctl` queries, read-only |
| `tasks` | Progress of Hyprism background work, such as theme generation; hidden while there is none | The shell's own task list |
| `processes` | Top processes by CPU and by memory | `monitoring-daemon.py` |

Per-widget options, such as storage mounts and list limits, are listed in the [configuration reference](configuration.md#desktop-widgets). Widgets whose data is unavailable on the current machine hide their missing parts instead of showing errors.

## Showing and hiding widgets

```bash
hyprism-shell widgets list
hyprism-shell widgets disable network
hyprism-shell widgets enable network
hyprism-shell widgets toggle media
hyprism-shell widgets disable --all
hyprism-shell widgets enable --all
```

Changes apply immediately and survive reloads, theme and wallpaper changes, and new sessions. `--all` affects only the desktop widgets, never the lock screen.

## Monitored services

The Services widget watches systemd units without controlling them:

```bash
hyprism-shell services list
hyprism-shell services add bluetooth
hyprism-shell services add pipewire.service --user
hyprism-shell services remove bluetooth.service
```

Names without a unit suffix are treated as `.service`; explicit types such as `.timer` and `.socket` are kept. These commands never start, stop, enable, or disable a unit. An explicitly empty list hides the card, and `problemOnly` shows it only when a unit is unhealthy.

## Media integration

`MediaService` reads MPRIS players through Quickshell. When several players exist, the first one that is playing is selected; otherwise the first player is used. The media widget, the island, the Hub, and the lock screen all share that selection.

| Control | Behavior |
| --- | --- |
| Previous, Play/Pause, Next | Sent to the selected player only when it reports support for the action |
| Seek bar | Shown when the player supports seeking and reports a valid length; dragging previews the position and seeks on release |
| Artwork | The track art URL; the application icon is shown while it loads or when there is none |

A player is shown only while it has a track title. Streams that report impossible lengths are treated as having no duration.

## Lock screen widgets

The lock screen offers only `weather` and `media`, stored under `lockscreen.widgets` and managed with `hyprism-shell lockscreen widgets`. They reuse the same data providers but are configured separately, so hiding a desktop widget never hides it on the lock screen and the reverse. The lock screen media strip is pointer-only and never takes keyboard focus. Details are in the [lock screen guide](lockscreen.md).
