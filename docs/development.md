---
title: Development
description: "Set up a checkout, run the checks, use the nested development session, and contribute."
category: Project
order: 20
icon: code-xml
---

This guide covers working on Hyprism from a clone. The [architecture guide](architecture.md) explains how the pieces fit together and describes every directory.

## Setup

```bash
git clone https://github.com/kristyancarvalho/hyprism.git
cd hyprism
```

Nothing has to be compiled. QML, Python, Lua, and shell scripts run directly from the checkout. Running the tests needs `python3` with Pillow; the QML focus test also needs `qmltestrunner` from Qt 6 and is skipped when it is missing. The development session needs a running Hyprland desktop.

## Makefile targets

| Target | Purpose |
| --- | --- |
| `make check` | Run `lint` and `test`; run this before proposing a change |
| `make lint` | Syntax-check shell scripts, byte-compile Python, and validate the bundled JSON files |
| `make test` | Run the `unittest` suite in `tests/` |
| `make dev-session` | Run the checkout in a nested Hyprland window |
| `make dev-session-stop` | Stop a running development session |
| `make reload` | Reload the installed shell (`hyprism-shell reload`) |
| `make install`, `make install-ptbr`, `make update`, `make uninstall` | Repository install workflow; see [Installation](installation.md) |
| `make install-system` | Copy immutable files under `PREFIX` and `DESTDIR`; used by the AUR packages |
| `make website`, `make website-up`, `make website-down`, `make website-logs`, `make website-build` | Documentation website through Docker Compose |
| `make website-releases-sync` | Refresh the website release archive from GitHub |
| `make help` | List the targets |

## Tests

The suite in `tests/` checks the CLI against temporary configuration files, validates themes, translations, packaging, and documentation links, and inspects QML sources for required structure. `tests/test_lock_media_focus.py` runs a real QML interaction test: it clicks each lock screen media button and checks that `Return` still reaches the password handler. Run a single module with `python3 -m unittest tests.test_lockscreen`.

## Development session

`make dev-session` opens a nested Hyprland window inside your running Hyprland desktop and runs the current checkout in it. Nothing is installed and the parent session is not touched. Close the window, press `Ctrl+C`, or run `make dev-session-stop` to end it.

Requirements: `Hyprland`, `quickshell`, `awww`, `dbus`, `jq` and `python3`, and a running Wayland session. Missing commands are listed with exit status 127.

How it works:

- Hyprland starts with `config/hypr/hyprland.lua` from the checkout, and `HYPRISM_ROOT` points at the checkout so scripts, QML and wallpapers resolve to source files instead of `/usr/share/hyprism` or `~/.local/share/hyprism`. No build step is needed.
- The session runs under its own D-Bus session, a private `XDG_RUNTIME_DIR` (`$XDG_RUNTIME_DIR/hyprism-dev`), and private `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME` under `~/.cache/hyprism-dev` (override with `HYPRISM_DEV_DIR`). Its `user.json` is seeded from `config/user.json` once and then kept between runs.
- Wallpapers come from the repository `wallpapers/` directory.
- Only the processes in the session's own process group are stopped on exit; nothing is killed by name.

Logs are in `~/.cache/hyprism-dev/logs/session.log` and `~/.cache/hyprism-dev/cache/hyprism/quickshell-startup.log`.

### Debugging

The shell prints QML warnings and errors to `quickshell-startup.log`. Quickshell also keeps a per-run log under the session's runtime directory in `quickshell/by-id/`. Query the nested compositor with `hyprctl` by setting `XDG_RUNTIME_DIR` to `$XDG_RUNTIME_DIR/hyprism-dev` and `HYPRLAND_INSTANCE_SIGNATURE` to the directory name under its `hypr/` folder.

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

## Documentation website

The Astro website in `website/` reads Markdown directly from `docs/`; do not create a second copy under the website source tree. Add frontmatter for `title`, `description`, `category`, `order`, and optional `icon` to control document navigation and search. Categories group related guides in the sidebar and index. The filename becomes the page slug, including nested directories.

Link to another guide with a relative Markdown link such as `[Theming](theming.md)`. Refer to repository screenshots and video with paths relative to `docs/`, such as `../assets/screenshots/desktop.webp`; the website maps those paths to its local media URLs. The gallery is managed in `website/src/data/gallery.json`, with image alt text, caption, category, optional description, and `featured` metadata. Keep gallery media in `assets/`.

Run the local site through Docker Compose with `make website`; open `http://localhost:4321` and press `Ctrl+C` to stop the foreground server. Use `make website-down` to clean up its isolated Compose project. The port can be changed with `make website WEBSITE_PORT=4322`. `make website-up`, `make website-logs`, and `make website-build` provide detached, log, and production build workflows. Refresh the local release archive from GitHub with `make website-releases-sync`; builds and page views use only the checked-in release metadata. `SITE_URL` may be set for canonical URLs and populated sitemap entries when a public site domain is established.
