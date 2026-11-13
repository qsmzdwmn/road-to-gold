#!/usr/bin/env python3
"""Inspect a Godot 4.6.3 Web PCK and load its audio in an isolated Godot process.
Usage: python3 tests/verify_audio_export.py builds/web/index.pck [--report result.json]
Only Python stdlib and the official Godot executable are needed; no preview site.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]

def inspect(pack):
    data=pack.read_bytes()
    magic,version,major,minor,patch,flags,base,directory=struct.unpack_from('<6IQQ',data,0)
    assert (magic,version,major,minor,patch)==(0x43504447,3,4,6,3),'Unexpected PCK/engine format'
    count=struct.unpack_from('<I',data,directory)[0];position=directory+4;entries={}
    for _ in range(count):
        length=struct.unpack_from('<I',data,position)[0];position+=4
        name=data[position:position+length].decode().rstrip('\0');position+=length
        offset,size=struct.unpack_from('<QQ',data,position);position+=16
        digest=data[position:position+16];position+=16
        file_flags=struct.unpack_from('<I',data,position)[0];position+=4
        content=data[base+offset:base+offset+size]
        assert hashlib.md5(content).digest()==digest,'Package integrity: '+name
        entries[name]=content
    assert not any(n.startswith(('tests/','tools/','work/')) or 'preview' in n.lower() or n.endswith(('.html','.glb','.blend')) for n in entries),'Unintended preview/development resource'
    manifest=json.loads(entries['assets/audio/manifest.json'])
    assert len(manifest['assets'])==10
    assert manifest==json.loads((ROOT/'assets/audio/manifest.json').read_text())
    for name,entry in manifest['assets'].items():
        assert hashlib.sha256((ROOT/'assets/audio'/name).read_bytes()).hexdigest()==entry['sha256'],'Approved audio changed: '+name
        assert 'assets/audio/'+name+'.import' in entries,'Missing audio import: '+name
    config=entries['project.binary'];assert config[:4]==b'ECFG'
    settings={};position=8
    for _ in range(struct.unpack_from('<I',config,4)[0]):
        length=struct.unpack_from('<I',config,position)[0];position+=4
        key=config[position:position+length].decode();position+=length
        length=struct.unpack_from('<I',config,position)[0];position+=4
        value=config[position:position+length];position+=length
        if key in ['application/config/name','application/config/version']:
            assert struct.unpack_from('<I',value,0)[0]==4
            size=struct.unpack_from('<I',value,4)[0];settings[key]=value[8:8+size].decode()
    assert settings['application/config/version']=='0.5.1'
    with tempfile.TemporaryDirectory(prefix='rtg-audio-pack-') as temporary:
        folder=Path(temporary)
        (folder/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Isolated Audio Package Verification"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        probe='''extends SceneTree
func _initialize():
 assert(ProjectSettings.load_resource_pack(PACK,true))
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
 assert(manifest.assets.size()==10)
 for name:String in manifest.assets:
  var stream=load("res://assets/audio/"+name)
  assert(stream is AudioStream)
  assert(absf(stream.get_length()-float(manifest.assets[name].seconds))<0.01)
  if name in ["hub_music.ogg","stadium_crowd.ogg"]:assert(stream.loop)
  print("PASS: EXPORTED AUDIO ",name)
 AudioServer.set_bus_layout(load("res://default_bus_layout.tres"))
 assert(AudioServer.bus_count==4)
 for bus:String in ["Master","Music","Sound Effects","Stadium Crowd"]:assert(AudioServer.get_bus_index(bus)>=0)
 print("PASS: exported audio buses")
 assert(load("res://scripts/race/race_quality.gd").load_mode()=="performance")
 print("PASS: exported default quality Performance")
 assert(not ResourceLoader.exists("res://assets/audio/preview.html"))
 print("PASS: no preview website resources")
 quit()
'''.replace('PACK',json.dumps(str(pack)))
        (folder/'probe.gd').write_text(probe)
        env=os.environ|{'XDG_CONFIG_HOME':str(folder/'config'),'XDG_DATA_HOME':str(folder/'data'),'XDG_CACHE_HOME':str(folder/'cache')}
        result=subprocess.run(['godot','--headless','--path',str(folder),'--script',str(folder/'probe.gd')],env=env,capture_output=True,text=True,timeout=90)
        log=result.stdout+result.stderr
        assert result.returncode==0 and 'ERROR:' not in log and 'WARNING:' not in log,log
        assert log.count('PASS:')==13,log
    return {'godot_version':[major,minor,patch],'metadata':settings,'pack_sha256':hashlib.sha256(data).hexdigest(),'file_count':count,'all_entry_md5_verified':True,'approved_audio_hashes_unchanged':True,'audio_imports':10,'stream_load_assertions':13,'no_preview_tools_tests_or_experimental_models':True,'probe_log':log}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('pack',type=Path);parser.add_argument('--report',type=Path)
    args=parser.parse_args();report=inspect(args.pack.resolve())
    if args.report:args.report.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
