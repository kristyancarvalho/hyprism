from pathlib import Path
import re
import unittest


QML_ROOT = Path(__file__).resolve().parents[1] / "config/quickshell"


class FloatingSurfaceTests(unittest.TestCase):
    def read(self, relative):
        return (QML_ROOT / relative).read_text(encoding="utf-8")

    def test_hub_surface_covers_hub_and_its_detail_panels(self):
        controller = self.read("ShellController.qml")
        modes = re.search(r"hubSurfaceModes: \[([^\]]*)\]", controller).group(1)
        self.assertEqual(re.findall(r'"([^"]+)"', modes), ["control", "network", "bluetooth", "themeSettings"])
        self.assertIn("if (floatingSurfacesSuppressed) return", controller)
        self.assertIn("onTriggered: controller.floatingSurfacesSuppressed = controller.hubSurfaceOpen", controller)

    def test_floating_windows_observe_the_shared_policy(self):
        shell = self.read("shell.qml")
        self.assertIn("suppressed: shellController.floatingSurfacesSuppressed || notificationServer.doNotDisturb", shell)
        self.assertIn("!controller.floatingSurfacesSuppressed", self.read("osd/OsdWindow.qml"))
        self.assertNotIn('mode === "control"', shell)

    def test_suppressed_notifications_are_stored_and_expire_without_presentation(self):
        shell = self.read("shell.qml")
        handler = shell[shell.index("onNotification: notification =>"):]
        handler = handler[:handler.index("}")]
        self.assertLess(handler.index("root.storeNotification(notification)"), handler.index("root.showPopup(notification)"))
        show = shell[shell.index("function showPopup(notification)"):]
        show = show[:show.index("const existing = popupIndex(key)")]
        self.assertIn("concealPopup(notification, Date.now() + popupDuration(notification))", show)
        expire = shell[shell.index("function expireDuePopups()"):]
        expire = expire[:expire.index("function setDoNotDisturb")]
        self.assertIn("concealedPopups.filter(popup => now >= popup.deadline)", expire)


if __name__ == "__main__":
    unittest.main()
