#!/usr/bin/env python3
import configparser
import json
import os
import pathlib
import shlex
import subprocess
import sys


def normalized(value):
    return ''.join(character for character in str(value).casefold() if character.isalnum())


def application_roots():
    data_home = pathlib.Path(os.environ.get('XDG_DATA_HOME', pathlib.Path.home() / '.local/share'))
    data_dirs = os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':')
    roots = [data_home / 'applications']
    roots.extend(pathlib.Path(directory) / 'applications' for directory in data_dirs if directory)
    return list(dict.fromkeys(roots))


def command_details(command):
    try:
        tokens = [token for token in shlex.split(command) if not token.startswith('%')]
    except ValueError:
        return '', '', ''
    executable_index = 0
    if tokens and pathlib.Path(tokens[0]).name == 'env':
        executable_index = 1
        while executable_index < len(tokens) and ('=' in tokens[executable_index] or tokens[executable_index].startswith('-')):
            executable_index += 1
    executable = pathlib.Path(tokens[executable_index]).name if executable_index < len(tokens) else ''
    flatpak_id = ''
    if executable == 'flatpak' and 'run' in tokens:
        run_index = tokens.index('run') + 1
        while run_index < len(tokens) and tokens[run_index].startswith('-'):
            run_index += 1
        if run_index < len(tokens):
            flatpak_id = tokens[run_index]
    return ' '.join(tokens), executable, flatpak_id


def desktop_entries():
    apps = {}
    for root in application_roots():
        if not root.exists():
            continue
        for path in root.rglob('*.desktop'):
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str
            try:
                parser.read(path, encoding='utf-8')
                section = parser['Desktop Entry']
                if section.get('Type') != 'Application' or section.getboolean('NoDisplay', fallback=False) or section.getboolean('Hidden', fallback=False):
                    continue
                command, executable, flatpak_id = command_details(section.get('Exec', ''))
                if not command:
                    continue
                desktop_id = str(path.relative_to(root)).replace('/', '-').removesuffix('.desktop') or path.stem
                if desktop_id in apps:
                    continue
                startup_class = section.get('StartupWMClass', '')
                if startup_class.startswith('@@'):
                    startup_class = ''
                name = section.get('Name', desktop_id)
                aliases = {desktop_id, path.stem, startup_class, executable, flatpak_id, pathlib.Path(section.get('TryExec', '')).name, name}
                ignored_parts = {'app', 'bin', 'class', 'com', 'desktop', 'org', 'opt', 'share', 'startup', 'usr'}
                aliases.update(part for value in tuple(aliases) for part in str(value).replace('-', '.').replace('_', '.').split('.') if len(part) >= 4 and part.casefold() not in ignored_parts)
                apps[desktop_id] = {
                    'id': desktop_id,
                    'name': name,
                    'comment': section.get('Comment', ''),
                    'icon': section.get('Icon', 'application-x-executable'),
                    'exec': command,
                    'startupClass': startup_class,
                    'executable': executable,
                    'primaryAliases': sorted({normalized(alias) for alias in (desktop_id, startup_class, flatpak_id) if normalized(alias)}),
                    'aliases': sorted({normalized(alias) for alias in aliases if normalized(alias)})
                }
            except (configparser.Error, OSError, KeyError, ValueError):
                continue
    return sorted(apps.values(), key=lambda item: item['name'].casefold())


def process_metadata(pid):
    executable = ''
    command = ''
    try:
        executable = pathlib.Path(os.readlink(f'/proc/{pid}/exe')).name
    except OSError:
        pass
    try:
        tokens = pathlib.Path(f'/proc/{pid}/cmdline').read_bytes().decode(errors='replace').split('\0')
        command = pathlib.Path(tokens[0]).name if tokens and tokens[0] else ''
    except OSError:
        pass
    return executable, command


def client_entries():
    try:
        result = subprocess.run(['hyprctl', '-j', 'clients'], check=True, capture_output=True, text=True, timeout=3)
        clients = json.loads(result.stdout)
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
        return {}
    index = {}
    for client in clients if isinstance(clients, list) else []:
        address = str(client.get('address', '')).lower()
        if not address:
            continue
        executable, command = process_metadata(client.get('pid', 0))
        index[address] = {
            'class': client.get('class', ''),
            'initialClass': client.get('initialClass', ''),
            'title': client.get('title', ''),
            'initialTitle': client.get('initialTitle', ''),
            'pid': client.get('pid', 0),
            'executable': executable,
            'command': command,
            'xwayland': bool(client.get('xwayland', False))
        }
    return index


if len(sys.argv) > 1 and sys.argv[1] == 'clients':
    print(json.dumps(client_entries()))
else:
    print(json.dumps(desktop_entries()))
