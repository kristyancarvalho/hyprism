import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts/hyprism-shell"
BACKEND_PATH = ROOT / "scripts/system/keyboard_backend.py"
SPEC = importlib.util.spec_from_file_location("keyboard_backend", BACKEND_PATH)
BACKEND = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BACKEND)


class KeyboardBackendTests(unittest.TestCase):
    def test_project_defaults_have_no_personal_keyboard_assumptions(self):
        config = json.loads((ROOT / "config/user.json").read_text(encoding="utf-8"))
        input_module = (ROOT / "config/hypr/modules/input.lua").read_text(encoding="utf-8")
        self.assertIsNone(config["keyboard"]["default"])
        self.assertEqual(config["keyboard"]["devices"], {})
        self.assertNotIn('kb_layout = "br"', input_module)
        self.assertNotIn("sonix-ak820", input_module)
        self.assertNotIn("2.4g-wireless-device", input_module)

    def test_common_presets_use_xkb_layout_and_variant(self):
        self.assertEqual(BACKEND.preset_value("us"), {"layout": "us", "variant": ""})
        self.assertEqual(BACKEND.preset_value("us-intl"), {"layout": "us", "variant": "intl"})
        self.assertEqual(BACKEND.preset_value("br-abnt2"), {"layout": "br", "variant": ""})

    def test_generated_lua_contains_only_explicit_values(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "keyboard.lua"
            BACKEND.render_config({
                "keyboard": {
                    "default": None,
                    "devices": {
                        "external-keyboard": {"layout": "us", "variant": "intl"},
                        "removed": None,
                    },
                },
            }, output)
            content = output.read_text(encoding="utf-8")
            self.assertIn('name = "external-keyboard"', content)
            self.assertIn('kb_layout = "us"', content)
            self.assertIn('kb_variant = "intl"', content)
            self.assertNotIn("removed", content)
            self.assertNotIn("at-translated", content)

    def test_group_targets_are_classification_only(self):
        devices = [
            {"id": "one", "ids": ["one", "one-hotkeys"], "classification": "internal", "auxiliary": False},
            {"id": "two", "ids": ["two"], "classification": "external", "auxiliary": False},
            {"id": "three", "ids": ["three"], "classification": "keyboard", "auxiliary": False},
        ]
        self.assertEqual(BACKEND.targets_for(devices, "built-in"), ["one", "one-hotkeys"])
        self.assertEqual(BACKEND.targets_for(devices, "external"), ["two"])
        self.assertEqual(BACKEND.targets_for(devices, "all"), ["one", "one-hotkeys", "two", "three"])

    def test_pointer_receiver_interfaces_are_auxiliary(self):
        interfaces = [
            {"id": "real", "name": "Real", "classification": "external", "group": "usb-real", "pointerGroup": True, "main": True, "layout": "us", "variant": "", "keymap": "US"},
            {"id": "receiver", "name": "Receiver", "classification": "external", "group": "usb-mouse", "pointerGroup": True, "main": False, "layout": "us", "variant": "", "keymap": "US"},
            {"id": "at", "name": "AT", "classification": "internal", "group": "internal-at", "pointerGroup": False, "main": False, "layout": "br", "variant": "", "keymap": "BR"},
            {"id": "hotkeys", "name": "Hotkeys", "classification": "internal", "group": "internal-hotkeys", "pointerGroup": True, "main": False, "layout": "br", "variant": "", "keymap": "BR"},
        ]
        with mock.patch.object(BACKEND, "discover_interfaces", return_value=interfaces):
            visible = BACKEND.discover_devices()
            all_devices = BACKEND.discover_devices(include_auxiliary=True)
        self.assertEqual([item["id"] for item in visible], ["built-in", "real"])
        self.assertEqual([item["id"] for item in all_devices], ["built-in", "real", "receiver"])
        self.assertEqual(next(item for item in visible if item["id"] == "built-in")["ids"], ["at", "hotkeys"])

    def test_inconclusive_detection_keeps_neutral_defaults(self):
        with mock.patch.object(BACKEND, "runtime_default_layout", return_value=None), mock.patch.object(
            BACKEND, "system_layout", return_value=None
        ), mock.patch.object(
            BACKEND, "discover_devices", side_effect=BACKEND.KeyboardError("Hyprland unavailable")
        ):
            detected = BACKEND.capture_initial_config()
        self.assertIsNone(detected["default"])
        self.assertEqual(detected["devices"], {})


class KeyboardCliTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)
        self.config = root / "user.json"
        self.config.write_text((ROOT / "config/user.json").read_text(encoding="utf-8"), encoding="utf-8")
        self.log = root / "hyprctl.log"
        self.hyprctl = root / "hyprctl"
        self.hyprctl.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "if sys.argv[1:] == ['devices', '-j']:\n"
            " print(json.dumps({'keyboards': [{'name': 'test-keyboard', 'model': 'Test Keyboard', 'layout': 'br', 'variant': '', 'active_keymap': 'Portuguese (Brazil)', 'main': True}]}))\n"
            "else:\n"
            " open(os.environ['HYPRISM_TEST_LOG'], 'a').write(' '.join(sys.argv[1:]) + '\\n')\n"
            " print('ok')\n",
            encoding="utf-8",
        )
        self.hyprctl.chmod(0o755)
        self.environment = {
            **os.environ,
            "HYPRISM_ROOT": str(ROOT),
            "HYPRISM_CONFIG": str(self.config),
            "HYPRISM_HYPRCTL": str(self.hyprctl),
            "HYPRISM_TEST_LOG": str(self.log),
            "XDG_CACHE_HOME": str(root / "cache"),
        }

    def tearDown(self):
        self.temporary.cleanup()

    def run_cli(self, *arguments):
        return subprocess.run([CLI, *arguments], env=self.environment, text=True, capture_output=True, check=False)

    def test_set_persists_per_device_and_generates_config(self):
        result = self.run_cli("keyboard", "set", "test-keyboard", "us-intl")
        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(self.config.read_text(encoding="utf-8"))
        self.assertEqual(config["keyboard"]["devices"]["test-keyboard"], {"layout": "us", "variant": "intl"})
        generated = Path(self.environment["XDG_CACHE_HOME"]) / "hyprism/state/keyboard.lua"
        self.assertIn('name = "test-keyboard"', generated.read_text(encoding="utf-8"))
        self.assertIn('kb_variant = "intl"', self.log.read_text(encoding="utf-8"))

    def test_system_preset_removes_device_override(self):
        config = json.loads(self.config.read_text(encoding="utf-8"))
        config["keyboard"]["devices"]["test-keyboard"] = {"layout": "us", "variant": "intl"}
        self.config.write_text(json.dumps(config), encoding="utf-8")
        result = self.run_cli("keyboard", "set", "test-keyboard", "system")
        self.assertEqual(result.returncode, 0, result.stderr)
        updated = json.loads(self.config.read_text(encoding="utf-8"))
        self.assertNotIn("test-keyboard", updated["keyboard"]["devices"])

    def test_system_preset_removes_disconnected_device_override(self):
        config = json.loads(self.config.read_text(encoding="utf-8"))
        config["keyboard"]["devices"]["disconnected-keyboard"] = {"layout": "de", "variant": ""}
        self.config.write_text(json.dumps(config), encoding="utf-8")
        result = self.run_cli("keyboard", "set", "disconnected-keyboard", "system")
        self.assertEqual(result.returncode, 0, result.stderr)
        updated = json.loads(self.config.read_text(encoding="utf-8"))
        self.assertNotIn("disconnected-keyboard", updated["keyboard"]["devices"])

    def test_devices_json_distinguishes_runtime_and_override(self):
        result = self.run_cli("keyboard", "devices", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        values = json.loads(result.stdout)
        self.assertEqual(values[0]["id"], "test-keyboard")
        self.assertEqual(values[0]["layout"], "br")
        self.assertEqual(values[0]["source"], "runtime")


if __name__ == "__main__":
    unittest.main()
