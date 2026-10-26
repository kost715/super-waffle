#!/usr/bin/env python3
"""Exercise native buttons using states emitted by the unmodified phonePush.

The SQF fixture checks the raw native dispatch/RPC path separately. Arma's CEF
event engine and network transport are not available in this browser test.
"""
import argparse
import json
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--original",type=Path,required=True)
    p.add_argument("--russian",type=Path,required=True)
    p.add_argument("--states-original",type=Path,required=True)
    p.add_argument("--states-russian",type=Path,required=True)
    args = p.parse_args()
    script = game_payload("phone.js",(ROOT/"addons/alspmc_core/ui/phone.js").read_bytes()).decode("ascii")
    checks = []
    with sync_playwright() as play:
        browser = play.chromium.launch(executable_path="/usr/bin/chromium",args=["--no-sandbox"])
        for variant,html,states in [("original",args.original,args.states_original),("ru-beta3",args.russian,args.states_russian)]:
            before,after,active,contract = json.loads(states.read_text())
            page = browser.new_page(viewport={"width":430,"height":900},user_agent="Arma 3 integration fixture")
            page.set_default_timeout(5000)
            errors = []
            page.on("pageerror",lambda e:errors.append(str(e)))
            # Define A3API before loading the page: the native preview is off.
            page.evaluate("window.__requests=[];window.A3API={SendAlert:s=>__requests.push(JSON.parse(s)),RequestTexture:()=>Promise.resolve('')}")
            page.set_content(html.read_text(encoding="utf-8-sig"),wait_until="load")
            if variant == "ru-beta3":
                page.evaluate("window.i18n && i18n.set('ru')")
            assert page.evaluate("IN_ARMA && __requests.some(r=>r.a==='ready')")
            page.evaluate("window.__nativePhone=phone;window.__nativeApps=APPS.slice()")
            page.evaluate(script)
            assert page.evaluate("phone===__nativePhone && __nativeApps.every((a,i)=>APPS[i]===a)")

            def push(state):
                page.evaluate("s=>phone.set(s)",state)

            def open_app(app):
                page.evaluate("v=>phone.open(v)",app)

            def latest():
                return page.evaluate("__requests.at(-1)")

            def passed(label):
                checks.append({"variant":variant,"check":label,"passed":True})

            push(before)
            open_app("work")
            b = page.locator('[data-accept="42"]')
            assert b.is_enabled()
            b.click()
            assert latest()=={"a":"accept","id":42}
            assert b.is_disabled()
            push(after)
            assert page.locator('[data-accept="42"]').count()==0
            page.locator('[data-worktab="now"]').click()
            assert page.locator('[data-cancel="job:42"]').count()==1
            passed("work accept sends native command and updated job replaces the busy button")

            open_app("market")
            page.locator('[data-mark="Kavala"]').click()
            assert latest()=={"a":"mark","town":"Kavala"}
            page.locator('[data-tab="prices"]').click()
            assert page.locator('#marketBody .pr').count()>=2
            page.locator('[data-mark="Kavala"]').click()
            assert latest()=={"a":"mark","town":"Kavala"}
            passed("market routes, price tab and native map commands remain active")

            push(before)
            open_app("garage")
            b = page.locator('[data-veh="insure"][data-id="veh-1"]')
            b.click()
            assert latest()=={"a":"veh","what":"insure","id":"veh-1","arg":""}
            assert b.is_disabled()
            push(after)
            assert page.locator('[data-veh="insure"][data-id="veh-1"]').count()==0
            assert page.locator('[data-veh="uninsure"][data-id="veh-1"]').is_enabled()
            passed("garage insurance sends native command and state refresh clears loading")

            push(before)
            open_app("legacy")
            assert page.evaluate("__requests.slice(-2).some(r=>r.a==='legacy')")
            assert page.locator('#legacyBody .card').count()==1
            push(after)
            assert page.locator('#legacyBody .card').count()==4
            passed("legacy publication request and returned progress replace the loading screen")

            push(before)
            open_app("markets")
            b = page.locator('[data-spec="buy"][data-g="electronics"]')
            b.click()
            assert latest()=={"a":"spec","what":"buy","good":"electronics","n":10}
            assert b.is_disabled()
            push(after)
            assert page.locator('[data-spec="buy"][data-g="electronics"]').is_enabled()
            assert page.evaluate("S.spec[0][3]")==10
            passed("speculation purchase and native portfolio refresh clear loading")

            push(before)
            open_app("rivals")
            assert page.locator('#rivalsBody .riv').count()==1
            assert "Kavala Haulage" in page.locator('#rivalsBody').inner_text()
            page.locator('[data-rmark="r1"]').click()
            assert latest()=={"a":"rivalMark","id":"r1"}
            b=page.locator('[data-rhire="r1:tyres"]')
            b.click(); b.click()
            assert latest()=={"a":"rivalHire","id":"r1","job":"tyres"}
            assert b.is_disabled()
            passed("populated rivals and feed render; map and confirmed hire retain native commands")
            # Reproduce the original native renderer failure with damaged rows.
            assert page.evaluate("""() => {
                const old=S.rivals; S.rivals=[null]; lastRivalsKey='';
                try { renderRivals(); return false; } catch (_) { return true; }
                finally { S.rivals=old; }
            }""")
            corrupt={**before,"rivals":[None,before["rivals"][0],list(before["rivals"][0].items())],"rivalFeed":[None,before["rivalFeed"][0],42]}
            push(corrupt)
            open_app("rivals")
            assert page.locator('#rivalsBody .riv').count()==2
            assert page.evaluate("S.rivals[0]===null && S.rivalFeed[0]===null")
            page.locator('[data-rmark="r1"]').first.click()
            assert latest()=={"a":"rivalMark","id":"r1"}
            push(after)
            assert page.locator('#rivalsBody .riv').count()==1
            assert not errors,errors
            passed("damaged/old rival rows no longer abort rendering, native state is preserved and a new push recovers")

            # Native pushes must continue after visiting the PMC app too.
            open_app("alspmc")
            push(after)
            open_app("garage")
            assert page.locator('[data-veh="uninsure"][data-id="veh-1"]').is_enabled()
            for app in page.evaluate("__nativeApps.map(a=>a.id)"):
                open_app(app)
            assert not errors,errors
            passed("all native apps still render after PMC and a subsequent native state push")
            push(active)
            assert page.evaluate("S.crew.job.alspmc===true && S.crew.job.progText==='0 / 1'")
            open_app("crew")
            assert "PMC: eliminate one target" in page.locator('#v-crew').inner_text()
            for app in ["work", "market", "garage", "legacy", "markets"]:
                open_app(app)
            open_app("garage")
            assert page.locator('[data-veh="uninsure"][data-id="veh-1"]').is_enabled()
            assert not errors, errors
            passed("native crew shows actual scenario mirror and other apps render with a PMC contract active")
            push(contract)
            assert page.evaluate("S.crew.job.alspmcContract===true")
            open_app("crew")
            assert "PMC:" in page.locator('#v-crew').inner_text()
            for app in ["work","market","garage","legacy","markets"]:
                open_app(app)
            open_app("garage")
            assert page.locator('[data-veh="uninsure"][data-id="veh-1"]').is_enabled()
            assert not errors,errors
            passed("new owner-paid contract mirror preserves native crew and all five original action apps")
            page.close()
        browser.close()
    report={"checks":checks,"passed":len(checks),"arma_runtime_tested":False,"native_preview_used":False}
    (ROOT/"reports/native-phone-ui.json").write_text(json.dumps(report,indent=2)+"\n")
    print(f"Passed {len(checks)} native phone action/refresh scenarios without browser preview data.")


if __name__=="__main__":
    main()
