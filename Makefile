SHELL := /usr/bin/bash
USER_NAME ?= $(shell id -un)
LANG := en
SUDO ?= sudo

PREFIX ?= /usr/local
DESTDIR ?=
PACKAGE_NAME ?= hyprism-shell

.PHONY: install install-ptbr install-system update uninstall check test lint reload help

install:
	$(SUDO) ./install.sh --user "$(USER_NAME)" --lang "$(LANG)"

install-ptbr:
	$(MAKE) install LANG=pt-BR

install-system:
	install -d "$(DESTDIR)$(PREFIX)/bin" "$(DESTDIR)$(PREFIX)/share/hyprism" "$(DESTDIR)$(PREFIX)/share/licenses/$(PACKAGE_NAME)"
	cp -a config scripts themes wallpapers "$(DESTDIR)$(PREFIX)/share/hyprism/"
	find "$(DESTDIR)$(PREFIX)/share/hyprism" -type d -name __pycache__ -prune -exec rm -rf -- {} +
	install -m 0755 scripts/hyprism-shell "$(DESTDIR)$(PREFIX)/bin/hyprism-shell"
	install -m 0644 LICENSE "$(DESTDIR)$(PREFIX)/share/licenses/$(PACKAGE_NAME)/LICENSE"

update:
	$(SUDO) ./install.sh --user "$(USER_NAME)" --lang en --no-packages

uninstall:
	$(SUDO) ./uninstall.sh --user "$(USER_NAME)"

check: lint test

test:
	python3 -m unittest discover -s tests -v

lint:
	bash -n install.sh uninstall.sh scripts/wallpaper scripts/hyprism-shell scripts/system/action scripts/system/brightness-ddc scripts/system/install-colloid-theme scripts/system/install-google-sans-flex scripts/system/lock scripts/system/move-or-scroll scripts/system/publish-json scripts/system/recording-backend scripts/system/reload-shell scripts/system/shell-ipc scripts/system/start-shell scripts/system/validate-hyprlock
	python3 -m py_compile scripts/hyprism-shell scripts/theme/generate-theme.py scripts/system/*.py
	python3 -m json.tool config/user.json >/dev/null
	python3 -m json.tool config/quickshell/i18n/en.json >/dev/null
	python3 -m json.tool config/quickshell/i18n/pt-BR.json >/dev/null

reload:
	hyprism-shell reload

help:
	@printf '%s\n' \
	  'install       Install Hyprism in English (LANG may override)' \
	  'install-ptbr  Install Hyprism in Brazilian Portuguese' \
	  'install-system Install immutable files under PREFIX with optional DESTDIR' \
	  'update        Reapply Hyprism while preserving user configuration' \
	  'uninstall     Remove and archive Hyprism-managed files' \
	  'check         Run lint and tests' \
	  'test          Run the automated test suite' \
	  'lint          Validate scripts, Python, and JSON' \
	  'reload        Reload the running Quickshell instance' \
	  'help          Show this help'
