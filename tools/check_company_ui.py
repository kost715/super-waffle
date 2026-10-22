#!/usr/bin/env python3
"""Browser controls on real SQF fixture states; CEF/RPC transport is modeled."""
import json
import os
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def text_of_names(company):
    return {uid: bytes(v).decode() if all(n < 256 for n in v) else "".join(map(chr, v))
            for uid, v in company.get("names", {}).items()}


def main():
    addon = ROOT / "addons/alspmc_core"
    reports = ROOT / "reports/stage1-0.7.1"
    owner = json.loads((reports / "company-owner-state.json").read_text())[0]
    manager = json.loads((reports / "company-manager-state.json").read_text())[0]
    member = json.loads((reports / "company-member-state.json").read_text())[0]
    invite = json.loads((reports / "company-invite-state.json").read_text())[0]
    phone_script = game_payload("phone.js", (addon / "ui/phone.js").read_bytes()).decode()
    company_script = game_payload("company.js", (addon / "ui/company.js").read_bytes()).decode()
    state = {"licensed": True, "name": list("Рубеж".encode()), "canRename": True,
             "licensePrice": 1, "basePrice": 1, "cash": 10, "bank": 1000,
             "bases": [], "nearby": [], "reply": 0, "ok": True, "company": owner}
    checks = []
    with sync_playwright() as play:
        browser = play.chromium.launch(executable_path=os.environ.get("CHROMIUM", "/usr/bin/chromium"), args=["--no-sandbox"])
        page = browser.new_page(viewport={"width": 1280, "height": 800})
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.evaluate("window.__requests=[];window.A3API={SendAlert:s=>__requests.push(JSON.parse(s))}")
        page.set_content((addon / "ui/desktop.html").read_text())
        page.evaluate(phone_script + ";" + company_script + ";ALSPMCDesktop.start();")
        page.evaluate(company_script)

        def update():
            page.evaluate("s=>{ALSPMCPhone.set(s);ALSPMCCompany.set(s)}", state)

        def latest():
            return page.evaluate("__requests.at(-1)")

        update()
        assert page.locator("#pmc-company").is_hidden()
        page.locator('nav [data-section="company"]').click()
        assert page.locator("#pmc-company").is_visible()
        assert page.locator("#v-alspmc").is_hidden()
        assert "Владелец" in page.locator("#pmc-company").inner_text()
        checks.append("dedicated desktop section and idempotent injection")
        assert "250" in page.locator("#pmc-company").inner_text()
        assert "Внесение средств" in page.locator("#pmc-company").inner_text()
        assert "Вывод средств" in page.locator("#pmc-company").inner_text()
        checks.append("server-produced balances, roles and complete journal render")
        field = page.locator("#pmc-company-amount")
        field.fill("30")
        owner["seconds"] += 2
        update()
        assert field.input_value() == "30"
        assert field.evaluate("e=>document.activeElement===e")
        checks.append("periodic server pushes preserve typed amount and focus")
        page.get_by_role("button", name="Внести из личного банка", exact=True).click()
        request = latest()
        assert request["op"] == "companyDeposit" and request["companyArg"] == [owner["revision"], 30]
        assert page.get_by_role("button", name="Внести из личного банка", exact=True).is_disabled()
        checks.append("revision-bound numeric intent and duplicate-click guard")
        state.update(reply=request["token"], ok=False)
        update()
        assert "отклонена" in page.locator("#pmc-company").inner_text()
        checks.append("server rejection clears pending request and explains failure")
        state["company"] = manager
        update()
        assert not page.get_by_role("button", name="Вывести в личный банк", exact=True).count()
        assert not page.get_by_role("button", name="Сделать сотрудником", exact=True).count()
        assert page.get_by_role("button", name="Пригласить игрока", exact=True).count()
        checks.append("manager controls exclude profit withdrawal and owner-only roles")
        state["company"] = member
        update()
        assert not page.get_by_role("button", name="Пригласить игрока", exact=True).count()
        assert not page.get_by_role("button", name="Вывести в личный банк", exact=True).count()
        assert page.get_by_role("button", name="Выйти из ЧВК…", exact=True).count()
        checks.append("employee controls and explicit leave confirmation")
        state["company"] = owner
        update()
        before = page.evaluate("__requests.length")
        page.get_by_role("button", name="Исключить…", exact=True).click()
        assert page.evaluate("__requests.length") == before
        # 0.7.1: the active-time counter alone must not rebuild the panel.
        owner["seconds"] += 120
        update()
        assert page.get_by_role("button", name="Подтвердить исключение", exact=True).count()
        assert str(owner["seconds"] // 60) + " мин" in page.locator("#pmc-company-time").inner_text()
        checks.append("pending confirmation survives a seconds-only server poll; time still updates")
        page.get_by_role("button", name="Подтвердить исключение", exact=True).click()
        assert latest()["op"] == "companyRemove"
        checks.append("removal requires a separate confirmation click")
        state.update(reply=latest()["token"], ok=True)
        update()
        actor = owner["ledger"][0][1]
        assert text_of_names(owner)[actor] + " · " in page.locator("#pmc-company").inner_text()
        checks.append("ledger shows player names, not UIDs")
        # Engine toArray may deliver Unicode code points; both forms decode.
        owner["candidates"] = [{"uid": "ru", "name": [ord(c) for c in "Рубеж"]}, {"uid": "u8", "name": list("Север".encode())}]
        update()
        assert page.locator("#pmc-company-candidate option").all_inner_texts() == ["Рубеж", "Север"]
        checks.append("Cyrillic names decode from code points and from UTF-8 bytes")
        page.locator("#pmc-company-candidate").focus()
        page.locator("#pmc-company-candidate").evaluate("e=>e.dataset.mark='open'")
        owner["candidates"] = owner["candidates"] + [{"uid": "late", "name": list(b"Late")}]
        update()
        assert page.locator("#pmc-company-candidate").evaluate("e=>e.dataset.mark") == "open"
        page.locator("#pmc-company-amount").focus()
        page.wait_for_function("document.querySelectorAll('#pmc-company-candidate option').length===3")
        checks.append("an open candidate list is rebuilt only after it loses focus")
        owner["candidates"] = [{"uid": "xss", "name": list('<img src=x onerror="alert(1)">'.encode())}]
        update()
        assert not page.locator("#pmc-company img").count()
        page.get_by_role("button", name="Пригласить игрока", exact=True).click()
        assert latest()["companyArg"] == [owner["revision"], "xss"]
        checks.append("candidate names are text, invitation sends UID and revision")
        state.update(reply=latest()["token"], ok=True, company={"ready": False})
        update()
        assert not page.locator("#pmc-company input").count()
        checks.append("invalid server economy disables financial form")
        state["company"] = {"ready": True, "invites": []}
        update()
        assert "Компания появится" in page.locator("#pmc-company").inner_text()
        checks.append("unaffiliated empty state")
        # Acceptance uses the same phone renderer without loading desktop controls.
        page.locator('nav [data-section="summary"]').click()
        state["company"] = invite
        update()
        page.locator('[data-alspmc-op="companyAccept"]').click()
        assert latest()["op"] == "companyAccept" and latest()["companyArg"] == [0, owner["id"]]
        checks.append("server-issued invitation has explicit phone acceptance")
        assert not errors, errors
        page.locator('nav [data-section="company"]').click()
        state.update(reply=latest()["token"], ok=True, company=owner)
        update()
        # 0.7.1 remote cancel: owner outside the crew, base PC only, two confirmations.
        state["quests"] = {"ready": True, "canStart": False, "reason": "active", "catalog": [], "history": [],
                           "active": {"id": "q5", "type": "gov_convoy", "stage": "rendezvous", "mode": "convoy",
                                      "canCancelRemote": True, "crew": [list(b"Test p2")], "rendezvousLeft": 600,
                                      "teamSize": 1, "pay": 5000, "level": 1, "grid": "001001"}}
        update()
        page.locator('nav [data-section="quests"]').click()
        page.locator('[data-alspmc-op="questTab"][data-alspmc-key="active"]').click()
        assert "10:00" in page.locator("#alspmc-quests").inner_text()
        before = page.evaluate("__requests.length")
        page.get_by_role("button", name="Отменить контракт…", exact=True).click()
        assert "Сейчас в группе: Test p2" in page.locator("#alspmc-confirm-text").inner_text()
        page.locator("#alspmc-confirm-yes").click()
        assert page.evaluate("__requests.length") == before
        assert "необратима" in page.locator("#alspmc-confirm-text").inner_text()
        assert page.locator("#alspmc-confirm-yes").inner_text() == "Да, отменить без награды"
        page.locator("#alspmc-confirm-yes").click()
        assert latest()["op"] == "questCancelRemote" and latest()["key"] == "q5"
        checks.append("remote contract cancel asks twice and sends only after the second confirmation")
        state.update(reply=latest()["token"], ok=True)
        state.pop("quests")
        update()
        page.locator('nav [data-section="company"]').click()
        for width in [1280, 800]:
            page.set_viewport_size({"width": width, "height": 800})
            assert page.locator("body").evaluate("e=>e.scrollWidth<=innerWidth+1")
        page.screenshot(path=str(reports / "company-desktop.png"))
        checks.append("desktop widths and no browser exceptions")
        browser.close()
    (reports / "company-ui.json").write_text(json.dumps({"passed": checks, "arma_runtime_tested": False}, ensure_ascii=False, indent=2) + "\n")
    print(f"Passed {len(checks)} company browser scenarios.")


if __name__ == "__main__":
    main()
