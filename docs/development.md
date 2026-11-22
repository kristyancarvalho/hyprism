# Development and project structure

## Project structure

```text
.github/           Issue forms and pull request template
assets/            Branding, screenshots, and demo media
config/            Quickshell, Hyprland, toolkit, terminal, and application configuration
docs/              Focused user documentation
packages/          Manual installer package manifests
packaging/         Standalone AUR package recipes
scripts/           CLI, theme generation, services, and session utilities
tests/             Configuration and behavior validation
themes/            Managed session themes with upstream attribution
wallpapers/        Built-in fallback wallpapers
install.sh         Installation and migration workflow
uninstall.sh       Managed removal and archival workflow
Makefile           Project entry points
```

## Development session

`make dev-session` opens a nested Hyprland window inside your running Hyprland desktop and runs the current checkout in it. Nothing is installed and the parent session is not touched. Close the window, press `Ctrl+C`, or run `make dev-session-stop` to end it.

Requirements: `Hyprland`, `quickshell`, `awww`, `dbus`, `jq` and `python3`, and a running Wayland session. Missing commands are listed with exit status 127.

How it works:

- Hyprland starts with `config/hypr/hyprland.lua` from the checkout, and `HYPRISM_ROOT` points at the checkout so scripts, QML and wallpapers resolve to source files instead of `/usr/share/hyprism` or `~/.local/share/hyprism`. No build step is needed.
- The session runs under its own D-Bus session, a private `XDG_RUNTIME_DIR` (`$XDG_RUNTIME_DIR/hyprism-dev`), and private `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME` under `~/.cache/hyprism-dev` (override with `HYPRISM_DEV_DIR`). Its `user.json` is seeded from `config/user.json` once and then kept between runs.
- Wallpapers come from the repository `wallpapers/` directory.
- Only the processes in the session's own process group are stopped on exit; nothing is killed by name.

Logs are in `~/.cache/hyprism-dev/logs/session.log` and `~/.cache/hyprism-dev/cache/hyprism/quickshell-startup.log`.

Troubleshooting: if the command refuses to start, make sure it is run from inside a graphical session. If a previous run was killed abnormally, `make dev-session-stop` clears its runtime directory. Use the Lua dispatcher syntax with the nested instance, for example `hl.dsp.exit()`.

## Contributing

Use the structured [issue chooser](https://github.com/kristyancarvalho/hyprism/issues/new/choose) for reproducible bugs, feature requests, and installation problems. Remove credentials and personal data from logs or screenshots.

Before proposing a change:

```bash
make check
```

Keep changes focused, preserve English and PT-BR coverage for user-facing text, and include screenshots or video when behavior is visual. Pull requests receive a concise checklist automatically.

## Credits and licenses

Preset palettes are adapted from [Nord](https://www.nordtheme.com), [Tokyo Night](https://github.com/folke/tokyonight.nvim), [Catppuccin](https://github.com/catppuccin/palette), [Gruvbox](https://github.com/morhetz/gruvbox), [Everforest](https://github.com/sainnhe/everforest), and [Rosé Pine](https://rosepinetheme.com), all available under the MIT License.

Hyprism integrates projects including [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.org/), [Matugen](https://github.com/InioX/matugen), [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme), and [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).

Hyprism's original code and documentation are available under the [MIT License](../LICENSE), copyright Hyprism contributors.

Vendored and adapted components retain their attribution and licenses in their respective directories, including [KSDDM](../themes/ksddm-hyprism/LICENSE) and [NvChad](../config/nvim/LICENSE).
