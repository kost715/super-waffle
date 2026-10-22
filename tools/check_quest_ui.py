#!/usr/bin/env python3
"""Quest protocol/state checks in both native phone variants and the desktop.

The server snapshots and RPC delivery are fixtures. Uses the exact ASCII JS
payload shipped in the PBO; no browser demo data or Arma engine is involved.
"""
import argparse
import json
import os
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--russian", type=Path, required=True)
    args = parser.parse_args()
    (ROOT / "reports").mkdir(exist_ok=True)
    script = game_payload("phone.js", (ROOT / "addons/alspmc_core/ui/phone.js").read_bytes()).decode("ascii")
    results = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=os.environ.get("CHROMIUM", "/usr/bin/chromium"), args=["--no-sandbox"])
        for variant, path in [("original", args.original), ("ru-beta3", args.russian),
                              ("desktop", ROOT / "addons/alspmc_core/ui/desktop.html")]:
            desktop = variant == "desktop"
            page = browser.new_page(viewport={"width":1280 if desktop else 430, "height":800 if desktop else 900})
            page.set_default_timeout(5000)
            errors = []
            page.on("pageerror", lambda e: errors.append(str(e)))
            page.evaluate("window.__requests=[];window.A3API={SendAlert:s=>__requests.push(JSON.parse(s)),RequestTexture:()=>Promise.resolve('')}")
            page.set_content(path.read_text(encoding="utf-8-sig"), wait_until="load")
            if variant == "ru-beta3":
                page.evaluate("window.i18n && i18n.set('ru')")
            page.evaluate(script)
            page.evaluate("ALSPMCDesktop.start()" if desktop else "phone.open('alspmc')")
            if desktop:
                page.locator('nav [data-section="quests"]').click()

            quest = {"ready":True, "canStart":False, "reason":"license", "pay":1000, "active":{}, "history":[]}
            state = {"licensed":False, "name":[], "canRename":False, "licensePrice":1, "basePrice":1,
                     "cash":0, "bank":0, "bases":[], "nearby":[], "hasOwnBase":False,
                     "clerkNear":False, "reply":0, "ok":True, "quests":quest}

            def update():
                page.evaluate("s=>ALSPMCPhone.set(s)", state)

            def click(op):
                page.locator(f'[data-alspmc-op="{op}"]').click()

            def tab(name):
                page.locator(f'[data-alspmc-op="questTab"][data-alspmc-key="{name}"]').click()

            def latest():
                return page.evaluate("__requests.filter(r=>r.a==='alspmc').at(-1)")

            def ack(request):
                state.update(reply=request["token"], ok=True)
                update()

            def passed(label):
                results.append({"variant":variant, "check":label, "passed":True})

            update()
            if desktop:
                assert page.locator('#alspmc-section-quests').is_visible()
                assert page.locator('#alspmc-section-base').is_hidden()
            assert page.locator('[data-alspmc-op="questStart"]').is_disabled()
            assert "лицензию" in page.locator('#alspmc-quests').inner_text()
            quest.update(reason="base")
            update()
            assert page.locator('[data-alspmc-op="questStart"]').is_disabled()
            assert "база" in page.locator('#alspmc-quests').inner_text()
            passed("server prerequisites disable start and explain the missing licence/base")

            state.update(licensed=True, canRename=True, hasOwnBase=True)
            quest.update(canStart=True, reason="")
            update()
            before = latest()
            click("questStart")
            assert latest() == before
            assert "1000" in page.locator('#alspmc-confirm-text').inner_text().replace("\xa0", "").replace(" ", "")
            click("cancel")
            assert latest() == before
            passed("start requires confirmation; dismissing it sends no command")

            click("questStart")
            click("confirm")
            request = latest()
            assert set(request) == {"a", "op", "token", "key"}
            assert request["op"] == "questStart" and request["key"] == "eliminate" and request["token"] > 0
            assert page.locator('[data-alspmc-op="questStart"]').is_disabled()
            active = {"id":"q42", "status":"active", "pay":1000, "grid":"123045", "teamSize":2,
                      "canCancel":True, "canMap":True, "left":1771, "pos":[12300,4500,0]}
            quest.update(canStart=False, reason="active", active=active)
            ack(request)
            assert "q42" in page.locator('#alspmc-quests').inner_text()
            assert "123045" in page.locator('#alspmc-quests').inner_text()
            assert "29:31" in page.locator('#alspmc-quests').inner_text()
            passed("start sends only contract key/token and acknowledgement opens active instance")

            click("questMap")
            assert latest() == {"a":"alspmc", "op":"questMap", "key":"q42"}
            active.update(canCancel=False)
            update()
            assert page.locator('[data-alspmc-op="questCancel"]').count() == 0
            active.update(canCancel=True)
            update()
            click("questCancel")
            assert "без выплаты" in page.locator('#alspmc-confirm-text').inner_text()
            click("cancel")
            assert latest()["op"] == "questMap"
            passed("map uses local protocol; only authorized leader sees cancel and confirmation")

            click("questCancel")
            click("confirm")
            request = latest()
            assert request["op"] == "questCancel" and request["key"] == "q42"
            quest.update(canStart=True, reason="", active={}, history=[
                {"id":"q42", "status":"cancelled", "reason":"cancelled", "pay":1000, "teamSize":2}])
            ack(request)
            assert "Отменён" in page.locator('#alspmc-quests').inner_text()
            assert "Выплаты нет" in page.locator('#alspmc-quests').inner_text()
            tab("available")
            assert page.locator('[data-alspmc-op="questStart"]').is_enabled()
            passed("cancel uses stable instance ID, shows history and enables a new attempt")

            quest["history"] = [
                {"id":"q43", "status":"done", "reason":"killed", "pay":1000, "teamSize":2},
                {"id":"q42", "status":"interrupted", "reason":"restart", "pay":1000, "teamSize":1},
                {"id":"q41", "status":"failed", "reason":"outsider", "pay":1000, "teamSize":1}]
            update()
            tab("history")
            content = page.locator('#alspmc-quests').inner_text()
            assert all(text in content for text in ["Выполнен", "Прерван", "Прерван перезапуском", "без зачёта"])
            assert page.locator('#alspmc-quests .alspmc-site').count() == 3
            assert not errors, errors
            assert page.locator('#v-alspmc').evaluate("e=>e.scrollWidth<=e.clientWidth+1")
            passed("success, restart and outsider results stay readable without JS errors or overflow")
            page.screenshot(path=str(ROOT / "reports" / f"quests-{variant}.png"))
            page.close()
        browser.close()
    (ROOT / "reports/quest-ui.json").write_text(json.dumps({"cases":results, "arma_runtime_tested":False}, indent=2)+"\n")
    print(f"Passed {len(results)} quest browser scenarios across both native phones and desktop.")


if __name__ == "__main__":
    main()
