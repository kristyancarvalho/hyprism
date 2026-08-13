#!/usr/bin/env python3
import colorsys
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
from PIL import Image


HOME = pathlib.Path.home()
CACHE = pathlib.Path(os.environ.get("HYPRISM_CACHE_DIR", HOME / ".cache/hyprism"))
OUT = CACHE / "theme"
KVANTUM_BASE = pathlib.Path(os.environ.get("HYPRISM_KVANTUM_BASE", "/usr/share/Kvantum/KvArcDark"))
FALLBACK = {
    "background": "#091015",
    "foreground": "#e0e8ee",
    "accent": "#3ba7d9",
    "secondary": "#8ebbd8",
    "error": "#e4777f",
}


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".hyprism-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(value)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        pathlib.Path(temporary).unlink(missing_ok=True)
        raise


def publish(path, value, validator=None):
    try:
        if not value.strip():
            raise ValueError("conteúdo vazio")
        if validator:
            validator(value)
        write(path, value)
        return True
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
    if contrast(candidate, background) >= target:
        return candidate.lower()
    red, green, blue = (channel / 255 for channel in rgb(candidate))
    hue, lightness, saturation = colorsys.rgb_to_hls(red, green, blue)
    for step in range(1, 36):
        adjusted_lightness = min(.86, lightness + step * .015)
        adjusted = hexrgb(tuple(channel * 255 for channel in colorsys.hls_to_rgb(hue, adjusted_lightness, saturation)))
        if contrast(adjusted, background) >= target:
            return adjusted
    return hexrgb(tuple(channel * 255 for channel in colorsys.hls_to_rgb(hue, .86, saturation)))


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


def matugen_palette(image):
    command = ["matugen", "image", image, "--source-color-index", "0", "-t", "scheme-content", "--dry-run", "--json", "hex"]
    result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=30)
    generated = json.loads(result.stdout)
    colors = generated["colors"]
    semantic = {
        "background": colors["background"]["dark"]["color"],
        "foreground": colors["on_surface"]["dark"]["color"],
        "accent": wallpaper_source_color(image),
        "matugenSource": colors["source_color"]["dark"]["color"],
        "secondary": colors["secondary"]["dark"]["color"],
        "error": colors["error"]["dark"]["color"],
    }
    return semantic, generated


def theme_from(raw, image):
    background = mix(raw["background"], "#000000", .62)
    foreground = accessible_text(raw["foreground"], background, 7)
    accent = faithful_accent(raw["accent"], background)
    secondary = faithful_accent(raw.get("secondary", accent), background, 3.0)
    surface = mix(background, foreground, .075)
    surface_variant = mix(background, foreground, .145)
    outline = mix(background, foreground, .24)
    return {
        "background": background,
        "surface": surface,
        "surfaceVariant": surface_variant,
        "surfaceElevated": mix(surface_variant, foreground, .04),
        "surfaceHover": mix(surface_variant, foreground, .08),
        "surfaceActive": mix(accent, background, .64),
        "foreground": foreground,
        "mutedForeground": mix(background, foreground, .55),
        "primary": accent,
        "secondary": secondary,
        "accent": accent,
        "accentDim": mix(accent, background, .58),
        "outline": outline,
        "border": outline,
        "borderSubtle": mix(background, outline, .58),
        "borderNormal": outline,
        "borderFocused": accent,
        "error": accessible_text(raw.get("error", FALLBACK["error"]), background, 3.2),
        "warning": faithful_accent("#d49b32", background, 3.2),
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
        "alpha=0.94",
    ]
    colors = terminal_colors(theme)
    lines.extend(f"regular{index}={color[1:]}" for index, color in enumerate(colors[:8]))
    lines.extend(f"bright{index}={color[1:]}" for index, color in enumerate(colors[8:]))
    return "\n".join(lines) + "\n"


def render_hyprland(theme):
    return (
        "return {\n"
        f'    active_border = "rgb({theme["accent"][1:]})",\n'
        f'    inactive_border = "rgb({theme["outline"][1:]})",\n'
        "}\n"
    )


def render_hyprlock(theme):
    values = {
        "background": theme["background"],
        "surface": theme["surface"],
        "surface_active": theme["surfaceActive"],
        "foreground": theme["foreground"],
        "muted": theme["mutedForeground"],
        "accent": theme["accent"],
        "error": theme["error"],
    }
    return "".join(f"$hyprism_{name} = rgb({color[1:]})\n" for name, color in values.items())


def render_gtk(theme, version):
    definitions = {
        "theme_bg_color": theme["background"],
        "theme_fg_color": theme["foreground"],
        "theme_base_color": theme["surface"],
        "theme_text_color": theme["foreground"],
        "theme_selected_bg_color": theme["accent"],
        "theme_selected_fg_color": theme["background"],
        "accent_bg_color": theme["accent"],
        "accent_fg_color": theme["background"],
        "accent_color": theme["accent"],
        "window_bg_color": theme["background"],
        "window_fg_color": theme["foreground"],
        "view_bg_color": theme["surface"],
        "view_fg_color": theme["foreground"],
        "headerbar_bg_color": theme["surfaceElevated"],
        "headerbar_fg_color": theme["foreground"],
        "sidebar_bg_color": theme["surfaceVariant"],
        "sidebar_fg_color": theme["foreground"],
        "card_bg_color": theme["surfaceVariant"],
        "card_fg_color": theme["foreground"],
        "dialog_bg_color": theme["surfaceElevated"],
        "dialog_fg_color": theme["foreground"],
        "popover_bg_color": theme["surfaceElevated"],
        "popover_fg_color": theme["foreground"],
        "borders": theme["borderSubtle"],
        "error_bg_color": theme["error"],
        "error_fg_color": theme["background"],
    }
    lines = [f"@define-color {name} {color};" for name, color in definitions.items()]
    lines.extend([
        "window, .background { background-color: @window_bg_color; color: @window_fg_color; }",
        "headerbar, .titlebar { background-color: @headerbar_bg_color; color: @headerbar_fg_color; border-color: @borders; }",
        ".sidebar, navigationview, navigationpage { background-color: @sidebar_bg_color; color: @sidebar_fg_color; }",
        "entry, textview, treeview, listview { background-color: @view_bg_color; color: @view_fg_color; }",
        "selection, *:selected { background-color: @accent_bg_color; color: @accent_fg_color; }",
        "*:focus-visible { outline-color: @accent_color; }",
        "button:checked, switch:checked, check:checked { background-color: @accent_bg_color; color: @accent_fg_color; }",
    ])
    if version == 4:
        lines.append(".error, .destructive-action { color: @error_bg_color; }")
    return "\n".join(lines) + "\n"


def replace_ini_value(content, key, value):
    pattern = rf"(?m)^{re.escape(key)}=.*$"
    replacement = f"{key}={value}"
    return re.sub(pattern, replacement, content) if re.search(pattern, content) else content + replacement + "\n"


def render_kvantum(theme):
    svg_path = KVANTUM_BASE / "KvArcDark.svg"
    config_path = KVANTUM_BASE / "KvArcDark.kvconfig"
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


image = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    raw, matugen = matugen_palette(image) if image else (FALLBACK, {"fallback": True})
except (OSError, KeyError, ValueError, json.JSONDecodeError, subprocess.SubprocessError) as error:
    print(f"Tema do Hyprism: o Matugen falhou ({error}); mantendo os artefatos atuais", file=sys.stderr)
    raise SystemExit(1)

theme = theme_from(raw, image)
publish(OUT / "matugen.json", json_text(matugen), json.loads)
publish(OUT / "theme.json", json_text(theme), json.loads)
publish(OUT / "kitty.conf", render_kitty(theme), validate_colors)
publish(OUT / "foot.ini", render_foot(theme), validate_colors)
publish(OUT / "hyprland.lua", render_hyprland(theme), validate_colors)
publish(OUT / "hyprlock-colors.conf", render_hyprlock(theme), validate_colors)
publish(OUT / "gtk-3.0.css", render_gtk(theme, 3), validate_colors)
publish(OUT / "gtk-4.0.css", render_gtk(theme, 4), validate_colors)
try:
    kvantum_svg, kvantum_config, kvantum_colors = render_kvantum(theme)
    publish(OUT / "kvantum/Hyprism/Hyprism.svg", kvantum_svg, validate_colors)
    publish(OUT / "kvantum/Hyprism/Hyprism.kvconfig", kvantum_config, validate_colors)
    publish(OUT / "kvantum/Hyprism/Hyprism.colors", kvantum_colors, validate_colors)
except (OSError, ValueError) as error:
    print(f"Tema do Hyprism: Kvantum preservado após falha ({error})", file=sys.stderr)
