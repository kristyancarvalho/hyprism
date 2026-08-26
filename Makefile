SHELL := /usr/bin/bash
USER_NAME ?= $(shell id -un)
LANG := en
SUDO ?= sudo

.PHONY: install install-ptbr update uninstall check test lint reload help

install:
	$(SUDO) ./install.sh --user "$(USER_NAME)" --lang "$(LANG)"

install-ptbr:
	$(MAKE) install LANG=pt-BR

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
	  'update        Reapply Hyprism while preserving user configuration' \
	  'uninstall     Remove and archive Hyprism-managed files' \
	  'check         Run lint and tests' \
	  'test          Run the automated test suite' \
	  'lint          Validate scripts, Python, and JSON' \
	  'reload        Reload the running Quickshell instance' \
	  'help          Show this help'
