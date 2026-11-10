from playwright.sync_api import sync_playwright
from pathlib import Path
import json,time
out=Path('/workspace/work/evolution-evidence');out.mkdir(exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=b.new_page(viewport={'width':1280,'height':900});errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type in ['error','warning'] else None)
 page.goto('http://127.0.0.1:8006/index.html');page.locator('#loading').wait_for(state='detached',timeout=90000);page.wait_for_timeout(2500)
 for key,name in [('1','front'),('2','side'),('3','three-quarter')]:
  page.keyboard.press(key);page.wait_for_timeout(1000);page.screenshot(path=str(out/f'after-{name}.png'))
 page.wait_for_timeout(5000)
 metrics=page.evaluate('window.athleteReviewMetrics');(out/'metrics.json').write_text(json.dumps({'metrics':metrics,'errors':errors},indent=2));print(json.dumps({'metrics':metrics,'errors':errors})[:1600],flush=True)
 b.close()
