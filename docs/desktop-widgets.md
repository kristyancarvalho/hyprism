---
title: Desktop widgets
description: "Explore the eleven optional cards for weather, media, hardware, network, and system activity."
category: Features
order: 10
icon: panels-top-left
---

# Desktop widgets

Desktop widgets are separate from core shell functionality such as the island, Hub, launcher, and notification daemon. Available CLI identifiers are:

```text
clock weather media system network storage sensors uptime services tasks processes
```

Control one widget or the complete desktop-widget set:

```bash
hyprism-shell widgets disable network
hyprism-shell widgets enable network
hyprism-shell widgets toggle media
hyprism-shell widgets disable --all
hyprism-shell widgets enable --all
```

State is persisted in `shell.widgets` and survives shell reloads, appearance changes, wallpaper changes, and new sessions.

The Services widget can monitor system and user units without controlling them:

```bash
hyprism-shell services list
hyprism-shell services add bluetooth
hyprism-shell services add pipewire.service --user
hyprism-shell services remove bluetooth.service
```

Names without a unit suffix are treated as `.service`; explicit types such as `.timer` and `.socket` are preserved. These commands only change the widget's monitored list—they never start, stop, enable, or disable a unit. An explicitly empty list hides the Services card.

The lock screen has its own widget set (weather and media); see the [lock screen guide](lockscreen.md).
