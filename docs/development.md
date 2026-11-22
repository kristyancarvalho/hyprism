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
