from pathlib import Path
from playwright.sync_api import sync_playwright
import json,hashlib,uuid,statistics,time
out=Path('/workspace/work/evolution-evidence')/('anatomy-review-20261110-'+uuid.uuid4().hex[:8]);out.mkdir(parents=True)
report={'date':'2026-11-10','viewport':[1280,900],'renderer':'Chromium SwiftShader WebGL 2 software rendering','customization':{'male':{'height':180,'weight':75,'shoulders':1,'legs':1,'hairstyle':1,'hair_color':0,'skin':2},'female':{'height':180,'weight':75,'shoulders':1,'legs':1,'hairstyle':3,'hair_color':0,'skin':4}},'runs':{}}
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 report['browser']=browser.version
 for phase,port in [('before',8007),('after',8006)]:
  context=browser.new_context(viewport={'width':1280,'height':900});page=context.new_page();errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type in ['error','warning'] else None)
  page.goto(f'http://127.0.0.1:{port}/index.html');page.locator('#loading').wait_for(state='detached',timeout=90000);page.wait_for_timeout(3000)
  shots={}
  for key,view in [('1','front'),('2','side'),('3','three-quarter')]:
   page.keyboard.press(key);page.wait_for_timeout(1400);name=f'{phase}-{view}.png';page.screenshot(path=str(out/name));shots[view]={'file':name,'sha256':hashlib.sha256((out/name).read_bytes()).hexdigest()}
  page.wait_for_timeout(18000);metrics=page.evaluate('window.athleteReviewMetrics');frame=metrics['frame_ms'][-100:]
  report['runs'][phase]={'shots':shots,'errors':errors,'metrics':metrics,'sample_summary':{'n':len(frame),'median_frame_ms':statistics.median(frame),'mean_frame_ms':statistics.mean(frame)}}
  print(phase,report['runs'][phase]['sample_summary'],'models',metrics['models'],'draws',metrics['draw_calls'],'errors',errors,flush=True)
  context.close()
 browser.close()
from PIL import Image,ImageDraw
import numpy as np
report['pixel_changes']={}
for view in ['front','side','three-quarter']:
 before=Image.open(out/f'before-{view}.png').convert('RGB');after=Image.open(out/f'after-{view}.png').convert('RGB')
 report['pixel_changes'][view]=float(np.mean(np.any(np.array(before)!=np.array(after),axis=2)))
 combined=Image.new('RGB',(2560,940),(16,24,32));combined.paste(before,(0,40));combined.paste(after,(1280,40));d=ImageDraw.Draw(combined);d.text((24,14),'BEFORE — initial v0.2.5 geometry',fill=(240,240,240));d.text((1304,14),'AFTER — Anatomy Polish; same camera, light and customization',fill=(225,185,95));combined.save(out/f'comparison-{view}.png')
# Enlargement of actual front render crops; not a replacement render.
for phase in ['before','after']:
 im=Image.open(out/f'{phase}-front.png');im.crop((225,140,520,570)).resize((590,860)).save(out/f'{phase}-upper-body-detail.png')
report['source_sha256']={name:hashlib.sha256(Path(path).read_bytes()).hexdigest() for name,path in {'before':'/workspace/work/evolution-before-project/scripts/customization/procedural_athlete.gd','after':'/workspace/work/evolution-review-project/scripts/customization/procedural_athlete.gd','identical_review_scene':'/workspace/work/evolution-review-project/tests/visual/athlete_showcase.gd'}.items()}
(out/'verification.json').write_text(json.dumps(report,indent=2)+'\n');Path('/workspace/work/evolution-comparison-latest.txt').write_text(str(out));print(out,flush=True)
