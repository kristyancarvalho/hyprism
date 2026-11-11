import json
import os
import shutil
from pathlib import Path
import subprocess
import tempfile

LAYOUTS = ("scrolling", "dwindle")
DEFAULT_LAYOUT = "dwindle"


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
        "terminalOpacity": opacity_preset["shell"],
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


def cache_dir():
    return Path(os.environ.get("HYPRISM_CACHE_DIR", Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hyprism"))


def generated_path():
    return cache_dir() / "theme/appearance.lua"


def layout_path():
    return cache_dir() / "theme/layout.lua"


def write_atomic(target, content):
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{target.stem}.", dir=target.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def persist(value):
    write_atomic(generated_path(), render(value))


def terminal_paths():
    return cache_dir() / "theme/kitty-opacity.conf", cache_dir() / "theme/foot-opacity.ini"


def persist_terminals(value):
    opacity = f'{value["terminalOpacity"]:.2f}'
    kitty, foot = terminal_paths()
    write_atomic(kitty, f"background_opacity {opacity}\n")
    write_atomic(foot, f"[colors-dark]\nalpha={opacity}\n")


def apply_terminals_runtime(value):
    kitten = shutil.which("kitten")
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    if not kitten or not runtime.is_dir():
        return
    for socket in runtime.glob("kitty-*"):
        if not socket.is_socket():
            continue
        try:
            subprocess.run([kitten, "@", "--to", f"unix:{socket}", "set-background-opacity", "--all", f'{value["terminalOpacity"]:.2f}'], capture_output=True, timeout=3, check=False)
        except (OSError, subprocess.SubprocessError):
            pass


def evaluate(request, failure):
    result = subprocess.run(["hyprctl", "eval", request], capture_output=True, text=True, check=False)
    if result.returncode or result.stdout.strip() != "ok":
        raise SystemExit((result.stderr or result.stdout).strip() or failure)


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
    evaluate(request, "Hyprland theme update failed")


def layout(config):
    settings = config.get("hyprland")
    value = settings.get("layout") if isinstance(settings, dict) else None
    return value if value in LAYOUTS else DEFAULT_LAYOUT


def set_layout(config, value):
    if value not in LAYOUTS:
        raise SystemExit(f"Unknown layout: {value}")
    settings = config.get("hyprland")
    if not isinstance(settings, dict):
        settings = {}
        config["hyprland"] = settings
    changed = settings.get("layout") != value
    settings["layout"] = value
    return changed


def render_layout(value):
    return f'return {{\n    layout = "{value}",\n}}\n'


def apply_layout_runtime(value):
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return
    evaluate(f'hl.config({{ general = {{ layout = "{value}" }} }})', "Hyprland layout update failed")


def sync_layout(config):
    value = layout(config)
    write_atomic(layout_path(), render_layout(value))
    apply_layout_runtime(value)
    return value


def sync(config, root):
    resolved = values(config, presets(root))
    persist(resolved)
    persist_terminals(resolved)
    apply_runtime(resolved)
    apply_terminals_runtime(resolved)
    sync_layout(config)
    return resolved
