#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_user="${SUDO_USER:-${USER:-}}"
install_packages=1
dry_run=0
install_language=en
timestamp="$(date +%Y%m%d-%H%M%S)-$$"

usage() { printf 'Usage: %s [--user USER] [--lang {en|pt-BR}] [--no-packages] [--dry-run]\n' "$0"; }
while (($#)); do
  case "$1" in
    --user) target_user=${2:?--user requires a user}; shift 2 ;;
    --lang) install_language=${2:?--lang requires a locale}; shift 2 ;;
    --no-packages) install_packages=0; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ $install_language == en || $install_language == pt-BR ]] || { printf 'Unsupported language: %s\n' "$install_language" >&2; exit 2; }

run() {
  if ((dry_run)); then printf '[dry-run] '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
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
  printf 'Backup created: %s → %s\n' "$destination" "$backup"
}
backup_copy() {
  local source=$1 relative backup
  [[ -e $source || -L $source ]] || return 0
  relative=${source#"$target_home"/}; backup="$target_home/.local/state/hyprism/backups/$timestamp/$relative"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$backup")"
  run cp -a "$source" "$backup"
  printf 'Backup created: %s → %s\n' "$source" "$backup"
}
ensure_user_line() {
  local destination=$1 line=$2
  [[ -f $destination ]] && grep -Fqx -- "$line" "$destination" && return 0
  backup_copy "$destination"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$destination")"
  as_user sh -c 'touch "$1"; if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then printf "\n" >> "$1"; fi; printf "%s\n" "$2" >> "$1"' sh "$destination" "$line"
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
  [[ -L $destination ]] || { printf 'Expected symbolic link was not created: %s\n' "$destination" >&2; exit 1; }
  [[ $(readlink -f "$destination") == $(readlink -f "$source") ]] \
    || { printf 'Symbolic link target is incorrect: %s\n' "$destination" >&2; exit 1; }
}
package_lines() { sed -E '/^[[:space:]]*(#|$)/d' "$1"; }
hyprlock_animations_current() {
  local candidate=$1 language=$2 animation check_text fail_text locked date_format
  [[ -s $candidate ]] || return 1
  if [[ $language == pt-BR ]]; then
    check_text='Autenticando…'
    fail_text='Senha incorreta'
    locked=Bloqueado
    date_format='%d/%m/%Y'
  else
    check_text='Authenticating…'
    fail_text='Incorrect password'
    locked=Locked
    date_format='%m/%d/%Y'
  fi
  grep -Fqx "    text = $locked" "$candidate" || return 1
  grep -Fqx "    text = cmd[update:60000] date +'$date_format'" "$candidate" || return 1
  grep -Fqx "    check_text = $check_text" "$candidate" || return 1
  grep -Fqx "    fail_text = $fail_text" "$candidate" || return 1
  grep -A7 '^animations {' "$candidate" | grep -Eq '^    enabled = true$' || return 1
  for animation in fadeIn fadeOut inputFieldFade inputFieldDots inputFieldColors; do
    grep -A7 '^animations {' "$candidate" | grep -Eq "^    animation = $animation, 1," || return 1
  done
}

[[ -r /etc/arch-release ]] || { printf 'Hyprism supports Arch Linux only.\n' >&2; exit 1; }
command -v pacman >/dev/null || { printf 'pacman is required.\n' >&2; exit 1; }
[[ -n $target_user ]] || { printf 'Could not determine the user; use --user.\n' >&2; exit 1; }
passwd_entry=$(getent passwd "$target_user" || true)
[[ -n $passwd_entry ]] || { printf 'Unknown user: %s\n' "$target_user" >&2; exit 1; }
target_home=$(cut -d: -f6 <<<"$passwd_entry")
target_group=$(id -gn "$target_user")
target_shell=$(basename "$(cut -d: -f7 <<<"$passwd_entry")")
[[ -d $target_home ]] || { printf 'Home directory does not exist: %s\n' "$target_home" >&2; exit 1; }
if ((dry_run == 0)) && [[ $(id -u) -ne 0 ]]; then
  printf 'Run the installer with sudo to configure SDDM safely.\n' >&2
  exit 1
fi

resolve_user_directory() {
  local kind=$1 fallback=$2 resolved=
  if ((dry_run == 0)) && command -v xdg-user-dir >/dev/null; then
    if [[ $(id -un) == "$target_user" ]]; then
      resolved=$(env HOME="$target_home" xdg-user-dir "$kind" 2>/dev/null || true)
    else
      resolved=$(runuser -u "$target_user" -- env HOME="$target_home" xdg-user-dir "$kind" 2>/dev/null || true)
    fi
  fi
  [[ $resolved == /* ]] || resolved=$fallback
  printf '%s\n' "$resolved"
}

if [[ $install_language == pt-BR ]]; then
  pictures_fallback="$target_home/Imagens"
  videos_fallback="$target_home/Vídeos"
  recordings_name=gravacoes
else
  pictures_fallback="$target_home/Pictures"
  videos_fallback="$target_home/Videos"
  recordings_name=Recordings
fi
pictures_dir=$(resolve_user_directory PICTURES "$pictures_fallback")
videos_dir=$(resolve_user_directory VIDEOS "$videos_fallback")

if ((install_packages)); then
  [[ $(id -u) -eq 0 ]] || { printf 'Run with sudo to install packages or use --no-packages.\n' >&2; exit 1; }
  mapfile -t official < <(package_lines "$repo_dir/packages/pacman.txt")
  run pacman -Syu --needed --noconfirm "${official[@]}"
  mapfile -t aur < <(package_lines "$repo_dir/packages/aur.txt")
  if ((${#aur[@]})); then
    helper=$(command -v paru || command -v yay || true)
    [[ -n $helper ]] || { printf 'AUR packages are required, but neither paru nor yay is installed. Install one and try again.\n' >&2; exit 1; }
    as_user "$helper" -S --needed --noconfirm "${aur[@]}"
  fi
fi

runtime_root="$target_home/.local/share/hyprism"
theme_dir="$target_home/.cache/hyprism/theme"
state_dir="$target_home/.cache/hyprism/state"
quickshell_parent="$target_home/.config/quickshell"
quickshell_config="$quickshell_parent/hyprism"
quickshell_default="$quickshell_parent/default"
existing_user_config=
installed_user_config="$target_home/.config/hyprism/user.json"
if ((dry_run == 0)) && [[ -s $installed_user_config ]]; then
  existing_user_config="$target_home/.cache/hyprism/.user-config-$timestamp.json"
  install -d -o "$target_user" -g "$target_group" "$(dirname "$existing_user_config")"
  install -m 0600 -o "$target_user" -g "$target_group" "$installed_user_config" "$existing_user_config"
fi

run install -d -o "$target_user" -g "$target_group" "$target_home/.config" "$target_home/.cache" "$target_home/.cache/hyprism" "$target_home/.local/bin" "$target_home/.local/share"
backup_path "$runtime_root"
run install -d -o "$target_user" -g "$target_group" "$runtime_root/config" "$runtime_root/scripts"
run cp -a "$repo_dir/config/." "$runtime_root/config/"
run cp -a "$repo_dir/scripts/." "$runtime_root/scripts/"
if ((dry_run == 0)); then
  chown -R "$target_user:$target_group" "$runtime_root"
  chmod +x "$runtime_root/scripts/hyprism-shell" "$runtime_root/scripts/wallpaper" "$runtime_root"/scripts/theme/*.py "$runtime_root"/scripts/system/*
fi
if ((dry_run == 0)); then
  migrate_arguments=(_migrate --language "$install_language")
  [[ -n $existing_user_config ]] && migrate_arguments+=(--existing "$existing_user_config")
  as_user env HYPRISM_ROOT="$runtime_root" HYPRISM_CONFIG="$runtime_root/config/user.json" HYPRISM_PICTURES_DIR="$pictures_dir" HYPRISM_VIDEOS_DIR="$videos_dir" "$runtime_root/scripts/hyprism-shell" "${migrate_arguments[@]}"
  [[ -z $existing_user_config ]] || run rm -f "$existing_user_config"
fi
wallpaper_dir="$pictures_dir/Wallpapers"
screenshot_dir="$pictures_dir/Screenshots"
recordings_dir="$videos_dir/$recordings_name"
if ((dry_run == 0)); then
  configured_wallpaper_dir=$(as_user jq -r '.paths.wallpapers // empty' "$runtime_root/config/user.json")
  configured_screenshot_dir=$(as_user jq -r '.paths.screenshots // empty' "$runtime_root/config/user.json")
  configured_recordings_dir=$(as_user jq -r '.paths.recordings // empty' "$runtime_root/config/user.json")
  [[ -z $configured_wallpaper_dir ]] || wallpaper_dir=${configured_wallpaper_dir/#\~/$target_home}
  [[ -z $configured_screenshot_dir ]] || screenshot_dir=${configured_screenshot_dir/#\~/$target_home}
  [[ -z $configured_recordings_dir ]] || recordings_dir=${configured_recordings_dir/#\~/$target_home}
fi
run install -d -o "$target_user" -g "$target_group" "$wallpaper_dir" "$screenshot_dir" "$recordings_dir"

sddm_theme_dir="/usr/share/sddm/themes/hyprism-ksddm"
sddm_state_dir="/var/lib/hyprism/sddm"
sddm_dropin="/etc/sddm.conf.d/20-hyprism.conf"
run install -d -m 0755 /var/lib/hyprism
run install -d -m 0755 -o "$target_user" -g "$target_group" "$sddm_state_dir"
run install -d -m 0755 "$sddm_theme_dir" /etc/sddm.conf.d
run rm -f "$sddm_theme_dir/theme.conf"
run cp -a "$repo_dir/themes/ksddm-hyprism/." "$sddm_theme_dir/"
run ln -sfn "$sddm_state_dir/theme.conf" "$sddm_theme_dir/theme.conf"
run install -m 0644 "$repo_dir/config/sddm/20-hyprism.conf" "$sddm_dropin"

locale -a 2>/dev/null | grep -Eiq '^C\.UTF-?8$|^C\.utf8$|^en_US\.UTF-?8$' \
  || { printf 'The system must provide at least one UTF-8 locale.\n' >&2; exit 1; }

font_dir="$target_home/.local/share/fonts/google-sans-flex"
font_regular="$font_dir/GoogleSansFlex-Regular.ttf"
font_medium="$font_dir/GoogleSansFlex-Medium.ttf"
font_semibold="$font_dir/GoogleSansFlex-SemiBold.ttf"
if [[ ! -s $font_regular || ! -s $font_medium || ! -s $font_semibold ]]; then
  as_user "$runtime_root/scripts/system/install-google-sans-flex"
else
  printf 'Google Sans Flex is already installed.\n'
fi
run install -d -m 0755 /usr/local/share/fonts/hyprism
run install -m 0644 "$font_regular" "$font_medium" "$font_semibold" /usr/local/share/fonts/hyprism/
if ((dry_run == 0)); then run fc-cache -f /usr/local/share/fonts/hyprism; fi

for image in "$repo_dir"/wallpapers/*.{png,jpg,jpeg,webp}; do
  [[ -f $image ]] || continue
  destination="$wallpaper_dir/$(basename "$image")"
  if [[ ! -e $destination ]]; then run install -m 0644 -o "$target_user" -g "$target_group" "$image" "$destination"; fi
done
if ! find -P "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print -quit | grep -q .; then
  command -v magick >/dev/null || { printf 'ImageMagick is required to create the initial wallpaper.\n' >&2; exit 1; }
  as_user magick -background none "$repo_dir/wallpapers/abyss.svg" "$wallpaper_dir/hyprism-abyss.png"
fi

colloid_revision=6c2dc65865628bda9fdc8157a30cd5eda6fd41f9
colloid_patch_hash=$(sha256sum "$runtime_root/config/matugen/colloid-matugen.patch" | cut -d' ' -f1)
appearance_mode=dark
if ((dry_run == 0)); then
  appearance_mode=$(as_user jq -r '.appearance.mode // "dark"' "$runtime_root/config/user.json")
fi
[[ $appearance_mode == dark || $appearance_mode == light ]] || appearance_mode=dark
if [[ $appearance_mode == light ]]; then colloid_name=Colloid-Hyprism-Light-Matugen; else colloid_name=Colloid-Hyprism-Dark-Matugen; fi
colloid_theme="$target_home/.local/share/themes/$colloid_name"

if [[ -L $quickshell_parent ]]; then backup_path "$quickshell_parent"; fi
run install -d -o "$target_user" -g "$target_group" "$quickshell_parent"

link_path "$runtime_root/config/hypr" "$target_home/.config/hypr"
link_path "$runtime_root/config/quickshell" "$quickshell_default"
link_path "$runtime_root/config/quickshell" "$quickshell_config"
link_path "$runtime_root/config/user.json" "$target_home/.config/hyprism/user.json"
link_path "$runtime_root/config/foot/foot.ini" "$target_home/.config/foot/foot.ini"
link_path "$runtime_root/config/kitty/kitty.conf" "$target_home/.config/kitty/kitty.conf"
link_path "$theme_dir/fastfetch/config.jsonc" "$target_home/.config/fastfetch/config.jsonc"
link_path "$runtime_root/config/fastfetch/images/archlinux.svg" "$target_home/.config/fastfetch/images/archlinux-source.svg"
link_path "$theme_dir/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
link_path "$theme_dir/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
link_path "$theme_dir/gtk-2.0/gtkrc" "$target_home/.gtkrc-2.0"
link_path "$runtime_root/config/qt5ct/qt5ct.conf" "$target_home/.config/qt5ct/qt5ct.conf"
link_path "$runtime_root/config/qt6ct/qt6ct.conf" "$target_home/.config/qt6ct/qt6ct.conf"
link_path "$runtime_root/config/Kvantum/kvantum.kvconfig" "$target_home/.config/Kvantum/kvantum.kvconfig"
link_path "$runtime_root/config/environment.d/90-hyprism.conf" "$target_home/.config/environment.d/90-hyprism.conf"
link_path "$runtime_root/config/systemd/user/hyprism-hyprsunset.service" "$target_home/.config/systemd/user/hyprism-hyprsunset.service"
if command -v flatpak >/dev/null; then
  as_user flatpak override --user --unset-env=QT_STYLE_OVERRIDE
fi
if [[ -s $theme_dir/nvim/matugen.lua ]]; then
  run install -m 0644 -o "$target_user" -g "$target_group" "$theme_dir/nvim/matugen.lua" "$runtime_root/config/nvim/lua/themes/matugen.lua"
fi
link_path "$runtime_root/config/nvim" "$target_home/.config/nvim"
link_path "$theme_dir/starship.toml" "$target_home/.config/starship.toml"
link_path "$theme_dir/tmux.conf" "$target_home/.config/tmux/theme.conf"
link_path "$theme_dir/zathura/zathurarc" "$target_home/.config/zathura/zathurarc"

backup_path "$target_home/.config/tmux/tmux.conf"
link_path "$runtime_root/config/tmux/tmux.conf" "$target_home/.tmux.conf"

case "$target_shell" in
  zsh)
    link_path "$runtime_root/config/shell/starship.zsh" "$target_home/.config/hyprism/starship.zsh"
    ensure_user_line "$target_home/.zshrc" 'source "$HOME/.config/hyprism/starship.zsh"'
    ;;
  bash)
    link_path "$runtime_root/config/shell/starship.bash" "$target_home/.config/hyprism/starship.bash"
    ensure_user_line "$target_home/.bashrc" 'source "$HOME/.config/hyprism/starship.bash"'
    ;;
  fish)
    link_path "$runtime_root/config/shell/starship.fish" "$target_home/.config/hyprism/starship.fish"
    ensure_user_line "$target_home/.config/fish/config.fish" 'source "$HOME/.config/hyprism/starship.fish"'
    ;;
  *) printf 'Shell %s kept without automatic Starship initialization.\n' "$target_shell" ;;
esac

link_path "$runtime_root/scripts/wallpaper" "$target_home/.local/bin/hyprism-wallpaper"
link_path "$runtime_root/scripts/system/action" "$target_home/.local/bin/hyprism-action"
link_path "$runtime_root/scripts/system/reload-shell" "$target_home/.local/bin/hyprism-reload-shell"
link_path "$runtime_root/scripts/system/start-shell" "$target_home/.local/bin/hyprism-start-shell"
link_path "$runtime_root/scripts/system/shell-ipc" "$target_home/.local/bin/hyprism-shell-ipc"
link_path "$runtime_root/scripts/system/lock" "$target_home/.local/bin/hyprism-lock"
link_path "$runtime_root/scripts/hyprism-shell" "$target_home/.local/bin/hyprism-shell"
link_path "$runtime_root/config/applications/hyprism-keyboard-setup.desktop" "$target_home/.local/share/applications/hyprism-keyboard-setup.desktop"

run install -d -o "$target_user" -g "$target_group" "$theme_dir" "$state_dir"
if [[ ! -s $theme_dir/fastfetch/logo-palette.json ]]; then
  backup_path "$target_home/.config/fastfetch/images/archlinux.png"
fi
first_wallpaper=$(find -P "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print -quit)
hyprlock_language=$install_language
if ((dry_run == 0)); then hyprlock_language=$(as_user jq -r '.language // "en"' "$runtime_root/config/user.json"); fi
if hyprlock_animations_current "$theme_dir/hyprlock.conf" "$hyprlock_language"; then hyprlock_animations_stale=0; else hyprlock_animations_stale=1; fi
if [[ ! -s $theme_dir/theme.json || ! -s $theme_dir/hyprtoolkit-colors.conf || ! -s $theme_dir/hyprlock-colors.conf || ! -s $theme_dir/hyprlock.conf || ! -s $theme_dir/gtk-3.0/settings.ini || ! -s $theme_dir/gtk-4.0/settings.ini || ! -s $theme_dir/gtk-2.0/gtkrc || $hyprlock_animations_stale -eq 1 || ! -s $theme_dir/colloid/_color-palette-matugen.scss || ! -s $theme_dir/colloid-gtk-4.0/gtk.css || ! -s $colloid_theme/gtk-3.0/gtk.css || $(cat "$colloid_theme/.hyprism-revision" 2>/dev/null || true) != "$colloid_revision" || $(cat "$colloid_theme/.hyprism-patch.sha256" 2>/dev/null || true) != "$colloid_patch_hash" || ! -s $theme_dir/kvantum/Hyprism/Hyprism.kvconfig || ! -s $theme_dir/icons/Hyprism-Papirus/index.theme || ! -s $theme_dir/starship.toml || ! -s $theme_dir/tmux.conf || ! -s $theme_dir/zathura/zathurarc || ! -s $theme_dir/nvim/matugen.lua || ! -s $target_home/.config/nvim/lua/themes/matugen.lua || ! -s $theme_dir/fastfetch/config.jsonc || ! -s $target_home/.config/fastfetch/images/archlinux.png || ! -e $state_dir/lock-wallpaper || ! -s $sddm_state_dir/current-wallpaper.jpg || ! -s $sddm_state_dir/theme.conf ]]; then
  if [[ -n ${first_wallpaper:-} ]]; then
    as_user env HYPRISM_ROOT="$runtime_root" HYPRISM_SDDM_STATE_DIR="$sddm_state_dir" "$runtime_root/scripts/wallpaper" set "$first_wallpaper"
  else
    as_user env HYPRISM_CACHE_DIR="$target_home/.cache/hyprism" HYPRISM_SDDM_STATE_DIR="$sddm_state_dir" "$runtime_root/scripts/theme/generate-theme.py"
  fi
fi
if [[ ! -s $theme_dir/foot.ini ]]; then
  run install -m 0644 -o "$target_user" -g "$target_group" "$runtime_root/config/foot/fallback.ini" "$theme_dir/foot.ini"
fi
if [[ ! -e $theme_dir/kitty.conf ]]; then
  run install -m 0644 -o "$target_user" -g "$target_group" /dev/null "$theme_dir/kitty.conf"
fi

tpm_revision=e261deb1b47614eed3400089ce7197dc68acc4eb
tpm_dir="$target_home/.tmux/plugins/tpm"
tpm_head=$(as_user git -C "$tpm_dir" rev-parse HEAD 2>/dev/null || true)
if [[ ! -x $tpm_dir/tpm || $tpm_head != "$tpm_revision" ]]; then
  backup_path "$tpm_dir"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$tpm_dir")"
  as_user git init --quiet "$tpm_dir"
  as_user git -C "$tpm_dir" remote add origin https://github.com/tmux-plugins/tpm.git
  as_user env GIT_TERMINAL_PROMPT=0 git -C "$tpm_dir" fetch --quiet --depth 1 origin "$tpm_revision"
  as_user git -C "$tpm_dir" checkout --quiet --detach FETCH_HEAD
fi
if ((dry_run == 0)); then
  [[ -x $tpm_dir/tpm && $(as_user git -C "$tpm_dir" rev-parse HEAD 2>/dev/null || true) == "$tpm_revision" ]] \
    || { printf 'TPM was not installed at the expected revision.\n' >&2; exit 1; }
  if as_user tmux list-sessions >/dev/null 2>&1; then
    as_user tmux source-file "$target_home/.tmux.conf"
  fi
  as_user "$tpm_dir/bin/install_plugins"
fi

if [[ -L $target_home/.config/gtk-3.0/gtk.css && $(readlink "$target_home/.config/gtk-3.0/gtk.css") == "$theme_dir/gtk-3.0.css" ]]; then
  backup_path "$target_home/.config/gtk-3.0/gtk.css"
fi
link_path "$theme_dir/colloid-gtk-4.0/gtk.css" "$target_home/.config/gtk-4.0/gtk.css"
link_path "$theme_dir/colloid-gtk-4.0/assets" "$target_home/.config/gtk-4.0/assets"
link_path "$theme_dir/kvantum/Hyprism" "$target_home/.config/Kvantum/Hyprism"
link_path "$theme_dir/icons/Hyprism-Papirus" "$target_home/.local/share/icons/Hyprism-Papirus"

if ((dry_run == 0)); then
  as_user env HYPRISM_CACHE_DIR="$target_home/.cache/hyprism" "$runtime_root/scripts/system/validate-hyprlock" "$target_home/.config/hypr/hyprlock.conf"
fi

if ((dry_run == 0)) && command -v gsettings >/dev/null; then
  as_user gsettings set org.gnome.desktop.interface gtk-theme "$colloid_name"
  as_user gsettings set org.gnome.desktop.interface icon-theme Hyprism-Papirus
  as_user gsettings set org.gnome.desktop.interface color-scheme "prefer-$appearance_mode"
fi

if ((dry_run == 0)); then
  browser_desktop=
  while IFS= read -r desktop_file; do
    if grep -Eq '^Type=Application$' "$desktop_file" && grep -Eq '^Exec=.*(/|^)zen-(bin|browser)([[:space:]]|$)' "$desktop_file"; then
      browser_desktop=$(basename "$desktop_file")
      break
    fi
  done < <(find /usr/local/share/applications /usr/share/applications -maxdepth 1 -type f -name '*.desktop' -print 2>/dev/null)
  [[ -n $browser_desktop ]] || { printf 'The installed Zen desktop entry was not found.\n' >&2; exit 1; }
  as_user xdg-settings set default-web-browser "$browser_desktop"
  for scheme in http https; do
    as_user xdg-settings set default-url-scheme-handler "$scheme" "$browser_desktop"
  done
  for mime in text/html x-scheme-handler/http x-scheme-handler/https; do
    as_user xdg-mime default "$browser_desktop" "$mime"
  done
  user_runtime="/run/user/$(id -u "$target_user")"
  if [[ -S $user_runtime/bus ]]; then
    as_user env XDG_RUNTIME_DIR="$user_runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$user_runtime/bus" systemctl --user daemon-reload
  fi
fi

if command -v systemctl >/dev/null; then
  for legacy_polkit_service in plasma-polkit-agent.service polkit-kde-agent.service; do
    as_user systemctl --user disable --no-reload "$legacy_polkit_service" 2>/dev/null || true
  done
  as_user systemctl --user enable --no-reload hyprpolkitagent.service
  if ((dry_run == 0)) && [[ -S ${user_runtime:-}/bus ]]; then
    for legacy_polkit_service in plasma-polkit-agent.service polkit-kde-agent.service; do
      as_user env XDG_RUNTIME_DIR="$user_runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$user_runtime/bus" systemctl --user stop "$legacy_polkit_service" 2>/dev/null || true
    done
    as_user pkill -f -- '^/usr/lib/polkit-kde-authentication-agent-1([[:space:]]|$)' 2>/dev/null || true
    as_user env XDG_RUNTIME_DIR="$user_runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$user_runtime/bus" systemctl --user start hyprpolkitagent.service
  fi
fi

if ((dry_run == 0)); then
  [[ -d $runtime_root && ! -L $runtime_root ]] \
    || { printf 'The runtime copy is missing or still depends on the clone.\n' >&2; exit 1; }
  verify_link "$runtime_root/config/hypr" "$target_home/.config/hypr"
  verify_link "$runtime_root/config/quickshell" "$quickshell_default"
  verify_link "$runtime_root/config/quickshell" "$quickshell_config"
  verify_link "$runtime_root/scripts/hyprism-shell" "$target_home/.local/bin/hyprism-shell"
  verify_link "$theme_dir/fastfetch/config.jsonc" "$target_home/.config/fastfetch/config.jsonc"
  verify_link "$theme_dir/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
  verify_link "$theme_dir/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
  verify_link "$theme_dir/gtk-2.0/gtkrc" "$target_home/.gtkrc-2.0"
  verify_link "$runtime_root/config/applications/hyprism-keyboard-setup.desktop" "$target_home/.local/share/applications/hyprism-keyboard-setup.desktop"
  verify_link "$runtime_root/config/fastfetch/images/archlinux.svg" "$target_home/.config/fastfetch/images/archlinux-source.svg"
  verify_link "$runtime_root/config/tmux/tmux.conf" "$target_home/.tmux.conf"
  verify_link "$runtime_root/config/systemd/user/hyprism-hyprsunset.service" "$target_home/.config/systemd/user/hyprism-hyprsunset.service"
  [[ -f $target_home/.config/hypr/hyprland.lua ]] \
    || { printf 'The Hyprland Lua entry point was not installed.\n' >&2; exit 1; }
  [[ ! -e $target_home/.config/hypr/hyprland.conf ]] \
    || { printf 'An obsolete Hyprland entry point is still installed.\n' >&2; exit 1; }
  [[ -f $quickshell_default/shell.qml && -f $quickshell_config/shell.qml ]] \
    || { printf 'The Quickshell entry point was not installed.\n' >&2; exit 1; }
  [[ -f $target_home/.config/foot/foot.ini && -s $theme_dir/foot.ini && -f $theme_dir/kitty.conf && -s $target_home/.config/hypr/hyprtoolkit.conf && -s $theme_dir/hyprtoolkit-colors.conf && -s $theme_dir/hyprlock-colors.conf && -s $theme_dir/hyprlock.conf ]] \
    || { printf 'The configuration or a fallback theme is missing.\n' >&2; exit 1; }
  [[ -s $target_home/.config/starship.toml && -s $target_home/.config/tmux/theme.conf && -s $target_home/.config/zathura/zathurarc && -s $target_home/.config/nvim/init.lua && -s $target_home/.config/nvim/lua/themes/matugen.lua ]] \
    || { printf 'The theme development environment was not installed.\n' >&2; exit 1; }
  [[ -x $tpm_dir/tpm && -d $target_home/.tmux/plugins/tmux-sensible && -d $target_home/.tmux/plugins/tmux-yank && -d $target_home/.tmux/plugins/tmux-resurrect && -d $target_home/.tmux/plugins/tmux-continuum ]] \
    || { printf 'TPM or its declared plugins were not installed.\n' >&2; exit 1; }
  [[ -s $target_home/.config/fastfetch/config.jsonc && -s $target_home/.config/fastfetch/images/archlinux.png && -s $target_home/.config/fastfetch/images/archlinux-source.svg ]] \
    || { printf 'The Fastfetch theme preset was not installed.\n' >&2; exit 1; }
  ! grep -ERqs '{{colors\.|{{hyprism\.' "$target_home/.config/starship.toml" "$target_home/.config/tmux/theme.conf" "$target_home/.config/zathura/zathurarc" "$target_home/.config/nvim/lua/themes/matugen.lua" "$target_home/.config/fastfetch/config.jsonc" \
    || { printf 'The development environment contains unresolved Matugen values.\n' >&2; exit 1; }
  [[ -s $colloid_theme/gtk-3.0/gtk.css && -s $colloid_theme/gtk-4.0/gtk.css ]] \
    || { printf 'The Colloid-Hyprism theme was not installed.\n' >&2; exit 1; }
  [[ -s $target_home/.config/gtk-4.0/gtk.css && -d $target_home/.config/gtk-4.0/assets && -s $target_home/.config/Kvantum/Hyprism/Hyprism.kvconfig && -s $target_home/.local/share/icons/Hyprism-Papirus/index.theme ]] \
    || { printf 'The dynamic libadwaita or Kvantum themes were not published.\n' >&2; exit 1; }
  [[ -s $font_regular && -s $font_medium && -s $font_semibold ]] \
    || { printf 'The Google Sans Flex font was not installed.\n' >&2; exit 1; }
  [[ -d /usr/share/icons/Papirus-Dark && -d /usr/share/icons/Papirus ]] \
    || { printf 'The Papirus icon theme was not installed.\n' >&2; exit 1; }
  [[ -s $theme_dir/hyprlock-colors.conf && -e $state_dir/lock-wallpaper ]] \
    || { printf 'The initial Hyprlock resources were not generated.\n' >&2; exit 1; }
  [[ -s $sddm_theme_dir/Main.qml && -s $sddm_theme_dir/SessionIdentity.qml && -s $sddm_theme_dir/metadata.desktop && -L $sddm_theme_dir/theme.conf && -s $sddm_state_dir/theme.conf && -s $sddm_state_dir/current-wallpaper.jpg && -s $sddm_dropin ]] \
    || { printf 'The dynamic SDDM theme was not installed correctly.\n' >&2; exit 1; }
  [[ -d /usr/lib/qt6/qml/QtQuick/VirtualKeyboard ]] \
    || { printf 'The SDDM virtual keyboard was not installed.\n' >&2; exit 1; }
  [[ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]] \
    || { printf 'The PolicyKit authentication agent was not installed.\n' >&2; exit 1; }
  as_user systemctl --user is-enabled --quiet hyprpolkitagent.service \
    || { printf 'The PolicyKit authentication agent was not enabled.\n' >&2; exit 1; }
  grep -qx 'InputMethod=qtvirtualkeyboard' "$sddm_dropin" \
    || { printf 'The SDDM virtual input method was not configured.\n' >&2; exit 1; }
  [[ $(stat -c '%U:%G:%a' "$sddm_state_dir") == "$target_user:$target_group:755" ]] \
    || { printf 'The dynamic SDDM state permissions are invalid.\n' >&2; exit 1; }
  [[ $(as_user fc-match --format '%{family}\n' 'Google Sans Flex') == *"Google Sans Flex"* ]] \
    || { printf 'The Google Sans Flex font was not indexed by Fontconfig.\n' >&2; exit 1; }
  [[ $(as_user fc-match --format '%{family}\n' 'Symbols Nerd Font Mono') == *"Symbols Nerd Font Mono"* ]] \
    || { printf 'The Nerd Font icon font was not indexed by Fontconfig.\n' >&2; exit 1; }
fi

legacy_hypr_theme="$target_home/.cache/hyprism/theme/hyprland.conf"
if [[ -f $legacy_hypr_theme ]]; then
  legacy_backup="$target_home/.local/state/hyprism/backups/$timestamp/.cache/hyprism/theme/hyprland.conf"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$legacy_backup")"
  run mv "$legacy_hypr_theme" "$legacy_backup"
  printf 'Legacy Hyprland configuration archived at %s\n' "$legacy_backup"
fi

if ((dry_run == 0)); then
  if command -v systemctl >/dev/null && [[ $(id -u) -eq 0 ]]; then
    systemctl enable NetworkManager.service bluetooth.service sddm.service
  fi
fi

missing=()
for command in Hyprland hyprlock qs foot kitty fastfetch matugen starship tmux nvim awww awww-daemon python3 jq curl git sassc magick kvantummanager qt5ct qt6ct fc-cache fc-match wl-copy wl-paste cliphist nmcli wpctl playerctl grim slurp hyprpicker brightnessctl ddcutil wf-recorder hyprsunset zen-browser xdg-settings powerprofilesctl sddm-greeter-qt6 flatpak zathura; do command -v "$command" >/dev/null || missing+=("$command"); done
effective_language=$install_language
if ((dry_run == 0)) && [[ -s $runtime_root/config/user.json ]]; then
  effective_language=$(as_user jq -r '.language // "en"' "$runtime_root/config/user.json")
fi
printf '\nHyprism installed for %s.\n' "$target_user"
printf 'Language: %s\n' "$effective_language"
printf 'Configuration: %s/.config/{hypr,quickshell/default,quickshell/hyprism,foot,kitty,gtk-3.0,gtk-4.0,Kvantum,qt5ct,qt6ct}\n' "$target_home"
printf 'Wallpapers: %s\nScreenshots: %s\n' "$wallpaper_dir" "$screenshot_dir"
printf 'Recordings: %s\nLogin theme: %s\nSDDM wallpaper: %s/current-wallpaper.jpg\n' "$recordings_dir" "$sddm_theme_dir" "$sddm_state_dir"
printf 'Starship: %s/.config/starship.toml\ntmux: %s/.tmux.conf (TPM at %s/.tmux/plugins)\nNvChad: %s/.config/nvim\n' "$target_home" "$target_home" "$target_home" "$target_home"
printf 'Fastfetch: %s/.config/fastfetch/config.jsonc\nFastfetch logo: %s/.config/fastfetch/images/archlinux.png\n' "$target_home" "$target_home"
printf 'Keyboard setup: hyprism-shell keyboard setup\n'
if ((${#missing[@]})); then printf 'Missing executables: %s\n' "${missing[*]}" >&2; exit 1; else printf 'All essential executables were validated.\n'; fi
printf 'Log out and select Hyprland to start.\n'
