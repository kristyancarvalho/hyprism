#!/usr/bin/env python3
import configparser
import json
import os
import pathlib
import shlex

apps = {}
roots = [pathlib.Path('/usr/share/applications'), pathlib.Path.home() / '.local/share/applications']
for root in roots:
    if not root.exists():
        continue
    for path in root.glob('*.desktop'):
        parser = configparser.ConfigParser(interpolation=None)
        try:
            parser.read(path, encoding='utf-8')
            section = parser['Desktop Entry']
            if section.get('Type') != 'Application' or section.getboolean('NoDisplay', fallback=False) or section.getboolean('Hidden', fallback=False):
                continue
            command = section.get('Exec', '')
            if not command:
                continue
            command = ' '.join(token for token in shlex.split(command) if not token.startswith('%'))
            apps[path.stem] = {'id': path.stem, 'name': section.get('Name', path.stem), 'comment': section.get('Comment', ''), 'icon': section.get('Icon', 'application-x-executable'), 'exec': command}
        except (configparser.Error, OSError, KeyError, ValueError):
            continue
print(json.dumps(sorted(apps.values(), key=lambda item: item['name'].casefold())))
