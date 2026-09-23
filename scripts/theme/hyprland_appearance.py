import json
import os
from pathlib import Path
import subprocess
import tempfile


def presets(root):
    with (root / "config/theme/presets.json").open(encoding="utf-8") as source:
        return json.load(source)


def values(config, definitions):
    shell = config.get("shell", {})
    opacity = shell.get("surfaceOpacity", 0.9)
    if isinstance(opacity, bool) or not isinstance(opacity, (int, float)):
        opacity = 0.9
    opacity_preset = min(definitions["surfaceOpacity"], key=lambda preset: abs(preset["shell"] - opacity))
    radius = shell.get("cornerRadiusPreset", 1)
    blur = shell.get("blurPreset", 2)
    if isinstance(radius, bool) or not isinstance(radius, int) or radius not in range(len(definitions["cornerRadius"])):
        radius = 1
    if isinstance(blur, bool) or not isinstance(blur, int) or blur not in range(len(definitions["blur"])):
        blur = 2
    return {
        "rounding": definitions["cornerRadius"][radius]["window"],
        "inactiveOpacity": opacity_preset["inactiveWindow"],
        "blur": definitions["blur"][blur],
    }


def render(value):
    blur = value["blur"]
    return (
        "return {\n"
        f'    rounding = {value["rounding"]},\n'
        f'    inactive_opacity = {value["inactiveOpacity"]:.2f},\n'
        "    blur = {\n"
        f'        enabled = {str(blur["enabled"]).lower()},\n'
        f'        size = {blur["size"]},\n'
        f'        passes = {blur["passes"]},\n'
        "    },\n"
        "}\n"
    )


def generated_path():
    cache = Path(os.environ.get("HYPRISM_CACHE_DIR", Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hyprism"))
    return cache / "theme/appearance.lua"


def persist(value):
    target = generated_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=".appearance.", dir=target.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(render(value))
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def apply_runtime(value):
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return
    blur = value["blur"]
    request = (
        "hl.config({ decoration = { "
        f'rounding = {value["rounding"]}, '
        f'inactive_opacity = {value["inactiveOpacity"]:.2f}, '
        "blur = { "
        f'enabled = {str(blur["enabled"]).lower()}, '
        f'size = {blur["size"]}, '
        f'passes = {blur["passes"]}'
        " } } })"
    )
    result = subprocess.run(["hyprctl", "eval", request], capture_output=True, text=True, check=False)
    if result.returncode or result.stdout.strip() != "ok":
        raise SystemExit((result.stderr or result.stdout).strip() or "Hyprland theme update failed")


def sync(config, root):
    resolved = values(config, presets(root))
    persist(resolved)
    apply_runtime(resolved)
    return resolved
