#!/usr/bin/env bash
# Reproducible, non-destructive Arch deployment for Hyprism.
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_user="${SUDO_USER:-${USER:-}}"
install_packages=1
dry_run=0
timestamp=$(date +%Y%m%d-%H%M%S)

usage() { printf 'Usage: %s [--user USER] [--no-packages] [--dry-run]\n' "$0"; }
while (($#)); do
  case "$1" in
    --user) target_user=${2:?--user requires USER}; shift 2 ;;
    --no-packages) install_packages=0; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

run() {
  if ((dry_run)); then printf '[dry-run] '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
}
as_user() {
  if [[ $(id -un) == "$target_user" ]]; then run env HOME="$target_home" "$@"; else run runuser -u "$target_user" -- env HOME="$target_home" "$@"; fi
}
backup_path() {
  local destination=$1 relative backup
  [[ -e $destination || -L $destination ]] || return 0
  [[ -L $destination && $(readlink -f "$destination" 2>/dev/null || true) == $(readlink -f "$2" 2>/dev/null || true) ]] && return 0
  relative=${destination#"$target_home"/}; backup="$target_home/.local/state/hyprism/backups/$timestamp/$relative"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$backup")"
  run mv "$destination" "$backup"
  printf 'Backed up %s to %s\n' "$destination" "$backup"
}
link_path() {
  local source=$1 destination=$2
  if [[ -L $destination && $(readlink -f "$destination" 2>/dev/null || true) == $(readlink -f "$source") ]]; then return; fi
  backup_path "$destination" "$source"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$destination")"
  run ln -s "$source" "$destination"
  ((dry_run)) || chown -h "$target_user:$target_group" "$destination"
}
package_lines() { sed -E '/^[[:space:]]*(#|$)/d' "$1"; }

[[ -r /etc/arch-release ]] || { printf 'Hyprism supports Arch Linux only.\n' >&2; exit 1; }
command -v pacman >/dev/null || { printf 'pacman is required.\n' >&2; exit 1; }
[[ -n $target_user ]] || { printf 'Unable to determine desktop user; pass --user.\n' >&2; exit 1; }
passwd_entry=$(getent passwd "$target_user" || true)
[[ -n $passwd_entry ]] || { printf 'Unknown user: %s\n' "$target_user" >&2; exit 1; }
target_home=$(cut -d: -f6 <<<"$passwd_entry")
target_group=$(id -gn "$target_user")
[[ -d $target_home ]] || { printf 'Home directory does not exist: %s\n' "$target_home" >&2; exit 1; }

if ((install_packages)); then
  [[ $(id -u) -eq 0 ]] || { printf 'Run with sudo to install packages, or use --no-packages.\n' >&2; exit 1; }
  mapfile -t official < <(package_lines "$repo_dir/packages/pacman.txt")
  mapfile -t missing < <(pacman -T "${official[@]}" 2>/dev/null || true)
  if ((${#missing[@]})); then run pacman -S --needed --noconfirm "${missing[@]}"; else printf 'Official packages are already installed.\n'; fi
  mapfile -t aur < <(package_lines "$repo_dir/packages/aur.txt")
  if ((${#aur[@]})); then
    helper=$(command -v paru || command -v yay || true)
    [[ -n $helper ]] || { printf 'AUR packages listed but neither paru nor yay is installed. Install one, then rerun.\n' >&2; exit 1; }
    as_user "$helper" -S --needed --noconfirm "${aur[@]}"
  fi
fi

run install -d -o "$target_user" -g "$target_group" "$target_home/.config" "$target_home/.local/bin" "$target_home/.local/share" "$target_home/Imagens/Wallpapers" "$target_home/Imagens/Screenshots"
link_path "$repo_dir" "$target_home/.local/share/hyprism"
link_path "$repo_dir/config/hypr" "$target_home/.config/hypr"
link_path "$repo_dir/config/quickshell" "$target_home/.config/quickshell"
link_path "$repo_dir/config/user.json" "$target_home/.config/hyprism/user.json"
link_path "$repo_dir/config/kitty/kitty.conf" "$target_home/.config/kitty/kitty.conf"
link_path "$repo_dir/config/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
link_path "$repo_dir/config/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
link_path "$repo_dir/config/qt6ct/qt6ct.conf" "$target_home/.config/qt6ct/qt6ct.conf"
link_path "$repo_dir/config/environment.d/90-hyprism.conf" "$target_home/.config/environment.d/90-hyprism.conf"

link_path "$repo_dir/scripts/wallpaper" "$target_home/.local/bin/hyprism-wallpaper"
link_path "$repo_dir/scripts/system/action" "$target_home/.local/bin/hyprism-action"
link_path "$repo_dir/scripts/system/hyprism-launch" "$target_home/.local/bin/hyprism-launch"
link_path "$repo_dir/scripts/system/reload-shell" "$target_home/.local/bin/hyprism-reload-shell"

for image in "$repo_dir"/wallpapers/*.{png,jpg,jpeg,webp}; do
  [[ -f $image ]] || continue
  destination="$target_home/Imagens/Wallpapers/$(basename "$image")"
  if [[ ! -e $destination ]]; then run install -m 0644 -o "$target_user" -g "$target_group" "$image" "$destination"; fi
done

if ((dry_run == 0)); then
  chmod +x "$repo_dir/install.sh" "$repo_dir/scripts/wallpaper" "$repo_dir"/scripts/theme/*.py "$repo_dir"/scripts/system/*
  first_wallpaper=$(find -P "$target_home/Imagens/Wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print -quit)
  [[ -n ${first_wallpaper:-} ]] && as_user env HYPRISM_ROOT="$repo_dir" "$repo_dir/scripts/wallpaper" set "$first_wallpaper" || printf 'No wallpaper available yet; palette will be generated on first selection.\n'
  if command -v systemctl >/dev/null && [[ $(id -u) -eq 0 ]]; then
    systemctl enable NetworkManager.service bluetooth.service 2>/dev/null || true
  fi
fi

missing=()
for command in hyprland quickshell kitty matugen awww wl-copy cliphist nmcli wpctl grim slurp; do command -v "$command" >/dev/null || missing+=("$command"); done
printf '\nHyprism installed for %s.\n' "$target_user"
printf 'Config: %s/.config/{hypr,quickshell,kitty}\n' "$target_home"
printf 'Wallpapers: %s/Imagens/Wallpapers\nScreenshots: %s/Imagens/Screenshots\n' "$target_home" "$target_home"
if ((${#missing[@]})); then printf 'Missing executables: %s\n' "${missing[*]}"; else printf 'All core executables validated.\n'; fi
printf 'Log out and select/reload Hyprland, or run hyprctl reload inside a session.\n'
