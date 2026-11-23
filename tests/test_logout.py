import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
LOGOUT = ROOT / "scripts/system/logout"


class LogoutHelperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.base = Path(self.temporary.name)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "calls.log"

    def tearDown(self):
        self.temporary.cleanup()

    def mock(self, name, status=0, output=""):
        path = self.bin / name
        path.write_text(f'#!/bin/sh\nprintf \'%s %s\\n\' "{name}" "$*" >> "{self.log}"\n[ -z "{output}" ] || printf \'%s\\n\' "{output}"\nexit {status}\n', encoding="utf-8")
        path.chmod(path.stat().st_mode | stat.S_IXUSR)

    def run_logout(self, signature="instance"):
        environment = {"PATH": str(self.bin)}
        if signature:
            environment["HYPRLAND_INSTANCE_SIGNATURE"] = signature
        return subprocess.run([shutil.which("bash"), str(LOGOUT)], env=environment, text=True, capture_output=True, check=False)

    def calls(self):
        return self.log.read_text(encoding="utf-8").splitlines() if self.log.exists() else []

    def test_hyprshutdown_is_preferred_and_the_dispatcher_is_not_used(self):
        self.mock("hyprshutdown")
        self.mock("hyprctl")
        result = self.run_logout()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["hyprshutdown "])

    def test_dispatcher_fallback_uses_the_lua_exit_dispatcher_exactly_once(self):
        self.mock("hyprctl", output="ok")
        result = self.run_logout()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["hyprctl dispatch hl.dsp.exit()"])

    def test_failed_hyprshutdown_falls_back_to_the_dispatcher(self):
        self.mock("hyprshutdown", status=3)
        self.mock("hyprctl", output="ok")
        result = self.run_logout()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["hyprshutdown ", "hyprctl dispatch hl.dsp.exit()"])
        self.assertIn("hyprshutdown failed", result.stderr)

    def test_dispatcher_errors_are_reported_and_fail_the_command(self):
        self.mock("hyprctl", status=7, output="error: expected a dispatcher")
        self.mock("notify-send")
        result = self.run_logout()
        self.assertEqual(result.returncode, 7)
        self.assertIn("expected a dispatcher", result.stderr)
        self.assertTrue(any(call.startswith("notify-send") and "expected a dispatcher" in call for call in self.calls()))

    def test_error_text_with_a_successful_status_is_still_a_failure(self):
        self.mock("hyprctl", status=0, output="error: invalid")
        result = self.run_logout()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid", result.stderr)

    def test_missing_hyprland_instance_never_invokes_hyprctl(self):
        self.mock("hyprctl")
        result = self.run_logout(signature="")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [])
        self.assertIn("No Hyprland instance", result.stderr)

    def test_missing_hyprctl_is_reported(self):
        result = self.run_logout()
        self.assertEqual(result.returncode, 127)
        self.assertIn("hyprctl is unavailable", result.stderr)


class LogoutIntegrationTests(unittest.TestCase):
    def test_keybinding_and_power_menu_share_the_same_helper(self):
        keybindings = (ROOT / "config/hypr/modules/keybindings.lua").read_text(encoding="utf-8")
        self.assertIn('bind(mod .. " + M", script("system/logout"))', keybindings)
        self.assertNotIn("hyprshutdown", keybindings)
        controller = (ROOT / "config/quickshell/ShellController.qml").read_text(encoding="utf-8")
        self.assertIn('logoutRunner.exec([rootDir + "/scripts/system/logout"])', controller)
        self.assertIn("if (logoutRunner.running) return", controller)
        self.assertIn("exitCode !== 0", controller)
        self.assertIn('I18n.tr("power.logoutFailed")', controller)
        menu = (ROOT / "config/quickshell/panels/PowerMenu.qml").read_text(encoding="utf-8")
        self.assertNotIn("hyprctl dispatch exit", menu)
        self.assertNotIn("hyprshutdown", menu)
        self.assertIn("logout: true", menu)
        self.assertIn("if (entry.logout) controller.logout()", menu)

    def test_confirmation_flow_still_guards_destructive_entries(self):
        menu = (ROOT / "config/quickshell/panels/PowerMenu.qml").read_text(encoding="utf-8")
        self.assertIn("if (entry.destructive && confirming !== entry.label) {", menu)
        self.assertIn("confirming = entry.label\n            return", menu)
        logout_entry = next(line for line in menu.splitlines() if 'icon: "logout"' in line)
        self.assertIn("destructive: true", logout_entry)

    def test_logout_failure_message_is_translated(self):
        for language in ("en", "pt-BR"):
            catalog = json.loads((ROOT / f"config/quickshell/i18n/{language}.json").read_text(encoding="utf-8"))
            self.assertTrue(catalog["power"]["logoutFailed"])

    def test_helper_is_executable_and_linted(self):
        self.assertTrue(os.access(LOGOUT, os.X_OK))
        self.assertIn("scripts/system/logout", (ROOT / "Makefile").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
