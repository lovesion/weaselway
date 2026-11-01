#!/usr/bin/env python3
"""Read-only upstream and local ABI audit. Never upgrade anything."""
import json, os, pathlib, subprocess, urllib.request, datetime
prefix=pathlib.Path('/opt/weaselway')
pins=json.loads((prefix/'versions.json').read_text())
results={}
for repo,kind in [('weaselway','commits/main'),('mesa','commits/mesa-26.2.1-wsl'),('dxgdrm','releases/latest'),('freerdp','releases/latest')]:
    try:
        req=urllib.request.Request(f'https://api.github.com/repos/weaselway/{repo}/{kind}',headers={'User-Agent':'Weaselway-Arch-maintenance'})
        with urllib.request.urlopen(req,timeout=20) as r: value=json.load(r)
        latest=value.get('sha',value.get('tag_name'))
        results[repo]={'installed':pins[repo],'latest':latest,'changed':latest!=pins[repo]}
    except Exception as e: results[repo]={'error':str(e)}
kernel=os.uname().release
results['kernel']={'running':kernel,'module_available':(prefix/'dxgdrm/lib/modules'/kernel/'extra/dxgdrm.ko').exists()}
installed=subprocess.check_output(['pacman','-Q','kwin','plasma-desktop','freerdp','mesa'],text=True).splitlines()
results['packages']={'installed':installed,'validated':pins.get('packages',[]),'changed':installed!=pins.get('packages',[])}
out=pathlib.Path(os.environ.get('XDG_STATE_HOME',str(pathlib.Path.home()/'.local/state')))/'weaselway'; out.mkdir(parents=True,exist_ok=True)
payload=json.dumps(results,ensure_ascii=False,indent=2)
old=(out/'update-status.json').read_text() if (out/'update-status.json').exists() else ''
(out/'update-status.json').write_text(payload+'\n')
print(payload)
needs_attention=any(v.get('changed') for v in results.values() if isinstance(v,dict)) or not results['kernel']['module_available']
if needs_attention and old.strip()!=payload.strip():
    subprocess.run(['notify-send','Weaselway 更新检查','有上游更新或内核兼容性变化。请查看 ~/.local/state/weaselway/update-status.json，再决定更新。'],check=False)
