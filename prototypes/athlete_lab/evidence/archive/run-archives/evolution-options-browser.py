from pathlib import Path
from playwright.sync_api import sync_playwright
import json,uuid
out=Path('/workspace/work/evolution-evidence')/('options-20261110-'+uuid.uuid4().hex[:8]);out.mkdir(parents=True);report={'checks':[],'errors':[]}
def check(value,msg):
 report['checks'].append({'pass':bool(value),'message':msg});print(('PASS: ' if value else 'FAIL: ')+msg,flush=True)
 if not value:raise AssertionError(msg)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']);report['browser']=b.version;page=b.new_page(viewport={'width':1280,'height':900})
 page.on('pageerror',lambda e:report['errors'].append(str(e)));page.on('console',lambda m:report['errors'].append(m.text) if m.type in ['error','warning'] else None)
 page.goto('http://127.0.0.1:8006/index.html');page.locator('#loading').wait_for(state='detached',timeout=90000);page.wait_for_function('window.athleteReviewMetrics && window.athleteReviewMetrics.appearance')
 try:
  for step in range(1,5):
   page.keyboard.press('h');expected=[(1+step)%4,(3+step)%4];page.wait_for_function('(v)=>window.athleteReviewMetrics.appearance.map(x=>x.hairstyle).join()==v.join()',arg=expected,timeout=15000)
   m=page.evaluate('window.athleteReviewMetrics');check([x['hairstyle'] for x in m['appearance']]==expected,'both categories render hairstyle identifiers '+str(expected));page.screenshot(path=str(out/f'hairstyles-{step}.png'))
  generation=[x['mesh_rebuilds'] for x in m['models']]
  colors=['171719','533522','d8b56c','934b32','acafb2']
  for step in range(1,6):
   page.keyboard.press('c');expected=colors[step%5];page.wait_for_function('(v)=>window.athleteReviewMetrics.hair_colors.every(x=>x==v)',arg=expected,timeout=15000)
   m=page.evaluate('window.athleteReviewMetrics');check(m['hair_colors']==[expected]*2 and [x['mesh_rebuilds'] for x in m['models']]==generation,'both hair materials match '+expected+' without rebuilding');page.screenshot(path=str(out/f'hair-color-{step%5}.png'))
  colors=['f4d4b4','dfb18b','be8b63','996442','70452f','482d23']
  for step in range(1,7):
   page.keyboard.press('s');expected=[colors[(2+step)%6],colors[(4+step)%6]];page.wait_for_function('(v)=>window.athleteReviewMetrics.skin_colors.join()==v.join()',arg=expected,timeout=15000)
   m=page.evaluate('window.athleteReviewMetrics');check(m['skin_colors']==expected and [x['mesh_rebuilds'] for x in m['models']]==generation,'both skin materials match '+str(expected)+' without rebuilding');page.screenshot(path=str(out/f'skin-tones-{step}.png'))
  check(not report['errors'],'no recorded runtime/JavaScript/WebAssembly errors or warnings')
 finally:
  (out/'verification.json').write_text(json.dumps(report,indent=2));Path('/workspace/work/evolution-options-latest.txt').write_text(str(out));b.close()
