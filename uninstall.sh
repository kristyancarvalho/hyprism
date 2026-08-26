#!/usr/bin/env bash
set -Eeuo pipefail

target_user="${SUDO_USER:-${USER:-}}"
dry_run=0
timestamp="$(date +%Y%m%d-%H%M%S)-$$"

usage() { printf 'Usage: %s [--user USER] [--dry-run]\n' "$0"; }
while (($#)); do
  case "$1" in
    --user) target_user=${2:?--user requires a user}; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

run() {
  if ((dry_run)); then printf '[dry-run] '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
}

[[ -n $target_user ]] || { printf 'Could not determine the user; use --user.\n' >&2; exit 1; }
entry=$(getent passwd "$target_user" || true)
[[ -n $entry ]] || { printf 'Unknown user: %s\n' "$target_user" >&2; exit 1; }
target_home=$(cut -d: -f6 <<<"$entry")
runtime_root="$target_home/.local/share/hyprism"
theme_root="$target_home/.cache/hyprism/theme"
backup_root="$target_home/.local/state/hyprism/uninstalled/$timestamp"

managed_links=(
  "$target_home/.config/hypr"
  "$target_home/.config/quickshell/default"
  "$target_home/.config/quickshell/hyprism"
  "$target_home/.config/hyprism/user.json"
  "$target_home/.config/foot/foot.ini"
  "$target_home/.config/kitty/kitty.conf"
  "$target_home/.config/fastfetch/config.jsonc"
  "$target_home/.config/fastfetch/images/archlinux-source.svg"
  "$target_home/.config/gtk-3.0/settings.ini"
  "$target_home/.config/gtk-4.0/settings.ini"
  "$target_home/.gtkrc-2.0"
  "$target_home/.config/qt5ct/qt5ct.conf"
  "$target_home/.config/qt6ct/qt6ct.conf"
  "$target_home/.config/Kvantum/kvantum.kvconfig"
  "$target_home/.config/environment.d/90-hyprism.conf"
  "$target_home/.config/systemd/user/hyprism-hyprsunset.service"
  "$target_home/.config/nvim"
  "$target_home/.config/starship.toml"
  "$target_home/.config/tmux/theme.conf"
  "$target_home/.config/zathura/zathurarc"
  "$target_home/.tmux.conf"
  "$target_home/.config/hyprism/starship.zsh"
  "$target_home/.config/hyprism/starship.bash"
  "$target_home/.config/hyprism/starship.fish"
  "$target_home/.config/gtk-4.0/gtk.css"
  "$target_home/.config/gtk-4.0/assets"
  "$target_home/.config/Kvantum/Hyprism"
  "$target_home/.local/share/icons/Hyprism-Papirus"
  "$target_home/.local/bin/hyprism-action"
  "$target_home/.local/bin/hyprism-lock"
  "$target_home/.local/bin/hyprism-reload-shell"
  "$target_home/.local/bin/hyprism-shell"
  "$target_home/.local/bin/hyprism-shell-ipc"
  "$target_home/.local/bin/hyprism-start-shell"
  "$target_home/.local/bin/hyprism-wallpaper"
)

if [[ -s $target_home/.config/hyprism/user.json ]]; then
  run install -d -o "$target_user" -g "$(id -gn "$target_user")" "$backup_root"
  run install -m 0600 -o "$target_user" -g "$(id -gn "$target_user")" "$target_home/.config/hyprism/user.json" "$backup_root/user.json"
fi

for path in "${managed_links[@]}"; do
  resolved=$(readlink -f "$path" 2>/dev/null || true)
  if [[ -L $path && ( $resolved == "$runtime_root"/* || $resolved == "$theme_root"/* ) ]]; then run unlink "$path"; fi
done

if [[ -d $runtime_root && ! -L $runtime_root ]]; then
  run install -d -o "$target_user" -g "$(id -gn "$target_user")" "$backup_root"
  run mv "$runtime_root" "$backup_root/runtime"
fi

if command -v systemctl >/dev/null; then
  if ((dry_run)); then
    run runuser -u "$target_user" -- systemctl --user disable --now hyprpolkitagent.service
    run runuser -u "$target_user" -- systemctl --user daemon-reload
  else
    runuser -u "$target_user" -- systemctl --user disable --now hyprpolkitagent.service >/dev/null 2>&1 || true
    runuser -u "$target_user" -- systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
fi
if [[ $(id -u) -eq 0 ]]; then
  run install -d -o "$target_user" -g "$(id -gn "$target_user")" "$backup_root"
  run rm -f /etc/sddm.conf.d/20-hyprism.conf
  [[ ! -d /usr/share/sddm/themes/hyprism-ksddm ]] || run mv /usr/share/sddm/themes/hyprism-ksddm "$backup_root/sddm-theme"
fi

if ((dry_run)); then
  printf 'Hyprism managed files would be removed. Preserved data would be stored at: %s\n' "$backup_root"
else
  printf 'Hyprism managed files were removed. Preserved data: %s\n' "$backup_root"
fi
