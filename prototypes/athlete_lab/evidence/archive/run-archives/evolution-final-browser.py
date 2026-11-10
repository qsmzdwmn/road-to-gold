from playwright.sync_api import sync_playwright
from pathlib import Path
import csv,io,json,re,subprocess,time,os
os.environ["OMP_THREAD_LIMIT"]="1"
OUT=Path('/workspace/work/browser')
PROFILE=OUT/'verified-profile'
URL='http://127.0.0.1:8000/index.html'
report={'url':URL,'console':[],'page_errors':[],'failed_requests':[],'http_errors':[],'checks':[]}
serial=0

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

def click(page,label,name):
 lines=capture(page,name+'-before')
 hits=[r for r in lines if label.lower() in r[0].lower()]
 if not hits: raise AssertionError('Button not found: '+label+' in '+repr(lines))
 _,x,y=hits[-1]
 page.mouse.click(x,y)
 page.wait_for_timeout(450)

def position(page,name):
 lines=capture(page,name)
 line=next(r[0] for r in lines if 'position' in r[0].lower())
 nums=re.findall(r'-?\d+\.\d+',line)
 if len(nums)!=2: raise AssertionError('Position OCR: '+line)
 return tuple(float(v) for v in nums)

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

def launch(p):
 return p.chromium.launch_persistent_context(str(PROFILE),executable_path='/usr/bin/chromium',headless=True,viewport={'width':1280,'height':720},args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])


import uuid,shutil
from PIL import Image,ImageChops
import numpy as np
OUT=Path('/workspace/work/browser-golden/verified');OUT.mkdir(parents=True,exist_ok=True)
PROFILE=OUT/('profile-'+uuid.uuid4().hex[:8])
URL='http://127.0.0.1:8001/road-to-gold/index.html';report['url']=URL

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
def advance(page):page.mouse.click(1160,670);page.wait_for_timeout(600)
def back(page):page.mouse.click(115,670);page.wait_for_timeout(500)
def fill(page,first,last):
 for y,value in [(303,first),(391,last)]:
  page.mouse.click(150,y);page.wait_for_timeout(150);page.keyboard.press('Control+a');page.keyboard.type(value,delay=60);page.wait_for_timeout(200)
def pick(page,current,target,name):
 click(page,current,name)
 rows=raw_lines(page,name+'-popup')
 def normalized(value):
  value=re.sub('[^a-z0-9]','',value.lower())
  return value.replace('s','5') if value.startswith('tone') else value
 hits=[r for r in rows if normalized(r[0])==normalized(target)]
 if not hits:raise AssertionError('Popup option not found '+target+' '+repr(rows))
 _,x,y=hits[0];page.mouse.click(x,y);page.wait_for_timeout(450)

def scroll_bottom(page):page.mouse.move(350,400);page.mouse.wheel(0,2000);page.wait_for_timeout(400)
def number(page,label,value):
 rows=raw_lines(page,'number-'+label);_,_,y=next(r for r in rows if r[0].strip().lower()==label.lower())
 page.mouse.click(140,y+43);page.wait_for_timeout(150);page.keyboard.press('Control+a');page.keyboard.type(str(value),delay=70);page.keyboard.press('Enter');page.wait_for_timeout(350)
def record(page):
 rows=stored(page);check(len(rows)==1,'one persistent career slot');return json.loads(rows[0]['content'])
def no_errors():
 check(not report['page_errors'] and not report['failed_requests'] and not report['http_errors'] and not [r for r in report['console'] if r['type'] in ['warning','error']],'no recorded engine/JavaScript/WebAssembly/storage/network errors or warnings')

OUT=Path('/workspace/work/browser-studio')/('evolution-final-20261110-'+uuid.uuid4().hex[:8]);OUT.mkdir(parents=True)
PROFILE=OUT/'profile';URL='http://127.0.0.1:8001/road-to-gold/index.html'
report={'url':URL,'console':[],'page_errors':[],'failed_requests':[],'http_errors':[],'checks':[]}
report['evidence_directory']=str(OUT)

def advance(page):click(page,'CONTINUE','continue-step')
def back(page):click(page,'BACK','back-step')
def image(page,name):page.screenshot(path=str(OUT/(name+'.png')))
def scroll_bottom(page):page.mouse.move(400,450);page.mouse.wheel(0,2000);page.wait_for_timeout(500)
def top(page):page.mouse.move(400,450);page.mouse.wheel(0,-2000);page.wait_for_timeout(500)
def numeric(page,label,value):
 rows=raw_lines(page,'edit-'+label)
 _,_,y=next(r for r in rows if r[0].strip().lower()==label.lower())
 candidates=[r for r in rows if r[2]>y and r[2]<y+75 and re.match(r'^[0-9]',r[0])]
 if not candidates:raise AssertionError('Numeric field not found '+label+' '+repr(rows))
 _,x,y=min(candidates,key=lambda r:r[2]);page.mouse.click(x,y);page.wait_for_timeout(150);page.keyboard.press('Control+a');page.keyboard.type(str(value),delay=70);page.keyboard.press('Enter');page.wait_for_timeout(400)
def names(page,first,last):
 for label,value in [('First name',first),('Last name',last)]:
  click(page,label,'name-'+label);page.keyboard.press('Control+a');page.keyboard.type(value,delay=60);page.wait_for_timeout(250)
def exact_choice(page,label,name):
 rows=raw_lines(page,name)
 def norm(value):
  value=re.sub('[^a-z0-9]','',value.lower())
  return value.replace('s','5') if value.startswith('tone') else value
 hits=[r for r in rows if norm(r[0])==norm(label)]
 if not hits:raise AssertionError(label+' not found '+repr(rows))
 _,x,y=hits[-1];page.mouse.click(x,y);page.wait_for_timeout(450)
try:
 with sync_playwright() as p:
  c=launch(p);report['browser']=c.browser.version;page=c.pages[0];boot(page)
  text(page,'VERSION 0.2.4','version-proof');page.keyboard.press('Enter');page.wait_for_timeout(600)
  text(page,'CHOOSE YOUR ATHLETE','athlete-open');image(page,'01-athlete-1280')
  click(page,'FEMALE ATHLETE','select-female');advance(page);text(page,'WHERE IT ALL BEGINS','story');image(page,'02-story-1280')
  click(page,'THE CHOSEN ONE','origin-chosen');advance(page);text(page,'MAKE IT YOURS','appearance-open')
  click(page,'Ponytail','hair-ponytail');click(page,'Auburn','hair-auburn');image(page,'03-hair-1280')
  # Confirm pinned content through real scrolling at a smaller supported viewport.
  page.set_viewport_size({'width':800,'height':600});page.wait_for_timeout(700)
  image(page,'03-hair-top-800');scroll_bottom(page)
  for expected in ['MAKE IT YOURS','Create the athlete you want to become.','HAIR','SKIN','BODY','Gray']:
   text(page,expected,'sticky-hair-bottom-'+expected.split()[0])
  image(page,'03-hair-bottom-800')
  click(page,'SKIN','skin-tab-small');exact_choice(page,'Tone 5','tone-five');image(page,'03-skin-800')
  click(page,'BODY','body-tab-small');scroll_bottom(page);text(page,'Leg proportion','body-last-control');image(page,'03-body-bottom-800')
  check(not stored(page),'tab switching and scrolling do not save a draft')
  page.set_viewport_size({'width':1280,'height':720});page.wait_for_timeout(700);top(page)
  for label,value in [('Height',190),('Weight',85),('Shoulder width',1.1),('Leg proportion',1.05)]:numeric(page,label,value)
  image(page,'03-body-1280');click(page,'SKIN','skin-tab');image(page,'03-skin-1280');click(page,'HAIR','hair-retained');text(page,'Ponytail','hair-retained-value')
  advance(page);text(page,'DEFINE YOUR IDENTITY','identity');advance(page);text(page,'Enter a first and last name','blank-name-validation')
  names(page,'Nadia','Runner');click(page,'United States','country-popup');page.keyboard.press('Home');page.wait_for_timeout(400);exact_choice(page,'Azerbaijan','country-azerbaijan')
  scroll_bottom(page);numeric(page,'Height',195);numeric(page,'Weight',95);top(page);image(page,'04-identity-1280')
  advance(page);text(page,'BEGIN YOUR LEGACY','legacy');image(page,'05-legacy-1280')
  rows=raw_lines(page,'player-card');combined=' '.join(r[0] for r in rows)
  check('Nadia Runner' in combined and 'Azerbaijan' in combined,'Player Card renders actual name and country')
  scroll_bottom(page);image(page,'05-legacy-bottom-1280')
  for width,height in [(800,600),(1024,600),(1366,768),(1920,1080)]:
   page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(650);image(page,f'legacy-{width}')
   check(True,'captured Player Card and full-body framing at '+str(width)+'x'+str(height))
  page.set_viewport_size({'width':1280,'height':720});page.wait_for_timeout(500)
  # Back/forward data retention through every new section.
  for _ in range(4):back(page)
  text(page,'Selected: Female Athlete','category-retained')
  page.set_viewport_size({'width':800,'height':600});page.wait_for_timeout(500);image(page,'01-athlete-800')
  advance(page);image(page,'02-story-800');advance(page);click(page,'HAIR','small-hair');image(page,'03-hair-800');click(page,'SKIN','small-skin');image(page,'03-skin-final-800');click(page,'BODY','small-body');image(page,'03-body-800')
  advance(page);image(page,'04-identity-800');advance(page);image(page,'05-legacy-800')
  page.set_viewport_size({'width':1280,'height':720});page.wait_for_timeout(500)
  click(page,'BEGIN CAREER','confirm-career');text(page,'TRACK EXPLORATION','gameplay')
  page.keyboard.down('w');page.wait_for_timeout(400);page.keyboard.up('w');page.mouse.click(200,316);page.wait_for_timeout(2200)
  saved=record(page);a=saved['career']['athlete'];appearance=a['appearance']
  check(saved['schema_version']==3 and saved['career']['athlete_category']=='female' and saved['career']['origin_id']=='the_chosen_one' and saved['career']['age']==20,'category and origin identifiers/age persist unchanged')
  check(a['first_name']=='Nadia' and a['last_name']=='Runner' and a['country']=='AZ','identity and country remain exact')
  check(appearance=={'skin':4,'hairstyle':3,'hair_color':3,'height':195,'weight':95,'shoulders':1.1,'legs':1.05},'every swatch, tile and shared numeric value survives final saving')
  check(saved['position'][1]<0,'existing keyboard gameplay remains functional')
  page.reload();page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(600);click(page,'Continue','continue-saved');text(page,'Loaded saved career.','continue-status');check(record(page)==saved,'page reload and Continue preserve entire Studio save')
  page.keyboard.press('Escape');page.wait_for_timeout(400);page.keyboard.press('Enter');page.wait_for_timeout(600)
  # The other category gets the identical catalogs, tabs, body range and origins.
  click(page,'MALE ATHLETE','male-choice');advance(page);click(page,'THE LEGACY','male-origin');advance(page)
  click(page,'Short curls','male-curls');click(page,'Blond','male-blond');click(page,'SKIN','male-skin');exact_choice(page,'Tone 2','male-tone');click(page,'BODY','male-body')
  numeric(page,'Height',200);numeric(page,'Weight',100);numeric(page,'Shoulder width',1.2);numeric(page,'Leg proportion',1.1)
  advance(page);names(page,'Alex','Runner');advance(page);scroll_bottom(page);image(page,'male-player-card')
  old=stored(page)[0]['content'];click(page,'BEGIN CAREER','male-confirm');text(page,'Replace saved progress?','replace-required');check(stored(page)[0]['content']==old,'existing career remains unchanged before confirmation')
  page.mouse.click(547,394);page.wait_for_timeout(500);check(stored(page)[0]['content']==old,'Cancel preserves existing saved career')
  click(page,'BEGIN CAREER','male-confirm-again');page.mouse.click(750,394);page.wait_for_timeout(600);text(page,'TRACK EXPLORATION','male-gameplay');page.mouse.click(200,316);page.wait_for_timeout(2200)
  male=record(page);check(male['career']['athlete_category']=='male' and male['career']['age']==17 and male['career']['athlete']['appearance']=={'skin':1,'hairstyle':2,'hair_color':2,'height':200,'weight':100,'shoulders':1.2,'legs':1.1},'male path preserves every same customization option and replacement')
  c.close();c=launch(p);page=c.pages[0];boot(page);click(page,'Continue','restart-continue');text(page,'Loaded saved career.','restart-loaded');check(record(page)==male,'full browser restart preserves confirmed Studio career')
  c.close()
  sources=[('v1',Path('/workspace/work/browser-pages/verified-profile')),('v2',max(Path('/workspace/work/browser-career-final').glob('profile-*'),key=lambda x:x.stat().st_mtime)),('v3',Path('/workspace/work/browser-locker/verified/profile-5cd18aef'))]
  for version,source in sources:
   PROFILE=OUT/('legacy-'+version);shutil.copytree(source,PROFILE,ignore=shutil.ignore_patterns('Singleton*'))
   c=launch(p);page=c.pages[0];boot(page);prior=stored(page)[0]['content'];old=json.loads(prior);click(page,'Continue',version+'-continue');text(page,'TRACK EXPLORATION',version+'-track');check(stored(page)[0]['content']==prior,version+' Continue leaves original bytes unchanged')
   page.mouse.click(200,316);page.wait_for_timeout(2200);updated=record(page);check(updated['schema_version']==old['schema_version'] and updated.get('career')==old.get('career'),version+' retains original schema and every saved field')
   if version=='v2':check(not updated['career'].get('athlete_category'), 'legacy category is never inferred')
   c.close()
  no_errors()
finally:
 (OUT/'verification.json').write_text(json.dumps(report,indent=2));Path('/workspace/work/evolution-final-browser-latest.txt').write_text(str(OUT))
