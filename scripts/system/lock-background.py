#!/usr/bin/env python3
import argparse
import hashlib
import os
from pathlib import Path
import sys
import tempfile

from PIL import Image, ImageFilter, ImageOps

CACHE_VERSION = "1"
MAXIMUM_SIZE = (1600, 1600)
BLUR_RADIUS = 14
KEEP_CACHED = 3


def cache_dir():
    configured = os.environ.get("HYPRISM_CACHE_DIR")
    if configured:
        return Path(configured)
    return Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hyprism"


def resolve_wallpaper(state):
    link = state / "lock-wallpaper"
    candidates = [link]
    try:
        candidates.append(Path((state / "current-wallpaper").read_text(encoding="utf-8").strip()))
    except OSError:
        pass
    for candidate in candidates:
        try:
            resolved = candidate.resolve(strict=True)
        except OSError:
            continue
        if resolved.is_file() and os.access(resolved, os.R_OK):
            return resolved
    return None


def blur(source, destination):
    with Image.open(source) as image:
        image = ImageOps.exif_transpose(image).convert("RGB")
        image.thumbnail(MAXIMUM_SIZE, Image.Resampling.LANCZOS)
        image = image.filter(ImageFilter.GaussianBlur(BLUR_RADIUS))
        descriptor, temporary = tempfile.mkstemp(prefix=".lock-blur.", suffix=".jpg", dir=destination.parent)
        try:
            with os.fdopen(descriptor, "wb") as output:
                image.save(output, "JPEG", quality=88)
            os.replace(temporary, destination)
        finally:
            Path(temporary).unlink(missing_ok=True)


def prune(directory, keep):
    entries = sorted(directory.glob("lock-blur-*.jpg"), key=lambda path: path.stat().st_mtime, reverse=True)
    for stale in entries[KEEP_CACHED:]:
        if stale != keep:
            stale.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, help="wallpaper to blur instead of the active one")
    arguments = parser.parse_args()
    state = cache_dir() / "state"
    source = arguments.source.resolve() if arguments.source else resolve_wallpaper(state)
    if source is None or not source.is_file():
        return 1
    status = source.stat()
    key = hashlib.sha256(f"{CACHE_VERSION}\0{source}\0{status.st_mtime_ns}\0{status.st_size}\0{BLUR_RADIUS}".encode()).hexdigest()[:24]
    directory = state / "lock-background"
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / f"lock-blur-{key}.jpg"
    if not destination.is_file():
        try:
            blur(source, destination)
        except (OSError, ValueError, Image.DecompressionBombError) as error:
            print(f"Unable to blur the wallpaper: {error}", file=sys.stderr)
            return 1
        prune(directory, destination)
    print(destination)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
