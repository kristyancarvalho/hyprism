#!/usr/bin/env python3
import configparser
import ctypes
import json
import os
import pathlib
import select
import shlex
import socket
import struct
import subprocess
import sys
import time


def normalized(value):
    return ''.join(character for character in str(value).casefold() if character.isalnum())


def application_roots():
    data_home = pathlib.Path(os.environ.get('XDG_DATA_HOME', pathlib.Path.home() / '.local/share'))
    data_dirs = os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':')
    roots = [data_home / 'applications']
    roots.extend(pathlib.Path(directory) / 'applications' for directory in data_dirs if directory)
    roots.extend([
        pathlib.Path.home() / '.local/share/flatpak/exports/share/applications',
        pathlib.Path('/var/lib/flatpak/exports/share/applications')
    ])
    return list(dict.fromkeys(roots))


def localized(section, key, fallback=''):
    locale = os.environ.get('LC_ALL') or os.environ.get('LC_MESSAGES') or os.environ.get('LANG', '')
    locale = locale.split('.', 1)[0].split('@', 1)[0]
    candidates = [locale]
    if '_' in locale:
        candidates.append(locale.split('_', 1)[0])
    for candidate in candidates:
        if candidate and section.get(f'{key}[{candidate}]'):
            return section.get(f'{key}[{candidate}]')
    return section.get(key, fallback)


def desktop_list(value):
    return [item for item in str(value).split(';') if item]


def desktop_visible(section):
    desktops = {item.casefold() for item in os.environ.get('XDG_CURRENT_DESKTOP', '').split(':') if item}
    only = {item.casefold() for item in desktop_list(section.get('OnlyShowIn', ''))}
    excluded = {item.casefold() for item in desktop_list(section.get('NotShowIn', ''))}
    if only and not desktops.intersection(only):
        return False
    return not desktops.intersection(excluded)


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
    seen = set()
    for root in application_roots():
        if not root.exists():
            continue
        for path in root.rglob('*.desktop'):
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str
            try:
                parser.read(path, encoding='utf-8')
                section = parser['Desktop Entry']
                desktop_id = str(path.relative_to(root)).replace('/', '-').removesuffix('.desktop') or path.stem
                if desktop_id in seen:
                    continue
                seen.add(desktop_id)
                no_display = section.getboolean('NoDisplay', fallback=False)
                hidden = section.getboolean('Hidden', fallback=False)
                if section.get('Type') != 'Application' or no_display or hidden or not desktop_visible(section):
                    continue
                command, executable, flatpak_id = command_details(section.get('Exec', ''))
                if not command:
                    continue
                startup_class = section.get('StartupWMClass', '')
                if startup_class.startswith('@@'):
                    startup_class = ''
                name = localized(section, 'Name', desktop_id)
                comment = localized(section, 'Comment', '')
                aliases = {desktop_id, path.stem, startup_class, executable, flatpak_id, pathlib.Path(section.get('TryExec', '')).name, name}
                ignored_parts = {'app', 'bin', 'class', 'com', 'desktop', 'org', 'opt', 'share', 'startup', 'usr'}
                aliases.update(part for value in tuple(aliases) for part in str(value).replace('-', '.').replace('_', '.').split('.') if len(part) >= 4 and part.casefold() not in ignored_parts)
                apps[desktop_id] = {
                    'id': desktop_id,
                    'name': name,
                    'comment': comment,
                    'icon': section.get('Icon', 'application-x-executable'),
                    'exec': command,
                    'path': str(path),
                    'terminal': section.getboolean('Terminal', fallback=False),
                    'noDisplay': no_display,
                    'hidden': hidden,
                    'onlyShowIn': desktop_list(section.get('OnlyShowIn', '')),
                    'notShowIn': desktop_list(section.get('NotShowIn', '')),
                    'startupClass': startup_class,
                    'executable': executable,
                    'primaryAliases': sorted({normalized(alias) for alias in (desktop_id, startup_class, flatpak_id) if normalized(alias)}),
                    'aliases': sorted({normalized(alias) for alias in aliases if normalized(alias)})
                }
            except (configparser.Error, OSError, KeyError, ValueError):
                continue
    return sorted(apps.values(), key=lambda item: item['name'].casefold())


def launch_desktop_entry(desktop_id):
    for entry in desktop_entries():
        if entry['id'] != desktop_id:
            continue
        subprocess.Popen(['gio', 'launch', entry['path']], start_new_session=True)
        return 0
    return 1


def watch_desktop_entries():
    libc = ctypes.CDLL(None, use_errno=True)
    init = libc.inotify_init1
    init.argtypes = [ctypes.c_int]
    init.restype = ctypes.c_int
    add = libc.inotify_add_watch
    add.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
    add.restype = ctypes.c_int
    event = struct.Struct('iIII')
    watch_mask = 0x00000004 | 0x00000008 | 0x00000040 | 0x00000080 | 0x00000100 | 0x00000200 | 0x00000400 | 0x00000800
    directory_flag = 0x40000000

    def open_watches():
        descriptor = init(os.O_CLOEXEC | os.O_NONBLOCK)
        if descriptor < 0:
            raise OSError(ctypes.get_errno(), os.strerror(ctypes.get_errno()))
        watched = set()
        candidates = []
        for root in application_roots():
            if root.is_dir():
                candidates.append(root)
                candidates.extend(path for path in root.rglob('*') if path.is_dir())
            elif root.parent.is_dir():
                candidates.append(root.parent)
        for path in candidates:
            resolved = str(path.resolve())
            if resolved in watched:
                continue
            if add(descriptor, os.fsencode(resolved), watch_mask) >= 0:
                watched.add(resolved)
        return descriptor

    def publish_index():
        print(json.dumps(desktop_entries()), flush=True)

    descriptor = open_watches()
    publish_index()
    deadline = None
    rebuild_watches = False
    try:
        while True:
            timeout = None if deadline is None else max(0, deadline - time.monotonic())
            ready, _, _ = select.select([descriptor], [], [], timeout)
            if not ready:
                publish_index()
                if rebuild_watches:
                    os.close(descriptor)
                    descriptor = open_watches()
                    rebuild_watches = False
                deadline = None
                continue
            try:
                data = os.read(descriptor, 65536)
            except BlockingIOError:
                continue
            offset = 0
            relevant = False
            while offset + event.size <= len(data):
                _, mask, _, length = event.unpack_from(data, offset)
                offset += event.size
                name = data[offset:offset + length].split(b'\0', 1)[0]
                offset += length
                if mask & directory_flag:
                    rebuild_watches = True
                    relevant = True
                elif not name or name.lower().endswith(b'.desktop'):
                    relevant = True
            if relevant:
                deadline = time.monotonic() + .35
    finally:
        os.close(descriptor)


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
        if not client.get('mapped', False) or not address.startswith('0x') or address == '0x0':
            continue
        executable, command = process_metadata(client.get('pid', 0))
        index[address] = {
            'address': address,
            'class': client.get('class', ''),
            'initialClass': client.get('initialClass', ''),
            'title': client.get('title', ''),
            'initialTitle': client.get('initialTitle', ''),
            'pid': client.get('pid', 0),
            'executable': executable,
            'command': command,
            'xwayland': bool(client.get('xwayland', False)),
            'workspace': client.get('workspace', {}).get('id', 0),
            'focusHistoryID': client.get('focusHistoryID', -1)
        }
    return index


def watch_client_entries():
    runtime = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
    signature = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
    event_path = pathlib.Path(runtime) / 'hypr' / signature / '.socket2.sock'
    relevant = ('openwindow', 'closewindow', 'movewindow', 'windowtitle', 'activewindow', 'changefloatingmode')

    def publish():
        print(json.dumps(client_entries()), flush=True)

    publish()
    while True:
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            connection.connect(str(event_path))
            connection.setblocking(False)
            buffer = b''
            deadline = time.monotonic() + 15
            dirty = False
            while True:
                timeout = max(0, deadline - time.monotonic())
                readable, _, _ = select.select([connection], [], [], timeout)
                if readable:
                    chunk = connection.recv(65536)
                    if not chunk:
                        break
                    buffer += chunk
                    lines = buffer.split(b'\n')
                    buffer = lines.pop()
                    if any(line.decode(errors='replace').startswith(relevant) for line in lines):
                        dirty = True
                        deadline = min(deadline, time.monotonic() + .08)
                if time.monotonic() >= deadline or dirty and not readable:
                    publish()
                    dirty = False
                    deadline = time.monotonic() + 15
        except OSError:
            time.sleep(1)
            publish()
        finally:
            connection.close()


if len(sys.argv) > 2 and sys.argv[1] == 'launch':
    raise SystemExit(launch_desktop_entry(sys.argv[2]))
elif len(sys.argv) > 1 and sys.argv[1] == 'clients':
    print(json.dumps(client_entries()))
elif len(sys.argv) > 1 and sys.argv[1] == 'clients-watch':
    watch_client_entries()
elif len(sys.argv) > 1 and sys.argv[1] == 'watch':
    watch_desktop_entries()
else:
    print(json.dumps(desktop_entries()))
