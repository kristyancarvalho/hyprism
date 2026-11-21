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
- **Release after a morph.** After PAM succeeds, the panel animates from its compact width to the exact desktop bar geometry while the lock stays held; the lock is released only when that animation finishes, so the already-running bar takes its place.
- **Single release path.** `LockSession.unlockGranted` is emitted only from the PAM `completed` handler with `PamResult.Success` for an attempt the lock screen started with a non-empty password. It is the only caller of the release function. There are no IPC unlock handlers, shortcuts, timers, or click handlers that release the lock.
- **Background.** The wallpaper image itself is blurred offline by `scripts/system/lock-background.py` (Pillow) and cached under `~/.cache/hyprism/state/lock-background/`; the lock surface renders that file with `PreserveAspectCrop` plus a palette dim. No screen capture, no compositor blur, so no window can show through. If no wallpaper resolves, a palette gradient is used; the desktop is never shown. Hyprism has one wallpaper for all outputs, so every output uses the same image.
- **Panel.** The password panel reuses the compact bar's anchor, top margin, height, radius and surface opacity. The panel is completely hidden at rest, with no message. The first key fades it in with a small slide at about 62% of the bar width and is inserted into the field. Each character is shown as one dot that fades in or out; the characters themselves are never displayed. If the field stays empty for 4 seconds the field hides again. A non-empty password is never hidden or cleared by a timer. `Escape` only clears the field.

## PAM service

`config/pam/hyprism-lock` is installed as `/etc/pam.d/hyprism-lock`:

```
auth    include system-auth
account include system-auth
```

This reuses the distribution's stack, including `pam_faillock` and failure delays. The package marks it as a `backup` file and `install.sh` never overwrites an existing file, so local changes survive upgrades. `/etc/pam.d/login` and other system files are untouched. `hyprism-shell lockscreen lock` refuses to lock when this service file is missing, because nobody could unlock afterwards.

## Lock-screen elements

The clock and the date below it (`sáb. 21/11/2026`, `Sat 21/11/2026`) are fixed and not configurable. The battery sits in the bottom-right corner as a small icon and percentage.

Only two optional widgets exist on the lock screen, with visibility stored under `lockscreen.widgets` in `user.json` (defaults in `config/lockscreen/widgets.json`, both on) and independent of `shell.widgets`:

| Widget | Position | Content |
| --- | --- | --- |
| `weather` | bottom-left | weather icon and temperature only |
| `media` | bottom-center | compact desktop media strip with working previous, play/pause and next controls |

```bash
hyprism-shell lockscreen widgets list
hyprism-shell lockscreen widgets enable <weather|media>
hyprism-shell lockscreen widgets disable <weather|media>
hyprism-shell lockscreen widgets enable --all
hyprism-shell lockscreen widgets disable --all
hyprism-shell lockscreen widgets reset
```

Each widget has its own fixed anchor, so hiding one never moves another. The media strip is shown only while a player with track information is playing or paused. Obsolete `lockscreen.widgets` entries from earlier versions are ignored and dropped the next time the lock screen configuration is written; desktop widget settings are never touched. Panels use the global surface opacity, corner radius and theme, so changing them is reflected live. While the session is locked, the desktop shell stores notifications in the history but does not show popups or OSDs, and does not replay them after unlocking.

## Recovery

If the lock-screen process dies while the session is locked (crash, `kill`), **the compositor stays locked**; nothing unlocks it. `hyprism-shell lockscreen status` then reports `orphaned`. Hyprism enables Hyprland's `misc:allow_session_lock_restore`, so running `hyprism-shell lockscreen lock` from a TTY (`HYPRLAND_INSTANCE_SIGNATURE` and `WAYLAND_DISPLAY` set) starts a new lock client that must authenticate again. Switching to a TTY and logging in is also always possible.

## Idle and suspend

Hyprism does not ship a `hypridle` configuration, so there is no idle or suspend hook to migrate. To lock on idle or before sleep, call `hyprism-shell lock` from your own idle manager (`lock_cmd` / `before_sleep_cmd`).
