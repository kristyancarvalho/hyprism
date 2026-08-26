import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("hyprism_network", ROOT / "scripts/system/network.py")
NETWORK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NETWORK)


def completed(args, stdout="", returncode=0):
    return subprocess.CompletedProcess(args, returncode, stdout, "")


class NetworkTests(unittest.TestCase):
    def test_records_preserve_colons_in_values(self):
        output = "IN-USE: \nSSID:Cafe:Guest\nSIGNAL:70\nIN-USE:*\nSSID:Home\nSIGNAL:90\n"
        self.assertEqual(NETWORK.records(output, "IN-USE")[0]["SSID"], "Cafe:Guest")
        self.assertEqual(NETWORK.records(output, "IN-USE")[1]["IN-USE"], "*")

    def test_visible_networks_use_saved_profiles_and_distinct_states(self):
        profiles = "\n".join((
            "UUID:saved-uuid", "TYPE:802-11-wireless", "TIMESTAMP:20",
            "UUID:ethernet-uuid", "TYPE:802-3-ethernet", "TIMESTAMP:30",
        ))
        visible = "\n".join((
            "IN-USE:*", "SSID:Home", "SIGNAL:80", "SECURITY:WPA2",
            "IN-USE: ", "SSID:Cafe", "SIGNAL:60", "SECURITY:--",
            "IN-USE: ", "SSID:Guest", "SIGNAL:50", "SECURITY:WPA2",
        ))

        def fake_run(args, input_text=None):
            if "UUID,TYPE,TIMESTAMP" in args:
                return completed(args, profiles)
            if "802-11-wireless.ssid" in args:
                return completed(args, "Home\n")
            return completed(args, visible)

        with patch.object(NETWORK, "run", fake_run):
            networks = NETWORK.visible_networks()
        by_ssid = {entry["ssid"]: entry for entry in networks}
        self.assertTrue(by_ssid["Home"]["connected"])
        self.assertTrue(by_ssid["Home"]["known"])
        self.assertEqual(by_ssid["Home"]["profileUuid"], "saved-uuid")
        self.assertFalse(by_ssid["Cafe"]["secure"])
        self.assertFalse(by_ssid["Cafe"]["known"])
        self.assertTrue(by_ssid["Guest"]["secure"])
        self.assertFalse(by_ssid["Guest"]["known"])

    def test_known_connection_uses_profile_uuid(self):
        calls = []
        with patch.object(NETWORK, "run", lambda args, input_text=None: calls.append((args, input_text)) or completed(args)):
            NETWORK.connect("Home", "saved-uuid")
        self.assertEqual(calls, [(["nmcli", "connection", "up", "uuid", "saved-uuid"], None)])

    def test_password_is_sent_over_stdin_not_process_arguments(self):
        calls = []
        with patch.object(NETWORK, "run", lambda args, input_text=None: calls.append((args, input_text)) or completed(args)):
            with patch.object(sys, "stdin", io.StringIO("secret value\n")):
                NETWORK.connect("Guest")
        arguments, input_text = calls[0]
        self.assertNotIn("secret value", arguments)
        self.assertEqual(arguments, ["nmcli", "--ask", "device", "wifi", "connect", "Guest"])
        self.assertEqual(input_text, "secret value\n")

    def test_open_network_connects_without_password(self):
        calls = []
        with patch.object(NETWORK, "run", lambda args, input_text=None: calls.append((args, input_text)) or completed(args)):
            with patch.object(sys, "stdin", io.StringIO("\n")):
                NETWORK.connect("Cafe")
        self.assertEqual(calls, [(["nmcli", "device", "wifi", "connect", "Cafe"], None)])


if __name__ == "__main__":
    unittest.main()
