#!/usr/bin/env python3
import json
import os
import pathlib
import subprocess
import sys
import tempfile

HOME = pathlib.Path.home()
CACHE = pathlib.Path(os.environ.get("HYPRISM_CACHE_DIR", HOME / ".cache/hyprism"))
OUT = CACHE / "theme"

FALLBACK = {"background": "#091015", "foreground": "#e0e8ee", "accent": "#82b1d3"}

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=".hyprism-", dir=path.parent)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(value)
    os.replace(temp, path)

def rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))

def hexrgb(value):
    return "#" + "".join(f"{max(0, min(255, round(v))):02x}" for v in value)

def mix(a, b, amount):
    return hexrgb(tuple(x * (1 - amount) + y * amount for x, y in zip(rgb(a), rgb(b))))

def luminance(value):
    channels = []
    for channel in rgb(value):
        channel /= 255
        channels.append(channel / 12.92 if channel <= .04045 else ((channel + .055) / 1.055) ** 2.4)
    return .2126 * channels[0] + .7152 * channels[1] + .0722 * channels[2]

def contrast(a, b):
    bright, dark = sorted((luminance(a), luminance(b)), reverse=True)
    return (bright + .05) / (dark + .05)

def accessible(candidate, background, target):
    if contrast(candidate, background) >= target:
        return candidate
    return mix(candidate, "#ffffff", .45)

def palette(image):
    if not image:
        return FALLBACK
    try:
        call = ["matugen", "image", image, "--source-color-index", "0", "-t", "scheme-content", "--dry-run", "--json", "hex"]
        raw = json.loads(subprocess.run(call, check=True, capture_output=True, text=True).stdout)
        write(OUT / "matugen.json", json.dumps(raw, indent=2) + "\n")
        colors = raw["colors"]
        return {
            "background": colors["background"]["dark"]["color"],
            "foreground": colors["on_surface"]["dark"]["color"],
            "accent": colors["primary"]["dark"]["color"],
            "secondary": colors["secondary"]["dark"]["color"],
            "error": colors["error"]["dark"]["color"],
        }
    except (OSError, KeyError, ValueError, subprocess.SubprocessError) as error:
        print(f"Tema do Hyprism: o Matugen falhou ({error}); usando a paleta segura", file=sys.stderr)
        return FALLBACK

image = sys.argv[1] if len(sys.argv) > 1 else ""
raw = palette(image)
background = mix(raw["background"], "#000000", .62)
foreground = accessible(raw["foreground"], background, 7)
primary = accessible(mix(raw["accent"], foreground, .10), background, 3.2)
secondary = accessible(mix(raw.get("secondary", primary), foreground, .08), background, 3.0)
surface = mix(background, foreground, .075)
surface_variant = mix(background, foreground, .145)
outline = mix(background, primary, .45)
muted = mix(background, foreground, .55)
theme = {
    "background": background, "surface": surface, "surfaceVariant": surface_variant,
    "surfaceElevated": mix(surface_variant, foreground, .04), "foreground": foreground,
    "mutedForeground": muted, "primary": primary, "secondary": secondary,
    "accent": primary, "accentDim": mix(primary, background, .55), "outline": outline,
    "border": outline, "error": accessible(raw.get("error", "#dc7179"), background, 3.2),
    "warning": "#e0ae61", "success": primary, "wallpaper": image,
}
write(OUT / "theme.json", json.dumps(theme, indent=2) + "\n")
kitty = [
    f"foreground {foreground}", f"background {background}", f"cursor {primary}",
    f"cursor_text_color {background}", f"selection_foreground {foreground}",
    f"selection_background {surface_variant}", f"url_color {primary}",
    f"active_border_color {primary}", f"inactive_border_color {outline}",
]
ansi = [background, theme["error"], primary, theme["warning"], secondary, secondary, primary, foreground,
        muted, theme["error"], primary, theme["warning"], secondary, secondary, primary, foreground]
kitty += [f"color{i} {color}" for i, color in enumerate(ansi)]
write(OUT / "kitty.conf", "\n".join(kitty) + "\n")
foot = [
    "[colors-dark]",
    f"foreground={foreground[1:]}",
    f"background={background[1:]}",
    f"cursor={background[1:]} {primary[1:]}",
    f"selection-foreground={foreground[1:]}",
    f"selection-background={surface_variant[1:]}",
    f"urls={primary[1:]}",
    "alpha=0.94",
]
foot += [f"regular{i}={color[1:]}" for i, color in enumerate(ansi[:8])]
foot += [f"bright{i}={color[1:]}" for i, color in enumerate(ansi[8:])]
write(OUT / "foot.ini", "\n".join(foot) + "\n")
write(
    OUT / "hyprland.lua",
    "return {\n"
    f'    active_border = "rgb({primary[1:]})",\n'
    f'    inactive_border = "rgb({outline[1:]})",\n'
    "}\n",
)
