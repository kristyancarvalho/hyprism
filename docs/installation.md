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
