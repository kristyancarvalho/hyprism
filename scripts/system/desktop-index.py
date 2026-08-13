#!/usr/bin/env python3
import configparser
import json
import os
import pathlib
import shlex

def normalized(value):
    return ''.join(character for character in value.casefold() if character.isalnum())


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
        return '', ''
    executable = tokens[0] if tokens else ''
    return ' '.join(tokens), pathlib.Path(executable).name


apps = {}
roots = application_roots()
compatibility_aliases = {
    'chromium': {'chrome', 'chromiumbrowser'},
    'code': {'codeurlhandler', 'visualstudiocode'},
    'firefox': {'orgmozillafirefox'}
}
for root in roots:
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
            command, executable = command_details(section.get('Exec', ''))
            if not command:
                continue
            relative_id = str(path.relative_to(root)).replace('/', '-').removesuffix('.desktop')
            desktop_id = relative_id or path.stem
            if desktop_id in apps:
                continue
            startup_class = section.get('StartupWMClass', '')
            aliases = {
                desktop_id,
                path.stem,
                startup_class,
                executable,
                section.get('TryExec', ''),
                section.get('Name', '')
            }
            aliases.update(compatibility_aliases.get(normalized(desktop_id), set()))
            apps[desktop_id] = {
                'id': desktop_id,
                'name': section.get('Name', desktop_id),
                'comment': section.get('Comment', ''),
                'icon': section.get('Icon', 'application-x-executable'),
                'exec': command,
                'startupClass': startup_class,
                'executable': executable,
                'aliases': sorted({normalized(alias) for alias in aliases if normalized(alias)})
            }
        except (configparser.Error, OSError, KeyError, ValueError):
            continue
print(json.dumps(sorted(apps.values(), key=lambda item: item['name'].casefold())))
