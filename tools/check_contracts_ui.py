#!/usr/bin/env python3
"""Exercise actual server-generated contract states on phone/RU/desktop HTML."""
import argparse
import copy
import json
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--russian", type=Path, required=True)
    parser.add_argument("--states", type=Path, required=True)
    args = parser.parse_args()
    states = json.loads(args.states.read_text())
    assert len(states) == 6, "Run the SQF contract fixtures first"
    low, high, waiting, nearby, active, done = states
    patrol_states = json.loads((args.states.parent/"patrol-phone-states.json").read_text())
    assert len(patrol_states) == 2
    script = game_payload("phone.js", (ROOT/"addons/alspmc_core/ui/phone.js").read_bytes()).decode("ascii")
    checks = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path="/usr/bin/chromium", args=["--no-sandbox"])
        for variant, path in [("original",args.original),("ru-beta3",args.russian),
                              ("desktop",ROOT/"addons/alspmc_core/ui/desktop.html")]:
            desktop = variant == "desktop"
            page = browser.new_page(viewport={"width":1280 if desktop else 430,"height":800 if desktop else 900})
            page.set_default_timeout(5000)
            errors = []
            page.on("pageerror",lambda e:errors.append(str(e)))
            page.evaluate("window.__requests=[];window.A3API={SendAlert:s=>__requests.push(JSON.parse(s)),RequestTexture:()=>Promise.resolve('')}")
            page.set_content(path.read_text(encoding="utf-8-sig"),wait_until="load")
            if variant == "ru-beta3":
                page.evaluate("window.i18n && i18n.set('ru')")
            page.evaluate(script)
            page.evaluate("ALSPMCDesktop.start()" if desktop else "phone.open('alspmc')")
            if desktop:
                page.locator('nav [data-section="quests"]').click()

            def push(state, reply=None):
                snapshot = copy.deepcopy(state)
                snapshot.update(cash=0,bank=0)
                if reply is not None:
                    snapshot.update(reply=reply,ok=True)
                page.evaluate("s=>ALSPMCPhone.set(s)",snapshot)

            def click(op,key=None):
                selector=f'[data-alspmc-op="{op}"]'
                if key is not None:
                    selector+=f'[data-alspmc-key="{key}"]'
                page.locator(selector).click()

            def latest():
                return page.evaluate("__requests.filter(r=>r.a==='alspmc').at(-1)")

            def passed(label):
                checks.append({"variant":variant,"check":label,"passed":True})

            push(low)
            assert page.locator('[data-alspmc-op="questStart"]').count()==4
            assert not any(e["key"] in ["gov_base","gov_patrol"] for e in low["quests"]["catalog"])
            assert "Рейтинг ЧВК: 1 / 5" in page.locator('#alspmc-quests').inner_text()
            assert "Обновление предложений через" in page.locator('#alspmc-quests').inner_text()
            click("questCategory","private")
            assert page.locator('[data-alspmc-op="questStart"]').count()==2
            assert page.locator('[data-alspmc-key="eliminate"][data-alspmc-op="questStart"]').count()==0
            passed("actual board shows four/two offers, level gates, renewal timer and no prototype")

            push(high)
            click("questCategory","government")
            base_entry=next(e for e in high["quests"]["catalog"] if e["key"]=="gov_base")
            choice=page.locator('[data-alspmc-base-choice]')
            assert choice.locator('option').count()>=3
            military=next(t for t in base_entry["targets"] if t["owner"]=="Military")
            choice.select_option(military["id"])
            base_key=base_entry["offer"]+"|"+military["id"]
            assert page.locator(f'[data-alspmc-key="{base_key}"]').is_enabled()
            click("questStart",base_key)
            assert "Штурм военной базы" in page.locator('#alspmc-confirm-text').inner_text()
            click("cancel")
            push(high)
            assert choice.input_value()==military["id"]
            passed("both native armies are selectable and base choice survives state refresh")
            guard_entry=next(e for e in high["quests"]["catalog"] if e["key"]=="gov_guard")
            before=latest()
            click("questStart",guard_entry["offer"])
            assert latest()==before
            assert "в казну ЧВК" in page.locator('#alspmc-confirm-text').inner_text()
            click("confirm")
            request=latest()
            assert set(request)=={"a","op","key","token"} and request["key"]==guard_entry["offer"]
            push(waiting,request["token"])
            assert page.locator('[data-alspmc-op="questReady"]').is_disabled()
            assert "Прибудьте" in page.locator('#alspmc-quests').inner_text()
            passed("acceptance sends only a contract key; actual rendezvous state blocks distant readiness")

            push(nearby)
            assert page.locator('[data-alspmc-op="questReady"]').is_enabled()
            click("questReady")
            request=latest()
            assert request["op"]=="questReady" and request["key"]==waiting["quests"]["active"]["id"]
            push(active,request["token"])
            assert page.locator('[data-alspmc-op="questReady"]').count()==0
            assert "10:00" in page.locator('#alspmc-quests').inner_text()
            assert "Награда в казну ЧВК" in page.locator('#alspmc-quests').inner_text()
            passed("nearby readiness starts the active duty and displays the server real-time countdown")

            click("questMap")
            assert latest()["op"]=="questMap" and "token" not in latest()
            click("questCancel")
            assert "без выплаты" in page.locator('#alspmc-confirm-text').inner_text()
            click("cancel")
            push(done)
            assert "Выполнен" in page.locator('#alspmc-quests').inner_text()
            assert "Владельцу перечислено" in page.locator('#alspmc-quests').inner_text()
            assert "18" in page.locator('#alspmc-quests').inner_text()
            passed("shared map/cancel protocol and the server receipt render without group split text")

            click("questTab","available")
            assert "Опыт: 1310" in page.locator('#alspmc-quests').inner_text()
            assert page.locator('#v-alspmc').evaluate("e=>e.scrollWidth<=e.clientWidth+1")
            assert not errors,errors
            page.screenshot(path=str(ROOT/"reports"/f"contracts-{variant}.png"))
            passed("earned rating refreshes and long Russian catalog fits without JS errors or overflow")
            push(patrol_states[0])
            click("questTab","active")
            assert "Пройдено точек: 0 / 4" in page.locator('#alspmc-quests').inner_text()
            assert "Осталось реального времени" not in page.locator('#alspmc-quests').inner_text()
            assert patrol_states[0]["quests"]["active"]["destination"] == []
            passed("actual checkpoint patrol state shows route progress without an area-duty countdown")
            push(patrol_states[1])
            assert "Пройдено точек: 1 / 4" in page.locator('#alspmc-quests').inner_text()
            assert patrol_states[0]["quests"]["active"]["pos"] != patrol_states[1]["quests"]["active"]["pos"]
            click("questMap")
            assert latest()["key"] == patrol_states[1]["quests"]["active"]["id"]
            assert not errors, errors
            page.screenshot(path=str(ROOT/"reports"/f"patrol-{variant}.png"))
            passed("next actual checkpoint refreshes on both devices and retains the native map protocol")
            page.close()
        browser.close()
    (ROOT/"reports/contracts-ui.json").write_text(json.dumps({"cases":checks,"arma_runtime_tested":False},indent=2)+"\n")
    print(f"Passed {len(checks)} full-contract browser scenarios using actual SQF snapshots.")


if __name__=="__main__":
    main()
