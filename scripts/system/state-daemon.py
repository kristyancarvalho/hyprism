#!/usr/bin/env python3
import json
import os
import pathlib
import shutil
import subprocess
import time

previous_cpu = None
previous_network = None
cached = {}


def command(args, timeout=1):
    try:
        environment = dict(os.environ)
        environment["LC_ALL"] = "C"
        return subprocess.run(args, text=True, capture_output=True, timeout=timeout, env=environment).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def volume(target="@DEFAULT_AUDIO_SINK@"):
    text = command(["wpctl", "get-volume", target])
    try:
        return {"available": bool(text), "percent": round(float(text.split()[1]) * 100), "muted": "MUTED" in text}
    except (IndexError, ValueError):
        return {"available": False, "percent": 0, "muted": False}


def virtualized():
    identifiers = []
    for name in ("product_name", "sys_vendor", "board_vendor"):
        try:
            identifiers.append((pathlib.Path("/sys/class/dmi/id") / name).read_text().strip().lower())
        except OSError:
            pass
    markers = ("virtualbox", "vmware", "qemu", "kvm", "bochs", "parallels", "microsoft corporation")
    return any(marker in value for value in identifiers for marker in markers)


virtual_machine = virtualized()


def network_identity():
    active = command(["nmcli", "-t", "-f", "TYPE,NAME,DEVICE", "connection", "show", "--active"])
    devices = command(["nmcli", "-t", "-f", "DEVICE,TYPE", "device", "status"])
    wifi_available = any(len(row.split(":", 1)) > 1 and row.split(":", 1)[1] == "wifi" for row in devices.splitlines())
    wifi_enabled = command(["nmcli", "-t", "-f", "WIFI", "general"]).lower() == "enabled"
    selected = None
    for row in active.splitlines():
        fields = row.split(":", 2)
        if fields and fields[0] in ("wifi", "802-3-ethernet", "ethernet"):
            selected = fields
            if fields[0] == "wifi":
                break
    if not selected:
        return {"available": bool(devices), "kind": "disconnected", "name": "Desconectado", "device": "", "enabled": False, "signal": 0, "wifiAvailable": wifi_available, "wifiEnabled": wifi_enabled, "virtualized": virtual_machine}
    kind = selected[0]
    name = selected[1] if len(selected) > 1 else ""
    device = selected[2] if len(selected) > 2 else ""
    signals = command(["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list"]).splitlines()
    strength = next((int(row.split(":")[1]) for row in signals if row.startswith("*:") and len(row.split(":")) > 1 and row.split(":")[1].isdigit()), 0)
    return {"available": True, "kind": "wifi" if kind == "wifi" else "ethernet", "name": name or ("Rede" if virtual_machine else "Ethernet"), "device": device, "enabled": True, "signal": strength, "wifiAvailable": wifi_available, "wifiEnabled": wifi_enabled, "virtualized": virtual_machine}


def network_rates(identity):
    global previous_network
    device = identity.get("device", "")
    received = 0
    transmitted = 0
    try:
        for row in pathlib.Path("/proc/net/dev").read_text().splitlines()[2:]:
            name, values = row.split(":", 1)
            if name.strip() != device:
                continue
            fields = values.split()
            received = int(fields[0])
            transmitted = int(fields[8])
            break
    except (OSError, ValueError, IndexError):
        pass
    now = time.monotonic()
    rates = {"receiveKib": 0, "transmitKib": 0}
    if previous_network and previous_network[0] == device and now > previous_network[3]:
        elapsed = now - previous_network[3]
        rates["receiveKib"] = max(0, round((received - previous_network[1]) / 1024 / elapsed, 1))
        rates["transmitKib"] = max(0, round((transmitted - previous_network[2]) / 1024 / elapsed, 1))
    previous_network = (device, received, transmitted, now)
    return merge_dicts(identity, rates)


def merge_dicts(first, second):
    result = dict(first)
    result.update(second)
    return result


def bluetooth():
    if not shutil.which("bluetoothctl"):
        return {"available": False, "powered": False, "connected": False, "devices": []}
    show = command(["bluetoothctl", "show"])
    if not show:
        return {"available": False, "powered": False, "connected": False, "devices": []}
    connected_addresses = command(["bluetoothctl", "devices", "Connected"])
    devices = []
    for row in command(["bluetoothctl", "devices", "Paired"]).splitlines():
        parts = row.split(maxsplit=2)
        if len(parts) == 3:
            devices.append({"address": parts[1], "name": parts[2], "connected": parts[1] in connected_addresses})
    return {"available": True, "powered": "Powered: yes" in show, "connected": any(device["connected"] for device in devices), "devices": devices}


def battery():
    for path in pathlib.Path("/sys/class/power_supply").glob("*"):
        try:
            if (path / "type").read_text().strip() == "Battery":
                return {"available": True, "percent": int((path / "capacity").read_text()), "status": (path / "status").read_text().strip()}
        except (OSError, ValueError):
            pass
    return {"available": False, "percent": 0, "status": ""}


def brightness():
    if not shutil.which("brightnessctl"):
        return {"available": False, "percent": 0}
    value = command(["brightnessctl", "-m"])
    try:
        return {"available": True, "percent": int(value.split(",")[3].rstrip("%"))}
    except (IndexError, ValueError):
        return {"available": False, "percent": 0}


def night_mode():
    cache_root = pathlib.Path(os.environ.get("XDG_CACHE_HOME", pathlib.Path.home() / ".cache"))
    state_path = cache_root / "hyprism/state/night-mode"
    available = bool(shutil.which("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"))
    try:
        enabled = state_path.read_text().strip() == "on"
    except OSError:
        enabled = False
    return {"available": available, "enabled": enabled if available else False}


def power_profile():
    if not shutil.which("powerprofilesctl"):
        return {"available": False, "mode": ""}
    mode = command(["powerprofilesctl", "get"])
    return {"available": bool(mode), "mode": mode if mode in ("power-saver", "balanced", "performance") else ""}


def memory():
    values = {}
    try:
        for line in pathlib.Path("/proc/meminfo").read_text().splitlines():
            values[line.split(":")[0]] = int(line.split()[1])
        return {"percent": round(100 * (values["MemTotal"] - values["MemAvailable"]) / values["MemTotal"]), "used": values["MemTotal"] - values["MemAvailable"], "total": values["MemTotal"]}
    except (OSError, KeyError, ValueError, ZeroDivisionError):
        return {"percent": 0, "used": 0, "total": 0}


def cpu():
    global previous_cpu
    try:
        fields = [int(value) for value in pathlib.Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
        total = sum(fields)
        idle = fields[3] + (fields[4] if len(fields) > 4 else 0)
        old = previous_cpu
        previous_cpu = (total, idle)
        usage = 0 if old is None or total == old[0] else round(100 * ((total - old[0]) - (idle - old[1])) / (total - old[0]))
        return {"percent": usage}
    except (OSError, ValueError, IndexError, ZeroDivisionError):
        return {"percent": 0}


def gpu():
    text = command(["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]) if shutil.which("nvidia-smi") else ""
    try:
        return {"available": True, "percent": round(float(text.splitlines()[0]))}
    except (IndexError, ValueError):
        return {"available": False, "percent": 0}


def temperature():
    values = []
    for path in pathlib.Path("/sys/class/thermal").glob("thermal_zone*/temp"):
        try:
            value = float(path.read_text().strip())
            celsius = value / 1000 if value > 1000 else value
            if 0 < celsius < 125:
                values.append(celsius)
        except (OSError, ValueError):
            pass
    return {"available": bool(values), "celsius": round(max(values), 1) if values else 0}


tick = 0
while True:
    if tick % 3 == 0:
        cached["audio"] = volume()
        cached["microphone"] = volume("@DEFAULT_AUDIO_SOURCE@")
        cached["networkIdentity"] = network_identity()
        cached["battery"] = battery()
        cached["brightness"] = brightness()
        cached["nightMode"] = night_mode()
        cached["powerProfile"] = power_profile()
        cached["gpu"] = gpu()
    if tick % 5 == 0:
        cached["bluetooth"] = bluetooth()
        cached["temperature"] = temperature()
    state = {
        "audio": cached.get("audio", {"available": False, "percent": 0, "muted": False}),
        "microphone": cached.get("microphone", {"available": False, "percent": 0, "muted": False}),
        "network": network_rates(cached.get("networkIdentity", {})),
        "bluetooth": cached.get("bluetooth", {"available": False, "powered": False, "connected": False, "devices": []}),
        "battery": cached.get("battery", {"available": False, "percent": 0, "status": ""}),
        "brightness": cached.get("brightness", {"available": False, "percent": 0}),
        "nightMode": cached.get("nightMode", {"available": False, "enabled": False}),
        "powerProfile": cached.get("powerProfile", {"available": False, "mode": ""}),
        "memory": memory(),
        "cpu": cpu(),
        "gpu": cached.get("gpu", {"available": False, "percent": 0}),
        "temperature": cached.get("temperature", {"available": False, "celsius": 0}),
    }
    print(json.dumps(state), flush=True)
    tick += 1
    time.sleep(1)
