import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]


class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.base = Path(self.temporary.name)
        self.runtime = self.base / "runtime"
        self.cache = self.base / "cache"
        self.wallpapers = self.base / "wallpapers"
        self.bin = self.base / "bin"
        self.log = self.base / "generator.log"
        self.output = self.base / "generated-wallpaper"
        (self.runtime / "scripts/theme").mkdir(parents=True)
        self.wallpapers.mkdir()
        self.bin.mkdir()
        wallpaper_script = self.runtime / "scripts/wallpaper"
        shutil.copy2(ROOT / "scripts/wallpaper", wallpaper_script)
        generator = self.runtime / "scripts/theme/generate-theme.py"
        generator.write_text(
            "#!/usr/bin/env bash\n"
            "set -eu\n"
            "name=$(basename \"$1\")\n"
            "printf 'start %s\\n' \"$name\" >>\"$HYPRISM_TEST_LOG\"\n"
            "[[ $name != first.png ]] || sleep .4\n"
            "printf '%s\\n' \"$name\" >\"$HYPRISM_TEST_OUTPUT\"\n",
            encoding="utf-8",
        )
        generator.chmod(0o755)
        shell_ipc = self.runtime / "scripts/system/shell-ipc"
        shell_ipc.parent.mkdir(parents=True)
        shell_ipc.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
        shell_ipc.chmod(0o755)
        for command in ("hyprctl", "kitten", "qs"):
            executable = self.bin / command
            executable.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            executable.chmod(0o755)
        systemctl = self.bin / "systemctl"
        systemctl.write_text("#!/usr/bin/env bash\nexit 1\n", encoding="utf-8")
        systemctl.chmod(0o755)
        self.environment = dict(
            os.environ,
            HOME=str(self.base / "home"),
            HYPRISM_CACHE_DIR=str(self.cache),
            HYPRISM_WALLPAPER_DIR=str(self.wallpapers),
            HYPRISM_TEST_LOG=str(self.log),
            HYPRISM_TEST_OUTPUT=str(self.output),
            PATH=str(self.bin) + os.pathsep + "/usr/bin",
            WAYLAND_DISPLAY="",
            XDG_RUNTIME_DIR=str(self.base / "runtime-dir"),
        )
        self.script = wallpaper_script

    def tearDown(self):
        self.temporary.cleanup()

    def test_overlapping_selections_finish_in_request_order(self):
        first = self.wallpapers / "first.png"
        second = self.wallpapers / "second.png"
        first.touch()
        second.touch()
        older = subprocess.Popen(
            [str(self.script), "set", str(first)],
            env=self.environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            if self.log.is_file() and "start first.png" in self.log.read_text(encoding="utf-8"):
                break
            time.sleep(.01)
        else:
            older.kill()
            self.fail("first wallpaper generation did not start")
        newer = subprocess.Popen(
            [str(self.script), "set", str(second)],
            env=self.environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        older_stdout, older_stderr = older.communicate(timeout=3)
        newer_stdout, newer_stderr = newer.communicate(timeout=3)
        self.assertEqual(older.returncode, 0, older_stdout + older_stderr)
        self.assertEqual(newer.returncode, 0, newer_stdout + newer_stderr)
        self.assertEqual(self.output.read_text(encoding="utf-8"), "second.png\n")
        self.assertEqual(
            (self.cache / "state/current-wallpaper").read_text(encoding="utf-8"),
            str(second.resolve()) + "\n",
        )

    def test_theme_switch_waits_for_wallpaper_selection(self):
        previous = self.wallpapers / "previous.png"
        selected = self.wallpapers / "first.png"
        previous.touch()
        selected.touch()
        state = self.cache / "state/current-wallpaper"
        state.parent.mkdir(parents=True)
        state.write_text(str(previous.resolve()) + "\n", encoding="utf-8")
        selection = subprocess.Popen(
            [str(self.script), "set", str(selected)],
            env=self.environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            if self.log.is_file() and "start first.png" in self.log.read_text(encoding="utf-8"):
                break
            time.sleep(.01)
        else:
            selection.kill()
            self.fail("wallpaper generation did not start")
        theme = subprocess.Popen(
            [str(self.script), "theme"],
            env=self.environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        selection_stdout, selection_stderr = selection.communicate(timeout=3)
        theme_stdout, theme_stderr = theme.communicate(timeout=3)
        self.assertEqual(selection.returncode, 0, selection_stdout + selection_stderr)
        self.assertEqual(theme.returncode, 0, theme_stdout + theme_stderr)
        self.assertEqual(
            self.log.read_text(encoding="utf-8").splitlines(),
            ["start first.png", "start first.png"],
        )


if __name__ == "__main__":
    unittest.main()
