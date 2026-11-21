# Quickshell lock screen

Hyprism ships a native lock screen implemented in Quickshell. Hyprlock stays installed and is selectable as a manual fallback while the new lock screen is being validated.

```bash
hyprism-shell lock                    # Super+L and the power menu: Quickshell lock screen
hyprism-shell lockscreen lock         # the same request, explicit form
hyprism-shell lockscreen status       # unlocked | locking | locked | orphaned
hyprism-shell lock --hyprlock         # legacy Hyprlock fallback
```

There is intentionally **no unlock command**. The CLI can request a lock and report non-sensitive state; the only way to release the session is a successful PAM authentication typed into the lock screen.

## How it works

- **Real session lock.** `config/quickshell/lockscreen.qml` uses `WlSessionLock` / `WlSessionLockSurface` (the `ext-session-lock-v1` protocol). It is not an overlay window. The compositor shows only lock surfaces while the lock is held, and input goes only to them.
- **Confirmed before trusted.** `WlSessionLock.secure` becomes true only when the compositor confirms every output is covered. Until then the UI shows a "securing" state and ignores keyboard input. The state file only becomes `locked` after confirmation.
- **Dedicated process.** The lock screen runs as its own Quickshell instance (`ShellId hyprism-lock`) started by `scripts/system/lockscreen`, with live reload disabled. Reloading or restarting the desktop shell (`hyprism-shell reload`) never touches it. A `flock` on `$XDG_RUNTIME_DIR/hyprism/lockscreen.lock` prevents duplicate instances; a second request is a no-op.
- **One authentication session.** A single `PamContext` is shared by all outputs, authenticating the current user through the `hyprism-lock` PAM service. Extra PAM prompts are shown and answered through the same field.
- **Release after a morph.** After PAM succeeds, the panel animates from 85% of the bar width to the exact desktop bar geometry while the lock stays held; the lock is released only when that animation finishes, so the already-running bar takes its place.
- **Single release path.** `LockSession.unlockGranted` is emitted only from the PAM `completed` handler with `PamResult.Success` for an attempt the lock screen started with a non-empty password. It is the only caller of the release function. There are no IPC unlock handlers, shortcuts, timers, or click handlers that release the lock.
- **Background.** The wallpaper image itself is blurred offline by `scripts/system/lock-background.py` (Pillow) and cached under `~/.cache/hyprism/state/lock-background/`; the lock surface renders that file with `PreserveAspectCrop` plus a palette dim. No screen capture, no compositor blur, so no window can show through. If no wallpaper resolves, a palette gradient is used; the desktop is never shown. Hyprism has one wallpaper for all outputs, so every output uses the same image.
- **Panel.** The password panel reuses the compact bar's anchor, top margin, width, height, radius and surface opacity. At rest it only shows a lock icon and "Session locked". The first key reveals the masked field and is inserted into it. If the field stays empty for 4 seconds the field hides again. A non-empty password is never hidden or cleared by a timer. `Escape` only clears the field.

## PAM service

`config/pam/hyprism-lock` is installed as `/etc/pam.d/hyprism-lock`:

```
auth    include system-auth
account include system-auth
```

This reuses the distribution's stack, including `pam_faillock` and failure delays. The package marks it as a `backup` file and `install.sh` never overwrites an existing file, so local changes survive upgrades. `/etc/pam.d/login` and other system files are untouched. `hyprism-shell lockscreen lock` refuses to lock when this service file is missing, because nobody could unlock afterwards.

## Lock-screen widgets

Lock-screen visibility is stored separately in `user.json` under `lockscreen.widgets` and never changes the desktop widget configuration (`shell.widgets`). The registry is `config/lockscreen/widgets.json`.

| Widget | Lock screen | Default |
| --- | --- | --- |
| `clock`, `weather`, `media` (read-only, only while playing) | supported | enabled |
| `system` (CPU and memory) | supported | disabled |
| `network`, `storage`, `sensors`, `uptime`, `services`, `tasks`, `processes` | not supported (privacy or interaction) | n/a |

```bash
hyprism-shell lockscreen widgets list
hyprism-shell lockscreen widgets enable system
hyprism-shell lockscreen widgets disable weather
hyprism-shell lockscreen widgets reset
```

The battery is not a widget: when a battery is present, a small icon and percentage sit in the bottom-right corner.

Widgets are read-only on the lock screen: they have no pointer or key handlers. While the session is locked, the desktop shell stores notifications in the history but does not show popups or OSDs, and does not replay them after unlocking.

## Recovery

If the lock-screen process dies while the session is locked (crash, `kill`), **the compositor stays locked**; nothing unlocks it. `hyprism-shell lockscreen status` then reports `orphaned`. Hyprism enables Hyprland's `misc:allow_session_lock_restore`, so running `hyprism-shell lockscreen lock` from a TTY (`HYPRLAND_INSTANCE_SIGNATURE` and `WAYLAND_DISPLAY` set) starts a new lock client that must authenticate again. Switching to a TTY and logging in is also always possible.

## Idle and suspend

Hyprism does not ship a `hypridle` configuration, so there is no idle or suspend hook to migrate. To lock on idle or before sleep, call `hyprism-shell lock` from your own idle manager (`lock_cmd` / `before_sleep_cmd`).
