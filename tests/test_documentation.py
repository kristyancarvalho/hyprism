from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DocumentationLinkTests(unittest.TestCase):
    def test_relative_links_and_images_resolve(self):
        files = [ROOT / "README.md", *sorted((ROOT / "docs").rglob("*.md"))]
        missing = []
        for file in files:
            for target in re.findall(r"\]\(([^)\s]+)\)", file.read_text(encoding="utf-8")):
                if re.match(r"^(https?:|mailto:|#)", target):
                    continue
                path = target.split("#", 1)[0]
                if path and not (file.parent / path).exists():
                    missing.append(f"{file.relative_to(ROOT)} -> {target}")
        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
