#!/usr/bin/env python3
import json, os, pathlib, shutil, subprocess, time
previous_cpu=None

def command(args, timeout=1):
    try: return subprocess.run(args, text=True, capture_output=True, timeout=timeout).stdout.strip()
    except (OSError, subprocess.SubprocessError): return ''
def volume(target='@DEFAULT_AUDIO_SINK@'):
    text = command(['wpctl', 'get-volume', target])
    try: return {'available': bool(text), 'percent': round(float(text.split()[1])*100), 'muted': 'MUTED' in text}
    except (IndexError, ValueError): return {'available': False, 'percent': 0, 'muted': False}
def network():
    active = command(['nmcli','-t','-f','TYPE,NAME,DEVICE','connection','show','--active'])
    if not active: return {'kind':'disconnected','name':'Desconectado','enabled':False,'signal':0}
    fields = active.splitlines()[0].split(':', 2)
    kind, name = fields[0], fields[1] if len(fields)>1 else ''
    signal = command(['nmcli','-t','-f','IN-USE,SIGNAL,SSID','device','wifi','list']).splitlines()
    strength = next((int(row.split(':')[1]) for row in signal if row.startswith('*:') and len(row.split(':')) > 1 and row.split(':')[1].isdigit()), 0)
    return {'kind':'wifi' if kind == 'wifi' else 'ethernet','name':name or ('Ethernet' if kind == 'ethernet' else 'Rede'),'enabled':True,'signal':strength}
def bluetooth():
    if not shutil.which('bluetoothctl'): return {'available':False,'powered':False,'connected':False,'devices':[]}
    show=command(['bluetoothctl','show'])
    if not show: return {'available':False,'powered':False,'connected':False,'devices':[]}
    powered='Powered: yes' in show; devices=[]
    for row in command(['bluetoothctl','devices','Paired']).splitlines():
        parts=row.split(maxsplit=2)
        if len(parts)==3: devices.append({'address':parts[1],'name':parts[2],'connected':parts[1] in command(['bluetoothctl','devices','Connected'])})
    return {'available':True,'powered':powered,'connected':any(d['connected'] for d in devices),'devices':devices}
def battery():
    for path in pathlib.Path('/sys/class/power_supply').glob('*'):
        try:
            if (path/'type').read_text().strip() == 'Battery': return {'available':True,'percent':int((path/'capacity').read_text()),'status':(path/'status').read_text().strip()}
        except (OSError, ValueError): pass
    return {'available':False,'percent':0,'status':''}
def brightness():
    value=command(['brightnessctl','-m'])
    try: return {'available':True,'percent':int(value.split(',')[3].rstrip('%'))}
    except (IndexError, ValueError): return {'available':False,'percent':0}
def memory():
    values={}
    try:
        for line in pathlib.Path('/proc/meminfo').read_text().splitlines(): values[line.split(':')[0]]=int(line.split()[1])
        return {'percent':round(100*(values['MemTotal']-values['MemAvailable'])/values['MemTotal']),'used':values['MemTotal']-values['MemAvailable'],'total':values['MemTotal']}
    except (OSError, KeyError, ValueError): return {'percent':0,'used':0,'total':0}
def cpu():
    global previous_cpu
    try:
        fields=[int(v) for v in pathlib.Path('/proc/stat').read_text().splitlines()[0].split()[1:]]
        total=sum(fields); idle=fields[3] + (fields[4] if len(fields)>4 else 0)
        old=previous_cpu; previous_cpu=(total,idle)
        usage=0 if old is None or total == old[0] else round(100*((total-old[0])-(idle-old[1]))/(total-old[0]))
        return {'percent':usage}
    except (OSError, ValueError, IndexError): return {'percent':0}
def gpu():
    text=command(['nvidia-smi','--query-gpu=utilization.gpu','--format=csv,noheader,nounits']) if shutil.which('nvidia-smi') else ''
    try: return {'available':True,'percent':round(float(text.splitlines()[0]))}
    except (IndexError, ValueError): return {'available':False,'percent':0}
def media():
    status=command(['playerctl','status'])
    if not status: return {'available':False,'status':'','artist':'','title':'','artUrl':''}
    text=command(['playerctl','metadata','--format','{{artist}}\t{{title}}\t{{mpris:artUrl}}'])
    parts=text.split('\t', 2)
    return {'available':True,'status':status,'artist':parts[0] if parts else '', 'title':parts[1] if len(parts)>1 else '', 'artUrl':parts[2] if len(parts)>2 else ''}
while True:
    state={'audio':volume(),'microphone':volume('@DEFAULT_AUDIO_SOURCE@'),'network':network(),'bluetooth':bluetooth(),'battery':battery(),'brightness':brightness(),'memory':memory(),'cpu':cpu(),'gpu':gpu(),'media':media(),'nightMode':False,'powerSaver':False}
    print(json.dumps(state), flush=True)
    time.sleep(3)
