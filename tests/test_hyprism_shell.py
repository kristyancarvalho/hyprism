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

    def use_fake_systemctl(self):
        directory = Path(self.temporary.name) / "bin"
        directory.mkdir(exist_ok=True)
        command = directory / "systemctl"
        command.write_text("""#!/usr/bin/env python3
import sys
unit = next((value for value in sys.argv if value.endswith(('.service', '.socket', '.timer'))), '')
if unit == 'manager-down.service':
    print('Failed to connect to bus', file=sys.stderr)
    raise SystemExit(1)
elif unit == 'missing.service':
    print('LoadState=not-found')
    print('ActiveState=inactive')
elif unit == 'inactive.timer':
    print('LoadState=loaded')
    print('ActiveState=inactive')
else:
    print('LoadState=loaded')
    print('ActiveState=active')
""", encoding="utf-8")
        command.chmod(0o755)
        self.environment["PATH"] = str(directory) + os.pathsep + self.environment["PATH"]

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

    def test_widget_commands_preserve_explicit_false_in_partial_config(self):
        self.config.write_text(json.dumps({
            "shell": {"widgets": {"clock": False, "weather": {"enabled": False}}},
            "custom": {"enabled": False},
        }), encoding="utf-8")
        listed = self.run_cli("widgets", "list")
        self.assertEqual(listed.returncode, 0)
        states = dict(line.split("\t") for line in listed.stdout.splitlines())
        self.assertEqual(states["clock"], "disabled")
        self.assertEqual(states["weather"], "disabled")
        enabled = self.run_cli("widgets", "enable", "clock")
        self.assertEqual(enabled.returncode, 0)
        updated = self.read_config()
        self.assertTrue(updated["shell"]["widgets"]["clock"]["enabled"])
        self.assertFalse(updated["shell"]["widgets"]["weather"]["enabled"])
        self.assertFalse(updated["custom"]["enabled"])

    def test_invalid_widget_does_not_change_configuration(self):
        before = self.config.read_bytes()
        invalid = self.run_cli("widgets", "disable", "does-not-exist")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)

    def test_services_list_reports_system_and_user_state(self):
        self.use_fake_systemctl()
        listed = self.run_cli("services", "list", "--json")
        self.assertEqual(listed.returncode, 0, listed.stderr)
        items = json.loads(listed.stdout)
        self.assertEqual([item["scope"] for item in items], ["system", "system", "user"])
        self.assertTrue(all(item["state"] == "active" for item in items))

    def test_services_add_normalizes_deduplicates_and_removes(self):
        self.use_fake_systemctl()
        added = self.run_cli("services", "add", "cups")
        self.assertEqual(added.returncode, 0, added.stderr)
        items = self.read_config()["shell"]["widgets"]["services"]["items"]
        self.assertEqual(sum(item["unit"] == "cups.service" for item in items), 1)
        duplicate = self.run_cli("services", "add", "cups.service")
        self.assertEqual(duplicate.returncode, 0, duplicate.stderr)
        items = self.read_config()["shell"]["widgets"]["services"]["items"]
        self.assertEqual(sum(item["unit"] == "cups.service" for item in items), 1)
        removed = self.run_cli("services", "remove", "cups")
        self.assertEqual(removed.returncode, 0, removed.stderr)
        self.assertFalse(any(item["unit"] == "cups.service" for item in self.read_config()["shell"]["widgets"]["services"]["items"]))

    def test_services_preserve_explicit_unit_type_and_user_scope(self):
        self.use_fake_systemctl()
        added = self.run_cli("services", "add", "inactive.timer", "--user")
        self.assertEqual(added.returncode, 0, added.stderr)
        listed = json.loads(self.run_cli("services", "list", "--json").stdout)
        item = next(item for item in listed if item["unit"] == "inactive.timer")
        self.assertEqual(item["scope"], "user")
        self.assertEqual(item["state"], "inactive")

    def test_services_reject_missing_unit_without_changing_config(self):
        self.use_fake_systemctl()
        before = self.config.read_bytes()
        missing = self.run_cli("services", "add", "missing")
        self.assertNotEqual(missing.returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)

    def test_services_report_configured_unit_that_disappears(self):
        self.use_fake_systemctl()
        config = self.read_config()
        config["shell"]["widgets"]["services"]["items"] = [
            {"name": "Missing", "unit": "missing.service", "scope": "system"}
        ]
        self.config.write_text(json.dumps(config), encoding="utf-8")
        listed = self.run_cli("services", "list", "--json")
        self.assertEqual(listed.returncode, 0, listed.stderr)
        self.assertEqual(json.loads(listed.stdout)[0]["state"], "not-found")

    def test_services_fail_clearly_when_systemd_manager_is_unavailable(self):
        self.use_fake_systemctl()
        config = self.read_config()
        config["shell"]["widgets"]["services"]["items"] = [
            {"name": "Unavailable", "unit": "manager-down.service", "scope": "user"}
        ]
        self.config.write_text(json.dumps(config), encoding="utf-8")
        listed = self.run_cli("services", "list")
        self.assertNotEqual(listed.returncode, 0)
        self.assertIn("Failed to connect to bus", listed.stderr)

    def test_services_explicit_empty_list_does_not_restore_defaults(self):
        self.use_fake_systemctl()
        config = self.read_config()
        config["shell"]["widgets"]["services"]["items"] = []
        self.config.write_text(json.dumps(config), encoding="utf-8")
        listed = self.run_cli("services", "list", "--json")
        self.assertEqual(json.loads(listed.stdout), [])
        absent = self.run_cli("services", "remove", "NetworkManager")
        self.assertEqual(absent.returncode, 0)
        self.assertEqual(self.read_config()["shell"]["widgets"]["services"]["items"], [])

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

    def test_white_temperature_persists_and_regenerates_in_light_mode(self):
        self.use_fake_theme_runtime()
        self.assertEqual(self.run_cli("theme", "temperature", "get").stdout, "0\n")
        selected = self.run_cli("theme", "temperature", "set", "2")
        self.assertEqual(selected.returncode, 0)
        self.assertEqual(self.read_config()["appearance"]["whiteTemperature"], 2)
        self.run_cli("theme", "set", "light")
        amber = self.run_cli("theme", "temperature", "set", "3")
        self.assertEqual(amber.stdout, "3\n")
        self.assertEqual(self.read_config()["appearance"]["whiteTemperature"], 3)
        invalid = self.run_cli("theme", "temperature", "set", "4")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertEqual(self.read_config()["appearance"]["whiteTemperature"], 3)

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
        self.assertEqual(migrated["appearance"]["whiteTemperature"], 0)
        self.assertFalse(migrated["appearance"]["schedule"]["enabled"])
        self.assertFalse(migrated["shell"]["widgets"]["clock"]["enabled"])
        self.assertEqual(migrated["weather"]["location"], "Recife")

    def test_fresh_migration_uses_requested_language(self):
        home = Path(self.temporary.name) / "home"
        self.environment["HOME"] = str(home)
        self.environment["HYPRISM_PICTURES_DIR"] = str(home / "Imagens")
        self.environment["HYPRISM_VIDEOS_DIR"] = str(home / "Vídeos")
        result = self.run_cli("_migrate", "--language", "pt-BR")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.read_config()["language"], "pt-BR")
        self.assertEqual(self.read_config()["appearance"]["mode"], "dark")
        self.assertEqual(self.read_config()["appearance"]["whiteTemperature"], 0)
        self.assertEqual(self.read_config()["paths"], {
            "wallpapers": "~/Imagens/Wallpapers",
            "screenshots": "~/Imagens/Screenshots",
            "recordings": "~/Vídeos/gravacoes",
        })

    def test_init_creates_user_state_and_preserves_explicit_values(self):
        home = Path(self.temporary.name) / "home"
        config = home / ".config/hyprism/user.json"
        self.environment.update({
            "HOME": str(home),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "HYPRISM_CONFIG": str(config),
            "HYPRISM_SKIP_SERVICE_ENABLE": "1",
        })
        initialized = self.run_cli("init", "--lang", "pt-BR")
        self.assertEqual(initialized.returncode, 0, initialized.stderr)
        value = json.loads(config.read_text(encoding="utf-8"))
        self.assertEqual(value["language"], "pt-BR")
        self.assertTrue((home / ".config/hypr").is_symlink())
        self.assertTrue((home / ".config/quickshell/default").is_symlink())
        self.assertTrue((home / "Imagens/Wallpapers/abyss.png").is_file())
        self.assertTrue((home / "Imagens/Screenshots").is_dir())
        self.assertTrue((home / "Vídeos/gravacoes").is_dir())
        self.assertEqual(value["paths"]["recordings"], "~/Vídeos/gravacoes")
        value["shell"]["widgets"]["clock"]["enabled"] = False
        value["custom"] = {"enabled": False}
        config.write_text(json.dumps(value), encoding="utf-8")
        repeated = self.run_cli("init", "--lang", "en")
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        persisted = json.loads(config.read_text(encoding="utf-8"))
        self.assertEqual(persisted["language"], "pt-BR")
        self.assertFalse(persisted["shell"]["widgets"]["clock"]["enabled"])
        self.assertFalse(persisted["custom"]["enabled"])

    def test_init_preserves_unmanaged_paths(self):
        home = Path(self.temporary.name) / "home"
        existing = home / ".config/hypr"
        existing.mkdir(parents=True)
        marker = existing / "custom.conf"
        marker.write_text("preserved\n", encoding="utf-8")
        self.environment.update({
            "HOME": str(home),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "HYPRISM_CONFIG": str(home / ".config/hyprism/user.json"),
            "HYPRISM_SKIP_SERVICE_ENABLE": "1",
        })
        initialized = self.run_cli("init")
        self.assertEqual(initialized.returncode, 0, initialized.stderr)
        self.assertFalse(existing.is_symlink())
        self.assertEqual(marker.read_text(encoding="utf-8"), "preserved\n")

    def test_migration_converts_legacy_warm_white(self):
        existing = Path(self.temporary.name) / "existing.json"
        existing.write_text(json.dumps({"appearance": {"mode": "light", "warmWhite": True}}), encoding="utf-8")
        result = self.run_cli("_migrate", "--language", "en", "--existing", str(existing))
        self.assertEqual(result.returncode, 0)
        appearance = self.read_config()["appearance"]
        self.assertEqual(appearance["whiteTemperature"], 2)
        self.assertNotIn("warmWhite", appearance)

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
