---
title: Installation
description: "Install Hyprism from the AUR or from a repository checkout, then initialize your desktop configuration."
category: Get started
order: 1
icon: package-check
---

# Installation

Install the latest stable release from the AUR, then initialize the user configuration in English:

```bash
paru -S hyprism-shell
hyprism-shell init
```

Use `hyprism-shell init --lang pt-BR` for a new Brazilian Portuguese configuration. The initializer preserves existing user settings and unmanaged configuration paths.

The development package follows every commit on `main` and is intended for users who explicitly want unreleased changes:

```bash
paru -S hyprism-shell-git
hyprism-shell init
```

`paru` is only an example AUR helper. Both packages can also be cloned from the AUR and installed with the standard `makepkg -si` workflow.

For a repository-managed installation instead, clone Hyprism and run the installer directly:

```bash
git clone https://github.com/kristyancarvalho/hyprism.git
cd hyprism
make install
```

Install the interface in Brazilian Portuguese explicitly:

```bash
make install-ptbr
```

The equivalent variable form is `make install LANG=pt-BR`. Reapply an existing installation while preserving its language and user configuration with:

```bash
make update
```

Useful maintenance targets are available through `make help`. Run `make check` to validate the repository, `make reload` to reload Quickshell, and `make uninstall` to remove Hyprism-managed paths.

> [!WARNING]
> Installation provisions packages and replaces user paths managed by Hyprism. Conflicting paths are moved to `~/.local/state/hyprism/backups/` before links are created. Uninstallation archives the runtime and `user.json` under `~/.local/state/hyprism/uninstalled/`.

The AUR packages own immutable files under `/usr/share/hyprism` and `/usr/bin`. User preferences remain under `~/.config/hyprism` and are not removed with the package.

## Requirements and support

- Arch Linux with internet access during initial package provisioning.
- A regular user with package-installation privileges. The repository installer additionally uses `sudo` for packages, fonts, and SDDM configuration.
- Hardware and drivers suitable for a current Hyprland and Wayland session.
- A standard user `PATH` containing `~/.local/bin` after installation.

The installer and package lists target Arch Linux. Other distributions are not currently supported by the automated installation workflow. Hyprism owns a broad set of linked configuration paths and is best evaluated as a complete, opinionated desktop environment rather than layered over an unrelated dotfiles setup.

## Packages

The AUR packages pull in the runtime the shell needs, including `hyprland`, `quickshell` 0.2.0 or newer, `awww`, `matugen`, `python-pillow`, `networkmanager`, `wireplumber`, `upower`, `power-profiles-daemon`, `wl-clipboard` with `cliphist`, `grim`, `slurp` and `satty`, and the Qt 6 SDDM stack (`sddm`, `qt6-declarative`, `qt6-svg`, and `qt6-virtualkeyboard`). The Kvantum, qt5ct, qt6ct, and Papirus theming stack is also installed. Optional extras such as `ddcutil` for external monitor brightness, `flatpak`, and `fastfetch` are listed as optional dependencies; `pacman -Qi hyprism-shell` shows them with their purpose. The repository installer reads `packages/pacman.txt` and `packages/aur.txt` instead.

Hyprism installs its Qt 6 Pixie SDDM fork as `hyprism-pixie`. The login theme reads the same wallpaper and generated palette as the desktop from `/var/lib/hyprism/sddm/`, and includes the Qt Quick Virtual Keyboard for password entry. Session choices use bundled DE/WM logos where the projects publish artwork, with a neutral desktop mark for unknown sessions.

To preview the installed theme without leaving the desktop session, run SDDM's greeter test mode:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/hyprism-pixie
```

This opens a separate greeter preview. Do not restart SDDM or log out to preview theme changes.

## First launch

After `hyprism-shell init`, choose **Hyprland** in your display manager, or start it from a TTY. The shell, wallpaper, and theme start automatically from Hyprland's autostart. Set your weather location with `hyprism-shell weather location "City"` and review the [configuration reference](configuration.md) for everything else.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| No bar or widgets after login | `~/.cache/hyprism/quickshell-startup.log`; run `hyprism-shell reload` |
| `hyprism-shell: command not found` after a repository install | `~/.local/bin` must be on `PATH` |
| Weather stays empty | Set a location with `hyprism-shell weather location`; the service needs network access to Open-Meteo |
| Lock request refused | `/etc/pam.d/hyprism-lock` must exist; reinstall the package or run `make update` |
| Colors did not follow a wallpaper change | The palette may be set to a preset; `hyprism-shell theme palette set wallpaper` |
| Paths you configured were replaced | Conflicting files are kept in `~/.local/state/hyprism/backups/` |
