import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
QML = ROOT / "config/quickshell"
RUNNER = Path("/usr/lib/qt6/bin/qmltestrunner")

DESIGN = """pragma Singleton
import QtQuick
QtObject {
    readonly property int radiusDefault: 6
    readonly property int animationFast: 0
    readonly property int easingMorph: Easing.Linear
    readonly property string fontFamily: "sans"
    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontWeightMedium: Font.Medium
    readonly property int iconXs: 12
    readonly property int iconSm: 14
}
"""


class LockMediaFocusTests(unittest.TestCase):
    def test_media_sources_never_take_keyboard_focus_on_the_lockscreen(self):
        lock = (QML / "lockscreen/LockMedia.qml").read_text(encoding="utf-8")
        self.assertIn("keyboardControls: false", lock)
        strip = (QML / "components/MediaStrip.qml").read_text(encoding="utf-8")
        self.assertIn("activeFocusOnTab: keyboardControls", strip)
        self.assertEqual(strip.count("keyboardFocusable: media.keyboardControls"), 3)
        button = (QML / "components/ShellButton.qml").read_text(encoding="utf-8")
        self.assertIn("if (button.keyboardFocusable) button.forceActiveFocus()", button)

    @unittest.skipUnless(RUNNER.exists(), "qmltestrunner is not installed")
    def test_clicking_media_buttons_keeps_return_with_the_password_handler(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            harness = base / "harness"
            harness.mkdir()
            shutil.copy(ROOT / "tests/qml/tst_lock_media_focus.qml", base)
            source = (QML / "components/ShellButton.qml").read_text(encoding="utf-8")
            (harness / "ShellButton.qml").write_text(source.replace('import ".."\n', ""), encoding="utf-8")
            (harness / "Design.qml").write_text(DESIGN, encoding="utf-8")
            (harness / "StatusIcon.qml").write_text("import QtQuick\nItem { property string name; property int iconSize; property color color }\n", encoding="utf-8")
            (harness / "qmldir").write_text("singleton Design 1.0 Design.qml\nShellButton 1.0 ShellButton.qml\nStatusIcon 1.0 StatusIcon.qml\n", encoding="utf-8")
            result = subprocess.run(
                [str(RUNNER), "-input", str(base / "tst_lock_media_focus.qml")],
                env=dict(os.environ, QT_QPA_PLATFORM="offscreen"),
                text=True,
                capture_output=True,
                timeout=120,
                check=False,
            )
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertRegex(output, r"Totals: 6 passed, 0 failed")


if __name__ == "__main__":
    unittest.main()
