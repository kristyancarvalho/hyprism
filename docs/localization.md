# Localization

English is the default for fresh installations. Brazilian Portuguese is available through `make install-ptbr` or `make install LANG=pt-BR`. Updates preserve a valid existing language choice.

The running interface can switch languages without a logout:

```bash
hyprism-shell language
hyprism-shell language set en
hyprism-shell language set pt-BR
```

Translations live in `config/quickshell/i18n/`. English is the canonical catalog and missing values fall back to English.
