import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
QML_ROOT = ROOT / "config/quickshell"


def flatten(value, prefix=""):
    result = {}
    for key, child in value.items():
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(child, dict):
            result.update(flatten(child, path))
        else:
            result[path] = child
    return result


class TranslationTests(unittest.TestCase):
    def catalogs(self):
        return {
            locale: flatten(json.loads((QML_ROOT / f"i18n/{locale}.json").read_text(encoding="utf-8")))
            for locale in ("en", "pt-BR")
        }

    def test_catalogs_have_identical_nonempty_keys(self):
        catalogs = self.catalogs()
        self.assertEqual(set(catalogs["en"]), set(catalogs["pt-BR"]))
        for catalog in catalogs.values():
            self.assertTrue(all(isinstance(value, str) and value for value in catalog.values()))

    def test_every_qml_lookup_exists_in_english(self):
        english = self.catalogs()["en"]
        used = set()
        for path in QML_ROOT.rglob("*.qml"):
            used.update(re.findall(r'I18n\.tr\("([^"]+)"', path.read_text(encoding="utf-8")))
        self.assertFalse(used - set(english))

    def test_default_language_is_english(self):
        config = json.loads((ROOT / "config/user.json").read_text(encoding="utf-8"))
        self.assertEqual(config["language"], "en")


if __name__ == "__main__":
    unittest.main()
