from playwright.sync_api import sync_playwright
from pathlib import Path
import json,time
import uuid
out=Path('/workspace/work/new-generation-evidence')/('corrected-20261110-'+uuid.uuid4().hex[:8]);out.mkdir(parents=True)
Path('/workspace/work/new-generation-captures-latest.txt').write_text(str(out))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=b.new_page(viewport={'width':1280,'height':900});errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type in ['error','warning'] else None)
 page.goto('http://127.0.0.1:8008/index.html');page.locator('#loading').wait_for(state='detached',timeout=90000);page.wait_for_timeout(2500)
 for key,name in [('1','front'),('2','side'),('3','three-quarter')]:
  page.keyboard.press(key);page.wait_for_timeout(1000);page.screenshot(path=str(out/f'after-{name}.png'))
 page.wait_for_timeout(5000)
 metrics=page.evaluate('window.athleteReviewMetrics');(out/'metrics.json').write_text(json.dumps({'metrics':metrics,'errors':errors},indent=2));print(json.dumps({'metrics':metrics,'errors':errors})[:1600],flush=True)
 page.set_viewport_size({'width':2560,'height':1800});page.keyboard.press('1');page.wait_for_timeout(1500);page.screenshot(path=str(out/'front-high-resolution.png'))
 from PIL import Image
 im=Image.open(out/'front-high-resolution.png')
 im.crop((560,270,1000,650)).save(out/'male-face-hair-detail.png')
 im.crop((1550,270,1990,650)).save(out/'female-face-hair-detail.png')
 im.crop((530,590,1020,1250)).save(out/'male-clothing-seams-detail.png')
 im.crop((1520,590,2010,1250)).save(out/'female-clothing-seams-detail.png')
 b.close()
