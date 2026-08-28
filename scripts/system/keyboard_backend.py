#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET


COMMON_PRESETS = (
    ("system", None, None),
    ("us", "us", ""),
    ("us-intl", "us", "intl"),
    ("br-abnt2", "br", ""),
    ("pt", "pt", ""),
    ("es", "es", ""),
    ("de", "de", ""),
    ("fr", "fr", ""),
)
PRESETS = {name: {"layout": layout, "variant": variant} for name, layout, variant in COMMON_PRESETS}


class KeyboardError(RuntimeError):
    pass


def run(arguments):
    try:
        return subprocess.run(arguments, text=True, capture_output=True, check=False)
    except FileNotFoundError:
        raise KeyboardError(f"Required command not found: {arguments[0]}")


def hyprctl(*arguments):
    executable = os.environ.get("HYPRISM_HYPRCTL", "hyprctl")
    result = run([executable, *arguments])
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise KeyboardError(detail or "Hyprland keyboard operation failed")
    return result.stdout


def normalize_device_name(value):
    return re.sub(r"\s+", "-", value.strip().lower())


def typing_device_metadata():
    records = []
    for event in sorted(Path("/sys/class/input").glob("event*")):
        name_file = event / "device/name"
        try:
            name = name_file.read_text(encoding="utf-8").strip()
        except OSError:
            continue
        properties = run(["udevadm", "info", "--query=property", f"--path={event.resolve()}"])
        integration = ""
        typing = False
        pointer = False
        group = ""
        if properties.returncode == 0:
            for line in properties.stdout.splitlines():
                if line.startswith("ID_INTEGRATION="):
                    integration = line.partition("=")[2]
                elif line == "ID_INPUT_KEYBOARD=1":
                    typing = True
                elif line in ("ID_INPUT_MOUSE=1", "ID_INPUT_TOUCHPAD=1", "ID_INPUT_POINTINGSTICK=1"):
                    pointer = True
                elif line.startswith("LIBINPUT_DEVICE_GROUP="):
                    group = line.partition("=")[2]
        records.append({
            "name": normalize_device_name(name),
            "integration": integration,
            "event": event.name,
            "typing": typing,
            "pointer": pointer,
            "group": group or str(event.resolve().parent),
        })
    pointer_groups = {item["group"] for item in records if item["pointer"]}
    metadata = {}
    for item in records:
        item["pointer_group"] = item["group"] in pointer_groups
        metadata.setdefault(item["name"], []).append(item)
    return metadata


def match_metadata(name, metadata):
    exact = metadata.get(name)
    if exact:
        return exact[0]
    base = re.sub(r"-\d+$", "", name)
    candidates = metadata.get(base)
    return candidates[0] if candidates else {}


def likely_typing_keyboard(value, metadata):
    if metadata:
        return any(item.get("typing", False) for item in metadata)
    name = value["name"]
    excluded = ("consumer-control", "system-control", "power-button", "video-bus", "sleep-button")
    return value.get("main", False) or ("keyboard" in name and not any(part in name for part in excluded))


def discover_interfaces():
    try:
        value = json.loads(hyprctl("devices", "-j"))
    except json.JSONDecodeError as error:
        raise KeyboardError(f"Invalid keyboard data from Hyprland: {error}")
    hardware = typing_device_metadata()
    devices = []
    for item in value.get("keyboards", []):
        name = item.get("name", "")
        if not name:
            continue
        matches = hardware.get(name) or hardware.get(re.sub(r"-\d+$", "", name)) or []
        matched = match_metadata(name, hardware)
        if not likely_typing_keyboard(item, matches):
            continue
        integration = matched.get("integration", "")
        classification = integration if integration in ("internal", "external") else "keyboard"
        devices.append({
            "id": name,
            "name": item.get("model") or name.replace("-", " ").title(),
            "classification": classification,
            "layout": item.get("layout", "") or "",
            "variant": item.get("variant", "") or "",
            "keymap": item.get("active_keymap", "") or "",
            "main": bool(item.get("main", False)),
            "group": matched.get("group", f"hypr:{name}"),
            "pointerGroup": bool(matched.get("pointer_group", False)),
        })
    return devices


def discover_devices(include_auxiliary=False):
    interfaces = discover_interfaces()
    groups = {}
    for item in interfaces:
        key = "internal" if item["classification"] == "internal" else item["group"]
        groups.setdefault(key, []).append(item)
    devices = []
    for key, members in groups.items():
        classification = "internal" if key == "internal" else members[0]["classification"]
        primary = next((item for item in members if item["main"]), None)
        if not primary and classification == "internal":
            primary = next((item for item in members if "translated-set-2" in item["id"]), None)
        primary = primary or members[0]
        auxiliary = classification == "external" and all(item["pointerGroup"] for item in members) and not any(item["main"] for item in members)
        device = {
            **primary,
            "id": "built-in" if key == "internal" else primary["id"],
            "ids": [item["id"] for item in members],
            "interfaces": members,
            "classification": classification,
            "auxiliary": auxiliary,
        }
        if include_auxiliary or not auxiliary:
            devices.append(device)
    devices.sort(key=lambda item: (0 if item["classification"] == "internal" else 1, item["name"].casefold()))
    return devices


def xkb_rules_path():
    configured = os.environ.get("HYPRISM_XKB_RULES")
    if configured:
        return Path(configured)
    for candidate in (Path("/usr/share/X11/xkb/rules/evdev.xml"), Path("/usr/share/X11/xkb/rules/base.xml")):
        if candidate.is_file():
            return candidate
    return None


def installed_layouts():
    path = xkb_rules_path()
    if not path:
        return []
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as error:
        raise KeyboardError(f"Could not read XKB layouts: {error}")
    layouts = []
    for layout in root.findall(".//layoutList/layout"):
        name = layout.findtext("configItem/name", "").strip()
        description = layout.findtext("configItem/description", name).strip()
        if name:
            variants = [item.text.strip() for item in layout.findall("variantList/variant/configItem/name") if item.text and item.text.strip()]
            layouts.append({"preset": f"xkb:{name}", "layout": name, "variant": "", "name": description, "variants": variants})
    return layouts


def system_layout():
    path = Path("/etc/vconsole.conf")
    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        content = ""
    fields = {}
    for line in content.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            fields[key.strip()] = value.strip().strip('"\'')
    layout = fields.get("XKBLAYOUT", "")
    if layout:
        return {"layout": layout, "variant": fields.get("XKBVARIANT", "")}
    result = run(["localectl", "status", "--no-pager"])
    if result.returncode != 0:
        return None
    status = {}
    for line in result.stdout.splitlines():
        key, separator, value = line.strip().partition(":")
        if separator:
            status[key] = value.strip()
    layout = status.get("X11 Layout", "")
    return {"layout": layout.split(",")[0], "variant": status.get("X11 Variant", "").split(",")[0]} if layout else None


def runtime_default_layout():
    try:
        layout = json.loads(hyprctl("getoption", "-j", "input:kb_layout"))
        variant = json.loads(hyprctl("getoption", "-j", "input:kb_variant"))
    except (KeyboardError, json.JSONDecodeError):
        return None
    value = layout.get("str", "")
    return {"layout": value, "variant": variant.get("str", "")} if value else None


def preset_value(name, variant=None):
    if name.startswith("xkb:"):
        layout = name.partition(":")[2]
        available = {item["layout"]: item for item in installed_layouts()}
        if layout not in available:
            raise KeyboardError(f"Unknown XKB layout: {layout}")
        if variant and variant not in available[layout]["variants"]:
            raise KeyboardError(f"Unknown XKB variant for {layout}: {variant}")
        return {"layout": layout, "variant": variant or ""}
    if name not in PRESETS:
        raise KeyboardError(f"Unknown keyboard preset: {name}")
    value = PRESETS[name]
    if value["layout"] is None:
        detected = runtime_default_layout() or system_layout()
        if not detected:
            raise KeyboardError("System keyboard layout could not be determined")
        return detected
    selected_variant = variant if variant is not None else value["variant"]
    if variant is not None:
        available = {item["layout"]: item for item in installed_layouts()}
        if value["layout"] not in available or variant not in available[value["layout"]]["variants"]:
            raise KeyboardError(f"Unknown XKB variant for {value['layout']}: {variant}")
    return {"layout": value["layout"], "variant": selected_variant}


def lua_string(value):
    return json.dumps(value, ensure_ascii=False)


def state_path():
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache / "hyprism/state/keyboard.lua"


def render_config(config, destination=None):
    keyboard = config.get("keyboard", {})
    lines = []
    default = keyboard.get("default")
    if isinstance(default, dict) and default.get("layout"):
        lines.extend((
            "hl.config({",
            "    input = {",
            f"        kb_layout = {lua_string(default['layout'])},",
            f"        kb_variant = {lua_string(default.get('variant', ''))},",
            "    },",
            "})",
            "",
        ))
    devices = keyboard.get("devices", {})
    if isinstance(devices, dict):
        for name in sorted(devices):
            value = devices[name]
            if not isinstance(value, dict) or not value.get("layout"):
                continue
            lines.extend((
                "hl.device({",
                f"    name = {lua_string(name)},",
                f"    kb_layout = {lua_string(value['layout'])},",
                f"    kb_variant = {lua_string(value.get('variant', ''))},",
                "})",
                "",
            ))
    destination = destination or state_path()
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{destination.name}.", dir=destination.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write("\n".join(lines))
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)
    return destination


def apply_device(device, value):
    expression = (
        "hl.device({ name = " + lua_string(device) +
        ", kb_layout = " + lua_string(value["layout"]) +
        ", kb_variant = " + lua_string(value.get("variant", "")) + " })"
    )
    hyprctl("eval", expression)


def apply_default(value):
    expression = (
        "hl.config({ input = { kb_layout = " + lua_string(value["layout"]) +
        ", kb_variant = " + lua_string(value.get("variant", "")) + " } })"
    )
    hyprctl("eval", expression)


def capture_initial_config():
    detected = runtime_default_layout() or system_layout()
    try:
        devices = discover_devices()
    except KeyboardError:
        devices = []
    if not detected:
        main = next((item for item in devices if item["main"] and item["layout"]), None)
        detected = {"layout": main["layout"], "variant": main["variant"]} if main else None
    return {
        "default": detected,
        "devices": {
            interface["id"]: {"layout": interface["layout"], "variant": interface["variant"]}
            for item in devices for interface in item["interfaces"] if interface["layout"]
        },
    }


def targets_for(devices, target):
    if target == "default":
        return []
    if target == "all":
        return [identifier for item in devices if not item.get("auxiliary", False) for identifier in item["ids"]]
    if target in ("built-in", "external"):
        classification = "internal" if target == "built-in" else "external"
        return [identifier for item in devices if item["classification"] == classification and not item.get("auxiliary", False) for identifier in item["ids"]]
    for item in devices:
        if item["id"] == target:
            return item["ids"]
        if target in item["ids"]:
            return [target]
    raise KeyboardError(f"Keyboard target not found: {target}")


def effective_value(config, device):
    keyboard = config.get("keyboard", {})
    overrides = keyboard.get("devices", {})
    override = next((overrides.get(name) for name in device.get("ids", [device["id"]]) if isinstance(overrides.get(name), dict)), None)
    if isinstance(override, dict) and override.get("layout"):
        return override, "override"
    default = keyboard.get("default")
    if isinstance(default, dict) and default.get("layout"):
        return default, "default"
    if device.get("layout"):
        return {"layout": device["layout"], "variant": device.get("variant", "")}, "runtime"
    detected = system_layout()
    return detected, "system" if detected else "unknown"
