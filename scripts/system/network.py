#!/usr/bin/env python3
import json
import subprocess
import sys


def run(args, input_text=None):
    try:
        return subprocess.run(
            args,
            input=input_text,
            text=True,
            capture_output=True,
            timeout=20,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as error:
        return subprocess.CompletedProcess(args, 1, "", str(error))


def records(output, first_field):
    parsed = []
    current = {}
    for line in output.splitlines():
        key, separator, value = line.partition(":")
        if not separator:
            continue
        if key == first_field and current:
            parsed.append(current)
            current = {}
        current[key] = value
    if current:
        parsed.append(current)
    return parsed


def saved_profiles():
    result = run([
        "nmcli", "--mode", "multiline", "--terse", "--escape", "no",
        "--fields", "UUID,TYPE,TIMESTAMP", "connection", "show",
    ])
    profiles = {}
    for profile in records(result.stdout, "UUID"):
        if profile.get("TYPE") not in ("802-11-wireless", "wifi"):
            continue
        uuid = profile.get("UUID", "")
        if not uuid:
            continue
        details = run([
            "nmcli", "--get-values", "802-11-wireless.ssid",
            "connection", "show", "uuid", uuid,
        ])
        ssid = details.stdout.rstrip("\n")
        if not ssid:
            continue
        timestamp = int(profile.get("TIMESTAMP", "0")) if profile.get("TIMESTAMP", "0").isdigit() else 0
        previous = profiles.get(ssid)
        if previous is None or timestamp > previous["timestamp"]:
            profiles[ssid] = {"uuid": uuid, "timestamp": timestamp}
    return profiles


def visible_networks():
    profiles = saved_profiles()
    result = run([
        "nmcli", "--mode", "multiline", "--terse", "--escape", "no",
        "--fields", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
        "--rescan", "auto",
    ])
    unique = {}
    for network in records(result.stdout, "IN-USE"):
        ssid = network.get("SSID", "")
        if not ssid:
            continue
        signal_text = network.get("SIGNAL", "0")
        signal = int(signal_text) if signal_text.isdigit() else 0
        existing = unique.get(ssid)
        if existing is not None and existing["signal"] >= signal:
            if network.get("IN-USE", "").strip() == "*":
                existing["connected"] = True
            continue
        profile = profiles.get(ssid)
        unique[ssid] = {
            "ssid": ssid,
            "signal": signal,
            "secure": bool(network.get("SECURITY", "").strip() and network.get("SECURITY", "").strip() != "--"),
            "connected": network.get("IN-USE", "").strip() == "*",
            "known": profile is not None,
            "profileUuid": profile["uuid"] if profile else "",
        }
    return sorted(unique.values(), key=lambda item: (not item["connected"], -item["signal"]))


def connect(ssid, profile_uuid=""):
    if profile_uuid:
        return run(["nmcli", "connection", "up", "uuid", profile_uuid])
    password = sys.stdin.readline().rstrip("\n")
    if password:
        return run(["nmcli", "--ask", "device", "wifi", "connect", ssid], password + "\n")
    return run(["nmcli", "device", "wifi", "connect", ssid])


def main(arguments):
    if len(arguments) < 2:
        raise SystemExit("usage: network.py {list|toggle|connect} ...")
    command = arguments[1]
    if command == "list":
        print(json.dumps(visible_networks()))
        return 0
    if command == "toggle" and len(arguments) == 3:
        return run(["nmcli", "radio", "wifi", arguments[2]]).returncode
    if command == "connect" and len(arguments) in (3, 4):
        return connect(arguments[2], arguments[3] if len(arguments) == 4 else "").returncode
    raise SystemExit("usage: network.py {list|toggle|connect} ...")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
