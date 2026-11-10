from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw
import json,uuid,hashlib,statistics
out=Path('/workspace/work/athlete-lab-evidence')/('review-20261110-'+uuid.uuid4().hex[:8]);out.mkdir(parents=True)
report={'url':'http://127.0.0.1:8009/index.html','checks':[],'errors':[],'viewport':[1280,900],'renderer':'SwiftShader software WebGL 2','screenshot_hashes':{}}
Path('/workspace/work/athlete-lab-evidence-latest.txt').write_text(str(out))
def check(ok,msg):
 report['checks'].append({'pass':bool(ok),'message':msg});print(('PASS: ' if ok else 'FAIL: ')+msg,flush=True)
 if not ok:raise AssertionError(msg)
def shot(page,name):
 page.screenshot(path=str(out/name));report['screenshot_hashes'][name]=hashlib.sha256((out/name).read_bytes()).hexdigest()
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']);report['browser']=b.version
 page=b.new_page(viewport={'width':1280,'height':900});page.on('pageerror',lambda e:report['errors'].append(str(e)));page.on('console',lambda m:report['errors'].append(m.text) if m.type in ['error','warning'] else None);page.on('requestfailed',lambda r:report['errors'].append(r.url+' '+str(r.failure)))
 page.goto(report['url']);page.wait_for_function('window.athleteReviewMetrics && window.athleteReviewMetrics.appearance',timeout=90000)
 try:
  # Matching camera/light/customization; rotate only the two review instances.
  for key,view in [('1','front'),('2','side'),('3','three-quarter')]:
   page.keyboard.press(key);page.wait_for_timeout(1100);shot(page,'both-'+view+'.png')
   im=Image.open(out/('both-'+view+'.png'));im.crop((190,140,590,880)).save(out/('male-'+view+'.png'));im.crop((690,140,1090,880)).save(out/('female-'+view+'.png'))
  page.wait_for_timeout(4000);metrics=page.evaluate('window.athleteReviewMetrics');report['render_metrics']=metrics
  check([x['bones'] for x in metrics['models']]==[22,22],'both real GLB imports render with humanoid skeletons')
  # Actual before/after under identical lab setup, using untouched original fallback.
  page.keyboard.press('1');page.keyboard.press('f');page.wait_for_timeout(1100);shot(page,'fallback-front.png');page.keyboard.press('f');page.wait_for_timeout(1100)
  before=Image.open(out/'fallback-front.png');after=Image.open(out/'both-front.png');combined=Image.new('RGB',(2560,940),(16,24,32));combined.paste(before,(0,40));combined.paste(after,(1280,40));d=ImageDraw.Draw(combined);d.text((24,12),'ORIGINAL FALLBACK',fill='white');d.text((1304,12),'ISOLATED GLB PROTOTYPE — NOT APPROVED',fill=(220,180,90));combined.save(out/'before-after.png')
  # High-resolution actual canvas captures, same camera/light/aspect, for crop details.
  page.set_viewport_size({'width':2560,'height':1800});page.wait_for_timeout(1400);shot(page,'front-high-resolution.png');im=Image.open(out/'front-high-resolution.png')
  for name,box in {'male-face-hair':(560,280,1000,650),'female-face-hair':(1550,280,1990,650),'male-clothing-seams':(530,590,1020,1250),'female-clothing-seams':(1520,590,2010,1250)}.items():im.crop(box).save(out/(name+'.png'))
  page.set_viewport_size({'width':1280,'height':900});page.wait_for_timeout(700)
  for step in range(1,5):
   page.keyboard.press('h');expected=[(1+step)%4,(3+step)%4];page.wait_for_function('(v)=>window.athleteReviewMetrics.appearance.map(x=>x.hairstyle).join()==v.join()',arg=expected,timeout=15000)
   check(True,'both categories display stored hairstyle IDs '+str(expected));shot(page,'hair-variants-'+str(step)+'.png')
  m=page.evaluate('window.athleteReviewMetrics');generation=[x['mesh_rebuilds'] for x in m['models']]
  for step in range(1,6):
   expected=['171719','533522','d8b56c','934b32','acafb2'][step%5];page.keyboard.press('c');page.wait_for_function('(v)=>window.athleteReviewMetrics.hair_colors.every(x=>x==v)',arg=expected,timeout=15000);m=page.evaluate('window.athleteReviewMetrics')
   check([x['mesh_rebuilds'] for x in m['models']]==generation,'exact hair color '+expected+' on both models, no asset rebuild')
  colors=['f4d4b4','dfb18b','be8b63','996442','70452f','482d23']
  for step in range(1,7):
   expected=[colors[(2+step)%6],colors[(4+step)%6]];page.keyboard.press('s');page.wait_for_function('(v)=>window.athleteReviewMetrics.skin_colors.join()==v.join()',arg=expected,timeout=15000);m=page.evaluate('window.athleteReviewMetrics')
   check([x['mesh_rebuilds'] for x in m['models']]==generation,'exact skin palette '+str(expected)+' on both models, no asset rebuild')
  check(not report['errors'],'no recorded Godot/JavaScript/WebAssembly/network errors or warnings')
 finally:
  (out/'verification.json').write_text(json.dumps(report,indent=2)+'\n');b.close();print(out,flush=True)
