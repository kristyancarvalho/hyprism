import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class PackagingTests(unittest.TestCase):
    def test_system_install_is_home_independent(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary)
            result = subprocess.run(
                ["make", "install-system", "PREFIX=/usr", f"DESTDIR={stage}"],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((stage / "usr/bin/hyprism-shell").is_file())
            self.assertTrue(os.access(stage / "usr/bin/hyprism-shell", os.X_OK))
            self.assertTrue((stage / "usr/share/hyprism/config/quickshell/shell.qml").is_file())
            self.assertTrue((stage / "usr/share/hyprism/scripts/system/keyboard_backend.py").is_file())
            self.assertTrue((stage / "usr/share/applications/hyprism-keyboard-setup.desktop").is_file())
            self.assertTrue((stage / "usr/share/licenses/hyprism-shell/LICENSE").is_file())
            self.assertFalse(any(stage.rglob("__pycache__")))
            self.assertFalse((stage / "home").exists())

    def test_staged_cli_discovers_resources_and_initializes_user_config(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary) / "stage"
            home = Path(temporary) / "home"
            subprocess.run(
                ["make", "install-system", "PREFIX=/usr", f"DESTDIR={stage}"],
                cwd=ROOT,
                stdout=subprocess.DEVNULL,
                check=True,
            )
            environment = {
                **os.environ,
                "HOME": str(home),
                "XDG_CACHE_HOME": str(home / ".cache"),
                "XDG_CONFIG_HOME": str(home / ".config"),
                "HYPRISM_ROOT": str(stage / "usr/share/hyprism"),
                "HYPRISM_CONFIG": str(home / ".config/hyprism/user.json"),
                "HYPRISM_SKIP_SERVICE_ENABLE": "1",
            }
            cli = stage / "usr/bin/hyprism-shell"
            initialized = subprocess.run([cli, "init"], env=environment, text=True, capture_output=True, check=False)
            self.assertEqual(initialized.returncode, 0, initialized.stderr)
            config = json.loads((home / ".config/hyprism/user.json").read_text(encoding="utf-8"))
            self.assertEqual(config["language"], "en")
            keyboard_help = subprocess.run([cli, "keyboard", "--help"], env=environment, text=True, capture_output=True, check=False)
            services_help = subprocess.run([cli, "services", "--help"], env=environment, text=True, capture_output=True, check=False)
            self.assertEqual(keyboard_help.returncode, 0, keyboard_help.stderr)
            self.assertEqual(services_help.returncode, 0, services_help.stderr)
            self.assertIn("list", services_help.stdout)
            self.assertIn("add", services_help.stdout)
            self.assertIn("remove", services_help.stdout)
            self.assertTrue((home / ".config/hypr").is_symlink())
            self.assertTrue((home / ".local/share/applications/hyprism-keyboard-setup.desktop").is_symlink())

    def test_aur_channels_share_runtime_dependencies(self):
        stable = (ROOT / "packaging/aur/hyprism-shell/PKGBUILD.in").read_text(encoding="utf-8")
        vcs = (ROOT / "packaging/aur/hyprism-shell-git/PKGBUILD").read_text(encoding="utf-8")
        stable_dependencies = stable[stable.index("depends=("):stable.index("\n)\n", stable.index("depends=("))]
        vcs_dependencies = vcs[vcs.index("depends=("):vcs.index("\n)\n", vcs.index("depends=("))]
        self.assertEqual(stable_dependencies, vcs_dependencies)
        self.assertIn("archive/refs/tags/v${pkgver}.tar.gz", stable)
        self.assertNotIn("'SKIP'", stable)
        self.assertIn("git+${url}.git#branch=main", vcs)
        self.assertIn("provides=(\"hyprism-shell=${pkgver}\")", vcs)
        self.assertIn("conflicts=('hyprism-shell')", vcs)

    def test_aur_workflows_prepare_git_before_checkout(self):
        for workflow_name in ("aur-stable.yml", "aur-git.yml"):
            workflow = (ROOT / ".github/workflows" / workflow_name).read_text(encoding="utf-8")
            self.assertLess(workflow.index("pacman -Syu"), workflow.index("actions/checkout"))
            self.assertIn("fetch-depth: 0", workflow)
            self.assertIn("fetch-tags: true", workflow)
            self.assertLess(workflow.index("actions/checkout"), workflow.index("chown -R aurbuilder"))


if __name__ == "__main__":
    unittest.main()
