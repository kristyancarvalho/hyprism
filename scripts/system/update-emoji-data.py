#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import pathlib
import re
import tempfile
import unicodedata
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ElementTree


ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "config/quickshell/data/emoji.json"
DEFAULT_EMOJI_SOURCE = "https://www.unicode.org/Public/emoji/latest/emoji-test.txt"
DEFAULT_ANNOTATIONS_SOURCE = "https://raw.githubusercontent.com/unicode-org/cldr/release-48/common/annotations/en.xml"
DEFAULT_DERIVED_SOURCE = "https://raw.githubusercontent.com/unicode-org/cldr/release-48/common/annotationsDerived/en.xml"
ENTRY = re.compile(
    r"^(?P<codepoints>[0-9A-F ]+)\s*;\s*(?P<status>fully-qualified|component)\s*"
    r"#\s*\S+\s+E(?P<emoji_version>[0-9.]+)\s+(?P<name>.+)$"
)


def read_source(source):
    parsed = urllib.parse.urlparse(source)
    if parsed.scheme in {"http", "https"}:
        request = urllib.request.Request(source, headers={"User-Agent": "Hyprism emoji updater"})
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.read()
    path = pathlib.Path(parsed.path if parsed.scheme == "file" else source).expanduser()
    return path.read_bytes()


def source_version(text):
    match = re.search(r"^# Version:\s*([^\s]+)", text, re.MULTILINE)
    if not match:
        raise ValueError("emoji-test.txt does not declare a Unicode Emoji version")
    return match.group(1)


def normalize(value):
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    plain = "".join(character for character in decomposed if not unicodedata.combining(character))
    return " ".join(re.findall(r"[^\W_]+", plain, flags=re.UNICODE))


def cldr_annotations(documents):
    names = {}
    keywords = {}
    for document in documents:
        root = ElementTree.fromstring(document)
        for annotation in root.iter("annotation"):
            glyph = annotation.get("cp", "")
            value = "".join(annotation.itertext()).strip()
            if not glyph or not value:
                continue
            if annotation.get("type") == "tts":
                names[glyph] = value
            else:
                keywords.setdefault(glyph, set()).update(part.strip() for part in value.split("|") if part.strip())
    return names, keywords


def parse_emoji(text, names, keywords):
    group = ""
    subgroup = ""
    entries = []
    seen = set()
    for line in text.splitlines():
        if line.startswith("# group:"):
            group = line.split(":", 1)[1].strip()
            continue
        if line.startswith("# subgroup:"):
            subgroup = line.split(":", 1)[1].strip()
            continue
        match = ENTRY.match(line)
        if not match:
            continue
        glyph = "".join(chr(int(codepoint, 16)) for codepoint in match.group("codepoints").split())
        if glyph in seen:
            raise ValueError(f"duplicate fully-qualified emoji: {match.group('codepoints')}")
        seen.add(glyph)
        name = names.get(glyph, match.group("name")).strip()
        terms = sorted({term.casefold() for term in keywords.get(glyph, set()) if term.casefold() != name.casefold()})
        haystack = normalize(" ".join((glyph, name, group, subgroup, *terms)))
        entries.append({
            "glyph": glyph,
            "name": name,
            "keywords": terms,
            "search": haystack,
        })
    if len(entries) < 3000:
        raise ValueError(f"emoji dataset is unexpectedly small ({len(entries)} entries)")
    return entries


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".emoji-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        pathlib.Path(temporary).unlink(missing_ok=True)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--emoji-source", default=DEFAULT_EMOJI_SOURCE, help="emoji-test.txt URL or path")
    parser.add_argument("--annotations-source", default=DEFAULT_ANNOTATIONS_SOURCE, help="CLDR annotations XML URL or path")
    parser.add_argument("--derived-annotations-source", default=DEFAULT_DERIVED_SOURCE, help="CLDR derived annotations XML URL or path")
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    arguments = parser.parse_args()

    emoji_bytes = read_source(arguments.emoji_source)
    annotation_bytes = read_source(arguments.annotations_source)
    derived_bytes = read_source(arguments.derived_annotations_source)
    emoji_text = emoji_bytes.decode("utf-8")
    names, keywords = cldr_annotations((annotation_bytes, derived_bytes))
    entries = parse_emoji(emoji_text, names, keywords)
    data = {
        "unicodeEmojiVersion": source_version(emoji_text),
        "locale": "en",
        "count": len(entries),
        "sources": {
            "emoji": arguments.emoji_source,
            "annotations": arguments.annotations_source,
            "derivedAnnotations": arguments.derived_annotations_source,
            "emojiSha256": hashlib.sha256(emoji_bytes).hexdigest(),
            "annotationsSha256": hashlib.sha256(annotation_bytes).hexdigest(),
            "derivedAnnotationsSha256": hashlib.sha256(derived_bytes).hexdigest(),
        },
        "emoji": entries,
    }
    serialized = json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n"
    json.loads(serialized)
    atomic_write(arguments.output.resolve(), serialized)
    print(f"Unicode Emoji {data['unicodeEmojiVersion']}: {len(entries)} entries written to {arguments.output}")


if __name__ == "__main__":
    main()
