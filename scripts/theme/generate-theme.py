#!/usr/bin/env python3
import colorsys
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import xml.etree.ElementTree as ElementTree
from PIL import Image


HOME = pathlib.Path.home()
ROOT = pathlib.Path(os.environ.get("HYPRISM_ROOT", pathlib.Path(__file__).resolve().parents[2]))
CACHE = pathlib.Path(os.environ.get("HYPRISM_CACHE_DIR", HOME / ".cache/hyprism"))
OUT = CACHE / "theme"
COLLOID_TEMPLATE = ROOT / "config/matugen/templates/colloid-gtk-theme.scss"
MATUGEN_TEMPLATES = ROOT / "config/matugen/templates"
HYPRLOCK_BASE = ROOT / "config/hypr/hyprlock.conf"
KVANTUM_BASES = {
    "dark": pathlib.Path(os.environ.get("HYPRISM_KVANTUM_BASE_DARK", "/usr/share/Kvantum/KvArcDark")),
    "light": pathlib.Path(os.environ.get("HYPRISM_KVANTUM_BASE_LIGHT", "/usr/share/Kvantum/KvArc")),
}
PAPIRUS_BASE = pathlib.Path(os.environ.get("HYPRISM_PAPIRUS_BASE", "/usr/share/icons/Papirus"))
FALLBACK = {
    "background": "#091015",
    "foreground": "#e0e8ee",
    "accent": "#3ba7d9",
    "secondary": "#8ebbd8",
    "secondary_container": "#28495a",
    "inactive_border": "#304653",
    "error": "#e4777f",
}
SDDM_STATE = pathlib.Path(os.environ.get("HYPRISM_SDDM_STATE_DIR", "/var/lib/hyprism/sddm"))
SDDM_STATE_EXPLICIT = "HYPRISM_SDDM_STATE_DIR" in os.environ
NVIM_THEME = pathlib.Path(os.environ.get("HYPRISM_NVIM_THEME_PATH", HOME / ".config/nvim/lua/themes/matugen.lua"))
FASTFETCH_DIR = pathlib.Path(os.environ.get("HYPRISM_FASTFETCH_DIR", pathlib.Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "fastfetch"))
FASTFETCH_LOGO_SOURCE = ROOT / "config/fastfetch/images/archlinux.svg"


def write(path, value, mode=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = value.encode("utf-8")
    try:
        if path.is_file() and path.read_bytes() == encoded:
            return False
    except OSError:
        pass
    descriptor, temporary = tempfile.mkstemp(prefix=".hyprism-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(value)
            handle.flush()
            os.fsync(handle.fileno())
        if mode is not None:
            os.chmod(temporary, mode)
        os.replace(temporary, path)
        return True
    except BaseException:
        pathlib.Path(temporary).unlink(missing_ok=True)
        raise


def publish(path, value, validator=None):
    try:
        if not value.strip():
            raise ValueError("conteúdo vazio")
        if validator:
            validator(value)
        return write(path, value)
    except (OSError, ValueError, TypeError) as error:
        print(f"Tema do Hyprism: {path.name} preservado após falha ({error})", file=sys.stderr)
        return False


def json_text(value):
    serialized = json.dumps(value, indent=2, ensure_ascii=False) + "\n"
    json.loads(serialized)
    return serialized


def rgb(value):
    source = value.lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", source):
        raise ValueError(f"cor inválida: {value}")
    return tuple(int(source[index:index + 2], 16) for index in (0, 2, 4))


def hexrgb(value):
    return "#" + "".join(f"{max(0, min(255, round(channel))):02x}" for channel in value)


def mix(first, second, amount):
    return hexrgb(tuple(left * (1 - amount) + right * amount for left, right in zip(rgb(first), rgb(second))))


def luminance(value):
    channels = []
    for channel in rgb(value):
        normalized = channel / 255
        channels.append(normalized / 12.92 if normalized <= .04045 else ((normalized + .055) / 1.055) ** 2.4)
    return .2126 * channels[0] + .7152 * channels[1] + .0722 * channels[2]


def contrast(first, second):
    bright, dark = sorted((luminance(first), luminance(second)), reverse=True)
    return (bright + .05) / (dark + .05)


def accessible_text(candidate, background, target):
    if contrast(candidate, background) >= target:
        return candidate
    return mix(candidate, "#ffffff", .45)


def faithful_accent(candidate, background, target=3.2):
    red, green, blue = (channel / 255 for channel in rgb(candidate))
    hue, lightness, saturation = colorsys.rgb_to_hls(red, green, blue)
    minimum = .5 if saturation < .16 else .48
    adjusted_lightness = max(minimum, min(.72, lightness))
    adjusted_saturation = min(.84, saturation)
    adjusted = hexrgb(tuple(channel * 255 for channel in colorsys.hls_to_rgb(hue, adjusted_lightness, adjusted_saturation)))
    if contrast(adjusted, background) >= target:
        return adjusted
    for step in range(1, 22):
        corrected_lightness = min(.78, adjusted_lightness + step * .012)
        adjusted = hexrgb(tuple(channel * 255 for channel in colorsys.hls_to_rgb(hue, corrected_lightness, adjusted_saturation)))
        if contrast(adjusted, background) >= target:
            return adjusted
    return adjusted


def warning_color(candidate, background):
    red, green, blue = (channel / 255 for channel in rgb(candidate))
    _, lightness, saturation = colorsys.rgb_to_hls(red, green, blue)
    hue = 10 / 360
    adjusted_lightness = max(.53, min(.64, lightness))
    adjusted_saturation = max(.58, min(.76, saturation))
    adjusted = hexrgb(tuple(channel * 255 for channel in colorsys.hls_to_rgb(hue, adjusted_lightness, adjusted_saturation)))
    return faithful_accent(adjusted, background, 3.2)


def wallpaper_source_color(image):
    with Image.open(image) as wallpaper:
        preview = wallpaper.convert("RGB")
        preview.thumbnail((96, 96), Image.Resampling.LANCZOS)
        palette = preview.quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert("RGB")
        candidates = palette.getcolors(palette.width * palette.height) or []
    if not candidates:
        raise ValueError("imagem sem cores utilizáveis")
    def score(candidate):
        count, color = candidate
        _, saturation, value = colorsys.rgb_to_hsv(*(channel / 255 for channel in color))
        return count ** .65 * (.2 + saturation * 1.3) * (.35 + value)
    return hexrgb(max(candidates, key=score)[1])


def matugen_palette(image, mode):
    command = ["matugen", "image", image, "--source-color-index", "0", "-t", "scheme-content", "--dry-run", "--json", "hex"]
    result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=30)
    generated = json.loads(result.stdout)
    colors = generated["colors"]
    semantic = {
        "background": colors["background"][mode]["color"],
        "foreground": colors["on_surface"][mode]["color"],
        "accent": wallpaper_source_color(image) if mode == "dark" else colors["primary"][mode]["color"],
        "primary": colors["primary"][mode]["color"],
        "on_primary": colors["on_primary"][mode]["color"],
        "primary_container": colors["primary_container"][mode]["color"],
        "matugenSource": colors["source_color"][mode]["color"],
        "secondary": colors["secondary"][mode]["color"],
        "on_secondary": colors["on_secondary"][mode]["color"],
        "secondary_container": colors["secondary_container"][mode]["color"],
        "tertiary": colors["tertiary"][mode]["color"],
        "on_tertiary": colors["on_tertiary"][mode]["color"],
        "surface_low": colors["surface_container_low"][mode]["color"],
        "surface_container": colors["surface_container"][mode]["color"],
        "surface_high": colors["surface_container_high"][mode]["color"],
        "surface_highest": colors["surface_container_highest"][mode]["color"],
        "on_surface_variant": colors["on_surface_variant"][mode]["color"],
        "outline": colors["outline"][mode]["color"],
        "inactive_border": colors["outline_variant"][mode]["color"],
        "error": colors["error"][mode]["color"],
        "on_error": colors["on_error"][mode]["color"],
        "error_container": colors["error_container"][mode]["color"],
    }
    return semantic, generated


def light_contrast(candidate, background, target=3.2):
    if contrast(candidate, background) >= target:
        return candidate
    for step in range(1, 22):
        adjusted = mix(candidate, "#000000", step * .025)
        if contrast(adjusted, background) >= target:
            return adjusted
    return mix(candidate, "#000000", .55)


def theme_from(raw, image, mode):
    if mode == "light":
        background = raw["background"]
        foreground = raw["foreground"]
        accent = light_contrast(raw["primary"], background)
        secondary = light_contrast(raw["secondary"], background, 3.0)
        tertiary = light_contrast(raw["tertiary"], background, 3.0)
        error = light_contrast(raw["error"], background, 3.2)
        return {
            "mode": mode,
            "background": background,
            "surface": raw["surface_low"],
            "surfaceContainer": raw["surface_container"],
            "surfaceContainerHigh": raw["surface_high"],
            "surfaceContainerHighest": raw["surface_highest"],
            "surfaceVariant": raw["surface_container"],
            "surfaceElevated": raw["surface_high"],
            "surfaceHover": raw["surface_highest"],
            "surfaceActive": mix(accent, background, .82),
            "foreground": foreground,
            "onSurface": foreground,
            "mutedForeground": raw["on_surface_variant"],
            "onSurfaceVariant": raw["on_surface_variant"],
            "primary": accent,
            "onPrimary": raw["on_primary"],
            "secondary": secondary,
            "onSecondary": raw["on_secondary"],
            "tertiary": tertiary,
            "onTertiary": raw["on_tertiary"],
            "secondaryContainer": mix(secondary, background, .78),
            "inactiveBorder": raw["inactive_border"],
            "accent": accent,
            "accentForeground": raw["on_primary"],
            "accentDim": mix(accent, background, .82),
            "outline": raw["outline"],
            "border": raw["outline"],
            "borderSubtle": raw["inactive_border"],
            "borderNormal": raw["outline"],
            "borderFocused": accent,
            "error": error,
            "onError": raw["on_error"],
            "errorContainer": raw["error_container"],
            "onErrorContainer": foreground,
            "warning": light_contrast("#b33b18", background, 3.2),
            "success": light_contrast("#2e7d32", background, 3.2),
            "wallpaper": image,
            "sourceAccent": raw["accent"],
            "matugenSource": raw.get("matugenSource", raw["accent"]),
        }
    background = mix(raw["background"], "#000000", .62)
    foreground = accessible_text(raw["foreground"], background, 7)
    accent = faithful_accent(raw["accent"], background)
    secondary = faithful_accent(raw.get("secondary", accent), background, 3.0)
    tertiary = faithful_accent(raw.get("tertiary", secondary), background, 3.0)
    surface = mix(background, foreground, .075)
    surface_variant = mix(background, foreground, .145)
    outline = mix(background, foreground, .24)
    accent_foreground = background if contrast(accent, background) >= 4.5 else foreground
    secondary_foreground = background if contrast(secondary, background) >= 4.5 else foreground
    tertiary_foreground = background if contrast(tertiary, background) >= 4.5 else foreground
    error = accessible_text(raw.get("error", FALLBACK["error"]), background, 3.2)
    on_error = accessible_text(background, error, 4.5)
    return {
        "mode": mode,
        "background": background,
        "surface": surface,
        "surfaceContainer": surface_variant,
        "surfaceContainerHigh": mix(surface_variant, foreground, .04),
        "surfaceContainerHighest": mix(surface_variant, foreground, .08),
        "surfaceVariant": surface_variant,
        "surfaceElevated": mix(surface_variant, foreground, .04),
        "surfaceHover": mix(surface_variant, foreground, .08),
        "surfaceActive": mix(accent, background, .64),
        "foreground": foreground,
        "onSurface": foreground,
        "mutedForeground": mix(background, foreground, .55),
        "onSurfaceVariant": mix(background, foreground, .55),
        "primary": accent,
        "onPrimary": accent_foreground,
        "secondary": secondary,
        "onSecondary": secondary_foreground,
        "tertiary": tertiary,
        "onTertiary": tertiary_foreground,
        "secondaryContainer": raw.get("secondary_container", FALLBACK["secondary_container"]),
        "inactiveBorder": raw.get("inactive_border", FALLBACK["inactive_border"]),
        "accent": accent,
        "accentForeground": accent_foreground,
        "accentDim": mix(accent, background, .58),
        "outline": outline,
        "border": outline,
        "borderSubtle": mix(background, outline, .58),
        "borderNormal": outline,
        "borderFocused": accent,
        "error": error,
        "onError": on_error,
        "errorContainer": mix(error, background, .58),
        "onErrorContainer": foreground,
        "warning": warning_color(raw.get("error", FALLBACK["error"]), background),
        "success": faithful_accent("#45a66d", background, 3.2),
        "wallpaper": image,
        "sourceAccent": raw["accent"],
        "matugenSource": raw.get("matugenSource", raw["accent"]),
    }


def terminal_colors(theme):
    return [
        theme["background"], theme["error"], theme["success"], theme["warning"],
        theme["accent"], theme["secondary"], theme["accent"], theme["foreground"],
        theme["mutedForeground"], theme["error"], theme["success"], theme["warning"],
        theme["accent"], theme["secondary"], theme["accent"], theme["foreground"],
    ]


def render_kitty(theme):
    lines = [
        f'foreground {theme["foreground"]}',
        f'background {theme["background"]}',
        f'cursor {theme["accent"]}',
        f'cursor_text_color {theme["background"]}',
        f'selection_foreground {theme["foreground"]}',
        f'selection_background {theme["surfaceVariant"]}',
        f'url_color {theme["accent"]}',
        f'active_border_color {theme["accent"]}',
        f'inactive_border_color {theme["outline"]}',
    ]
    lines.extend(f"color{index} {color}" for index, color in enumerate(terminal_colors(theme)))
    return "\n".join(lines) + "\n"


def render_foot(theme):
    lines = [
        "[colors-dark]",
        f'foreground={theme["foreground"][1:]}',
        f'background={theme["background"][1:]}',
        f'cursor={theme["background"][1:]} {theme["accent"][1:]}',
        f'selection-foreground={theme["foreground"][1:]}',
        f'selection-background={theme["surfaceVariant"][1:]}',
        f'urls={theme["accent"][1:]}',
        "alpha=0.82",
    ]
    colors = terminal_colors(theme)
    lines.extend(f"regular{index}={color[1:]}" for index, color in enumerate(colors[:8]))
    lines.extend(f"bright{index}={color[1:]}" for index, color in enumerate(colors[8:]))
    return "\n".join(lines) + "\n"


def render_hyprland(theme):
    shadow = f'rgba({theme["onSurface"][1:]}2e)' if theme["mode"] == "light" else "rgba(0000006e)"
    return (
        "local theme = {\n"
        f'    secondary_container = "rgb({theme["secondaryContainer"][1:]})",\n'
        f'    inactive_border = "rgb({theme["inactiveBorder"][1:]})",\n'
        f'    shadow = "{shadow}",\n'
        "}\n\n"
        "return {\n"
        "    active_border = theme.secondary_container,\n"
        "    inactive_border = theme.inactive_border,\n"
        "    shadow = theme.shadow,\n"
        "}\n"
    )


def render_hyprtoolkit(theme):
    values = {
        "background": theme["background"],
        "base": theme["surface"],
        "alternate_base": theme["surfaceContainerHigh"],
        "text": theme["onSurface"],
        "bright_text": mix(theme["foreground"], "#000000" if theme["mode"] == "light" else "#ffffff", .18),
        "link_text": theme["primary"],
        "accent": theme["primary"],
        "accent_secondary": theme["secondary"],
    }
    return "".join(f"{name} = rgba({color[1:]}ff)\n" for name, color in values.items())


def render_hyprlock(theme):
    values = {
        "background": theme["background"],
        "surface": theme["surface"],
        "surface_active": theme["surfaceActive"],
        "foreground": theme["foreground"],
        "muted": theme["mutedForeground"],
        "accent": theme["accent"],
        "secondary": theme["secondary"],
        "error": theme["error"],
    }
    return "".join(f"$hyprism_{name} = rgb({color[1:]})\n" for name, color in values.items())


def render_hyprlock_config(theme):
    colors = render_hyprlock(theme)
    lines = []
    for line in HYPRLOCK_BASE.read_text(encoding="utf-8").splitlines():
        if line.startswith("$hyprism_"):
            continue
        if re.match(r"^    path\s*=", line):
            lines.append(f"    path = {CACHE / 'state/lock-wallpaper'}")
        else:
            lines.append(line)
    return colors + "\n" + "\n".join(lines) + "\n"


def render_sddm(theme):
    values = {
        "background": (SDDM_STATE / "current-wallpaper.jpg").resolve().as_uri(),
        "background-color": theme["background"],
        "surface-color": theme["surface"],
        "surface-container-color": theme["surfaceContainer"],
        "surface-container-high-color": theme["surfaceContainerHigh"],
        "surface-hover-color": theme["surfaceHover"],
        "foreground-color": theme["foreground"],
        "muted-color": theme["mutedForeground"],
        "primary-color": theme["primary"],
        "on-primary-color": theme["onPrimary"],
        "secondary-color": theme["secondary"],
        "tertiary-color": theme["tertiary"],
        "accent-color": theme["primary"],
        "accent-foreground-color": theme["onPrimary"],
        "error-color": theme["error"],
    }
    return "[General]\n" + "".join(f"{key}={value}\n" for key, value in values.items())


def publish_sddm(theme, image):
    if not SDDM_STATE.exists():
        if not SDDM_STATE_EXPLICIT:
            return False
        SDDM_STATE.mkdir(parents=True, exist_ok=True)
    if not SDDM_STATE.is_dir() or not os.access(SDDM_STATE, os.W_OK):
        print(f"Tema do Hyprism: estado do SDDM sem permissão de escrita em {SDDM_STATE}", file=sys.stderr)
        return False
    wallpaper = SDDM_STATE / "current-wallpaper.jpg"
    temporary_wallpaper = None
    try:
        if image:
            descriptor, temporary_wallpaper = tempfile.mkstemp(prefix=".current-wallpaper-", suffix=".jpg", dir=SDDM_STATE)
            os.close(descriptor)
            with Image.open(image) as source:
                source.seek(0)
                converted = source.convert("RGB")
                converted.save(temporary_wallpaper, format="JPEG", quality=94, optimize=True)
            with open(temporary_wallpaper, "rb") as handle:
                os.fsync(handle.fileno())
            with Image.open(temporary_wallpaper) as verification:
                verification.verify()
            os.chmod(temporary_wallpaper, 0o644)
            os.replace(temporary_wallpaper, wallpaper)
            temporary_wallpaper = None
        if not wallpaper.is_file() or not os.access(wallpaper, os.R_OK):
            raise ValueError("wallpaper legível ausente")
        write(SDDM_STATE / "theme.conf", render_sddm(theme), 0o644)
        return True
    except (OSError, ValueError) as error:
        if temporary_wallpaper:
            pathlib.Path(temporary_wallpaper).unlink(missing_ok=True)
        print(f"Tema do Hyprism: estado anterior do SDDM preservado após falha ({error})", file=sys.stderr)
        return False


def render_colloid(matugen, theme):
    template = COLLOID_TEMPLATE.read_text(encoding="utf-8")
    pattern = re.compile(r"\{\{colors\.([a-z0-9_]+)\.(light|dark)\.hex\}\}")

    def color(match):
        name, _ = match.groups()
        roles = {
            "primary": theme["accent"],
            "on_primary": theme["accentForeground"],
            "primary_container": theme["surfaceActive"],
            "on_primary_container": theme["foreground"],
            "background": theme["background"],
            "on_background": theme["foreground"],
            "surface": theme["background"],
            "on_surface": theme["foreground"],
            "surface_variant": theme["surfaceVariant"],
            "on_surface_variant": theme["mutedForeground"],
            "surface_container_lowest": theme["background"],
            "surface_container_low": theme["surface"],
            "surface_container": theme["surfaceContainer"],
            "surface_container_high": theme["surfaceContainerHigh"],
            "surface_container_highest": theme["surfaceContainerHighest"],
            "outline": theme["outline"],
            "outline_variant": theme["inactiveBorder"],
            "inverse_surface": theme["foreground"],
            "inverse_on_surface": theme["background"],
            "inverse_primary": theme["accentDim"],
            "secondary": theme["secondary"],
            "on_secondary": theme["onSecondary"],
            "secondary_container": theme["secondaryContainer"],
            "on_secondary_container": theme["foreground"],
            "tertiary": theme["tertiary"],
            "on_tertiary": theme["onTertiary"],
            "tertiary_container": theme["surfaceActive"],
            "on_tertiary_container": theme["foreground"],
            "error": theme["error"],
            "on_error": theme["onError"],
            "error_container": theme["errorContainer"],
            "on_error_container": theme["onErrorContainer"],
            "shadow": "#000000",
            "scrim": "#000000",
        }
        if name in roles:
            return roles[name]
        try:
            value = matugen["colors"][name][theme["mode"]]["color"]
        except (KeyError, TypeError) as error:
            raise ValueError(f"cor Matugen ausente: {name}.{theme['mode']}") from error
        rgb(value)
        return value

    rendered = pattern.sub(color, template)
    validate_colors(rendered)
    required = (
        "$accent-dark:", "$bg-dark:", "$surface-container-dark:",
        "$grey-050:", "$grey-950:", "$default-dark:",
    )
    if any(name not in rendered for name in required):
        raise ValueError("variáveis obrigatórias do Colloid ausentes")
    return rendered


def render_matugen_template(name, matugen, theme):
    template = (MATUGEN_TEMPLATES / name).read_text(encoding="utf-8")
    pattern = re.compile(r"\{\{colors\.([a-z0-9_]+)\.(light|dark|default)\.hex\}\}")
    fallback_roles = {
        "background": theme["background"],
        "primary": theme["accent"],
        "on_primary": theme["accentForeground"],
        "primary_container": theme["surfaceActive"],
        "on_primary_container": theme["foreground"],
        "secondary": theme["secondary"],
        "on_secondary": theme["background"],
        "secondary_container": theme["secondaryContainer"],
        "on_secondary_container": theme["foreground"],
        "tertiary": theme["success"],
        "on_tertiary": theme["background"],
        "tertiary_container": theme["surfaceActive"],
        "on_tertiary_container": theme["foreground"],
        "error": theme["error"],
        "on_error": theme["background"],
        "error_container": mix(theme["error"], theme["background"], .58),
        "on_error_container": theme["foreground"],
        "primary_fixed_dim": theme["accentDim"],
        "on_primary_fixed_variant": theme["foreground"],
        "surface": theme["background"],
        "surface_container_low": theme["surface"],
        "surface_container": theme["surfaceVariant"],
        "surface_container_high": theme["surfaceElevated"],
        "surface_container_highest": theme["surfaceHover"],
        "on_surface": theme["foreground"],
        "on_surface_variant": theme["mutedForeground"],
        "outline": theme["outline"],
        "outline_variant": theme["inactiveBorder"],
    }

    def color(match):
        role, mode = match.groups()
        if role in fallback_roles:
            return fallback_roles[role]
        try:
            variants = matugen["colors"][role]
            value = variants.get(theme["mode"], variants.get(mode, variants.get("default")))["color"]
        except (KeyError, TypeError, AttributeError):
            if role not in fallback_roles:
                raise ValueError(f"cor Matugen ausente: {role}.{mode}")
            value = fallback_roles[role]
        rgb(value)
        return value

    rendered = render_hyprism_values(pattern.sub(color, template), theme)
    validate_colors(rendered)
    return rendered


def render_hyprism_values(template, theme):
    pattern = re.compile(r"\{\{hyprism\.([A-Za-z0-9_]+)\}\}")

    def color(match):
        role = match.group(1)
        if role not in theme:
            raise ValueError(f"cor do Hyprism ausente: {role}")
        rgb(theme[role])
        return theme[role]

    rendered = pattern.sub(color, template)
    validate_colors(rendered)
    return rendered


def render_hyprism_template(name, theme):
    template = (MATUGEN_TEMPLATES / name).read_text(encoding="utf-8")
    return render_hyprism_values(template, theme)


def validate_fastfetch(content):
    validate_colors(content)
    config = json.loads(content)
    logo = config.get("logo", {})
    if logo.get("type") != "kitty-icat" or logo.get("source") != "~/.config/fastfetch/images/archlinux.png":
        raise ValueError("logo de imagem do Fastfetch ausente")
    modules = {module if isinstance(module, str) else module.get("type") for module in config.get("modules", [])}
    required = {"title", "os", "kernel", "uptime", "packages", "shell", "wm", "terminal", "memory", "disk", "theme", "command", "custom"}
    if not required.issubset(modules):
        raise ValueError("módulos obrigatórios do Fastfetch ausentes")


def validate_png(path):
    with Image.open(path) as image:
        image.verify()
    with Image.open(path) as image:
        if image.format != "PNG" or image.width < 256 or image.height < 256:
            raise ValueError("imagem PNG do Fastfetch inválida")
        rgba = image.convert("RGBA")
        alpha_minimum, alpha_maximum = rgba.getchannel("A").getextrema()
        if alpha_minimum != 0 or alpha_maximum == 0 or rgba.getbbox() is None:
            raise ValueError("transparência do logo do Fastfetch inválida")


def render_fastfetch_logo(theme):
    content = FASTFETCH_LOGO_SOURCE.read_text(encoding="utf-8")
    source = "#1793d1"
    if content.lower().count(source) != 1:
        raise ValueError("preenchimento monocromático do logo ausente")
    content = re.sub(re.escape(source), theme["accent"], content, flags=re.IGNORECASE)
    ElementTree.fromstring(content)
    return content, {"fill": theme["accent"]}


def publish_fastfetch_logo(theme):
    target = FASTFETCH_DIR / "images/archlinux.png"
    stamp = OUT / "fastfetch/logo-palette.json"
    temporary = None
    try:
        rendered, colors = render_fastfetch_logo(theme)
        signature = json_text(colors)
        if stamp.is_file() and stamp.read_text(encoding="utf-8") == signature and target.is_file():
            try:
                validate_png(target)
            except (OSError, ValueError):
                pass
            else:
                return False
        executable = shutil.which("magick")
        if not executable:
            raise ValueError("ImageMagick ausente")
        target.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary = tempfile.mkstemp(prefix=".archlinux-", suffix=".png", dir=target.parent)
        os.close(descriptor)
        result = subprocess.run(
            [executable, "-background", "none", "svg:-", "-resize", "640x640", f"PNG32:{temporary}"],
            input=rendered,
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
        if result.returncode != 0:
            raise ValueError((result.stderr or result.stdout).strip() or "falha no ImageMagick")
        validate_png(temporary)
        with open(temporary, "rb") as handle:
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, target)
        temporary = None
        try:
            write(stamp, signature)
        except OSError as error:
            print(f"Tema do Hyprism: estado de cores do Fastfetch não foi salvo ({error})", file=sys.stderr)
        return True
    except (OSError, ValueError, subprocess.SubprocessError, ElementTree.ParseError) as error:
        if temporary:
            pathlib.Path(temporary).unlink(missing_ok=True)
        print(f"Tema do Hyprism: logo anterior do Fastfetch preservado após falha ({error})", file=sys.stderr)
        return False


def validate_starship(content):
    validate_colors(content)
    tomllib.loads(content)


def validate_nvchad(content):
    validate_colors(content)
    if "M.base_30" not in content or "M.base_16" not in content or not content.rstrip().endswith("return M"):
        raise ValueError("tema NvChad incompleto")


def reload_tmux(path):
    executable = shutil.which("tmux")
    if not executable or os.environ.get("HYPRISM_SKIP_TMUX_RELOAD") == "1":
        return
    try:
        sessions = subprocess.run([executable, "list-sessions"], capture_output=True, text=True, timeout=3, check=False)
        if sessions.returncode != 0:
            return
        result = subprocess.run([executable, "source-file", str(path)], capture_output=True, text=True, timeout=5, check=False)
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()
            raise ValueError(detail or "tmux rejeitou o tema")
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        print(f"Tema do Hyprism: tmux ativo preservado após falha ({error})", file=sys.stderr)


def update_colloid(palette_path, mode):
    if os.environ.get("HYPRISM_SKIP_COLLOID") == "1":
        print("Tema do Hyprism: compilação do Colloid ignorada neste ambiente")
        return
    command = [str(ROOT / "scripts/system/install-colloid-theme"), str(palette_path), mode]
    result = subprocess.run(command, capture_output=True, text=True, check=False, timeout=300)
    if result.returncode == 0:
        if result.stdout.strip():
            print(result.stdout.strip())
        return
    print("Tema do Hyprism: falha ao atualizar o GTK; tema anterior preservado", file=sys.stderr)
    details = (result.stderr or result.stdout).strip().splitlines()[-12:]
    for line in details:
        print(f"  {line}", file=sys.stderr)


def papirus_output_name(name):
    if name == "folder-blue.svg":
        return "folder.svg"
    if name.startswith("folder-blue-"):
        return "folder-" + name[len("folder-blue-"):]
    if name == "user-blue-home.svg":
        return "user-home.svg"
    if name == "user-blue-desktop.svg":
        return "user-desktop.svg"
    return ""


def papirus_sources():
    if not PAPIRUS_BASE.is_dir():
        raise ValueError(f"Papirus ausente em {PAPIRUS_BASE}")
    sources = []
    for path in PAPIRUS_BASE.rglob("*.svg"):
        output_name = papirus_output_name(path.name)
        if output_name and path.parent.name == "places":
            sources.append((path, path.parent.parent.name, output_name))
    if not sources:
        raise ValueError("assets de pasta do Papirus não encontrados")
    return sources


def render_papirus_svg(content, theme):
    replacements = {
        "#5294e2": theme["accent"],
        "#4877b1": mix(theme["accent"], "#000000", .18),
        "#1d344f": mix(theme["accent"], "#000000", .62),
    }
    for source, destination in replacements.items():
        content = re.sub(re.escape(source), destination, content, flags=re.IGNORECASE)
    ElementTree.fromstring(content)
    return content


def papirus_index(directories, mode):
    lines = [
        "[Icon Theme]",
        "Name=Hyprism-Papirus",
        "Comment=Pastas Papirus com o acento dinâmico do Hyprism",
        "Inherits=" + ("Papirus-Dark,Papirus,hicolor" if mode == "dark" else "Papirus,hicolor"),
        "Example=folder",
        "Directories=" + ",".join(f"{directory}/places" for directory in directories),
        "",
    ]
    for directory in directories:
        size_text = directory.split("x", 1)[0]
        size = int(size_text) if size_text.isdigit() else 16
        scale = 2 if directory.endswith("@2x") else 1
        lines.extend([
            f"[{directory}/places]",
            "Context=Places",
            f"Size={size}",
            f"Scale={scale}",
            "Type=Fixed",
            "",
        ])
    return "\n".join(lines)


def publish_papirus(theme):
    icon_root = OUT / "icons"
    icon_root.mkdir(parents=True, exist_ok=True)
    temporary = pathlib.Path(tempfile.mkdtemp(prefix=".Hyprism-Papirus-", dir=icon_root))
    try:
        directories = set()
        exact_hits = 0
        for source, directory, output_name in papirus_sources():
            destination = temporary / directory / "places" / output_name
            destination.parent.mkdir(parents=True, exist_ok=True)
            rendered = render_papirus_svg(source.read_text(encoding="utf-8"), theme)
            exact_hits += rendered.lower().count(theme["accent"].lower())
            destination.write_text(rendered, encoding="utf-8")
            directories.add(directory)
        if exact_hits == 0:
            raise ValueError("o acento exato não foi aplicado aos ícones")
        (temporary / "index.theme").write_text(papirus_index(sorted(directories), theme["mode"]), encoding="utf-8")
        cache_tool = shutil.which("gtk-update-icon-cache")
        if cache_tool:
            subprocess.run([cache_tool, "-f", "-t", str(temporary)], check=True, capture_output=True, timeout=30)
        link_candidate = icon_root / f".Hyprism-Papirus-link-{os.getpid()}"
        link_candidate.symlink_to(temporary.name)
        os.replace(link_candidate, icon_root / "Hyprism-Papirus")
        generations = sorted((path for path in icon_root.glob(".Hyprism-Papirus-*") if path.is_dir()), key=lambda path: path.stat().st_mtime, reverse=True)
        for previous in generations[2:]:
            shutil.rmtree(previous)
        return True
    except (OSError, ValueError, subprocess.SubprocessError, ElementTree.ParseError) as error:
        shutil.rmtree(temporary, ignore_errors=True)
        print(f"Tema do Hyprism: Papirus preservado após falha ({error})", file=sys.stderr)
        return False


def replace_ini_value(content, key, value):
    pattern = rf"(?m)^{re.escape(key)}=.*$"
    replacement = f"{key}={value}"
    return re.sub(pattern, replacement, content) if re.search(pattern, content) else content + replacement + "\n"


def render_kvantum(theme):
    base = KVANTUM_BASES[theme["mode"]]
    name = "KvArcDark" if theme["mode"] == "dark" else "KvArc"
    svg_path = base / f"{name}.svg"
    config_path = base / f"{name}.kvconfig"
    svg = svg_path.read_text(encoding="utf-8")
    config = config_path.read_text(encoding="utf-8")
    color_map = {
        "#5294e2": theme["accent"],
        "#58acff": theme["accent"],
        "#4693e6": theme["accent"],
        "#3176bf": theme["accentDim"],
        "#0582ff": theme["accent"],
        "#b74aff": theme["secondary"],
        "#f04a50": theme["error"],
        "#22252e": theme["background"],
        "#111217": theme["background"],
        "#383c4a": theme["surface"],
        "#404552": theme["surfaceVariant"],
        "#474d5d": theme["surfaceHover"],
        "#505666": theme["surfaceElevated"],
        "#4d5367": theme["outline"],
        "#3c404e": theme["surfaceVariant"],
        "#343844": theme["surface"],
        "#2d303b": theme["surface"],
        "#2f343f": theme["surfaceVariant"],
    }
    for source, destination in color_map.items():
        svg = re.sub(re.escape(source), destination, svg, flags=re.IGNORECASE)
    replacements = {
        "author": "Hyprism",
        "comment": "Tema dinâmico Hyprism baseado no motor KvArcDark",
        "layout_spacing": "6",
        "layout_margin": "8",
        "animate_states": "true",
        "window.color": theme["background"],
        "base.color": theme["surface"],
        "alt.base.color": theme["surfaceVariant"],
        "button.color": theme["surfaceVariant"],
        "light.color": theme["surfaceElevated"],
        "mid.light.color": theme["surfaceHover"],
        "dark.color": theme["background"],
        "mid.color": theme["outline"],
        "highlight.color": theme["accent"],
        "inactive.highlight.color": theme["accentDim"],
        "text.color": theme["foreground"],
        "window.text.color": theme["foreground"],
        "button.text.color": theme["foreground"],
        "disabled.text.color": theme["mutedForeground"],
        "tooltip.text.color": theme["foreground"],
        "highlight.text.color": theme["background"],
        "link.color": theme["accent"],
        "link.visited.color": theme["secondary"],
        "progress.indicator.text.color": theme["background"],
    }
    for key, value in replacements.items():
        config = replace_ini_value(config, key, value)
    colors = (
        "[ColorEffects:Disabled]\nColorAmount=0\nColorEffect=0\nContrastAmount=0.35\nContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n\n"
        "[Colors:Button]\n"
        f'BackgroundNormal={theme["surfaceVariant"]}\nForegroundNormal={theme["foreground"]}\nForegroundInactive={theme["mutedForeground"]}\n\n'
        "[Colors:Selection]\n"
        f'BackgroundNormal={theme["accent"]}\nForegroundNormal={theme["background"]}\n\n'
        "[Colors:View]\n"
        f'BackgroundNormal={theme["surface"]}\nForegroundNormal={theme["foreground"]}\nForegroundInactive={theme["mutedForeground"]}\n\n'
        "[Colors:Window]\n"
        f'BackgroundNormal={theme["background"]}\nForegroundNormal={theme["foreground"]}\nForegroundInactive={theme["mutedForeground"]}\n\n'
        "[General]\nColorScheme=Hyprism\nName=Hyprism\nshadeSortColumn=true\n\n"
        "[KDE]\ncontrast=4\n"
    )
    return svg, config, colors


def validate_colors(content):
    if re.search(r"undefined|null|NaN|\{\{", content, re.IGNORECASE):
        raise ValueError("valor não resolvido")


def validate_hyprtoolkit(content):
    validate_colors(content)
    names = "background|base|alternate_base|text|bright_text|link_text|accent|accent_secondary"
    if len(re.findall(rf"^({names}) = rgba\([0-9a-f]{{8}}\)$", content, re.MULTILINE)) != 8:
        raise ValueError("paleta do hyprtoolkit inválida")


def appearance_mode():
    config = pathlib.Path(os.environ.get("HYPRISM_CONFIG", HOME / ".config/hyprism/user.json"))
    try:
        value = json.loads(config.read_text(encoding="utf-8")).get("appearance", {}).get("mode", "dark")
    except (OSError, AttributeError, json.JSONDecodeError):
        value = "dark"
    return value if value in ("dark", "light") else "dark"


def fallback_palette(mode):
    if mode == "dark":
        return dict(FALLBACK, primary=FALLBACK["accent"], on_primary=FALLBACK["background"], primary_container="#28495a", on_secondary=FALLBACK["background"], on_tertiary=FALLBACK["background"], surface_low="#131b21", surface_container="#202b33", surface_high="#26333c", surface_highest="#2e3d47", on_surface_variant="#9aa8b2", outline="#426172", on_error=FALLBACK["background"], error_container="#592c32", tertiary=FALLBACK["secondary"])
    return {
        "background": "#f9f9ff", "foreground": "#191c20", "accent": "#37618e", "primary": "#37618e",
        "on_primary": "#ffffff", "primary_container": "#d1e4ff", "matugenSource": "#37618e",
        "secondary": "#515f74", "on_secondary": "#ffffff", "secondary_container": "#d5e3f8",
        "tertiary": "#695779", "on_tertiary": "#ffffff", "surface_low": "#f2f3fa",
        "surface_container": "#eceef5", "surface_high": "#e6e8ef", "surface_highest": "#e0e2e9",
        "on_surface_variant": "#42474e", "outline": "#72777f", "inactive_border": "#c2c7cf",
        "error": "#ba1a1a", "on_error": "#ffffff", "error_container": "#ffdad6",
    }


def render_gtk_settings(theme):
    name = f"Colloid-Hyprism-{'Light' if theme['mode'] == 'light' else 'Dark'}-Matugen"
    return (
        "[Settings]\n"
        f"gtk-application-prefer-dark-theme={1 if theme['mode'] == 'dark' else 0}\n"
        f"gtk-theme-name={name}\n"
        "gtk-icon-theme-name=Hyprism-Papirus\n"
        "gtk-font-name=Google Sans Flex 10\n"
    )


def render_gtk2_settings(theme):
    name = f"Colloid-Hyprism-{'Light' if theme['mode'] == 'light' else 'Dark'}-Matugen"
    return (
        f'gtk-theme-name="{name}"\n'
        'gtk-icon-theme-name="Hyprism-Papirus"\n'
        'gtk-font-name="Google Sans Flex 10"\n'
    )


def main():
    image = sys.argv[1] if len(sys.argv) > 1 else ""
    mode = appearance_mode()
    try:
        raw, matugen = matugen_palette(image, mode) if image else (fallback_palette(mode), {"fallback": True})
    except (OSError, KeyError, ValueError, json.JSONDecodeError, subprocess.SubprocessError) as error:
        print(f"Tema do Hyprism: o Matugen falhou ({error}); mantendo os artefatos atuais", file=sys.stderr)
        raise SystemExit(1)

    theme = theme_from(raw, image, mode)
    publish(OUT / "matugen.json", json_text(matugen), json.loads)
    publish(OUT / "theme.json", json_text(theme), json.loads)
    publish(OUT / "kitty.conf", render_kitty(theme), validate_colors)
    publish(OUT / "foot.ini", render_foot(theme), validate_colors)
    publish(OUT / "hyprland.lua", render_hyprland(theme), validate_colors)
    publish(OUT / "hyprtoolkit-colors.conf", render_hyprtoolkit(theme), validate_hyprtoolkit)
    publish(OUT / "hyprlock-colors.conf", render_hyprlock(theme), validate_colors)
    publish(OUT / "hyprlock.conf", render_hyprlock_config(theme), validate_colors)
    publish(OUT / "gtk-3.0/settings.ini", render_gtk_settings(theme), validate_colors)
    publish(OUT / "gtk-4.0/settings.ini", render_gtk_settings(theme), validate_colors)
    publish(OUT / "gtk-2.0/gtkrc", render_gtk2_settings(theme), validate_colors)
    publish(OUT / "sddm/theme.conf", render_sddm(theme), validate_colors)
    publish_sddm(theme, image)
    try:
        starship = render_matugen_template("starship.toml", matugen, theme)
        publish(OUT / "starship.toml", starship, validate_starship)
    except (OSError, ValueError, TypeError, tomllib.TOMLDecodeError) as error:
        print(f"Tema do Hyprism: Starship preservado após falha ({error})", file=sys.stderr)
    try:
        tmux = render_matugen_template("tmux.conf", matugen, theme)
        tmux_path = OUT / "tmux.conf"
        if publish(tmux_path, tmux, validate_colors):
            reload_tmux(tmux_path)
    except (OSError, ValueError, TypeError) as error:
        print(f"Tema do Hyprism: tmux preservado após falha ({error})", file=sys.stderr)
    try:
        nvchad = render_matugen_template("nvchad.lua", matugen, theme)
        publish(OUT / "nvim/matugen.lua", nvchad, validate_nvchad)
        publish(NVIM_THEME, nvchad, validate_nvchad)
    except (OSError, ValueError, TypeError) as error:
        print(f"Tema do Hyprism: NvChad preservado após falha ({error})", file=sys.stderr)
    try:
        fastfetch = render_hyprism_template("fastfetch.jsonc", theme)
        publish(OUT / "fastfetch/config.jsonc", fastfetch, validate_fastfetch)
    except (OSError, ValueError, TypeError, json.JSONDecodeError) as error:
        print(f"Tema do Hyprism: configuração anterior do Fastfetch preservada após falha ({error})", file=sys.stderr)
    try:
        zathura = render_hyprism_template("zathurarc", theme)
        publish(OUT / "zathura/zathurarc", zathura, validate_colors)
    except (OSError, ValueError, TypeError) as error:
        print(f"Tema do Hyprism: Zathura preservado após falha ({error})", file=sys.stderr)
    publish_fastfetch_logo(theme)
    try:
        colloid_palette = OUT / "colloid/_color-palette-matugen.scss"
        if publish(colloid_palette, render_colloid(matugen, theme), validate_colors):
            update_colloid(colloid_palette, mode)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Tema do Hyprism: Colloid preservado após falha ({error})", file=sys.stderr)
    publish_papirus(theme)
    try:
        kvantum_svg, kvantum_config, kvantum_colors = render_kvantum(theme)
        publish(OUT / "kvantum/Hyprism/Hyprism.svg", kvantum_svg, validate_colors)
        publish(OUT / "kvantum/Hyprism/Hyprism.kvconfig", kvantum_config, validate_colors)
        publish(OUT / "kvantum/Hyprism/Hyprism.colors", kvantum_colors, validate_colors)
    except (OSError, ValueError) as error:
        print(f"Tema do Hyprism: Kvantum preservado após falha ({error})", file=sys.stderr)


if __name__ == "__main__":
    main()
