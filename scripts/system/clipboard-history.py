#!/usr/bin/env python3

import hashlib
import io
import json
import os
from pathlib import Path
import re
import subprocess

from PIL import Image


IMAGE_PREVIEW = re.compile(r"^\[\[ binary data (.+?) ([A-Za-z0-9]+) (\d+)x(\d+) \]\]$")
FORMAT_MIME = {
    "bmp": "image/bmp",
    "gif": "image/gif",
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "png": "image/png",
    "tiff": "image/tiff",
    "webp": "image/webp",
}
MAX_ENTRIES = 80
MAX_THUMBNAILS = 64


def cache_directory():
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    directory = cache_home / "hyprism" / "clipboard"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    return directory


def decoded(identifier):
    try:
        result = subprocess.run(
            ["cliphist", "decode", identifier],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        return b""
    return result.stdout if result.returncode == 0 else b""


def thumbnail(identifier, preview, directory):
    key = hashlib.sha256(f"{identifier}\0{preview}".encode()).hexdigest()
    destination = directory / f"{key}.png"
    if destination.is_file():
        destination.touch()
        return destination
    content = decoded(identifier)
    if not content:
        return None
    try:
        with Image.open(io.BytesIO(content)) as source:
            source.seek(0)
            image = source.convert("RGBA")
            image.thumbnail((420, 240), Image.Resampling.LANCZOS)
            temporary = destination.with_suffix(".tmp")
            image.save(temporary, format="PNG", optimize=True)
            os.replace(temporary, destination)
            return destination
    except (OSError, ValueError):
        destination.with_suffix(".tmp").unlink(missing_ok=True)
        return None


def text_entry(identifier, preview):
    replacement = "�" in preview or any(ord(character) < 32 for character in preview)
    entry_type = "unknown" if replacement else "text"
    label = "Conteúdo binário" if replacement else preview
    return {
        "id": identifier,
        "type": entry_type,
        "text": label or "Texto copiado",
        "searchText": label or "texto",
        "mime": "application/octet-stream" if replacement else "text/plain;charset=utf-8",
        "thumbnail": "",
        "width": 0,
        "height": 0,
    }


def image_entry(identifier, preview, match, directory, generate_thumbnail):
    image_format = match.group(2).lower()
    width = int(match.group(3))
    height = int(match.group(4))
    generated = thumbnail(identifier, preview, directory) if generate_thumbnail else None
    dimensions = f"{width}×{height}"
    return {
        "id": identifier,
        "type": "image",
        "text": f"Imagem · {dimensions}",
        "searchText": f"imagem {image_format} {dimensions}",
        "mime": FORMAT_MIME.get(image_format, f"image/{image_format}"),
        "thumbnail": generated.as_uri() if generated else "",
        "width": width,
        "height": height,
    }


def cleanup(directory):
    thumbnails = sorted(directory.glob("*.png"), key=lambda path: path.stat().st_mtime, reverse=True)
    for path in thumbnails[MAX_THUMBNAILS:]:
        path.unlink(missing_ok=True)


def history():
    try:
        result = subprocess.run(
            ["cliphist", "list"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        return []
    if result.returncode != 0:
        return []
    directory = cache_directory()
    entries = []
    image_count = 0
    for raw_line in result.stdout.decode("utf-8", errors="replace").splitlines()[:MAX_ENTRIES]:
        identifier, separator, preview = raw_line.partition("\t")
        if not separator or not identifier.isdigit():
            continue
        match = IMAGE_PREVIEW.match(preview)
        if match:
            entries.append(image_entry(identifier, preview, match, directory, image_count < MAX_THUMBNAILS))
            image_count += 1
        else:
            entries.append(text_entry(identifier, preview))
    cleanup(directory)
    return entries


if __name__ == "__main__":
    print(json.dumps(history(), ensure_ascii=False, separators=(",", ":")))
