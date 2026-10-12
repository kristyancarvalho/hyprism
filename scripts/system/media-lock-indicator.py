#!/usr/bin/env python3
import html
import shutil
import subprocess
import unicodedata


SEPARATOR = "\x1f"
MAX_TITLE_LENGTH = 46
MAX_ARTIST_LENGTH = 24


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


def indicator():
    playerctl = shutil.which("playerctl")
    if not playerctl:
        return ""

    status_format = f"{{{{playerName}}}}{SEPARATOR}{{{{lc(status)}}}}"
    for line in query(playerctl, ["--all-players", "--format", status_format, "status"]).splitlines():
        if SEPARATOR not in line:
            continue
        player, status = line.split(SEPARATOR, 1)
        if status.strip().casefold() != "playing" or not player:
            continue

        metadata_format = f"{{{{title}}}}{SEPARATOR}{{{{artist}}}}"
        metadata = query(playerctl, [f"--player={player}", "--format", metadata_format, "metadata"])
        title, separator, artist = metadata.partition(SEPARATOR)
        title = clean(title, MAX_TITLE_LENGTH)
        artist = clean(artist, MAX_ARTIST_LENGTH) if separator else ""
        if title and artist:
            return f"♫ {title} · {artist}"
        if title or artist:
            return f"♫ {title or artist}"
        return "♫"
    return ""


if __name__ == "__main__":
    try:
        output = indicator()
    except (OSError, UnicodeError, ValueError):
        output = ""
    if output:
        print(output)
