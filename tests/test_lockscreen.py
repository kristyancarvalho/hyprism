import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

from PIL import Image, ImageDraw, ImageStat


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts/hyprism-shell"
LOCKSCREEN = ROOT / "scripts/system/lockscreen"
BACKGROUND = ROOT / "scripts/system/lock-background.py"
QML = ROOT / "config/quickshell"


class LockscreenWidgetTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.config = Path(self.temporary.name) / "user.json"
        self.config.write_text((ROOT / "config/user.json").read_text(encoding="utf-8"), encoding="utf-8")
        self.environment = dict(os.environ, HYPRISM_ROOT=str(ROOT), HYPRISM_CONFIG=str(self.config))

    def tearDown(self):
        self.temporary.cleanup()

    def run_cli(self, *arguments):
        return subprocess.run([str(CLI), *arguments], env=self.environment, text=True, capture_output=True, check=False)

    def read_config(self):
        return json.loads(self.config.read_text(encoding="utf-8"))

    def test_list_shows_every_desktop_widget_with_defaults(self):
        result = self.run_cli("lockscreen", "widgets", "list")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["clock\tenabled", "weather\tenabled", "media\tenabled", "system\tdisabled", "network\tdisabled", "storage\tdisabled", "sensors\tdisabled", "uptime\tdisabled", "services\tdisabled", "tasks\tdisabled", "processes\tdisabled"])

    def test_enable_and_disable_change_only_lockscreen_configuration(self):
        before = self.read_config()
        self.assertEqual(self.run_cli("lockscreen", "widgets", "disable", "weather").returncode, 0)
        self.assertEqual(self.run_cli("lockscreen", "widgets", "enable", "system").returncode, 0)
        after = self.read_config()
        self.assertIs(after["lockscreen"]["widgets"]["weather"], False)
        self.assertIs(after["lockscreen"]["widgets"]["system"], True)
        self.assertEqual(after["shell"], before["shell"])
        desktop = self.run_cli("widgets", "list")
        self.assertIn("weather\tenabled", desktop.stdout)

    def test_desktop_changes_do_not_touch_lockscreen_preferences(self):
        self.run_cli("lockscreen", "widgets", "disable", "clock")
        self.assertEqual(self.run_cli("widgets", "disable", "clock").returncode, 0)
        self.assertEqual(self.run_cli("widgets", "enable", "--all").returncode, 0)
        self.assertIs(self.read_config()["lockscreen"]["widgets"]["clock"], False)

    def test_unknown_widgets_are_rejected_without_writing(self):
        original = self.config.read_text(encoding="utf-8")
        for arguments in (("enable", "nope"), ("disable", "battery"), ("enable", "")):
            result = self.run_cli("lockscreen", "widgets", *arguments)
            self.assertNotEqual(result.returncode, 0, arguments)
        self.assertEqual(self.config.read_text(encoding="utf-8"), original)

    def test_every_desktop_widget_can_be_toggled_individually(self):
        names = [line.split("\t")[0] for line in self.run_cli("widgets", "list").stdout.splitlines()]
        for name in names:
            self.assertEqual(self.run_cli("lockscreen", "widgets", "enable", name).returncode, 0, name)
            self.assertIn(f"{name}\tenabled", self.run_cli("lockscreen", "widgets", "list").stdout)
            others = {line for line in self.run_cli("lockscreen", "widgets", "list").stdout.splitlines()}
            self.assertEqual(self.run_cli("lockscreen", "widgets", "disable", name).returncode, 0, name)
            self.assertIn(f"{name}\tdisabled", self.run_cli("lockscreen", "widgets", "list").stdout)
            self.assertEqual(len(others), len(names))

    def test_enable_and_disable_all(self):
        enabled = self.run_cli("lockscreen", "widgets", "enable", "--all").stdout.splitlines()
        self.assertTrue(all(line.endswith("\tenabled") for line in enabled) and len(enabled) == 11)
        disabled = self.run_cli("lockscreen", "widgets", "disable", "--all").stdout.splitlines()
        self.assertTrue(all(line.endswith("\tdisabled") for line in disabled))
        persisted = self.read_config()["lockscreen"]["widgets"]
        self.assertEqual(set(persisted.values()), {False})
        self.assertEqual(len(persisted), 11)

    def test_existing_partial_configuration_keeps_values_and_defaults_the_rest(self):
        config = self.read_config()
        config["lockscreen"]["widgets"] = {"clock": False, "weather": True}
        self.config.write_text(json.dumps(config), encoding="utf-8")
        lines = self.run_cli("lockscreen", "widgets", "list").stdout.splitlines()
        self.assertIn("clock\tdisabled", lines)
        self.assertIn("media\tenabled", lines)
        self.assertIn("tasks\tdisabled", lines)

    def test_registry_defaults_cover_exactly_the_desktop_widgets(self):
        qml = (QML / "ShellController.qml").read_text(encoding="utf-8")
        block = qml[qml.index("readonly property var widgetDefaults"):qml.index("property var config:")]
        registered = re.findall(r"^        (\w+): \{", block, re.M)
        desktop = list(json.loads((ROOT / "config/user.json").read_text(encoding="utf-8"))["shell"]["widgets"])
        defaults = json.loads((ROOT / "config/lockscreen/widgets.json").read_text(encoding="utf-8"))["defaults"]
        cli = [line.split("\t")[0] for line in self.run_cli("lockscreen", "widgets", "list").stdout.splitlines()]
        self.assertEqual(registered, desktop)
        self.assertEqual(list(defaults), desktop)
        self.assertEqual(cli, desktop)
        self.assertEqual(json.loads((ROOT / "config/user.json").read_text(encoding="utf-8"))["lockscreen"]["widgets"], defaults)

    def test_missing_configuration_uses_catalog_defaults_and_keeps_explicit_false(self):
        config = self.read_config()
        del config["lockscreen"]
        self.config.write_text(json.dumps(config), encoding="utf-8")
        self.assertIn("media\tenabled", self.run_cli("lockscreen", "widgets", "list").stdout)
        self.run_cli("lockscreen", "widgets", "disable", "media")
        self.assertIn("media\tdisabled", self.run_cli("lockscreen", "widgets", "list").stdout)
        self.assertIn("media\tenabled", self.run_cli("widgets", "list").stdout)

    def test_battery_is_not_a_configurable_widget_and_legacy_values_are_ignored(self):
        config = self.read_config()
        config["lockscreen"]["widgets"]["battery"] = True
        self.config.write_text(json.dumps(config), encoding="utf-8")
        self.assertNotIn("battery", self.run_cli("lockscreen", "widgets", "list").stdout)
        self.assertNotEqual(self.run_cli("lockscreen", "widgets", "enable", "battery").returncode, 0)

    def test_enabling_every_desktop_widget_keeps_values_and_lockscreen_untouched(self):
        config = self.read_config()
        for entry in config["shell"]["widgets"].values():
            entry["enabled"] = False
        config["lockscreen"]["widgets"]["clock"] = False
        self.config.write_text(json.dumps(config), encoding="utf-8")
        result = self.run_cli("widgets", "enable", "--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        after = self.read_config()
        self.assertTrue(all(entry["enabled"] is True for entry in after["shell"]["widgets"].values()))
        self.assertEqual(after["lockscreen"], config["lockscreen"])
        self.assertEqual(after["shell"]["widgets"]["storage"]["mounts"], config["shell"]["widgets"]["storage"]["mounts"])

    def test_lockscreen_changes_never_touch_desktop_widgets(self):
        before = self.read_config()["shell"]
        for arguments in (("disable", "clock"), ("enable", "system"), ("disable", "media"), ("reset",)):
            self.assertEqual(self.run_cli("lockscreen", "widgets", *arguments).returncode, 0)
        self.assertEqual(self.read_config()["shell"], before)

    def test_reset_restores_defaults(self):
        self.run_cli("lockscreen", "widgets", "disable", "clock")
        self.run_cli("lockscreen", "widgets", "enable", "system")
        result = self.run_cli("lockscreen", "widgets", "reset")
        self.assertEqual(result.stdout.splitlines(), ["clock\tenabled", "weather\tenabled", "media\tenabled", "system\tdisabled", "network\tdisabled", "storage\tdisabled", "sensors\tdisabled", "uptime\tdisabled", "services\tdisabled", "tasks\tdisabled", "processes\tdisabled"])
        self.assertEqual(self.read_config()["lockscreen"]["widgets"], json.loads((ROOT / "config/lockscreen/widgets.json").read_text(encoding="utf-8"))["defaults"])

    def test_cli_exposes_no_unlock_operation(self):
        for arguments in (("lockscreen", "--help"), ("lockscreen", "widgets", "--help"), ("--help",)):
            result = self.run_cli(*arguments)
            self.assertNotIn("unlock", (result.stdout + result.stderr).lower())
        self.assertNotEqual(self.run_cli("lockscreen", "unlock").returncode, 0)


class LockscreenLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.runtime = Path(self.temporary.name) / "run"
        self.runtime.mkdir(mode=0o700)
        self.environment = dict(os.environ, XDG_RUNTIME_DIR=str(self.runtime), HYPRISM_ROOT=str(ROOT))

    def tearDown(self):
        self.temporary.cleanup()

    def status(self):
        result = subprocess.run([str(LOCKSCREEN), "status"], env=self.environment, text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_status_is_unlocked_by_default(self):
        self.assertEqual(self.status(), "unlocked")

    def test_recorded_lock_without_a_process_is_reported_as_orphaned(self):
        state = self.runtime / "hyprism"
        state.mkdir()
        (state / "lockscreen.state").write_text("locked\n", encoding="utf-8")
        self.assertEqual(self.status(), "orphaned")

    def test_launcher_has_no_unlock_command(self):
        result = subprocess.run([str(LOCKSCREEN), "unlock"], env=self.environment, text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 2)

    def test_lock_refuses_without_wayland_session(self):
        environment = {key: value for key, value in self.environment.items() if key != "WAYLAND_DISPLAY"}
        result = subprocess.run([str(LOCKSCREEN), "lock"], env=environment, text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.runtime / "hyprism").exists())

    def test_lock_dispatcher_selects_hyprlock_only_on_request(self):
        runtime = Path(self.temporary.name) / "root"
        scripts = runtime / "scripts/system"
        scripts.mkdir(parents=True)
        for name in ("lock", "lockscreen", "lock-hyprlock"):
            if name == "lock":
                target = (ROOT / "scripts/system/lock").read_text(encoding="utf-8")
            else:
                target = f"#!/usr/bin/env bash\nprintf '{name} %s\\n' \"$*\"\n"
            (scripts / name).write_text(target, encoding="utf-8")
            (scripts / name).chmod(0o755)
        environment = dict(self.environment, HYPRISM_ROOT=str(runtime))
        default = subprocess.run([str(scripts / "lock")], env=environment, text=True, capture_output=True, check=False)
        fallback = subprocess.run([str(scripts / "lock"), "--hyprlock"], env=environment, text=True, capture_output=True, check=False)
        self.assertEqual(default.stdout, "lockscreen lock\n")
        self.assertEqual(fallback.stdout, "lock-hyprlock \n")


class LockBackgroundTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.cache = Path(self.temporary.name) / "cache"
        (self.cache / "state").mkdir(parents=True)
        self.wallpaper = Path(self.temporary.name) / "wall.png"
        image = Image.new("RGB", (800, 500), "black")
        draw = ImageDraw.Draw(image)
        for x in range(0, 800, 20):
            draw.line([(x, 0), (x, 500)], fill="white", width=2)
        image.save(self.wallpaper)
        self.environment = dict(os.environ, HYPRISM_CACHE_DIR=str(self.cache))

    def tearDown(self):
        self.temporary.cleanup()

    def run_background(self):
        return subprocess.run([str(BACKGROUND)], env=self.environment, text=True, capture_output=True, check=False)

    def test_without_wallpaper_nothing_is_printed(self):
        result = self.run_background()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_wallpaper_symlink_produces_a_blurred_cached_copy(self):
        (self.cache / "state/lock-wallpaper").symlink_to(self.wallpaper)
        first = self.run_background()
        self.assertEqual(first.returncode, 0, first.stderr)
        output = Path(first.stdout.strip())
        self.assertTrue(output.is_file())
        self.assertEqual(output.parent, self.cache / "state/lock-background")
        with Image.open(output) as blurred, Image.open(self.wallpaper) as source:
            self.assertEqual(blurred.width, source.width)
            sharp = ImageStat.Stat(source.convert("L")).stddev[0]
            soft = ImageStat.Stat(blurred.convert("L")).stddev[0]
            self.assertLess(soft, sharp * .5)
        modified = output.stat().st_mtime_ns
        second = self.run_background()
        self.assertEqual(second.stdout, first.stdout)
        self.assertEqual(output.stat().st_mtime_ns, modified)

    def test_a_different_wallpaper_gets_a_different_cache_entry(self):
        link = self.cache / "state/lock-wallpaper"
        link.symlink_to(self.wallpaper)
        first = self.run_background().stdout
        other = Path(self.temporary.name) / "other.png"
        Image.new("RGB", (300, 900), "blue").save(other)
        link.unlink()
        link.symlink_to(other)
        self.assertNotEqual(self.run_background().stdout, first)


class LockscreenSecurityContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.entry = (QML / "lockscreen.qml").read_text(encoding="utf-8")
        cls.session = (QML / "lockscreen/LockSession.qml").read_text(encoding="utf-8")
        cls.sources = {path.name: path.read_text(encoding="utf-8") for path in [QML / "lockscreen.qml", *sorted((QML / "lockscreen").glob("*.qml"))]}

    def test_uses_the_native_session_lock_not_an_overlay(self):
        self.assertIn("WlSessionLock {", self.entry)
        self.assertIn("WlSessionLockSurface {", self.sources["LockSurface.qml"])
        for name, source in self.sources.items():
            for forbidden in ("PanelWindow", "FloatingWindow", "ScreencopyView", "WlrLayershell", "BackgroundEffect"):
                self.assertNotIn(forbidden, source, f"{name} uses {forbidden}")

    def test_battery_is_a_fixed_indicator_not_a_widget(self):
        widgets = self.sources["LockWidgets.qml"]
        self.assertNotIn("battery", widgets.lower())
        surface = self.sources["LockSurface.qml"]
        self.assertIn("LockBattery {", surface)
        self.assertIn("anchors.right: parent.right", surface)
        self.assertIn("anchors.bottom: parent.bottom", surface)
        self.assertNotIn("battery", (ROOT / "config/lockscreen/widgets.json").read_text(encoding="utf-8"))

    def test_lock_widgets_reuse_the_desktop_widget_board(self):
        widgets = self.sources["LockWidgets.qml"]
        self.assertIn("WidgetBoard {", widgets)
        self.assertIn("playingOnly: true", widgets)
        self.assertIn("enabled: false", widgets)
        desktop = (QML / "widgets/DesktopWidgets.qml").read_text(encoding="utf-8")
        self.assertIn("WidgetBoard {", desktop)
        board = (QML / "widgets/WidgetBoard.qml").read_text(encoding="utf-8")
        for name in ("MediaCard", "ClockCard", "WeatherCard", "DesktopCard"):
            self.assertIn(name, board)
        for service in ("SystemService", "MediaService", "MonitoringService"):
            self.assertIn(f"{service} {{", self.entry)

    def test_media_card_is_the_single_desktop_implementation(self):
        card = (QML / "components/MediaCard.qml").read_text(encoding="utf-8")
        for icon in ('"previous"', '"pause"', '"play"', '"next"'):
            self.assertIn(icon, card)
        self.assertNotIn("lockscreen", card)
        self.assertFalse(any((QML / "lockscreen").glob("*Media*")))

    def test_lock_widget_visibility_comes_only_from_the_lockscreen_namespace(self):
        self.assertIn("preferences[names[index]]", self.entry)
        self.assertIn("parsed.lockscreen", self.entry)
        self.assertIn("watchChanges: true", self.entry)

    def test_prompt_is_hidden_until_typing_and_shows_no_lock_message(self):
        panel = self.sources["LockPanel.qml"]
        self.assertIn("opacity: revealed ? 1 : 0", panel)
        self.assertIn("visible: opacity > 0", panel)
        self.assertIn("session.promptVisible && session.secure", panel)
        self.assertNotIn("lockscreen.locked", panel)
        for catalog in ("en", "pt-BR"):
            strings = json.loads((QML / f"i18n/{catalog}.json").read_text(encoding="utf-8"))["lockscreen"]
            self.assertNotIn("locked", strings)
            self.assertNotIn("requesting", strings)

    def test_password_indicators_track_the_character_count_without_exposing_it(self):
        panel = self.sources["LockPanel.qml"]
        self.assertIn("function syncDots()", panel)
        self.assertIn("const target = session.secretLength", panel)
        self.assertIn("dotModel.clear()", panel)
        self.assertIn("onSecretLengthChanged(): void { panel.syncDots() }", panel)
        self.assertNotIn("console.", panel)
        self.assertNotIn("secretLength", self.entry)
        self.assertNotRegex(self.entry + self.sources["LockSurface.qml"], r"IpcHandler[^}]*secret")

    def test_prompt_reveal_is_a_restrained_fade_and_slide_that_never_blocks_input(self):
        panel = self.sources["LockPanel.qml"]
        self.assertIn("Behavior on opacity", panel)
        self.assertIn("Behavior on lift", panel)
        self.assertIn("property real lift: revealed ? 0 : -8", panel)
        self.assertIn("visible: opacity > 0", panel)
        self.assertNotIn("OutBack", panel)
        self.assertNotIn("OutBounce", panel)
        self.assertIn("Keys.onPressed: event => surface.session.handleKey(event)", self.sources["LockSurface.qml"])
        self.assertNotIn("promptVisible", self.session[self.session.index("function handleKey"):self.session.index("function submit")])

    def test_clock_is_a_fixed_centered_element_with_two_tones(self):
        clock = self.sources["LockClock.qml"]
        self.assertIn('formattedDate("HH")', clock)
        self.assertIn('formattedDate("mm")', clock)
        self.assertIn("colors.foreground", clock)
        self.assertIn("colors.accent", clock)
        surface = self.sources["LockSurface.qml"]
        self.assertIn("y: Math.round((root.height - height) / 2)", surface)
        self.assertIn("anchors.horizontalCenter: parent.horizontalCenter", surface)
        widgets = self.sources["LockWidgets.qml"]
        self.assertIn("showClock: false", widgets)
        self.assertIn("mediaBelow: true", widgets)

    def test_media_sits_on_its_own_row_below_the_other_widgets(self):
        board = (QML / "widgets/WidgetBoard.qml").read_text(encoding="utf-8")
        self.assertIn("property bool mediaBelow: false", board)
        self.assertIn("y: board.columnsHeight > 0 ? board.columnsHeight + board.cardGap : 0", board)
        self.assertIn("board.mediaShown && !board.mediaBelow", board)
        self.assertIn("board.mediaShown && board.mediaBelow", board)
        desktop = (QML / "widgets/DesktopWidgets.qml").read_text(encoding="utf-8")
        self.assertNotIn("mediaBelow", desktop)
        self.assertNotIn("showClock", desktop)

    def test_surface_opacity_uses_only_the_global_setting(self):
        for name, source in self.sources.items():
            self.assertNotRegex(source, r"surfaceOpacity:\s*[0-9.]+\s*$", name)
        self.assertIn("surfaceOpacity: shellConfig.surfaceOpacity", self.sources["LockPanel.qml"])
        self.assertIn("Design.shellSurfaceOpacity = controller.config.shell.surfaceOpacity", self.entry)

    def test_panel_is_narrower_than_the_bar_and_morphs_to_its_width(self):
        panel = self.sources["LockPanel.qml"]
        self.assertIn("barWidth * .62", panel)
        self.assertIn("restWidth + (barWidth - restWidth) * session.morphProgress", panel)
        self.assertIn("Design.compactWidth(shellConfig, screenWidth)", panel)

    def test_release_follows_the_morph_and_requires_authentication(self):
        self.assertIn("onUnlockGranted: root.beginRelease()", self.entry)
        self.assertEqual(self.entry.count("beginRelease()"), 2)
        self.assertIn("if (unlocked || !releasing) return", self.entry)
        self.assertIn("onFinished: handoff.start()", self.entry)
        self.assertIn("if (!secure || authenticating || unlocking) return", self.session)

    def test_desktop_shell_recovers_its_configuration_watch(self):
        shell = (QML / "shell.qml").read_text(encoding="utf-8")
        self.assertIn("onLoadFailed: configRetry.restart()", shell)
        self.assertIn("onLoadFailed: themeRetry.restart()", shell)

    def test_scaled_widget_surfaces_are_smoothed(self):
        for name in ("widgets/DesktopWidgets.qml", "lockscreen/LockWidgets.qml"):
            source = (QML / name).read_text(encoding="utf-8")
            self.assertIn("layer.smooth: true", source, name)

    def test_live_reload_is_disabled(self):
        self.assertIn("settings.watchFiles: false", self.entry)

    def test_the_lock_is_released_in_exactly_one_place(self):
        occurrences = [(name, line) for name, source in self.sources.items() for line in source.splitlines() if re.search(r"\.locked\s*=\s*false|\.unlock\(", line)]
        self.assertEqual(len(occurrences), 1, occurrences)
        self.assertIn("function releaseLock()", self.entry)
        self.assertIn("onUnlockGranted: root.beginRelease()", self.entry)
        self.assertEqual(self.entry.count("releaseLock()"), 3)

    def test_unlock_signal_is_emitted_only_from_a_pam_success(self):
        emissions = [line for line in self.session.splitlines() if "unlockGranted()" in line and "signal" not in line]
        self.assertEqual(len(emissions), 1)
        block = self.session[self.session.index("onCompleted: result"):]
        self.assertLess(block.index("PamResult.Success && expected"), block.index("session.unlockGranted()"))
        self.assertIn("if (!secure || authenticating || unlocking || secret.length === 0) return", self.session)

    def test_no_ipc_handler_can_unlock(self):
        handlers = re.findall(r"IpcHandler\s*{(.*?)\n    }", self.entry, re.S)
        self.assertEqual(len(handlers), 1)
        self.assertNotIn("unlock", handlers[0].lower())
        self.assertNotIn("locked", handlers[0])

    def test_input_is_ignored_until_the_compositor_confirms_the_lock(self):
        self.assertIn("secure: lock.secure", self.entry)
        self.assertIn("if (!secure || authenticating || unlocking) return", self.session)

    def test_password_is_never_logged_or_passed_to_processes(self):
        for name, source in self.sources.items():
            self.assertNotRegex(source, r"console\.(log|warn|error|info|debug)\([^)]*(secret|pendingResponse|response)", name)
            self.assertNotIn("Quickshell.execDetached", source, name)
            self.assertNotIn("Process {", source, name)
        self.assertIn('config: "hyprism-lock"', self.session)
        self.assertNotIn("user:", self.session)

    def test_lock_widgets_are_read_only(self):
        widgets = self.sources["LockWidgets.qml"]
        for forbidden in ("MouseArea", "TapHandler", "HoverHandler", "onClicked", "controller.run(", "Process"):
            self.assertNotIn(forbidden, widgets)
        self.assertIn("enabled: false", widgets)


if __name__ == "__main__":
    unittest.main()
