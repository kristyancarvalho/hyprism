#!/usr/bin/env python3
import json, os, pathlib, subprocess, time, urllib.parse, urllib.request
home = pathlib.Path.home(); cache = pathlib.Path(os.environ.get('HYPRISM_CACHE_DIR', home/'.cache/hyprism'))/'state/weather.json'
config = pathlib.Path(os.environ.get('HYPRISM_CONFIG', home/'.config/hyprism/user.json'))
fallback={'city':'São Paulo','temperature':None,'apparentTemperature':None,'weatherCode':-1,'minimum':None,'maximum':None,'updatedAt':0}
try: settings=json.loads(config.read_text()).get('weather', {})
except (OSError, ValueError): settings={}
if not settings.get('enabled', True) or settings.get('latitude') is None or settings.get('longitude') is None:
    print(json.dumps(fallback)); raise SystemExit
params={'latitude':settings['latitude'],'longitude':settings['longitude'],'current':'temperature_2m,apparent_temperature,weather_code','daily':'temperature_2m_max,temperature_2m_min','timezone':settings.get('timezone','auto')}
try:
    with urllib.request.urlopen('https://api.open-meteo.com/v1/forecast?'+urllib.parse.urlencode(params), timeout=5) as reply: data=json.load(reply)
    result={'city':settings.get('location') or 'Tempo local','temperature':data['current']['temperature_2m'],'apparentTemperature':data['current']['apparent_temperature'],'weatherCode':data['current']['weather_code'],'minimum':data['daily']['temperature_2m_min'][0],'maximum':data['daily']['temperature_2m_max'][0],'updatedAt':int(time.time())}
    cache.parent.mkdir(parents=True, exist_ok=True); cache.write_text(json.dumps(result)); print(json.dumps(result))
except (OSError, KeyError, ValueError, urllib.error.URLError):
    try: print(cache.read_text())
    except OSError: print(json.dumps(fallback))
