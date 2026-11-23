# Hyprism Pixie SDDM

This theme vendors the Qt 6 implementation from [xCaptaiN09/pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm), imported from upstream commit `1e1a863761f742e8d509d569382b17c112e29fdc` on `main`. Hyprism maintains a hosted fork at [kristyancarvalho/pixie-sddm](https://github.com/kristyancarvalho/pixie-sddm), with the original Pixie repository as its parent and `upstream` remote.

The original Pixie MIT license and copyright notice are kept in `LICENSE`. `Main.qml`, `components/Clock.qml`, and `components/PowerBar.qml` are Pixie-derived. Hyprism changes include palette and wallpaper configuration, session logos and matching, explicit SDDM authentication and user selection, capability-gated power controls, and Qt 6 Virtual Keyboard support.

No KSDDM or SilentSDDM source is reused. The former Hyprism theme was separately GPL-3.0-or-later licensed; its session matching approach was reimplemented without copying its code. The old license is not applied to this Pixie-derived code.

## Bundled artwork

| Asset | Source | License |
| --- | --- | --- |
| Hyprland, dwm, KDE Plasma, GNOME, XFCE, Sway, i3, awesomeWM, bspwm, Cinnamon | [Simple Icons](https://github.com/simple-icons/simple-icons) | CC0 1.0 |
| Qtile | [qtile/qtile](https://github.com/qtile/qtile), `libqtile/resources/logo.png` | MIT |
| LXQt | [lxqt/lxqt-themes](https://github.com/lxqt/lxqt-themes), `graphics/helix.svg` | CC BY-SA 3.0; artwork metadata credits Giacomo Barazzetti; LXQt credits the original design to Caig |
| LXDE | [lxde/lxde.github.io](https://github.com/lxde/lxde.github.io), `images/lxde-logo.svg` | CC BY 3.0; the source file has no named creator metadata |
| MATE | [MATE logo](https://commons.wikimedia.org/wiki/File:Mate-logo.svg), from mate-desktop.org | Public domain per Wikimedia Commons |
| Unknown session | `assets/logos/desktop.svg` | Hyprism, MIT |

The dwl project does not publish a distinct logo in its upstream source. Its session name is recognized and uses the neutral desktop mark instead of displaying a different project's logo.

The bundled Flex Rounded font files are retained from Pixie's imported tree. Their source and attribution are part of the upstream Pixie repository; they are not Hyprism-created assets. The Material Design Icons font is distributed under Apache 2.0; its license is included in `licenses/Apache-2.0.txt`. The LXDE and LXQt artwork license texts are included under `licenses/`.
