#!/usr/bin/env python3
import subprocess, sys
def run(args):
    try: return subprocess.run(args, text=True, capture_output=True, timeout=12).stdout
    except (OSError, subprocess.SubprocessError): return ''
if len(sys.argv) < 2: raise SystemExit('usage: bluetooth.py {power|connect|disconnect} [value]')
if sys.argv[1] == 'power': run(['bluetoothctl','power',sys.argv[2]])
elif sys.argv[1] in ('connect','disconnect'): run(['bluetoothctl',sys.argv[1],sys.argv[2]])
