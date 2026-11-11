import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/system/media-lock-indicator.py"
FAKE_PLAYERCTL = '''#!/usr/bin/env python3
import json
import os
import sys

players = json.loads(os.environ.get("HYPRISM_TEST_PLAYERS", "[]"))
arguments = sys.argv[1:]
if arguments[-1:] == ["status"]:
    if os.environ.get("HYPRISM_TEST_STATUS_ERROR"):
        raise SystemExit(1)
    template = arguments[arguments.index("--format") + 1]
    for player in players:
        print(template.replace("{{playerName}}", player["name"]).replace("{{lc(status)}}", player["status"].lower()))
elif arguments[-1:] == ["metadata"]:
    name = next(argument.removeprefix("--player=") for argument in arguments if argument.startswith("--player="))
    player = next(player for player in players if player["name"] == name)
    if player.get("metadataError"):
        raise SystemExit(1)
    template = arguments[arguments.index("--format") + 1]
    print(template.replace("{{title}}", player.get("title", "")).replace("{{artist}}", player.get("artist", "")).replace("{{mpris:artUrl}}", player.get("artUrl", "")))
'''


class HyprlockMediaTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        fake = self.bin / "playerctl"
        fake.write_text(FAKE_PLAYERCTL, encoding="utf-8")
        fake.chmod(0o755)
        self.fixture = self.directory / "players.json"

    def tearDown(self):
        self.temporary.cleanup()

    def run_indicator(self, players=None, arguments=(), **extra):
        self.fixture.write_text(json.dumps(players or []), encoding="utf-8")
        environment = {
            **os.environ,
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "HYPRISM_TEST_PLAYERS": self.fixture.read_text(encoding="utf-8"),
            "HYPRISM_CACHE_DIR": str(self.directory / "cache"),
        }
        environment.update(extra)
        return subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            env=environment,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_hides_without_a_player_and_for_nonplaying_states(self):
        self.assertEqual(self.run_indicator().stdout, "")
        for status in ("Paused", "Stopped", "Idle"):
            with self.subTest(status=status):
                result = self.run_indicator([{"name": "firefox", "status": status, "title": "Track"}])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "")

    def test_shows_current_metadata_and_escapes_markup(self):
        result = self.run_indicator([{
            "name": "firefox.instance_1",
            "status": "Playing",
            "title": "<Track & One>",
            "artist": "Artist & Co",
        }])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "♫ &lt;Track &amp; One&gt; · Artist &amp; Co\n")

    def test_uses_the_playing_player_among_multiple_players(self):
        result = self.run_indicator([
            {"name": "browser", "status": "Paused", "title": "Paused track"},
            {"name": "spotify", "status": "Playing", "title": "Current", "artist": "Artist"},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "♫ Current · Artist\n")

    def test_playing_without_metadata_uses_generic_indicator(self):
        for player in (
            {"name": "player", "status": "Playing"},
            {"name": "player", "status": "Playing", "metadataError": True},
        ):
            with self.subTest(player=player):
                result = self.run_indicator([player])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "♫\n")

    def test_long_metadata_is_truncated_and_track_state_refreshes(self):
        result = self.run_indicator([{
            "name": "player",
            "status": "Playing",
            "title": "T" * 100,
            "artist": "A" * 100,
        }])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(result.stdout.strip().split(" · ")[0]) - 2, 46)
        self.assertIn("… · ", result.stdout)
        paused = self.run_indicator([{"name": "player", "status": "Paused", "title": "Next"}])
        self.assertEqual(paused.stdout, "")

    def test_missing_playerctl_and_command_failures_are_silent(self):
        environment = {**os.environ, "PATH": "", "HYPRISM_TEST_PLAYERS": "[]"}
        result = subprocess.run([sys.executable, str(SCRIPT)], env=environment, text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        result = self.run_indicator([], HYPRISM_TEST_STATUS_ERROR="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_cover_command_loads_local_artwork_and_hides_it_when_paused(self):
        source = self.directory / "artwork.png"
        Image.new("RGB", (40, 20), (180, 30, 80)).save(source)
        result = self.run_indicator([{
            "name": "player",
            "status": "Playing",
            "title": "Track",
            "artUrl": source.as_uri(),
        }], arguments=["--cover"])
        self.assertEqual(result.returncode, 0, result.stderr)
        cover = Path(result.stdout.strip())
        with Image.open(cover) as image:
            self.assertEqual(image.size, (256, 256))
            self.assertEqual(image.getpixel((128, 128)), (180, 30, 80))
        paused = self.run_indicator([{"name": "player", "status": "Paused"}], arguments=["--cover"])
        self.assertEqual(paused.returncode, 0, paused.stderr)
        empty_cover = Path(paused.stdout.strip())
        with Image.open(empty_cover) as image:
            self.assertEqual(image.size, (1, 1))
            self.assertEqual(image.getpixel((0, 0))[3], 0)


if __name__ == "__main__":
    unittest.main()
