#!/usr/bin/env python3
"""Exercise the real original/RU phone with the shipped ASCII addon script."""
import argparse
import json
import os
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def utf8(text):
    return list(text.encode("utf-8"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--russian", type=Path, required=True)
    args = parser.parse_args()
    script = game_payload("phone.js", (ROOT/"addons/alspmc_core/ui/phone.js").read_bytes()).decode("ascii")
    report = {"cases":[], "native_apps":{}, "arma_runtime_tested":False}
    reports = ROOT/"reports"
    reports.mkdir(exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=os.environ.get("CHROMIUM", "/usr/bin/chromium"),args=["--no-sandbox"])
        for variant,path in [("original",args.original),("ru-beta3",args.russian)]:
            page = browser.new_page(viewport={"width":430,"height":900})
            page.set_default_timeout(6000)
            errors=[]
            page.on("pageerror",lambda e: errors.append(str(e)))
            page.set_content(path.read_text(encoding="utf-8-sig"),wait_until="load")
            if variant == "ru-beta3":
                page.evaluate("window.i18n && i18n.set('ru')")
            page.evaluate("window.__requests=[];window.__nativePhone=phone;window.__appsBefore=APPS.length;window.A3API={SendAlert:s=>__requests.push(JSON.parse(s)),RequestTexture:()=>Promise.resolve('')};")
            page.evaluate(script)
            page.evaluate(script)
            assert page.evaluate("APPS.length===__appsBefore+1 && window.phone===__nativePhone")
            assert page.locator('#grid [data-open="alspmc"]').count()==1
            page.evaluate("phone.open('alspmc')")
            state={"licensed":False,"name":[],"canRename":False,"licensePrice":1,"basePrice":1,
                   "cash":10,"bank":10,"clerkNear":False,"bases":[],"hasOwnBase":False,
                   "nearby":[{"key":"h_100_100","town":utf8("Приморск"),"grid":"001001","area":300,"distance":12}],
                   "reply":0,"ok":True}

            def set_state():
                page.evaluate("s=>ALSPMCPhone.set(s)",state)

            def click(op):
                page.locator('[data-alspmc-op="'+op+'"]').click()

            def latest():
                return page.evaluate("__requests.filter(r=>r.a==='alspmc').at(-1)")

            def acknowledge(request,ok=True):
                state.update(reply=request["token"],ok=ok)
                set_state()

            def passed(label):
                report["cases"].append({"variant":variant,"check":label,"passed":True})

            set_state()
            assert page.locator('#alspmc-license').is_disabled()
            assert page.locator('#alspmc-name').is_disabled()
            assert page.locator('[data-alspmc-op="base"]').is_disabled()
            passed("registration, one icon, licence and name prerequisites")
            state["clerkNear"]=True
            set_state()
            click("license")
            assert latest()["op"]=="status"
            click("cancel")
            assert latest()["op"]=="status"
            click("license")
            click("confirm")
            request=latest()
            assert request["op"]=="license" and request["token"]>0 and "price" not in request
            state.update(licensed=True,canRename=True,bank=9)
            acknowledge(request)
            assert page.locator('#alspmc-license').is_hidden()
            passed("licence confirmation, cancellation, namespaced command, server price")

            name="Legacy & Рубеж"
            page.locator('#alspmc-name').fill(name)
            page.evaluate("phone.set({time:'09:23'})")
            set_state()
            assert page.locator('#alspmc-name').input_value()==name
            assert page.locator('#alspmc-name').evaluate("e=>document.activeElement===e")
            click("name")
            request=latest()
            assert request["op"]=="name" and request["name"]==utf8(name)
            assert all(isinstance(b,int) and 0<=b<=255 for b in request["name"])
            state["name"]=utf8(name)
            acknowledge(request)
            page.wait_for_timeout(100)
            assert page.locator('#alspmc-title').inner_text()==name
            assert page.locator('#alspmc-name').input_value()==name
            passed("Cyrillic and English name, UTF8 bytes, focused draft survives refresh, RU translator exclusion")

            click("base")
            click("confirm")
            request=latest()
            assert request["op"]=="base" and request["key"]=="h_100_100" and "price" not in request
            base={"key":"h_100_100","name":utf8(name),"town":utf8("Приморск"),"grid":"001001",
                  "pos":[100,100,0],"price":1,"locked":False,"canSell":True,"near":True}
            state.update(bases=[base],hasOwnBase=True,nearby=[],bank=8)
            acknowledge(request)
            assert page.locator('#alspmc-bases .cargo').inner_text()==name
            assert page.locator('[data-alspmc-op="base"]').count()==0
            passed("base selection, confirmation, name and place rendering")

            for op in ["mark","view","furnish"]:
                click(op)
                assert latest()=={"a":"alspmc","op":op,"key":"h_100_100"}
            click("lock")
            request=latest()
            assert request["op"]=="lock" and request["key"]=="h_100_100"
            base["locked"]=True
            acknowledge(request)
            assert page.locator('[data-alspmc-op="unlock"]').count()==1
            click("unlock")
            request=latest()
            base["locked"]=False
            acknowledge(request)
            passed("mark, view, furnish, lock and unlock route only to PMC handlers")

            base["canSell"]=False
            base["near"]=False
            set_state()
            assert page.locator('[data-alspmc-op="sell"]').count()==0
            assert page.locator('[data-alspmc-op="furnish"]').is_disabled()
            base.update(canSell=True,near=True)
            set_state()
            click("sell")
            assert latest()["op"]=="unlock"
            click("cancel")
            passed("base permissions and sale cancellation")

            # The original phone keeps its entire state and app registry.
            native_ids=page.evaluate("APPS.filter(a=>a.id!=='alspmc').map(a=>a.id)")
            for app_id in native_ids:
                page.evaluate("v=>phone.open(v)",app_id)
            assert not errors,errors
            report["native_apps"][variant]=native_ids
            passed("all original phone apps open without JS exceptions")
            page.evaluate("phone.open('alspmc')")
            set_state()
            page.add_style_tag(content="*,*::before,*::after{animation:none!important;transition:none!important}")
            assert page.locator('#v-alspmc').evaluate("e=>e.scrollWidth<=e.clientWidth+1")
            if variant=="ru-beta3":
                page.locator('#v-alspmc').evaluate("e=>e.scrollTop=0")
                page.screenshot(path=str(reports/'phone-pmc-ru.png'))
            passed("phone-width layout without horizontal overflow")
            page.close()
        browser.close()
    (reports/'phone-ui.json').write_text(json.dumps(report,indent=2)+"\n")
    print(f"Passed {len(report['cases'])} phone browser scenarios and opened all native apps in both variants.")


if __name__=="__main__":
    main()
