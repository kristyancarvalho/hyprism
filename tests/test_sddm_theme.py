import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
THEME = ROOT / "themes/hyprism-pixie"
RUNNER = Path("/usr/lib/qt6/bin/qmltestrunner")
MAIN = (THEME / "Main.qml").read_text(encoding="utf-8")
STYLE = (THEME / "imports/QtQuick/VirtualKeyboard/Styles/hyprism/style.qml").read_text(encoding="utf-8")


def translation_keys(language):
    block = re.search(r'"%s": \{(.*?)\n        \}' % re.escape(language), MAIN, re.DOTALL).group(1)
    return dict(re.findall(r'^\s+(\w+): "(.*)",?$', block, re.MULTILINE))


class SddmThemeTests(unittest.TestCase):
    def test_login_card_is_one_positioned_surface(self):
        self.assertNotIn("loginCardSurface", MAIN)
        card = MAIN[MAIN.index("        id: card\n"):MAIN.index("    SequentialAnimation {\n        id: shake")]
        self.assertEqual(card.count("Behavior on y"), 1)
        self.assertEqual(card[:card.index("id: cardSurface")].count("Behavior on opacity"), 1)
        self.assertIn("id: cardSurface", card)
        self.assertIn("id: loginCard", card)
        self.assertIn("restingY", card)
        self.assertIn("keyboardReserve", card)
        self.assertNotIn("Behavior on y", card[card.index("id: loginCard"):])
        self.assertIn("transform: Translate { id: cardShake", card)

    def test_blur_is_limited_to_the_card_background(self):
        self.assertIn("import QtQuick.Effects", MAIN)
        self.assertIn("id: blurredBackdrop", MAIN)
        self.assertIn("blurEnabled: true", MAIN)
        blur = MAIN[MAIN.index("id: blurClip"):MAIN.index("id: cardMask")]
        self.assertIn("maskEnabled: true", blur)
        self.assertNotIn("loginCard", blur)
        content = MAIN[MAIN.index("id: loginCard"):MAIN.index("id: shake")]
        self.assertNotIn("MultiEffect", content)
        self.assertNotIn("layer.enabled", content)

    def test_password_field_has_no_decorative_dot_and_uses_real_eye_icons(self):
        self.assertNotIn("●", MAIN)
        self.assertNotIn("◉", MAIN)
        self.assertNotIn("◎", MAIN)
        self.assertIn("root.glyph(root.passwordVisible ? 0xF0209 : 0xF0208)", MAIN)
        self.assertIn('ToolTip.text: root.passwordVisible ? root.tr("hidePassword") : root.tr("showPassword")', MAIN)
        visibility = MAIN[MAIN.index("id: visibilityButton"):MAIN.index("id: submitButton")]
        self.assertIn("focusPolicy: Qt.NoFocus", visibility)
        self.assertIn("onClicked: root.passwordVisible = !root.passwordVisible", visibility)

    def test_glyphs_exist_in_the_bundled_icon_font(self):
        try:
            from fontTools.ttLib import TTFont
        except ImportError:
            self.skipTest("fontTools is not installed")
        names = TTFont(THEME / "assets/fonts/MaterialDesignIcons.ttf").getBestCmap()
        expected = {0xF0208: "eye", 0xF0209: "eye-off", 0xF0004: "account", 0xF04B2: "sleep", 0xF0709: "restart", 0xF0425: "power", 0xF006E: "backspace", 0xF0311: "keyboard-return"}
        for code, name in expected.items():
            self.assertEqual(names.get(code), name)

    def test_avatar_falls_back_to_a_person_icon_not_an_initial(self):
        self.assertNotIn("charAt(0)", MAIN)
        self.assertIn("avatarImage.status !== Image.Ready", MAIN)
        self.assertIn("root.glyph(0xF0004)", MAIN)
        self.assertIn("source: root.userIcon", MAIN)

    def test_clock_weight_matches_the_lock_screen(self):
        clock = (THEME / "components/Clock.qml").read_text(encoding="utf-8")
        self.assertEqual(clock.count("font.weight: Font.DemiBold"), 4)
        self.assertNotIn("Font.Medium", clock)

    def test_open_and_close_operations_are_animated(self):
        self.assertEqual(MAIN.count("enter: Transition"), 2)
        self.assertEqual(MAIN.count("exit: Transition"), 2)
        keyboard = MAIN[MAIN.index("id: virtualKeyboard"):]
        self.assertIn("Behavior on y", keyboard)
        self.assertIn("Behavior on opacity", keyboard)
        feedback = MAIN[MAIN.index("id: feedback"):MAIN.index("id: shake")]
        self.assertIn("Behavior on opacity", feedback)
        self.assertIn("root.introduced ? 1 : 0", MAIN)

    def test_session_indicator_is_centered_in_its_button(self):
        session = MAIN[MAIN.index("id: sessionButton"):MAIN.index("id: passwordSurface")]
        self.assertIn("anchors.centerIn: parent", session)

    def test_clock_uses_google_sans_flex_bundled_with_its_license(self):
        self.assertIn('property string fontFamily: "Google Sans Flex"', (THEME / "components/Clock.qml").read_text(encoding="utf-8"))
        self.assertIn("fontFamily: root.clockFontFamily", MAIN)
        self.assertIn('source: "assets/fonts/GoogleSansFlex-Regular.ttf"', MAIN)
        for weight in ("Regular", "Medium", "SemiBold"):
            self.assertGreater((THEME / f"assets/fonts/GoogleSansFlex-{weight}.ttf").stat().st_size, 100000)
        self.assertIn("SIL OPEN FONT LICENSE", (THEME / "licenses/OFL-1.1.txt").read_text(encoding="utf-8"))
        self.assertIn("Google Sans Flex", (THEME / "ORIGIN.md").read_text(encoding="utf-8"))
        design = (ROOT / "config/quickshell/Design.qml").read_text(encoding="utf-8")
        self.assertIn('fontFamily: "Google Sans Flex"', design)

    def test_translations_are_complete_and_localize_the_date(self):
        english = translation_keys("en")
        portuguese = translation_keys("pt-BR")
        self.assertEqual(set(english), set(portuguese))
        self.assertGreaterEqual(len(english), 18)
        for key, value in portuguese.items():
            if key not in ("dateFormat",):
                self.assertNotEqual(value, english[key], key)
        self.assertEqual(english["dateFormat"], "dddd, MMMM d")
        self.assertEqual(portuguese["dateFormat"], "dddd, d 'de' MMMM")
        self.assertIn('config.language === "pt-BR" ? "pt-BR" : "en"', MAIN)
        self.assertIn('Qt.locale(language === "pt-BR" ? "pt_BR" : "en_US")', MAIN)
        self.assertIn("root.locale.toString(root.now, root.tr(\"dateFormat\"))", MAIN)
        for forbidden in ("Qt.formatDateTime", '"Enter password"', "Press any key"):
            self.assertNotIn(forbidden, MAIN.replace('password: "Enter password"', "").replace('pressAnyKey: "Press any key to sign in"', ""))

    def test_failure_feedback_is_assigned_to_the_feedback_label(self):
        self.assertIn('feedback.text = root.tr("failed")', MAIN)
        self.assertNotIn("root.feedback", MAIN)

    def test_virtual_keyboard_uses_the_hyprism_style_and_compact_geometry(self):
        self.assertIn('VirtualKeyboardSettings.styleName = "hyprism"', MAIN)
        self.assertIn("InputPanel {", MAIN)
        self.assertIn("virtualKeyboard.active", MAIN)
        self.assertIn("Qt.inputMethod.show()", MAIN)
        self.assertIn("Qt.inputMethod.hide()", MAIN)
        self.assertIn("Math.max(640, root.height * 1.056)", MAIN)
        self.assertIn("keyboardDesignWidth: 2560", STYLE)
        self.assertIn("keyboardDesignHeight: 800", STYLE)
        self.assertNotRegex(STYLE, r"#[0-9a-fA-F]{3,8}\b")
        self.assertNotIn('"black"', STYLE)
        for key in ("accent", "surface", "surfaceVariant", "text", "muted", "background"):
            self.assertIn(f"currentStyle.pal.{key}", STYLE)
        for panel in ("keyPanel", "backspaceKeyPanel", "enterKeyPanel", "shiftKeyPanel", "spaceKeyPanel", "symbolKeyPanel", "modeKeyPanel", "hideKeyPanel", "languageKeyPanel", "alternateKeysListBackground"):
            self.assertIn(f"{panel}:", STYLE)
        for color in ("accent", "accentForeground", "surface", "surfaceVariant", "text", "muted", "error", "background"):
            self.assertIn(f'property: "{color}"', MAIN)

    def test_sddm_configuration_keeps_the_input_method_and_exposes_the_style(self):
        configuration = (ROOT / "config/sddm/20-hyprism.conf").read_text(encoding="utf-8")
        self.assertIn("InputMethod=qtvirtualkeyboard", configuration)
        environment = re.search(r"^GreeterEnvironment=(.*)$", configuration, re.MULTILINE).group(1).split(",")
        self.assertIn("QT_IM_MODULE=qtvirtualkeyboard", environment)
        self.assertIn("QT_VIRTUALKEYBOARD_STYLE=hyprism", environment)
        self.assertIn("QML_IMPORT_PATH=/usr/share/sddm/themes/hyprism-pixie/imports", environment)
        self.assertTrue((THEME / "imports/QtQuick/VirtualKeyboard/Styles/hyprism/style.qml").is_file())
        self.assertIn("singleton KeyboardPalette", (THEME / "imports/HyprismPixie/qmldir").read_text(encoding="utf-8"))

    def test_power_controls_are_capability_gated_and_localized(self):
        bar = (THEME / "components/PowerBar.qml").read_text(encoding="utf-8")
        for capability in ("power.canSuspend", "power.canReboot", "power.canPowerOff"):
            self.assertIn(capability, bar)
        self.assertIn("power: sddm", MAIN)
        for key in ("suspend", "restart", "shutdown"):
            self.assertIn(f'root.tr("{key}")', MAIN)
        self.assertEqual(translation_keys("pt-BR")["suspend"], "Suspender")
        self.assertEqual(translation_keys("pt-BR")["restart"], "Reiniciar")
        self.assertEqual(translation_keys("pt-BR")["shutdown"], "Desligar")

    def qml_modules_available(self):
        roots = [Path("/usr/lib/qt6/qml"), Path("/usr/lib/x86_64-linux-gnu/qt6/qml"), Path("/usr/lib64/qt6/qml")]
        return any((root / "QtQuick/VirtualKeyboard").is_dir() and (root / "QtQuick/Controls").is_dir() for root in roots)

    def run_qml(self, name):
        if not self.qml_modules_available():
            self.skipTest("Qt Quick Controls and Virtual Keyboard are not installed")
        result = subprocess.run(
            [str(RUNNER), "-input", str(ROOT / "tests/qml" / name)],
            env=dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_IM_MODULE="qtvirtualkeyboard", QML_IMPORT_PATH=str(THEME / "imports")),
            text=True,
            capture_output=True,
            timeout=120,
            check=False,
        )
        output = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, output)
        self.assertNotRegex(output, r"Unable to assign|is not defined|Cannot find style|module .* is not installed")
        return output

    @unittest.skipUnless(RUNNER.exists(), "qmltestrunner is not installed")
    def test_virtual_keys_type_into_a_dummy_password_field(self):
        self.assertRegex(self.run_qml("tst_pixie_keyboard.qml"), r"Totals: 7 passed, 0 failed")

    @unittest.skipUnless(RUNNER.exists(), "qmltestrunner is not installed")
    def test_power_bar_offers_only_supported_actions_with_mocked_backend(self):
        self.assertRegex(self.run_qml("tst_pixie_power.qml"), r"Totals: 5 passed, 0 failed")


if __name__ == "__main__":
    unittest.main()
