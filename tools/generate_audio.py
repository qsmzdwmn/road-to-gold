#!/usr/bin/env python3
"""Original ROAD TO GOLD score/SFX. Offline only; Python + NumPy + ffmpeg.
No recordings, downloaded samples, speech, APIs or runtime synthesis.
Deterministic seed 510. 24 kHz; Ogg loops, mono PCM effects.
"""
from pathlib import Path
import hashlib, json, math, subprocess, tempfile, wave
import numpy as np
RATE = 24000
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'
RNG = np.random.default_rng(510)
REPORT = {}

def tone(freq, duration, kind='bell'):
    t = np.arange(round(duration*RATE))/RATE
    if kind == 'pad':
        s = sum(np.sin(2*np.pi*freq*k*t + 0.01*np.sin(t*2*np.pi*.2))*a for k,a in [(1,1),(2,.22),(3,.07)])
        env = np.minimum(t/.65,1)*np.minimum((duration-t)/.85,1)
    else:
        s = np.sin(2*np.pi*freq*t)+.2*np.sin(2*np.pi*freq*2*t)*np.exp(-t*4)
        env = (1-np.exp(-t*130))*np.exp(-t*3.0)
    return s*env

def add(dst, src, at, gain=1, wrap=False):
    start=round(at*RATE)
    if wrap:
        np.add.at(dst, (start+np.arange(len(src)))%len(dst), src*gain)
    else:
        end=min(len(dst),start+len(src))
        if end>start: dst[start:end]+=src[:end-start]*gain

def clap():
    t=np.arange(round(.115*RATE))/RATE
    noise=RNG.normal(0,1,len(t)); noise=np.r_[0,np.diff(noise)]*.4
    # Three close transients imitate palms; no sustained noise bed.
    env=sum(np.where(t>=a,np.exp(-np.maximum(0,t-a)*105),0)*g for a,g in [(0,1),(.012,.7),(.025,.4)])
    return noise*env + np.sin(2*np.pi*660*t)*np.exp(-t*100)*.1

def crowd(seconds, density):
    dst=np.zeros(round(seconds*RATE))
    for at in RNG.uniform(0,seconds,round(seconds*density)):
        add(dst,clap(),at,RNG.uniform(.025,.10),True)
    # Quiet, nonverbal distant rising/falling cheers; harmonics dominate hiss.
    for at in np.arange(.2,seconds,1.35):
        duration=RNG.uniform(.65,1.4); t=np.arange(round(duration*RATE))/RATE
        f=RNG.uniform(240,390)*(1+.12*np.sin(np.pi*t/duration))
        phase=2*np.pi*np.cumsum(f)/RATE
        s=(np.sin(phase)+.23*np.sin(phase*2)+.09*np.sin(phase*3))*np.sin(np.pi*t/duration)**2
        add(dst,s,at,.016,True)
    # Short low-pass diffusion gives distance without a permanent static layer.
    dst=np.convolve(dst,np.ones(5)/5,mode='same')
    return dst

def save(name, data, peak=.7, loop=False):
    data=np.asarray(data,dtype=float)
    data-=np.mean(data,axis=0)
    data*=peak/max(float(np.max(np.abs(data))),1e-8)
    if not loop:
        n=min(300,len(data)//8); data[:n]*=np.linspace(0,1,n)[:,None] if data.ndim==2 else np.linspace(0,1,n)
        data[-n:]*=np.linspace(1,0,n)[:,None] if data.ndim==2 else np.linspace(1,0,n)
    pcm=np.round(np.clip(data,-1,1)*32767).astype('<i2')
    target=OUT/name
    with tempfile.TemporaryDirectory() as temp:
        src=Path(temp)/'source.wav'
        with wave.open(str(src),'wb') as w:
            w.setnchannels(data.shape[1] if data.ndim==2 else 1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
        if target.suffix=='.ogg':
            subprocess.run(['ffmpeg','-v','error','-y','-i',str(src),'-c:a','libvorbis','-q:a','3',str(target)],check=True)
        else: target.write_bytes(src.read_bytes())
    REPORT[name]={'seconds':round(len(data)/RATE,3),'channels':data.shape[1] if data.ndim==2 else 1,'bytes':target.stat().st_size,'pcm_bytes':pcm.nbytes,'peak':round(float(np.max(np.abs(data))),4),'rms':round(float(np.sqrt(np.mean(data**2))),4),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}

OUT.mkdir(parents=True,exist_ok=True)
# 90 BPM, 12 bars. Original D-minor progression and sparse rising motif.
length=32.; music=np.zeros(round(length*RATE)); beat=2/3
chords=[(146.832,174.614,220),(116.541,146.832,174.614),(130.813,174.614,220),(130.813,164.814,195.998),(97.999,146.832,174.614),(110,164.814,220)]
for bar,chord in enumerate(chords):
    at=bar*8*beat
    for f in chord:add(music,tone(f,6.4,'pad'),at,.055,True)
    for b in [0,3,4,7]:add(music,tone(chord[b%3]*2,1.6),at+b*beat,.025,True)
for b,f in [(4,440),(7,523.251),(12,587.33),(20,523.251),(23,440),(28,392),(36,440),(39,523.251),(44,659.255),(46,587.33)]:add(music,tone(f,2.6),b*beat,.05,True)
# Small cyclic stereo reflection, seamless at loop boundary.
stereo=np.stack([music+np.roll(music,round(.17*RATE))*.14,music+np.roll(music,round(.23*RATE))*.14],axis=1)
save('hub_music.ogg',stereo,.42,True)
save('stadium_crowd.ogg',crowd(12,14),.30,True)
save('crowd_finish.ogg',crowd(2.4,55)*np.sin(np.linspace(0,np.pi,round(2.4*RATE)))**.65,.48)
pb=np.zeros(round(3.2*RATE))
for at,f in [(0,523.251),(.23,659.255),(.46,783.991),(.76,1046.502)]:add(pb,tone(f,2),at,.14)
add(pb,crowd(2.6,28),.15,.55)
save('crowd_pb.ogg',pb,.52)
t=np.arange(round(.3*RATE))/RATE
pop=RNG.normal(0,1,len(t))*np.exp(-t*65)*.45+np.sin(2*np.pi*(160*t+25*(1-np.exp(-t*35))))*np.exp(-t*35)*.35
save('start_pistol.wav',pop,.65)
for name,f in [('footstep_left.wav',95),('footstep_right.wav',109)]:
    t=np.arange(round(.12*RATE))/RATE
    step=np.sin(2*np.pi*f*t)*np.exp(-t*65)+RNG.normal(0,.16,len(t))*np.exp(-t*95)
    save(name,step,.34)
save('finish.wav',tone(659.255,.7)*.65+tone(987.767,.7)*.35,.34)
save('ui_navigation.wav',tone(660,.085),.16)
save('ui_confirm.wav',tone(880,.18)+tone(1320,.18)*.2,.20)
(OUT/'manifest.json').write_text(json.dumps({'generator':'tools/generate_audio.py','seed':510,'sample_rate':RATE,'assets':REPORT},indent=2)+'\n')
print(json.dumps(REPORT,indent=2));print('Total bytes:',sum(v['bytes'] for v in REPORT.values()))
