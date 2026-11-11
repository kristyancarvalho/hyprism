#!/usr/bin/env python3
import base64
import hashlib
import html
import ipaddress
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unicodedata
from io import BytesIO
from pathlib import Path
from urllib.error import URLError
from urllib.parse import unquote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from PIL import Image, ImageOps


SEPARATOR = "\x1f"
MAX_TITLE_LENGTH = 46
MAX_ARTIST_LENGTH = 24
MAX_COVER_BYTES = 5 * 1024 * 1024
MAX_COVER_PIXELS = 16_000_000
ARTWORK_SIZE = 256


def query(playerctl, arguments):
    try:
        result = subprocess.run(
            [playerctl, "--no-messages", *arguments],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=0.8,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return result.stdout


def clean(value, maximum):
    value = unicodedata.normalize("NFC", value)
    value = " ".join("".join(" " if unicodedata.category(character) == "Cc" else character for character in value).split())
    if len(value) > maximum:
        value = value[: maximum - 1].rstrip() + "…"
    return html.escape(value, quote=False)


def current_track():
    playerctl = shutil.which("playerctl")
    if not playerctl:
        return None

    status_format = f"{{{{playerName}}}}{SEPARATOR}{{{{lc(status)}}}}"
    for line in query(playerctl, ["--all-players", "--format", status_format, "status"]).splitlines():
        if SEPARATOR not in line:
            continue
        player, status = line.split(SEPARATOR, 1)
        if status.strip().casefold() != "playing" or not player:
            continue

        metadata_format = f"{{{{title}}}}{SEPARATOR}{{{{artist}}}}{SEPARATOR}{{{{mpris:artUrl}}}}"
        metadata = query(playerctl, [f"--player={player}", "--format", metadata_format, "metadata"])
        fields = metadata.rstrip("\n").split(SEPARATOR, 2)
        fields.extend([""] * (3 - len(fields)))
        title, artist, art_url = fields
        title = clean(title, MAX_TITLE_LENGTH)
        artist = clean(artist, MAX_ARTIST_LENGTH)
        return {"title": title, "artist": artist, "art_url": art_url.strip()}
    return None


def indicator():
    track = current_track()
    if track is None:
        return ""
    title = track["title"]
    artist = track["artist"]
    if title and artist:
        return f"♫ {title} · {artist}"
    if title or artist:
        return f"♫ {title or artist}"
    return "♫"


def cache_directory():
    cache = Path(os.environ.get("HYPRISM_CACHE_DIR", Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hyprism"))
    state = cache / "state"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(state, 0o700)
    return state


def write_png(path, image):
    descriptor, temporary = tempfile.mkstemp(prefix=".hyprism-cover-", suffix=".png", dir=path.parent)
    os.close(descriptor)
    try:
        image.save(temporary, format="PNG")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def empty_cover(state):
    path = state / "lock-media-empty.png"
    if not path.is_file():
        write_png(path, Image.new("RGBA", (1, 1), (0, 0, 0, 0)))
    return path


def public_https_url(url):
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        return False
    if parsed.hostname.casefold() == "localhost" or parsed.hostname.casefold().endswith(".localhost"):
        return False
    try:
        addresses = socket.getaddrinfo(parsed.hostname, parsed.port or 443, type=socket.SOCK_STREAM)
        return bool(addresses) and all(ipaddress.ip_address(address[4][0].split("%", 1)[0]).is_global for address in addresses)
    except (OSError, ValueError):
        return False


class HTTPSRedirectHandler(HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, new_url):
        return super().redirect_request(request, file, code, message, headers, new_url) if urlsplit(new_url).scheme == "https" else None


def cover_bytes(url):
    parsed = urlsplit(url)
    if len(url) > 8192:
        return None
    if parsed.scheme == "data":
        header, separator, payload = url.partition(",")
        if separator and header.casefold() in ("data:image/png;base64", "data:image/jpeg;base64", "data:image/webp;base64"):
            try:
                data = base64.b64decode(payload, validate=True)
            except ValueError:
                return None
        else:
            return None
    elif parsed.scheme == "file" and parsed.netloc in ("", "localhost") and not parsed.query and not parsed.fragment:
        path = Path(unquote(parsed.path))
        if not path.is_file() or path.stat().st_size > MAX_COVER_BYTES:
            return None
        with path.open("rb") as image_file:
            data = image_file.read(MAX_COVER_BYTES + 1)
    elif parsed.scheme == "https" and public_https_url(url):
        request = Request(url, headers={"User-Agent": "Hyprism/1.0"})
        opener = build_opener(HTTPSRedirectHandler())
        with opener.open(request, timeout=2.5) as response:
            if urlsplit(response.geturl()).scheme != "https":
                return None
            data = response.read(MAX_COVER_BYTES + 1)
    else:
        return None
    return data if 0 < len(data) <= MAX_COVER_BYTES else None


def cover_image(data):
    with Image.open(BytesIO(data)) as source:
        if source.format not in ("PNG", "JPEG", "WEBP") or source.width * source.height > MAX_COVER_PIXELS:
            return None
        source.seek(0)
        return ImageOps.fit(source.convert("RGB"), (ARTWORK_SIZE, ARTWORK_SIZE), method=Image.Resampling.LANCZOS)


def media_cover():
    state = cache_directory()
    fallback = empty_cover(state)
    track = current_track()
    if track is None or not track["art_url"]:
        return fallback

    art_url = track["art_url"]
    key = hashlib.sha256(art_url.encode("utf-8", errors="replace")).hexdigest()
    cover_path = state / "lock-media-cover.png"
    state_path = state / "lock-media-cover.json"
    try:
        previous = json.loads(state_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        previous = {}
    if previous.get("key") == key:
        if previous.get("loaded") is True and cover_path.is_file():
            return cover_path
        if previous.get("retryAfter", 0) > time.time():
            return fallback

    try:
        data = cover_bytes(art_url)
        image = cover_image(data) if data else None
        if image is None:
            raise ValueError("unsupported cover image")
        write_png(cover_path, image)
        state_data = {"key": key, "loaded": True}
    except (OSError, ValueError, URLError, TimeoutError, Image.DecompressionBombError):
        state_data = {"key": key, "loaded": False, "retryAfter": time.time() + 60}
        try:
            write_state(state_path, state_data)
        except OSError:
            pass
        return fallback
    write_state(state_path, state_data)
    return cover_path


def write_state(path, state):
    descriptor, temporary = tempfile.mkstemp(prefix=".hyprism-cover-", suffix=".json", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(state, handle)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


if __name__ == "__main__":
    try:
        output = str(media_cover()) if sys.argv[1:] == ["--cover"] else indicator()
    except Exception:
        output = ""
    if output:
        print(output)
