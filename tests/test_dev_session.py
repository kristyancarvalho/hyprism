import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SESSION = ROOT / "scripts/dev/session"


class DevSessionTests(unittest.TestCase):
    def run_session(self, *arguments, environment=None):
        return subprocess.run(["/usr/bin/bash", str(SESSION), *arguments], env=environment, text=True, capture_output=True, check=False)

    def test_makefile_exposes_both_targets_without_touching_install(self):
        help_text = subprocess.run(["make", "-C", str(ROOT), "help"], text=True, capture_output=True, check=True).stdout
        self.assertIn("dev-session ", help_text)
        self.assertIn("dev-session-stop", help_text)
        dry = subprocess.run(["make", "--no-print-directory", "-C", str(ROOT), "-n", "dev-session"], text=True, capture_output=True, check=True).stdout
        self.assertEqual(dry.strip(), "./scripts/dev/session start")

    def test_unknown_action_is_rejected(self):
        result = self.run_session("bogus")
        self.assertEqual(result.returncode, 2)

    def test_missing_dependencies_are_reported_with_exit_127(self):
        with tempfile.TemporaryDirectory() as empty:
            result = self.run_session("start", environment={"PATH": empty, "HOME": empty})
        self.assertEqual(result.returncode, 127)
        self.assertIn("Missing required commands", result.stderr)

    def test_start_refuses_without_a_parent_compositor(self):
        with tempfile.TemporaryDirectory() as directory:
            fake = Path(directory) / "bin"
            fake.mkdir()
            for tool in ("Hyprland", "dbus-run-session", "qs", "awww-daemon", "awww", "jq", "python3"):
                (fake / tool).write_text("#!/bin/sh\n", encoding="utf-8")
                (fake / tool).chmod(0o755)
            environment = {"PATH": str(fake), "HOME": directory, "XDG_RUNTIME_DIR": directory}
            result = self.run_session("start", environment=environment)
        self.assertEqual(result.returncode, 1)
        self.assertIn("No parent compositor", result.stderr)

    def test_session_is_source_first_and_isolated(self):
        text = SESSION.read_text(encoding="utf-8")
        for required in (
            "HYPRISM_ROOT=$root_dir",
            "HYPRISM_CONFIG=$dev_base/config/hyprism/user.json",
            "XDG_CONFIG_HOME=$dev_base/config",
            "dbus-run-session",
            "-u HYPRLAND_INSTANCE_SIGNATURE",
            "setsid",
        ):
            self.assertIn(required, text)
        self.assertNotIn("pkill", text)
        self.assertNotIn("killall", text)

    def test_stop_without_a_session_is_a_noop(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_session("stop", environment={"PATH": os.environ["PATH"], "HOME": directory, "XDG_RUNTIME_DIR": directory})
        self.assertEqual(result.returncode, 0)
        self.assertIn("No development session", result.stdout)


if __name__ == "__main__":
    unittest.main()
