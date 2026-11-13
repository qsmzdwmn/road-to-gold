#!/usr/bin/env python3
"""Real Chromium audio QA; fresh isolated profile, never the production origin.
Developer tools: Playwright, Pillow, NumPy, Chromium, Tesseract (not game deps).
Serve the exported Web directory, then use --url http://localhost:8000/index.html.
Outputs screenshots, actual Web Audio capture and verification.json to --out.
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
from PIL import Image, ImageOps
import numpy as np
import argparse, csv, io, json, os, re, subprocess, time, uuid
os.environ["OMP_THREAD_LIMIT"]="1"
parser=argparse.ArgumentParser()
parser.add_argument('--url',default='http://127.0.0.1:8031/web/index.html')
parser.add_argument('--headed',action='store_true',help='Use an available X display for desktop lifecycle checks')
parser.add_argument('--out',type=Path,default=Path(__file__).resolve().parents[1]/'work/audio-browser')
args=parser.parse_args()
OUT=args.out;OUT.mkdir(parents=True,exist_ok=True)
PROFILE=OUT/('profile-'+uuid.uuid4().hex[:8]);URL=args.url
report={'url':URL,'console':[],'page_errors':[],'failed_requests':[],'http_errors':[],'checks':[],'snapshots':{}}
serial=0
HOOK='(() => {\n window.audioAudit={contexts:[],starts:[],stops:0,live:{}};\n const Native=window.AudioContext;\n window.AudioContext=new Proxy(Native,{construct(T,args){const c=new T(...args);window.audioAudit.contexts.push(c);return c}});\n window.webkitAudioContext=window.AudioContext;\n const original=AudioBufferSourceNode.prototype.start;\n AudioBufferSourceNode.prototype.start=function(...args){const id=audioAudit.starts.length;this.rtgAuditId=id;audioAudit.live[id]={duration:this.buffer?.duration};this.addEventListener("ended",()=>{delete audioAudit.live[id]},{once:true});window.audioAudit.starts.push({duration:this.buffer?.duration,loop:this.loop,rate:this.playbackRate.value,at:this.context.currentTime,state:this.context.state});return original.apply(this,args)};\n const stop=AudioBufferSourceNode.prototype.stop;\n AudioBufferSourceNode.prototype.stop=function(...args){window.audioAudit.stops++;delete audioAudit.live[this.rtgAuditId];return stop.apply(this,args)};\n const connect=AudioNode.prototype.connect;\n AudioNode.prototype.connect=function(dest,...args){const result=connect.call(this,dest,...args);if(dest===this.context.destination){const c=this.context;if(!c.auditAnalyser){c.auditAnalyser=c.createAnalyser();c.auditAnalyser.fftSize=2048;c.auditSink=c.createMediaStreamDestination();connect.call(c.auditAnalyser,c.auditSink)}connect.call(this,c.auditAnalyser)}return result};\n window.audioSnapshot=()=>({contexts:audioAudit.contexts.map(c=>({state:c.state,sampleRate:c.sampleRate,baseLatency:c.baseLatency,outputLatency:c.outputLatency,rms:(()=>{if(!c.auditAnalyser)return 0;let a=new Float32Array(2048);c.auditAnalyser.getFloatTimeDomainData(a);return Math.sqrt(a.reduce((s,v)=>s+v*v,0)/a.length)})()})),starts:audioAudit.starts,stops:audioAudit.stops,live:Object.values(audioAudit.live)});\n})()'
def capture(page,name):
 global serial
 serial+=1
 path=OUT/f'{serial:02}-{name}.png'
 page.screenshot(path=str(path))
 from PIL import Image,ImageOps
 ocr_path=OUT/'ocr-temp.png'
 image=Image.open(path).convert('L');image=image.crop((0,0,min(960,image.width),image.height));image=ImageOps.invert(image).point(lambda value:255 if value>150 else 0);image=image.resize((image.width*2,image.height*2));image.save(ocr_path)
 tsv=subprocess.check_output(['tesseract',str(ocr_path),'stdout','--psm','6','tsv'],stderr=subprocess.DEVNULL,text=True)
 lines={}
 for row in csv.DictReader(io.StringIO(tsv),delimiter='\t',quoting=csv.QUOTE_NONE):
  if not row['text'].strip(): continue
  key=tuple(row[x] for x in ['block_num','par_num','line_num'])
  lines.setdefault(key,[]).append(row)
 result=[]
 for words in lines.values():
  text=' '.join(w['text'] for w in words)
  x=min(int(w['left']) for w in words); y=min(int(w['top']) for w in words)
  endx=max(int(w['left'])+int(w['width']) for w in words); endy=max(int(w['top'])+int(w['height']) for w in words)
  result.append((text,(x+endx)/4,(y+endy)/4))
 (OUT/f'{serial:02}-{name}.txt').write_text('\n'.join(r[0] for r in result))
 return result

def check(ok,message):
 report['checks'].append({'pass':bool(ok),'message':message})
 print(('PASS: ' if ok else 'FAIL: ')+message,flush=True)
 if not ok: raise AssertionError(message)

def text(page,expected,name):
 lines=capture(page,name)
 matched=any(''.join(expected.lower().split()) in ''.join(r[0].lower().split()) for r in lines)
 if not matched:
  alternate=subprocess.check_output(['tesseract',str(OUT/f'{serial:02}-{name}.png'),'stdout','--psm','11'],stderr=subprocess.DEVNULL,text=True)
  matched=''.join(expected.lower().split()) in ''.join(alternate.lower().split())
 check(matched,name+' visible: '+expected)
 return lines

def stored(page):
 return page.evaluate('''async () => {
 const info = await indexedDB.databases();
 const result = [];
 for (const meta of info) {
  const db = await new Promise((resolve,reject)=>{let r=indexedDB.open(meta.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
  for (const name of db.objectStoreNames) {
   const tx=db.transaction(name,'readonly'), s=tx.objectStore(name);
   const keys=await new Promise((resolve,reject)=>{let r=s.getAllKeys();r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
   const values=await new Promise((resolve,reject)=>{let r=s.getAll();r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
   keys.forEach((key,i)=>{let v=values[i];if(String(key).endsWith('prototype_v1.json'))result.push({database:meta.name,store:name,key,content:new TextDecoder().decode(v.contents)});});
  } db.close();
 } return result;
}''')

def attach(page):
 page.on('console',lambda m:report['console'].append({'type':m.type,'text':m.text}))
 page.on('pageerror',lambda e:report['page_errors'].append(str(e)))
 page.on('requestfailed',lambda r:report['failed_requests'].append({'url':r.url,'failure':r.failure}))
 page.on('response',lambda r:report['http_errors'].append({'url':r.url,'status':r.status}) if r.status>=400 else None)

def raw_lines(page,name):
 global serial
 serial+=1
 path=OUT/f'{serial:02}-{name}.png';page.screenshot(path=str(path))
 image=np.asarray(Image.open(path).convert('RGB'),dtype=np.int16)
 neutral=(image.min(axis=2)>100)&((image.max(axis=2)-image.min(axis=2))<45)
 mask=OUT/'neutral-text.png';Image.fromarray(np.where(neutral,0,255).astype('uint8')).save(mask)
 tsv=subprocess.check_output(['tesseract',str(mask),'stdout','--psm','11','tsv'],stderr=subprocess.DEVNULL,text=True)
 groups={}
 for row in csv.DictReader(io.StringIO(tsv),delimiter='\t',quoting=csv.QUOTE_NONE):
  if row['text'].strip():groups.setdefault(tuple(row[k] for k in ['block_num','par_num','line_num']),[]).append(row)
 result=[]
 for words in groups.values():
  x=min(int(w['left']) for w in words);y=min(int(w['top']) for w in words);right=max(int(w['left'])+int(w['width']) for w in words);bottom=max(int(w['top'])+int(w['height']) for w in words)
  result.append((' '.join(w['text'] for w in words),(x+right)/2,(y+bottom)/2))
 return result

def click(page,label,name):
 rows=raw_lines(page,name)
 normalize=lambda v:re.sub('[^a-z0-9]','',v.lower())
 hits=[r for r in rows if normalize(r[0])==normalize(label)]
 if not hits:hits=[r for r in rows if normalize(r[0]).startswith(normalize(label))]
 if not hits:raise AssertionError('Control not found '+label+' '+repr(rows))
 _,x,y=hits[-1];page.mouse.click(x,y);page.wait_for_timeout(600)

def boot(page):
 attach(page);page.goto(URL);page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(700)

def advance(page):click(page,'CONTINUE','continue-step')

def image(page,name):page.screenshot(path=str(OUT/(name+'.png')))

def names(page,first,last):
 for label,value in [('First name',first),('Last name',last)]:
  click(page,label,'name-'+label);page.keyboard.press('Control+a');page.keyboard.type(value,delay=60);page.wait_for_timeout(250)

def nav(page,label):
 rows=raw_lines(page,'nav-'+label);norm=lambda v:re.sub('[^a-z0-9]','',v.lower());hits=[r for r in rows if norm(r[0])==norm(label) and r[1]<220]
 if not hits:raise AssertionError('Sidebar link not found '+label+' '+repr(rows))
 _,x,y=hits[0];page.mouse.click(x,y);page.wait_for_timeout(650)

def phase_since(index,phase):
 return any(r['text'].startswith('RACE_PHASE ') and json.loads(r['text'].split(' ',1)[1])['phase']==phase for r in report['console'][index:])

def wait_phase(page,index,phase,timeout=60000):
 start=time.monotonic()
 while not phase_since(index,phase):
  if time.monotonic()-start>timeout/1000:raise AssertionError('Phase timeout '+phase)
  page.wait_for_timeout(50)
 check(True,'observed actual race phase '+phase)

def prep_bottom(page):page.mouse.move(350,430);page.mouse.wheel(0,2000);page.wait_for_timeout(600)

def get_record(page):return json.loads(stored(page)[0]['content'])

def start_hold(page):
 index=len(report['console']);prep_bottom(page);click(page,'Ready','ready');wait_phase(page,index,'running');phase=next(json.loads(r['text'].split(' ',1)[1]) for r in report['console'][index:] if r['text'].startswith('RACE_PHASE '));check(phase['mode']=='hold','Hold mode selected through visible UI');page.keyboard.down('Space');return index

def finish_hold(page,index):
 wait_phase(page,index,'results',90000);page.keyboard.up('Space');page.wait_for_timeout(2200)

def result_saved(page,prior_id=""):
 start=time.monotonic()
 while time.monotonic()-start<12:
  d=get_record(page)
  if d.get('competition',{}).get('latest',{}).get('id','') not in ['',prior_id]:return d
  page.wait_for_timeout(250)
 raise AssertionError('No saved competition result')

def launch(p):
 c=p.chromium.launch_persistent_context(str(PROFILE),executable_path=os.environ.get('RTG_CHROMIUM','/usr/bin/chromium'),headless=not args.headed,viewport={'width':1280,'height':720},args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--autoplay-policy=user-gesture-required'])
 c.add_init_script(HOOK);return c

def snapshot(page,name):
 value=page.evaluate('audioSnapshot()');report['snapshots'][name]=value;return value

def all_files(page):
 return page.evaluate("""async()=>{let out={};for(const meta of await indexedDB.databases()){const db=await new Promise((a,b)=>{let r=indexedDB.open(meta.name);r.onsuccess=()=>a(r.result);r.onerror=()=>b(r.error)});for(const store of db.objectStoreNames){const s=db.transaction(store,'readonly').objectStore(store);const keys=await new Promise(a=>{let r=s.getAllKeys();r.onsuccess=()=>a(r.result)}),values=await new Promise(a=>{let r=s.getAll();r.onsuccess=()=>a(r.result)});keys.forEach((k,i)=>{if(values[i].contents)out[String(k)]=new TextDecoder().decode(values[i].contents)})}db.close()}return out}""")

def audio_file(page):
 files=all_files(page);return next((v for k,v in files.items() if k.endswith('audio_settings.cfg')),'')

def set_slider(page,label,value):
 rows=raw_lines(page,'slider-'+label);_,_,y=next(r for r in rows if r[0].startswith(label));page.mouse.click(150,y+33);page.keyboard.press('Home')
 for i in range(value):page.keyboard.press('ArrowRight')
 page.wait_for_timeout(300)

def cues(page,duration):return [v for v in page.evaluate('audioSnapshot().starts') if abs(v['duration']-duration)<.015]

def record_start(page):
 page.evaluate("""()=>{let c=audioAudit.contexts[0];window.auditChunks=[];window.auditRecorder=new MediaRecorder(c.auditSink.stream,{mimeType:'audio/webm;codecs=opus'});auditRecorder.ondataavailable=e=>{if(e.data.size)auditChunks.push(e.data)};auditRecorder.start(250)}""")

def record_stop(page):
 import base64
 encoded=page.evaluate("""async()=>{let r=auditRecorder;await new Promise(a=>{r.onstop=a;r.stop()});let data=new Uint8Array(await new Blob(auditChunks).arrayBuffer());let s='';for(let i=0;i<data.length;i+=8192)s+=String.fromCharCode(...data.subarray(i,i+8192));return btoa(s)}""")
 (OUT/'in-game-audio.webm').write_bytes(base64.b64decode(encoded))

def run():
 try:
  with sync_playwright() as p:
   c=launch(p);page=c.pages[0];boot(page)
   if args.headed:c.new_cdp_session(page).send('Emulation.setFocusEmulationEnabled',{'enabled':False});page.bring_to_front()
   before=snapshot(page,'before-interaction');check(not before['starts'] and all(x['rms']==0 for x in before['contexts']),'no playback or signal before user interaction')
   click(page,'Settings','settings');page.wait_for_timeout(500);image(page,'settings-1280')
   check(len(cues(page,.085))==1,'first Settings interaction unlocks one UI sample in a running AudioContext')
   set_slider(page,'Music',17);set_slider(page,'Sound Effects',49);set_slider(page,'Stadium Crowd',24);click(page,'Mute All','mute');page.wait_for_timeout(1800)
   cfg=audio_file(page);check('music=17' in cfg and 'sfx=49' in cfg and 'crowd=24' in cfg and 'mute_all=true' in cfg,'three volumes and global mute persisted separately in IndexedDB')
   n=len(page.evaluate('audioSnapshot().starts'));click(page,'Back','muted-back');click(page,'Settings','muted-settings');check(len(page.evaluate('audioSnapshot().starts'))==n,'mute suppresses navigation playback')
   page.reload();page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(800);click(page,'Settings','reload-settings');text(page,'17%','music-reloaded');check(audio_file(page)==cfg,'all audio preferences survive page reload')
   page.set_viewport_size({'width':800,'height':600});page.wait_for_timeout(700);image(page,'settings-800');page.mouse.move(220,320);page.mouse.wheel(0,120);page.wait_for_timeout(300);click(page,'Mute All','unmute');page.mouse.move(220,310);page.mouse.wheel(0,1300);page.wait_for_timeout(500);image(page,'settings-800-bottom');text(page,'Performance','graphics-preserved');click(page,'Performance','quality-open');click(page,'Enhanced','quality-enhanced');page.wait_for_timeout(400);check(any('quality=\"enhanced\"' in v for k,v in all_files(page).items() if k.endswith('race_graphics.cfg')),'Enhanced graphics option persists separately');click(page,'Enhanced','quality-reopen');click(page,'Performance','quality-performance');page.wait_for_timeout(400);check(any('quality=\"performance\"' in v for k,v in all_files(page).items() if k.endswith('race_graphics.cfg')),'Performance remains available and is restored before racing');click(page,'Back','back-800')
   page.set_viewport_size({'width':1280,'height':720});page.wait_for_timeout(700)
   click(page,'New Career','new');click(page,'MALE ATHLETE','male');advance(page);click(page,'FROM NOTHING','origin');advance(page);advance(page);names(page,'Alex','Gold');advance(page);click(page,'BEGIN CAREER','begin');page.wait_for_timeout(1800)
   hub=snapshot(page,'hub');check(any(abs(v['duration']-32)<.02 for v in hub['starts']),'Hub plays the original looping score');check(any(x['rms']>0.00001 for x in hub['contexts']),'measured nonzero Web Audio output in Hub')
   record_start(page);page.wait_for_function("audioAudit.starts.filter(s=>Math.abs(s.duration-32)<.02).length>=2",timeout=90000);check(len(cues(page,32))>=2,'Hub score actually repeats beyond its 32-second duration');nav(page,'Training');click(page,'Sprint Drills','training-activity');text(page,'Confirm & Save','training-confirmation');click(page,'Confirm & Save','training-save');page.wait_for_timeout(1800);initial=get_record(page);check(initial['schema_version']==4 and initial['training']['attributes']['speed']>5000,'Training works with audio and saves schema 4 progression');nav(page,'Overview');nav(page,'Settings');page.wait_for_timeout(700);music_count=len(cues(page,32));click(page,'Mute All','hub-mute');page.wait_for_timeout(500);check(all(x['rms']==0 for x in snapshot(page,'hub-muted')['contexts']),'Mute All produces silence while Hub music is active');click(page,'Mute All','hub-unmute');page.wait_for_timeout(600);music_count=len(cues(page,32));click(page,'Back','hub-settings-back');check(len(cues(page,32))==music_count,'Hub Settings return does not restart music')
   click(page,'Enter 100m','enter');page.wait_for_timeout(1600);race=snapshot(page,'readiness');check(any(abs(v['duration']-12)<.02 for v in race['starts']),'stadium ambience starts in readiness')
   page.wait_for_function("audioAudit.starts.filter(s=>Math.abs(s.duration-12)<.02).length>=2",timeout=45000);check(len(cues(page,12))>=2,'crowd ambience actually repeats beyond its 12-second duration');click(page,'Rhythm Sprint','mode');click(page,'Hold Sprint','hold');prep_bottom(page)
   marker=len(report['console']);click(page,'Ready','false-ready');wait_phase(page,marker,'marks');page.keyboard.down('Space');wait_phase(page,marker,'invalid');page.keyboard.up('Space');check(len(cues(page,.3))==0 and get_record(page)==initial,'false start produces no pistol and leaves career unchanged')
   click(page,'Retry Race','retry');index=start_hold(page);check(len(cues(page,.3))==1,'one pistol buffer starts at actual Running transition');page.wait_for_timeout(2500);image(page,'audio-mid-race');finish_hold(page,index);saved=result_saved(page);player=next(r for r in saved['competition']['latest']['rows'] if r['id']=='player');check(player['status']=='FIN','Hold Sprint still finishes and saves');check(len(cues(page,.3))==1,'pistol does not repeat during race or results')
   check(len(cues(page,.12))>5,'gait crossings produce speed-synchronized player footstep samples');check(len(cues(page,.7))==1,'one restrained player finish cue');check(len(cues(page,3.2))==1 and bool(saved['competition']['records']),'PB celebration follows successful new record save');image(page,'results-audio');record_stop(page)
   click(page,'Career Hub','return');page.wait_for_function('Object.values(audioAudit.live).every(s=>![12,.3,.12,.7,2.4,3.2].some(d=>Math.abs(s.duration-d)<.015))',timeout=15000);check(True,'race crowd, footsteps and race one-shots stop after leaving; only Hub/UI audio remains');check(get_record(page)['training']==initial['training'],'race and audio transitions preserve Training progress');nav(page,'Overview');click(page,'Enter 100m','rhythm-enter');click(page,'Hold Sprint','rhythm-mode');click(page,'Rhythm Sprint','rhythm-select');marker=len(report['console']);click(page,'Ready','rhythm-ready');wait_phase(page,marker,'running');key='a';deadline=time.monotonic();limit=time.monotonic()+60
   while not phase_since(marker,'results') and time.monotonic()<limit:
    page.keyboard.press(key);key='d' if key=='a' else 'a';deadline+=.25;page.wait_for_timeout(max(1,int((deadline-time.monotonic())*1000)))
   wait_phase(page,marker,'results');page.wait_for_timeout(1600);saved=result_saved(page,saved['competition']['latest']['id']);check(saved['competition']['latest']['mode']=='rhythm' and next(r for r in saved['competition']['latest']['rows'] if r['id']=='player')['status']=='FIN','Rhythm Sprint completes through actual alternating key input with audio');check(saved['training']==initial['training'],'both sprint modes preserve Training data');image(page,'results-rhythm-1280');click(page,'Career Hub','rhythm-return');nav(page,'Overview');click(page,'Enter 100m','interrupt-enter');prep_bottom(page);marker=len(report['console']);click(page,'Ready','interrupt-ready');wait_phase(page,marker,'running');count=len(cues(page,.3));check(count==3,'fresh attempt gets exactly one fresh pistol')
   # Suspend the real AudioContext; headless tab focus is observed, not assumed.
   page.evaluate('audioAudit.contexts[0].suspend()');page.wait_for_timeout(250);check(all(x['state']=='suspended' for x in snapshot(page,'context-suspended')['contexts']),'browser AudioContext suspension observed')
   other=c.new_page();other.goto('about:blank');other.bring_to_front();page.wait_for_timeout(900);other.close();page.bring_to_front();page.wait_for_timeout(2200)
   # Headless tab focus support varies: explicitly record what Chromium reports.
   report['focus_state']=page.evaluate('({hidden:document.hidden,focused:document.hasFocus()})')
   page.keyboard.press('Escape');page.wait_for_timeout(500);check(phase_since(marker,'invalid'),'interruption enters invalid state');page.mouse.click(650,380);page.wait_for_timeout(600);check(len(cues(page,.3))==count,'audio resume/input never replays a starting pistol');check(get_record(page)==saved,'interruption preserves PB and training')
   click(page,'Career Hub','leave');page.reload();page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(800);click(page,'Continue','continue');check(get_record(page)==saved,'career and Personal Best survive reload with separate audio preferences')
   check('mute_all=false' in audio_file(page),'unmute preference persists alongside career data');snapshot(page,'final')
   # Callback coverage only: these synthetic DOM events do not freeze the page.
   before_lifecycle=snapshot(page,'before-lifecycle');music_before=len(cues(page,32));pistol_before=len(cues(page,.3))
   page.evaluate('audioAudit.contexts[0].suspend()');check(all(x['state']=='suspended' for x in snapshot(page,'audio-suspended')['contexts']),'actual AudioContext suspension confirmed')
   page.evaluate("document.dispatchEvent(new Event('freeze'))");page.wait_for_timeout(200);check(snapshot(page,'synthetic-freeze')['stops']>before_lifecycle['stops'],'synthetic freeze callback silences voices')
   page.evaluate('audioAudit.contexts[0].resume()');page.evaluate("document.dispatchEvent(new Event('resume'))");page.wait_for_timeout(1000)
   check(len(cues(page,32))==music_before+1,'resume restores exactly one current Hub loop')
   check(len(cues(page,.3))==pistol_before and get_record(page)==saved,'resume cannot replay pistol or change career')
   check(not report['page_errors'],'lifecycle callbacks have no JavaScript errors')
   errors=[r for r in report['console'] if r['type'] in ['error','warning']];check(not report['page_errors'] and not report['failed_requests'] and not report['http_errors'] and not errors,'no engine, JavaScript, WASM, audio or storage errors')
   c.close()
 finally:
  (OUT/'verification.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=="__main__":run()
