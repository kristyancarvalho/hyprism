import importlib.util
import os
import pathlib
import tempfile
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("desktop_index", ROOT / "scripts/system/desktop-index.py")
desktop_index = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(desktop_index)


class DesktopIndexTest(unittest.TestCase):
    def write_entry(self, root, desktop_id, fields):
        path = root / f"{desktop_id}.desktop"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("[Desktop Entry]\n" + "\n".join(fields) + "\n", encoding="utf-8")
        return path

    def entries(self, roots):
        with mock.patch.object(desktop_index, "application_roots", return_value=roots):
            return desktop_index.desktop_entries()

    def test_application_roots_cover_xdg_and_flatpak_exports(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = pathlib.Path(temporary) / "home"
            with mock.patch.dict(os.environ, {
                "HOME": str(home),
                "XDG_DATA_HOME": str(home / "data"),
                "XDG_DATA_DIRS": "/opt/share:/usr/share",
            }, clear=False), mock.patch("pathlib.Path.home", return_value=home):
                roots = desktop_index.application_roots()
            self.assertEqual(roots[0], home / "data/applications")
            self.assertIn(pathlib.Path("/opt/share/applications"), roots)
            self.assertIn(pathlib.Path("/usr/share/applications"), roots)
            self.assertIn(home / ".local/share/flatpak/exports/share/applications", roots)
            self.assertIn(pathlib.Path("/var/lib/flatpak/exports/share/applications"), roots)

    def test_duplicate_keys_use_the_last_value(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            self.write_entry(root, "browser", [
                "Type=Application",
                "Name=Browser",
                "Exec=true",
                "StartupWMClass=Browser-old",
                "StartupWMClass=Browser",
            ])
            entries = self.entries([root])
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["startupClass"], "Browser")

    def test_hidden_user_entry_shadows_system_entry(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            user = base / "user"
            system = base / "system"
            self.write_entry(user, "example", [
                "Type=Application",
                "Name=Hidden override",
                "Exec=true",
                "Hidden=true",
            ])
            self.write_entry(system, "example", [
                "Type=Application",
                "Name=System application",
                "Exec=true",
            ])
            self.assertEqual(self.entries([user, system]), [])

    def test_desktop_visibility_and_try_exec_filters_follow_entry_fields(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            self.write_entry(root, "visible", ["Type=Application", "Name=Visible", "Exec=true"])
            self.write_entry(root, "nodisplay", ["Type=Application", "Name=No display", "Exec=true", "NoDisplay=true"])
            self.write_entry(root, "only-gnome", ["Type=Application", "Name=GNOME", "Exec=true", "OnlyShowIn=GNOME;"])
            self.write_entry(root, "not-hyprland", ["Type=Application", "Name=Excluded", "Exec=true", "NotShowIn=Hyprland;"])
            self.write_entry(root, "missing", ["Type=Application", "Name=Missing", "Exec=true", "TryExec=hyprism-command-that-does-not-exist"])
            with mock.patch.dict(os.environ, {"XDG_CURRENT_DESKTOP": "Hyprland"}, clear=False):
                entries = self.entries([root])
            self.assertEqual([entry["id"] for entry in entries], ["visible"])

    def test_dbus_activatable_entry_does_not_require_exec(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            self.write_entry(root, "dbus-app", [
                "Type=Application",
                "Name=D-Bus application",
                "DBusActivatable=true",
            ])
            entries = self.entries([root])
            self.assertEqual(len(entries), 1)
            self.assertTrue(entries[0]["dbusActivatable"])


if __name__ == "__main__":
    unittest.main()
