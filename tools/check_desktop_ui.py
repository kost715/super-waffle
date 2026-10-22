#!/usr/bin/env python3
"""Exercise desktop HTML using the exact shared ASCII script shipped in PBO."""
import json
import os
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def utf8(text):
    return list(text.encode("utf-8"))


def main():
    addon = ROOT/"addons/alspmc_core"
    script = game_payload("phone.js", (addon/"ui/phone.js").read_bytes()).decode("ascii")
    reports = ROOT/"reports"
    reports.mkdir(exist_ok=True)
    checks = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=os.environ.get("CHROMIUM", "/usr/bin/chromium"), args=["--no-sandbox"])
        page = browser.new_page(viewport={"width":1280,"height":800})
        page.set_default_timeout(5000)
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.evaluate("window.__requests=[];window.A3API={SendAlert:s=>__requests.push(JSON.parse(s))}")
        page.set_content((addon/"ui/desktop.html").read_text(),wait_until="load")
        assert page.evaluate("__requests.at(-1)") == {"a":"alspmcDesktop","op":"ready"}
        page.evaluate(script + ";ALSPMCDesktop.start();")
        page.evaluate(script)
        assert page.locator('#alspmc-body').count() == 1
        assert page.locator('#alspmc-loading').is_visible()
        assert page.evaluate("__requests.at(-1)") == {"a":"alspmc","op":"status","token":0}
        checks.append("ready handshake, shared controller, idempotent injection")

        state = {"licensed":True,"name":utf8("Рубеж"),"canRename":True,"licensePrice":1,"basePrice":1,
                 "cash":10,"bank":8,"clerkNear":False,"bases":[],"hasOwnBase":True,
                 "nearby":[],"reply":0,"ok":True}
        base = {"key":"h_100_100","name":utf8("Рубеж"),"town":utf8("Приморск"),"grid":"001001",
                "pos":[100,100,0],"price":1,"locked":False,"canSell":True,"near":True}
        state["bases"] = [base]

        def update():
            page.evaluate("s=>ALSPMCPhone.set(s)", state)

        def click(op):
            page.locator('[data-alspmc-op="'+op+'"]').click()

        def latest():
            return page.evaluate("__requests.at(-1)")

        def ack(request):
            state.update(reply=request["token"],ok=True)
            update()

        update()
        assert page.locator('#alspmc-title').inner_text() == "Рубеж"
        assert page.locator('#alspmc-bases .cargo').inner_text() == "Рубеж"
        assert "Приморск" in page.locator('#alspmc-bases').inner_text()
        assert page.locator('#session-label').inner_text() == "База подключена · 001001"
        checks.append("exact Cyrillic organization and location, base status")

        for section, visible in [("name","name"),("license","license"),("base","base"),("summary","base")]:
            page.locator('nav [data-section="'+section+'"]').click()
            assert page.locator('#alspmc-section-'+visible).is_visible()
            assert page.locator('nav [aria-current="true"]').count() == 1
        checks.append("desktop navigation sections and current selection")

        name = "Legacy & Рубеж ПК"
        page.locator('#alspmc-name').fill(name)
        update()
        assert page.locator('#alspmc-name').input_value() == name
        assert page.locator('#alspmc-name').evaluate("e=>document.activeElement===e")
        click("name")
        request = latest()
        assert request["a"] == "alspmc" and request["op"] == "name" and request["name"] == utf8(name)
        state["name"] = utf8(name)
        base["name"] = utf8(name)
        ack(request)
        assert page.locator('#alspmc-title').inner_text() == name
        checks.append("UTF8 rename with preserved input focus and shared phone protocol")

        for op in ["mark","view","furnish"]:
            click(op)
            assert latest() == {"a":"alspmc","op":op,"key":"h_100_100"}
        click("lock")
        request = latest()
        assert request["op"] == "lock"
        base["locked"] = True
        ack(request)
        click("unlock")
        request = latest()
        assert request["op"] == "unlock"
        base["locked"] = False
        ack(request)
        checks.append("map, view, furnishing, lock and unlock use shared commands")

        click("sell")
        assert latest() == request
        assert page.locator('#alspmc-confirm').is_visible()
        click("cancel")
        assert latest() == request
        assert page.locator('#alspmc-confirm').is_hidden()
        click("sell")
        click("confirm")
        request = latest()
        assert request["op"] == "sell" and request["key"] == "h_100_100"
        ack(request)
        checks.append("sale requires confirmation and cancellation does not send command")

        base.update(canSell=False,near=False)
        update()
        assert page.locator('[data-alspmc-op="sell"]').count() == 0
        assert page.locator('[data-alspmc-op="furnish"]').is_disabled()
        base.update(canSell=True,near=True)
        update()
        page.evaluate("s=>ALSPMCPhone.notice(s)", utf8("Название ЧВК сохранено."))
        assert page.locator('#alspmc-notice').inner_text() == "Название ЧВК сохранено."
        checks.append("permissions, disabled actions, exact UTF8 notifications")

        page.locator('#alspmc-name').focus()
        before = len(page.evaluate("__requests"))
        page.keyboard.press("Escape")
        assert len(page.evaluate("__requests")) == before
        page.keyboard.press("Escape")
        assert latest() == {"a":"alspmcDesktop","op":"close"}
        page.locator('.window-close').click()
        assert latest() == {"a":"alspmcDesktop","op":"close"}
        checks.append("input Escape releases focus, window Escape and close button end session")

        for width,height in [(1280,800),(1024,768),(800,600)]:
            page.set_viewport_size({"width":width,"height":height})
            for section in ["summary","name","base","license"]:
                page.locator('nav [data-section="'+section+'"]').click()
                assert page.locator('body').evaluate("e=>e.scrollWidth<=e.clientWidth+1")
                assert page.locator('#desktop-scroll').evaluate("e=>e.scrollWidth<=e.clientWidth+1")
        checks.append("four sections at three desktop sizes without horizontal overflow")
        page.set_viewport_size({"width":1280,"height":800})
        page.locator('nav [data-section="summary"]').click()
        page.locator('#desktop-scroll').evaluate("e=>e.scrollTop=0")
        page.screenshot(path=str(reports/"desktop-pmc.png"))

        # Full feature parity also preserves registration/purchase prerequisites.
        state.update(licensed=False,canRename=False,clerkNear=False,hasOwnBase=False,bases=[],
                     nearby=[{"key":"h_110_100","town":utf8("Приморск"),"grid":"002001","area":250,"distance":20}])
        update()
        assert page.locator('#alspmc-license').is_disabled()
        assert page.locator('[data-alspmc-op="base"]').is_disabled()
        state["clerkNear"] = True
        update()
        click("license")
        click("confirm")
        request = latest()
        assert request["op"] == "license" and "price" not in request
        state.update(licensed=True,canRename=True)
        ack(request)
        click("base")
        click("confirm")
        request = latest()
        assert request["op"] == "base" and request["key"] == "h_110_100" and "price" not in request
        ack(request)
        checks.append("all phone features present including native licence and base prerequisites")
        assert not errors, errors
        browser.close()
    report = {"checks":checks,"passed":len(checks),"arma_runtime_tested":False}
    (reports/"desktop-ui.json").write_text(json.dumps(report,indent=2)+"\n")
    print(f"Passed {len(checks)} desktop browser scenarios.")


if __name__ == "__main__":
    main()
