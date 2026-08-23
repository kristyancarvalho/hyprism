#!/usr/bin/env python3
import concurrent.futures
import json
import os
import pathlib
import platform
import shutil
import subprocess
import sys
import time


def safe_config():
    try:
        value = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
        return value if isinstance(value, dict) else {}
    except (json.JSONDecodeError, TypeError):
        return {}


def enabled(config, name, fallback=True):
    value = config.get(name, {})
    if isinstance(value, bool):
        return value
    return bool(value.get("enabled", fallback)) if isinstance(value, dict) else fallback


def options(config, name):
    value = config.get(name, {})
    return value if isinstance(value, dict) else {}


def bounded_integer(value, fallback, minimum, maximum):
    try:
        return max(minimum, min(maximum, int(value)))
    except (TypeError, ValueError):
        return fallback


def storage(config):
    requested = options(config, "storage").get("mounts", ["/", "/home"])
    mounts = requested if isinstance(requested, list) else ["/", "/home"]
    result = []
    filesystems = set()
    mount_sources = {}
    try:
        for line in pathlib.Path("/proc/self/mountinfo").read_text().splitlines():
            fields = line.split()
            separator = fields.index("-")
            mount_sources[fields[4].replace("\\040", " ")] = fields[separator + 2]
    except (OSError, ValueError, IndexError):
        pass
    for requested_mount in mounts:
        mount = pathlib.Path(str(requested_mount)).expanduser()
        try:
            statistics = os.statvfs(mount)
            total = statistics.f_blocks * statistics.f_frsize
            available = statistics.f_bavail * statistics.f_frsize
            used = max(0, total - available)
            if total <= 0:
                continue
            matching_mounts = [candidate for candidate in mount_sources if str(mount) == candidate or str(mount).startswith(candidate.rstrip("/") + "/")]
            source = mount_sources[max(matching_mounts, key=len)] if matching_mounts else ""
            identity = source or (mount.stat().st_dev, total)
            if identity in filesystems:
                continue
            filesystems.add(identity)
            result.append({
                "mount": str(mount),
                "usedBytes": used,
                "totalBytes": total,
                "percent": round(used * 100 / total, 1)
            })
        except OSError:
            continue
    return {"available": bool(result), "mounts": result}


def sensor_label(device, label):
    source = f"{device} {label}".casefold()
    if any(value in source for value in ("amdgpu", "nvidia", "nouveau", "gpu")):
        return "GPU"
    if any(value in source for value in ("coretemp", "k10temp", "zenpower", "package", "tdie", "tctl", "cpu")):
        return "CPU"
    return label.strip() or device.strip() or "Sensor"


def sensor_value(path):
    try:
        value = float(path.read_text().strip())
        celsius = value / 1000 if abs(value) > 200 else value
        return round(celsius, 1) if 0 < celsius < 150 else None
    except (OSError, ValueError):
        return None


def sensors():
    values = {}
    for directory in pathlib.Path("/sys/class/hwmon").glob("hwmon*"):
        try:
            device = (directory / "name").read_text().strip()
        except OSError:
            device = directory.name
        for input_path in directory.glob("temp*_input"):
            value = sensor_value(input_path)
            if value is None:
                continue
            label_path = input_path.with_name(input_path.name.replace("_input", "_label"))
            try:
                raw_label = label_path.read_text().strip()
            except OSError:
                raw_label = device
            label = sensor_label(device, raw_label)
            values[label] = max(value, values.get(label, value))
    if not values:
        for input_path in pathlib.Path("/sys/class/thermal").glob("thermal_zone*/temp"):
            value = sensor_value(input_path)
            if value is None:
                continue
            try:
                zone_type = (input_path.parent / "type").read_text().strip()
            except OSError:
                zone_type = "Sensor"
            label = sensor_label(zone_type, zone_type)
            values[label] = max(value, values.get(label, value))
    result = [{"label": label, "celsius": value} for label, value in values.items()]
    preferred = sorted(result, key=lambda item: (item["label"] not in ("CPU", "GPU"), -item["celsius"]))
    return {"available": bool(preferred), "items": preferred[:4]}


def uptime():
    try:
        uptime_seconds = max(0, int(float(pathlib.Path("/proc/uptime").read_text().split()[0])))
    except (OSError, ValueError, IndexError):
        uptime_seconds = 0
    try:
        process_count = sum(entry.name.isdigit() for entry in pathlib.Path("/proc").iterdir())
    except OSError:
        process_count = 0
    return {
        "available": uptime_seconds > 0,
        "uptimeSeconds": uptime_seconds,
        "processCount": process_count
    }


def command_output(command, timeout):
    try:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            env={**os.environ, "LC_ALL": "C"}
        )
    except (OSError, subprocess.SubprocessError):
        return None


def session_label():
    desktop = os.environ.get("XDG_CURRENT_DESKTOP") or os.environ.get("XDG_SESSION_DESKTOP") or "Hyprland"
    desktop = desktop.split(":")[0].strip() or "Hyprland"
    session_type = (os.environ.get("XDG_SESSION_TYPE") or "wayland").strip().capitalize()
    return f"{desktop} / {session_type}"


def system_identity():
    return {
        "available": True,
        "kernel": f"Linux {platform.release()}",
        "session": session_label(),
        "snapshotStatus": "unavailable",
        "snapshotTimestamp": 0,
        "updatesKnown": False,
        "updateCount": 0
    }


def latest_snapshot():
    if not shutil.which("snapper"):
        return {"snapshotStatus": "unavailable", "snapshotTimestamp": 0}
    configurations = command_output(["snapper", "--csvout", "--separator", "|", "list-configs"], 4)
    if not configurations or configurations.returncode != 0:
        return {"snapshotStatus": "unavailable", "snapshotTimestamp": 0}
    names = []
    for line in configurations.stdout.splitlines()[1:]:
        name = line.split("|", 1)[0].strip()
        if name:
            names.append(name)
    if not names:
        return {"snapshotStatus": "none", "snapshotTimestamp": 0}
    latest = 0
    readable = False
    for name in names:
        listing = command_output(["snapper", "--csvout", "--separator", "|", "-c", name, "list"], 8)
        if not listing or listing.returncode != 0:
            continue
        readable = True
        lines = listing.stdout.splitlines()
        if not lines:
            continue
        headers = lines[0].split("|")
        try:
            date_index = headers.index("date")
        except ValueError:
            continue
        for line in lines[1:]:
            fields = line.split("|")
            if len(fields) <= date_index or not fields[date_index].strip():
                continue
            try:
                timestamp = int(time.mktime(time.strptime(fields[date_index].strip(), "%Y-%m-%d %H:%M:%S")))
                latest = max(latest, timestamp)
            except ValueError:
                continue
    if latest > 0:
        return {"snapshotStatus": "available", "snapshotTimestamp": latest}
    return {"snapshotStatus": "none" if readable else "unavailable", "snapshotTimestamp": 0}


def pending_updates():
    if shutil.which("checkupdates"):
        result = command_output(["checkupdates"], 30)
        if result and result.returncode in (0, 2):
            return {"updatesKnown": True, "updateCount": len([line for line in result.stdout.splitlines() if line.strip()])}
    if shutil.which("pacman"):
        result = command_output(["pacman", "-Qu"], 8)
        if result and result.returncode == 0:
            return {"updatesKnown": True, "updateCount": len([line for line in result.stdout.splitlines() if line.strip()])}
    return {"updatesKnown": False, "updateCount": 0}


def service_scope(item):
    if isinstance(item, str):
        unit = item if item.endswith(".service") else item + ".service"
        return {"name": item.removesuffix(".service"), "unit": unit, "scope": "user" if item.casefold() in ("pipewire", "wireplumber") else "system"}
    if not isinstance(item, dict):
        return None
    unit = str(item.get("unit", "")).strip()
    if not unit:
        return None
    return {
        "name": str(item.get("name", unit.removesuffix(".service"))).strip(),
        "unit": unit if unit.endswith(".service") else unit + ".service",
        "scope": "user" if item.get("scope") == "user" else "system"
    }


def service_state(item):
    command = ["systemctl"]
    if item["scope"] == "user":
        command.append("--user")
    command.extend(["show", item["unit"], "--property=LoadState,ActiveState", "--value"])
    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=2, env={**os.environ, "LC_ALL": "C"})
        values = completed.stdout.splitlines()
        load_state = values[0].strip() if values else "not-found"
        active_state = values[1].strip() if len(values) > 1 else "unknown"
    except (OSError, subprocess.SubprocessError):
        load_state = "not-found"
        active_state = "unknown"
    if load_state == "not-found":
        state = "unavailable"
    elif active_state == "active":
        state = "running"
    elif active_state == "failed":
        state = "failed"
    elif active_state in ("inactive", "deactivating"):
        state = "stopped"
    else:
        state = "unknown"
    return {"name": item["name"], "unit": item["unit"], "scope": item["scope"], "state": state}


def services(config):
    configured = options(config, "services").get("items", [])
    items = [service_scope(item) for item in configured] if isinstance(configured, list) else []
    result = [service_state(item) for item in items if item]
    return {"available": bool(result), "healthy": bool(result) and all(item["state"] == "running" for item in result), "items": result}


clock_ticks = os.sysconf("SC_CLK_TCK")
page_size = os.sysconf("SC_PAGE_SIZE")
previous_process_ticks = {}
previous_process_time = time.monotonic()


def process_snapshot():
    snapshot = []
    for directory in pathlib.Path("/proc").iterdir():
        if not directory.name.isdigit():
            continue
        try:
            stat = (directory / "stat").read_text().split()
            name = (directory / "comm").read_text().strip()
            resident_pages = int((directory / "statm").read_text().split()[1])
            ticks = int(stat[13]) + int(stat[14])
            snapshot.append({"pid": int(directory.name), "name": name, "ticks": ticks, "memoryBytes": resident_pages * page_size})
        except (OSError, ValueError, IndexError):
            continue
    return snapshot


def processes(config):
    global previous_process_ticks, previous_process_time
    limit = bounded_integer(options(config, "processes").get("limit", 3), 3, 1, 6)
    now = time.monotonic()
    elapsed = max(.001, now - previous_process_time)
    snapshot = process_snapshot()
    current_ticks = {item["pid"]: item["ticks"] for item in snapshot}
    for item in snapshot:
        old_ticks = previous_process_ticks.get(item["pid"], item["ticks"])
        item["cpuPercent"] = round(max(0, item["ticks"] - old_ticks) * 100 / clock_ticks / elapsed, 1)
        item.pop("ticks", None)
    previous_process_ticks = current_ticks
    previous_process_time = now
    by_cpu = sorted(snapshot, key=lambda item: (item["cpuPercent"], item["memoryBytes"]), reverse=True)[:limit]
    by_memory = sorted(snapshot, key=lambda item: item["memoryBytes"], reverse=True)[:limit]
    return {"available": bool(snapshot), "cpu": by_cpu, "memory": by_memory, "limit": limit}


config = safe_config()
loop_interval = 1 if any(enabled(config, name) for name in ("sensors", "uptime", "services", "processes")) else 60
state = {
    "storage": {"available": False, "mounts": []},
    "sensors": {"available": False, "items": []},
    "uptime": {"available": False, "uptimeSeconds": 0, "processCount": 0},
    "systemInfo": system_identity(),
    "services": {"available": False, "healthy": False, "items": []},
    "processes": {"available": False, "cpu": [], "memory": [], "limit": 3}
}
tick = 0
executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
snapshot_future = None
updates_future = None
while True:
    changed = False
    if snapshot_future is not None and snapshot_future.done():
        try:
            state["systemInfo"].update(snapshot_future.result())
        except Exception:
            state["systemInfo"].update({"snapshotStatus": "unavailable", "snapshotTimestamp": 0})
        snapshot_future = None
        changed = True
    if updates_future is not None and updates_future.done():
        try:
            state["systemInfo"].update(updates_future.result())
        except Exception:
            state["systemInfo"].update({"updatesKnown": False, "updateCount": 0})
        updates_future = None
        changed = True
    if enabled(config, "storage") and tick % 60 == 0:
        state["storage"] = storage(config)
        changed = True
    if enabled(config, "sensors") and tick % 5 == 0:
        state["sensors"] = sensors()
        changed = True
    if enabled(config, "uptime") and tick % 60 == 0:
        state["uptime"] = uptime()
        changed = True
    if enabled(config, "uptime") and tick % 300 == 0 and snapshot_future is None:
        snapshot_future = executor.submit(latest_snapshot)
    if enabled(config, "uptime") and tick % 1800 == 0 and updates_future is None:
        updates_future = executor.submit(pending_updates)
    if enabled(config, "services") and tick % 15 == 0:
        state["services"] = services(config)
        changed = True
    if enabled(config, "processes") and tick % 3 == 0:
        state["processes"] = processes(config)
        changed = True
    if changed:
        print(json.dumps(state), flush=True)
    tick += loop_interval
    time.sleep(loop_interval)
