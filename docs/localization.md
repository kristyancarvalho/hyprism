---
title: Localization
description: "Switch the interface between English and Brazilian Portuguese."
category: Guides
order: 8
icon: languages
---

# Localization

English is the default for fresh installations. Brazilian Portuguese is available through `make install-ptbr` or `make install LANG=pt-BR`. Updates preserve a valid existing language choice.

The running interface can switch languages without a logout:

```bash
hyprism-shell language
hyprism-shell language set en
hyprism-shell language set pt-BR
```

The same setting selects the login screen language. `hyprism-shell language set` rewrites the `language=` line of `/var/lib/hyprism/sddm/theme.conf` for the next SDDM session; its strings live in `themes/hyprism-pixie/Main.qml`.

Translations live in `config/quickshell/i18n/`. English is the canonical catalog and missing values fall back to English.
