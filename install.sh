#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_user="${SUDO_USER:-${USER:-}}"
install_packages=1
dry_run=0
timestamp="$(date +%Y%m%d-%H%M%S)-$$"

usage() { printf 'Uso: %s [--user USUÁRIO] [--no-packages] [--dry-run]\n' "$0"; }
while (($#)); do
  case "$1" in
    --user) target_user=${2:?--user exige um usuário}; shift 2 ;;
    --no-packages) install_packages=0; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

run() {
  if ((dry_run)); then printf '[simulação] '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
}
as_user() {
  if [[ $(id -un) == "$target_user" ]]; then run env HOME="$target_home" "$@"; else run runuser -u "$target_user" -- env HOME="$target_home" "$@"; fi
}
backup_path() {
  local destination=$1 source=${2:-} relative backup
  [[ -e $destination || -L $destination ]] || return 0
  [[ -n $source && -L $destination && $(readlink -f "$destination" 2>/dev/null || true) == $(readlink -f "$source" 2>/dev/null || true) ]] && return 0
  relative=${destination#"$target_home"/}; backup="$target_home/.local/state/hyprism/backups/$timestamp/$relative"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$backup")"
  run mv "$destination" "$backup"
  printf 'Backup criado: %s → %s\n' "$destination" "$backup"
}
link_path() {
  local source=$1 destination=$2
  if [[ -L $destination && $(readlink -f "$destination" 2>/dev/null || true) == $(readlink -f "$source") ]]; then return; fi
  backup_path "$destination" "$source"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$destination")"
  run ln -s "$source" "$destination"
  ((dry_run)) || chown -h "$target_user:$target_group" "$destination"
}
verify_link() {
  local source=$1 destination=$2
  [[ -L $destination ]] || { printf 'O link simbólico esperado não foi criado: %s\n' "$destination" >&2; exit 1; }
  [[ $(readlink -f "$destination") == $(readlink -f "$source") ]] \
    || { printf 'O destino do link simbólico está incorreto: %s\n' "$destination" >&2; exit 1; }
}
package_lines() { sed -E '/^[[:space:]]*(#|$)/d' "$1"; }

[[ -r /etc/arch-release ]] || { printf 'O Hyprism oferece suporte apenas ao Arch Linux.\n' >&2; exit 1; }
command -v pacman >/dev/null || { printf 'O pacman é obrigatório.\n' >&2; exit 1; }
[[ -n $target_user ]] || { printf 'Não foi possível determinar o usuário; use --user.\n' >&2; exit 1; }
passwd_entry=$(getent passwd "$target_user" || true)
[[ -n $passwd_entry ]] || { printf 'Usuário desconhecido: %s\n' "$target_user" >&2; exit 1; }
target_home=$(cut -d: -f6 <<<"$passwd_entry")
target_group=$(id -gn "$target_user")
[[ -d $target_home ]] || { printf 'A pasta pessoal não existe: %s\n' "$target_home" >&2; exit 1; }

if ((install_packages)); then
  [[ $(id -u) -eq 0 ]] || { printf 'Execute com sudo para instalar pacotes ou use --no-packages.\n' >&2; exit 1; }
  mapfile -t official < <(package_lines "$repo_dir/packages/pacman.txt")
  run pacman -Syu --needed --noconfirm "${official[@]}"
  mapfile -t aur < <(package_lines "$repo_dir/packages/aur.txt")
  if ((${#aur[@]})); then
    helper=$(command -v paru || command -v yay || true)
    [[ -n $helper ]] || { printf 'Há pacotes AUR, mas paru e yay não estão instalados. Instale um deles e tente novamente.\n' >&2; exit 1; }
    as_user "$helper" -S --needed --noconfirm "${aur[@]}"
  fi
fi

runtime_root="$target_home/.local/share/hyprism"
quickshell_parent="$target_home/.config/quickshell"
quickshell_config="$quickshell_parent/hyprism"
quickshell_default="$quickshell_parent/default"

run install -d -o "$target_user" -g "$target_group" "$target_home/.config" "$target_home/.local/bin" "$target_home/.local/share" "$target_home/Imagens/Wallpapers" "$target_home/Imagens/Screenshots"
backup_path "$runtime_root"
run install -d -o "$target_user" -g "$target_group" "$runtime_root/config" "$runtime_root/scripts"
run cp -a "$repo_dir/config/." "$runtime_root/config/"
run cp -a "$repo_dir/scripts/." "$runtime_root/scripts/"
if ((dry_run == 0)); then
  chown -R "$target_user:$target_group" "$runtime_root"
  chmod +x "$runtime_root/scripts/wallpaper" "$runtime_root"/scripts/theme/*.py "$runtime_root"/scripts/system/*
fi

locale -a 2>/dev/null | grep -Eiq '^C\.UTF-?8$|^C\.utf8$|^en_US\.UTF-?8$' \
  || { printf 'O sistema precisa oferecer ao menos um locale UTF-8.\n' >&2; exit 1; }

font_dir="$target_home/.local/share/fonts/google-sans-flex"
font_regular="$font_dir/GoogleSansFlex-Regular.ttf"
font_medium="$font_dir/GoogleSansFlex-Medium.ttf"
font_semibold="$font_dir/GoogleSansFlex-SemiBold.ttf"
if [[ ! -s $font_regular || ! -s $font_medium || ! -s $font_semibold ]]; then
  as_user "$runtime_root/scripts/system/install-google-sans-flex"
else
  printf 'Google Sans Flex já está instalada.\n'
fi

for image in "$repo_dir"/wallpapers/*.{png,jpg,jpeg,webp}; do
  [[ -f $image ]] || continue
  destination="$target_home/Imagens/Wallpapers/$(basename "$image")"
  if [[ ! -e $destination ]]; then run install -m 0644 -o "$target_user" -g "$target_group" "$image" "$destination"; fi
done

colloid_revision=9bf9fc5a5974ae0659f59a4281aae6f594c95bdd
colloid_theme="$target_home/.local/share/themes/Colloid-Hyprism-Dark-Compact"
if [[ ! -s $colloid_theme/gtk-3.0/gtk.css || ! -s $colloid_theme/gtk-4.0/gtk.css || $(cat "$colloid_theme/.hyprism-revision" 2>/dev/null || true) != "$colloid_revision" ]]; then
  as_user env XDG_DATA_HOME="$target_home/.local/share" "$runtime_root/scripts/system/install-colloid-theme"
else
  printf 'Colloid-Hyprism já está instalado.\n'
fi

if [[ -L $quickshell_parent ]]; then backup_path "$quickshell_parent"; fi
run install -d -o "$target_user" -g "$target_group" "$quickshell_parent"

link_path "$runtime_root/config/hypr" "$target_home/.config/hypr"
link_path "$runtime_root/config/quickshell" "$quickshell_default"
link_path "$runtime_root/config/quickshell" "$quickshell_config"
link_path "$runtime_root/config/user.json" "$target_home/.config/hyprism/user.json"
link_path "$runtime_root/config/foot/foot.ini" "$target_home/.config/foot/foot.ini"
link_path "$runtime_root/config/kitty/kitty.conf" "$target_home/.config/kitty/kitty.conf"
link_path "$runtime_root/config/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
link_path "$runtime_root/config/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
link_path "$runtime_root/config/qt5ct/qt5ct.conf" "$target_home/.config/qt5ct/qt5ct.conf"
link_path "$runtime_root/config/qt6ct/qt6ct.conf" "$target_home/.config/qt6ct/qt6ct.conf"
link_path "$runtime_root/config/Kvantum/kvantum.kvconfig" "$target_home/.config/Kvantum/kvantum.kvconfig"
link_path "$runtime_root/config/environment.d/90-hyprism.conf" "$target_home/.config/environment.d/90-hyprism.conf"

link_path "$runtime_root/scripts/wallpaper" "$target_home/.local/bin/hyprism-wallpaper"
link_path "$runtime_root/scripts/system/action" "$target_home/.local/bin/hyprism-action"
link_path "$runtime_root/scripts/system/reload-shell" "$target_home/.local/bin/hyprism-reload-shell"
link_path "$runtime_root/scripts/system/start-shell" "$target_home/.local/bin/hyprism-start-shell"
link_path "$runtime_root/scripts/system/shell-ipc" "$target_home/.local/bin/hyprism-shell-ipc"

theme_dir="$target_home/.cache/hyprism/theme"
state_dir="$target_home/.cache/hyprism/state"
run install -d -o "$target_user" -g "$target_group" "$theme_dir" "$state_dir"
first_wallpaper=$(find -P "$target_home/Imagens/Wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print -quit)
if [[ ! -s $theme_dir/theme.json || ! -s $theme_dir/hyprlock-colors.conf || ! -s $theme_dir/gtk-3.0.css || ! -s $theme_dir/gtk-4.0.css || ! -s $theme_dir/kvantum/Hyprism/Hyprism.kvconfig || ! -s $theme_dir/icons/Hyprism-Papirus/index.theme || ! -e $state_dir/lock-wallpaper ]]; then
  if [[ -n ${first_wallpaper:-} ]]; then
    as_user env HYPRISM_ROOT="$runtime_root" "$runtime_root/scripts/wallpaper" set "$first_wallpaper"
  else
    as_user env HYPRISM_CACHE_DIR="$target_home/.cache/hyprism" "$runtime_root/scripts/theme/generate-theme.py"
  fi
fi
if [[ ! -s $theme_dir/foot.ini ]]; then
  run install -m 0644 -o "$target_user" -g "$target_group" "$runtime_root/config/foot/fallback.ini" "$theme_dir/foot.ini"
fi
if [[ ! -e $theme_dir/kitty.conf ]]; then
  run install -m 0644 -o "$target_user" -g "$target_group" /dev/null "$theme_dir/kitty.conf"
fi
link_path "$theme_dir/gtk-3.0.css" "$target_home/.config/gtk-3.0/gtk.css"
link_path "$theme_dir/gtk-4.0.css" "$target_home/.config/gtk-4.0/gtk.css"
link_path "$theme_dir/kvantum/Hyprism" "$target_home/.config/Kvantum/Hyprism"
link_path "$theme_dir/icons/Hyprism-Papirus" "$target_home/.local/share/icons/Hyprism-Papirus"

if ((dry_run == 0)); then
  as_user env HYPRISM_CACHE_DIR="$target_home/.cache/hyprism" "$runtime_root/scripts/system/validate-hyprlock" "$target_home/.config/hypr/hyprlock.conf"
fi

if ((dry_run == 0)) && command -v gsettings >/dev/null; then
  as_user gsettings set org.gnome.desktop.interface gtk-theme Colloid-Hyprism-Dark-Compact
  as_user gsettings set org.gnome.desktop.interface icon-theme Hyprism-Papirus
  as_user gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

if ((dry_run == 0)); then
  [[ -d $runtime_root && ! -L $runtime_root ]] \
    || { printf 'A cópia runtime está ausente ou ainda depende do clone.\n' >&2; exit 1; }
  verify_link "$runtime_root/config/hypr" "$target_home/.config/hypr"
  verify_link "$runtime_root/config/quickshell" "$quickshell_default"
  verify_link "$runtime_root/config/quickshell" "$quickshell_config"
  [[ -f $target_home/.config/hypr/hyprland.lua ]] \
    || { printf 'O ponto de entrada Lua do Hyprland não foi instalado.\n' >&2; exit 1; }
  [[ ! -e $target_home/.config/hypr/hyprland.conf ]] \
    || { printf 'Um ponto de entrada obsoleto do Hyprland ainda está instalado.\n' >&2; exit 1; }
  [[ -f $quickshell_default/shell.qml && -f $quickshell_config/shell.qml ]] \
    || { printf 'O ponto de entrada do Quickshell não foi instalado.\n' >&2; exit 1; }
  [[ -f $target_home/.config/foot/foot.ini && -s $theme_dir/foot.ini && -f $theme_dir/kitty.conf && -s $theme_dir/hyprlock-colors.conf ]] \
    || { printf 'A configuração ou um tema de fallback está ausente.\n' >&2; exit 1; }
  [[ -s $colloid_theme/gtk-3.0/gtk.css && -s $colloid_theme/gtk-4.0/gtk.css ]] \
    || { printf 'O tema Colloid-Hyprism não foi instalado.\n' >&2; exit 1; }
  [[ -s $target_home/.config/gtk-3.0/gtk.css && -s $target_home/.config/gtk-4.0/gtk.css && -s $target_home/.config/Kvantum/Hyprism/Hyprism.kvconfig && -s $target_home/.local/share/icons/Hyprism-Papirus/index.theme ]] \
    || { printf 'Os temas dinâmicos GTK ou Kvantum não foram publicados.\n' >&2; exit 1; }
  [[ -s $font_regular && -s $font_medium && -s $font_semibold ]] \
    || { printf 'A fonte Google Sans Flex não foi instalada.\n' >&2; exit 1; }
  [[ -d /usr/share/icons/Papirus-Dark && -d /usr/share/icons/Papirus ]] \
    || { printf 'O tema de ícones Papirus não foi instalado.\n' >&2; exit 1; }
  [[ -s $theme_dir/hyprlock-colors.conf && -e $state_dir/lock-wallpaper ]] \
    || { printf 'Os recursos iniciais do Hyprlock não foram gerados.\n' >&2; exit 1; }
  [[ $(as_user fc-match --format '%{family}\n' 'Google Sans Flex') == *"Google Sans Flex"* ]] \
    || { printf 'A fonte Google Sans Flex não foi indexada pelo Fontconfig.\n' >&2; exit 1; }
  [[ $(as_user fc-match --format '%{family}\n' 'Symbols Nerd Font Mono') == *"Symbols Nerd Font Mono"* ]] \
    || { printf 'A fonte de ícones Nerd Font não foi indexada pelo Fontconfig.\n' >&2; exit 1; }
fi

legacy_hypr_theme="$target_home/.cache/hyprism/theme/hyprland.conf"
if [[ -f $legacy_hypr_theme ]]; then
  legacy_backup="$target_home/.local/state/hyprism/backups/$timestamp/.cache/hyprism/theme/hyprland.conf"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$legacy_backup")"
  run mv "$legacy_hypr_theme" "$legacy_backup"
  printf 'Configuração obsoleta do Hyprland arquivada em %s\n' "$legacy_backup"
fi

if ((dry_run == 0)); then
  if command -v systemctl >/dev/null && [[ $(id -u) -eq 0 ]]; then
    systemctl enable NetworkManager.service bluetooth.service
  fi
fi

missing=()
for command in Hyprland hyprlock qs foot kitty matugen awww awww-daemon python3 jq curl git sassc kvantummanager qt5ct qt6ct fc-cache fc-match wl-copy wl-paste cliphist nmcli wpctl playerctl grim slurp hyprpicker brightnessctl wf-recorder hyprsunset powerprofilesctl; do command -v "$command" >/dev/null || missing+=("$command"); done
printf '\nHyprism instalado para %s.\n' "$target_user"
printf 'Configurações: %s/.config/{hypr,quickshell/default,quickshell/hyprism,foot,kitty,gtk-3.0,gtk-4.0,Kvantum,qt5ct,qt6ct}\n' "$target_home"
printf 'Papéis de parede: %s/Imagens/Wallpapers\nCapturas de tela: %s/Imagens/Screenshots\n' "$target_home" "$target_home"
if ((${#missing[@]})); then printf 'Executáveis ausentes: %s\n' "${missing[*]}" >&2; exit 1; else printf 'Todos os executáveis essenciais foram validados.\n'; fi
printf 'Encerre a sessão e selecione o Hyprland para iniciar.\n'
