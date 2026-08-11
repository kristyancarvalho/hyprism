#!/usr/bin/env python3
import json, subprocess, sys
def run(args):
    try: return subprocess.run(args, text=True, capture_output=True, timeout=12).stdout.strip()
    except (OSError, subprocess.SubprocessError): return ''
if len(sys.argv) < 2: raise SystemExit('uso: network.py {list|toggle|connect} ...')
command=sys.argv[1]
if command == 'list':
    unique={}
    for row in run(['nmcli','-t','-f','SSID,SIGNAL,SECURITY','device','wifi','list','--rescan','auto']).splitlines():
        fields=row.split(':', 2)
        if len(fields) >= 2 and fields[0] and fields[0] not in unique:
            unique[fields[0]]={'ssid':fields[0], 'signal':int(fields[1]) if fields[1].isdigit() else 0, 'secure':bool(fields[2]) if len(fields)>2 else False}
    print(json.dumps(sorted(unique.values(), key=lambda item:item['signal'], reverse=True)))
elif command == 'toggle':
    run(['nmcli','radio','wifi',sys.argv[2]])
elif command == 'connect':
    args=['nmcli','device','wifi','connect',sys.argv[2]]
    if len(sys.argv) > 3 and sys.argv[3]: args += ['password',sys.argv[3]]
    run(args)
