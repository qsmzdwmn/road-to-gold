#!/usr/bin/env python3
"""Legacy browser fixture checks in a fresh isolated profile; no production access.
Uses the same --url/--out options as browser_audio_verification.py.
"""
from urllib.parse import urlsplit
import json
from pathlib import Path
import browser_audio_verification as qa


def backups(page):
    return page.evaluate('''async()=>{let out=[];for(const meta of await indexedDB.databases()){const db=await new Promise((a,b)=>{let r=indexedDB.open(meta.name);r.onsuccess=()=>a(r.result);r.onerror=()=>b(r.error)});for(const store of db.objectStoreNames){const s=db.transaction(store,'readonly').objectStore(store),keys=await new Promise(a=>{let r=s.getAllKeys();r.onsuccess=()=>a(r.result)}),values=await new Promise(a=>{let r=s.getAll();r.onsuccess=()=>a(r.result)});keys.forEach((k,i)=>{if(String(k).endsWith('.bak'))out.push(new TextDecoder().decode(values[i].contents))})}db.close()}return out}''')


def fixture(page, data):
    rows=qa.stored(page);qa.check(len(rows)==1,'isolated legacy fixture targets exactly one career slot')
    destination=qa.URL.rsplit('/',1)[0]+'/__legacy_fixture__'
    page.context.route(destination,lambda route:route.fulfill(status=200,content_type='text/html',body='<title>Isolated test fixture</title>'))
    page.goto(destination);page.wait_for_timeout(500)
    page.evaluate('''async arg=>{const [row,content]=arg,db=await new Promise((a,b)=>{let r=indexedDB.open(row.database);r.onsuccess=()=>a(r.result);r.onerror=()=>b(r.error)});await new Promise((a,b)=>{const tx=db.transaction(row.store,'readwrite'),store=tx.objectStore(row.store),r=store.get(row.key);r.onsuccess=()=>{let v=r.result;v.contents=new TextEncoder().encode(content);v.timestamp=new Date(0);store.put(v,row.key)};tx.oncomplete=a;tx.onerror=()=>b(tx.error)});db.close()}''',[rows[0],json.dumps(data)])
    page.goto(qa.URL);page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(700)


def run():
    assert urlsplit(qa.URL).hostname in ['localhost','127.0.0.1'],'Fixtures must use a local test origin'
    try:
        with qa.sync_playwright() as p:
            context=qa.launch(p);page=context.pages[0];qa.boot(page)
            qa.click(page,'New Career','new');qa.click(page,'FEMALE ATHLETE','female');qa.advance(page);qa.click(page,'THE CHOSEN ONE','origin');qa.advance(page);qa.advance(page);qa.names(page,'Legacy','Gold');qa.advance(page);qa.click(page,'BEGIN CAREER','begin');page.wait_for_timeout(1200)
            legacy=qa.get_record(page);legacy.pop('training',None);legacy.pop('competition',None);legacy['schema_version']=2;legacy['career'].pop('athlete_category',None);legacy['career']['origin_id']='the_chosen_one';legacy['career']['age']=20;legacy['career']['athlete']['appearance']['hairstyle']=3
            fixture(page,legacy);original=qa.stored(page)[0]['content'];qa.click(page,'Continue','legacy-continue');qa.click(page,'Enter 100m','legacy-enter');qa.click(page,'Rhythm Sprint','legacy-mode');qa.click(page,'Hold Sprint','legacy-hold')
            page.set_viewport_size({'width':800,'height':600});page.wait_for_timeout(700);qa.image(page,'legacy-readiness-800');qa.check(qa.get_record(page)==legacy,'legacy readiness never infers category or rewrites saved values');qa.prep_bottom(page);qa.click(page,'Choose athlete category','category');qa.click(page,'Female Athlete','female-category');qa.click(page,'Save Category','save-category')
            for _ in range(60):
                selected=qa.get_record(page)
                if selected.get('schema_version')==4 and selected['career'].get('athlete_category')=='female' and original in backups(page):break
                page.wait_for_timeout(250)
            qa.check(selected['schema_version']==4 and selected['career']['athlete_category']=='female' and selected['career']['athlete']['appearance']['hairstyle']==3 and selected['career']['age']==20 and original in backups(page),'explicit category migration preserves appearance/age and original-save backup')
            index=qa.start_hold(page);qa.check(len(qa.cues(page,.3))==1,'legacy migrated athlete receives one actual-GO pistol');qa.finish_hold(page,index);saved=qa.result_saved(page)
            qa.check(saved['training']==selected['training'] and 'female/sprint_100m' in saved['competition']['records'],'female legacy race saves category PB and preserves Training');qa.image(page,'legacy-results-800')
            qa.click(page,'Career Hub','legacy-hub');page.reload();page.locator('#loading').wait_for(state='detached',timeout=60000);page.wait_for_timeout(700);qa.click(page,'Continue','legacy-reload');qa.nav(page,'Records');qa.check(qa.get_record(page)==saved,'legacy migration and PB survive browser reload')
            future=json.loads(json.dumps(saved));future['competition']['version']=99;fixture(page,future);qa.text(page,'Unsupported competition data','future-protected');qa.check(qa.get_record(page)==future,'future competition data remains untouched')
            qa.check(not qa.report['page_errors'] and not qa.report['failed_requests'] and not qa.report['http_errors'] and not [r for r in qa.report['console'] if r['type'] in ['warning','error']],'legacy browser checks have no engine, audio or storage errors');context.close()
    finally:
        (qa.OUT/'verification.json').write_text(json.dumps(qa.report,indent=2)+'\n')

if __name__=='__main__':run()
