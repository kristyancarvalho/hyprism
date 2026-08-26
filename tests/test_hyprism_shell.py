import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts/hyprism-shell"


class HyprismShellTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.config = Path(self.temporary.name) / "user.json"
        self.config.write_text((ROOT / "config/user.json").read_text(encoding="utf-8"), encoding="utf-8")
        self.environment = dict(os.environ, HYPRISM_ROOT=str(ROOT), HYPRISM_CONFIG=str(self.config))

    def tearDown(self):
        self.temporary.cleanup()

    def run_cli(self, *arguments):
        return subprocess.run(
            [str(CLI), *arguments],
            env=self.environment,
            text=True,
            capture_output=True,
            check=False,
        )

    def read_config(self):
        return json.loads(self.config.read_text(encoding="utf-8"))

    def use_fake_theme_runtime(self):
        runtime = Path(self.temporary.name) / "theme-runtime"
        script = runtime / "scripts/wallpaper"
        script.parent.mkdir(parents=True)
        script.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
        script.chmod(0o755)
        self.environment["HYPRISM_ROOT"] = str(runtime)

    def test_language_get_set_and_validation(self):
        self.assertEqual(self.run_cli("language").stdout, "en\n")
        changed = self.run_cli("language", "set", "pt-BR")
        self.assertEqual(changed.returncode, 0)
        self.assertEqual(self.read_config()["language"], "pt-BR")

    def test_atomic_write_preserves_managed_symlink(self):
        target = Path(self.temporary.name) / "managed.json"
        target.write_bytes(self.config.read_bytes())
        self.config.unlink()
        self.config.symlink_to(target)
        result = self.run_cli("language", "set", "pt-BR")
        self.assertEqual(result.returncode, 0)
        self.assertTrue(self.config.is_symlink())
        self.assertEqual(json.loads(target.read_text(encoding="utf-8"))["language"], "pt-BR")
        invalid = self.run_cli("language", "set", "fr")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.read_config()["language"], "pt-BR")

    def test_widget_commands_preserve_options(self):
        disabled = self.run_cli("widgets", "disable", "network")
        self.assertEqual(disabled.returncode, 0)
        network = self.read_config()["shell"]["widgets"]["network"]
        self.assertFalse(network["enabled"])
        self.assertEqual(network["historySamples"], 60)
        toggled = self.run_cli("widgets", "toggle", "network")
        self.assertEqual(toggled.returncode, 0)
        self.assertTrue(self.read_config()["shell"]["widgets"]["network"]["enabled"])

    def test_invalid_widget_does_not_change_configuration(self):
        before = self.config.read_bytes()
        invalid = self.run_cli("widgets", "disable", "does-not-exist")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)

    def test_all_widgets_only_changes_desktop_widgets(self):
        config = self.read_config()
        config["custom"] = {"enabled": True}
        self.config.write_text(json.dumps(config), encoding="utf-8")
        result = self.run_cli("widgets", "disable", "--all")
        self.assertEqual(result.returncode, 0)
        updated = self.read_config()
        self.assertTrue(updated["custom"]["enabled"])
        self.assertTrue(all(not updated["shell"]["widgets"][name]["enabled"] for name in (
            "clock", "weather", "media", "system", "network", "storage", "sensors", "uptime", "services", "tasks", "processes"
        )))

    def test_weather_query_and_empty_location(self):
        self.assertEqual(self.run_cli("weather", "location").stdout, "São Paulo\n")
        invalid = self.run_cli("weather", "location", "")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.read_config()["weather"]["location"], "São Paulo")

    def test_theme_mode_and_manual_override(self):
        self.use_fake_theme_runtime()
        self.assertEqual(self.run_cli("theme", "get").stdout, "dark\n")
        selected = self.run_cli("theme", "set", "light")
        self.assertEqual(selected.returncode, 0)
        self.assertEqual(selected.stdout, "light\n")
        self.assertEqual(self.read_config()["appearance"]["mode"], "light")
        config = self.read_config()
        config["appearance"]["schedule"]["enabled"] = True
        self.config.write_text(json.dumps(config), encoding="utf-8")
        toggled = self.run_cli("theme", "toggle")
        self.assertEqual(toggled.returncode, 0)
        self.assertEqual(self.read_config()["appearance"]["mode"], "dark")
        self.assertFalse(self.read_config()["appearance"]["schedule"]["enabled"])

    def test_warm_white_persists_and_regenerates_in_light_mode(self):
        self.use_fake_theme_runtime()
        self.assertEqual(self.run_cli("theme", "warm-white", "get").stdout, "disabled\n")
        enabled = self.run_cli("theme", "warm-white", "set", "on")
        self.assertEqual(enabled.returncode, 0)
        self.assertTrue(self.read_config()["appearance"]["warmWhite"])
        self.run_cli("theme", "set", "light")
        toggled = self.run_cli("theme", "warm-white", "toggle")
        self.assertEqual(toggled.stdout, "disabled\n")
        self.assertFalse(self.read_config()["appearance"]["warmWhite"])

    def test_theme_schedule_validation_and_cross_midnight(self):
        self.use_fake_theme_runtime()
        configured = self.run_cli("theme", "schedule", "set", "18:00", "06:00")
        self.assertEqual(configured.returncode, 0)
        self.assertEqual(self.run_cli("theme", "schedule", "get").stdout, "disabled 18:00 06:00\n")
        before = self.config.read_bytes()
        invalid = self.run_cli("theme", "schedule", "set", "25:00", "06:00")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)
        same = self.run_cli("theme", "schedule", "set", "06:00", "06:00")
        self.assertNotEqual(same.returncode, 0)
        config = self.read_config()
        config["appearance"]["schedule"]["enabled"] = True
        self.config.write_text(json.dumps(config), encoding="utf-8")
        night = self.run_cli("_theme-reconcile", "--now", "19:00")
        self.assertEqual(night.returncode, 0)
        self.assertEqual(self.read_config()["appearance"]["mode"], "light")
        day = self.run_cli("_theme-reconcile", "--now", "12:00")
        self.assertEqual(day.returncode, 0)
        self.assertEqual(self.read_config()["appearance"]["mode"], "dark")

    def test_theme_schedule_set_can_update_state_atomically(self):
        self.use_fake_theme_runtime()
        enabled = self.run_cli("theme", "schedule", "set", "08:15", "19:45", "--enable")
        self.assertEqual(enabled.returncode, 0)
        schedule = self.read_config()["appearance"]["schedule"]
        self.assertEqual(schedule["lightStart"], "08:15")
        self.assertEqual(schedule["darkStart"], "19:45")
        self.assertTrue(schedule["enabled"])
        disabled = self.run_cli("theme", "schedule", "set", "07:30", "18:30", "--disable")
        self.assertEqual(disabled.returncode, 0)
        schedule = self.read_config()["appearance"]["schedule"]
        self.assertEqual(schedule["lightStart"], "07:30")
        self.assertEqual(schedule["darkStart"], "18:30")
        self.assertFalse(schedule["enabled"])

    def test_migration_preserves_legacy_preferences_and_ptbr(self):
        existing = Path(self.temporary.name) / "existing.json"
        existing.write_text(json.dumps({"shell": {"widgets": {"clock": {"enabled": False}}}, "weather": {"location": "Recife"}}), encoding="utf-8")
        result = self.run_cli("_migrate", "--language", "en", "--existing", str(existing))
        self.assertEqual(result.returncode, 0)
        migrated = self.read_config()
        self.assertEqual(migrated["language"], "pt-BR")
        self.assertEqual(migrated["appearance"]["mode"], "dark")
        self.assertFalse(migrated["appearance"]["warmWhite"])
        self.assertFalse(migrated["appearance"]["schedule"]["enabled"])
        self.assertFalse(migrated["shell"]["widgets"]["clock"]["enabled"])
        self.assertEqual(migrated["weather"]["location"], "Recife")

    def test_fresh_migration_uses_requested_language(self):
        result = self.run_cli("_migrate", "--language", "pt-BR")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.read_config()["language"], "pt-BR")
        self.assertEqual(self.read_config()["appearance"]["mode"], "dark")
        self.assertFalse(self.read_config()["appearance"]["warmWhite"])

    def test_public_actions_route_to_internal_implementations(self):
        fake_root = Path(self.temporary.name) / "runtime"
        (fake_root / "config").mkdir(parents=True)
        (fake_root / "config/user.json").write_text((ROOT / "config/user.json").read_text(encoding="utf-8"), encoding="utf-8")
        for relative in (
            "scripts/wallpaper",
            "scripts/system/action",
            "scripts/system/lock",
            "scripts/system/reload-shell",
            "scripts/system/shell-ipc",
        ):
            script = fake_root / relative
            script.parent.mkdir(parents=True, exist_ok=True)
            script.write_text("#!/usr/bin/env bash\nprintf '%s\\n' \"$*\"\n", encoding="utf-8")
            script.chmod(0o755)
        self.environment["HYPRISM_ROOT"] = str(fake_root)
        cases = {
            ("wallpaper", "random"): "random\n",
            ("wallpaper", "set", "/tmp/image.png"): "set /tmp/image.png\n",
            ("wallpaper", "current"): "current\n",
            ("wallpaper", "list"): "list\n",
            ("screenshot", "region"): "screenshot-area\n",
            ("screenshot", "monitor"): "screenshot-monitor\n",
            ("color",): "color-picker\n",
            ("lock",): "\n",
            ("reload",): "\n",
            ("recording",): "shell toggleRecording\n",
            ("night-mode", "on"): "night-mode on\n",
            ("night-mode", "off"): "night-mode off\n",
            ("night-mode", "toggle"): "night-mode toggle\n",
            ("open", "hub"): "shell openHub\n",
            ("open", "launcher"): "shell toggleLauncher\n",
            ("open", "clipboard"): "shell toggleClipboard\n",
            ("open", "wallpapers"): "shell toggleWallpaperPicker\n",
            ("open", "network"): "shell toggleNetwork\n",
            ("open", "bluetooth"): "shell toggleBluetooth\n",
            ("open", "power"): "shell togglePowerMenu\n",
            ("open", "emoji"): "shell toggleEmojiPicker\n",
            ("open", "recording"): "shell toggleRecording\n",
        }
        for arguments, expected in cases.items():
            with self.subTest(arguments=arguments):
                result = self.run_cli(*arguments)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, expected)

    def test_help_only_shows_public_commands(self):
        help_result = self.run_cli("--help")
        self.assertEqual(help_result.returncode, 0)
        self.assertNotIn("_migrate", help_result.stdout)


if __name__ == "__main__":
    unittest.main()
