#!/usr/bin/env python3
"""Browser controls on real SQF fixture states; CEF/RPC transport is modeled."""
import json
from pathlib import Path
from playwright.sync_api import sync_playwright
from build import game_payload

ROOT = Path(__file__).resolve().parents[1]


def main():
    addon = ROOT / "addons/alspmc_core"
    reports = ROOT / "reports/stage1-0.7.0"
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
        browser = play.chromium.launch(executable_path="/usr/bin/chromium", args=["--no-sandbox"])
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
        page.get_by_role("button", name="Подтвердить исключение", exact=True).click()
        assert latest()["op"] == "companyRemove"
        checks.append("removal requires a separate confirmation click")
        state.update(reply=latest()["token"], ok=True)
        update()
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
