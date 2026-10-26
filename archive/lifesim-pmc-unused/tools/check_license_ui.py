#!/usr/bin/env python3
"""Check that the old office UI hides only the PMC licence moved to phone."""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--russian", type=Path, required=True)
    args = parser.parse_args()
    keys = {k.attrib["ID"]:k.findtext("Russian") for k in
            ET.parse(ROOT/"addons/alspmc_core/stringtable.xml").findall(".//Key")}
    name, desc = keys["STR_ALSPMC_license_name"], keys["STR_ALSPMC_license_desc"]
    byte_text = name.encode().decode("latin1")
    cases = {"unicode": name, "latin1": byte_text,
             "cp1252": name.encode().decode("cp1252",errors="replace"),
             "double": byte_text.encode().decode("latin1")}
    results = []
    reports = ROOT/"reports"
    reports.mkdir(exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path="/usr/bin/chromium",args=["--no-sandbox"])
        for variant, path in [("original",args.original),("ru-beta3",args.russian)]:
            for encoding, text in cases.items():
                page = browser.new_page(viewport={"width":1280,"height":900})
                errors = []
                page.on("pageerror",lambda e: errors.append(str(e)))
                page.evaluate("window.__requests=[]; window.A3API={SendAlert:s=>window.__requests.push(JSON.parse(s))};")
                page.set_content(path.read_text(encoding="utf-8-sig"),wait_until="load")
                if variant == "ru-beta3":
                    page.evaluate("window.i18n && i18n.set('ru')")
                page.add_script_tag(path=str(ROOT/"addons/alspmc_core/ui/licensePhoneOnly.js"))
                state = {"cash":12000,"bank":5,"rank":0,"rankName":"Courier","kit":True,
                         "list":[["business","Business license",12000,"Own shops, warehouses and factories.",False,0,"Courier",[]],
                                 ["alspmc_pmc",text,1,text,False,0,"Courier",[]]]}
                page.evaluate("s=>{window.__state=s;window.__before=JSON.stringify(s);lic.set(s);}",state)
                assert page.locator('[data-buy="alspmc_pmc"]').count()==0
                button = page.locator('[data-buy="business"]')
                button.wait_for(state="visible")
                card = button.locator("xpath=ancestor::div[contains(@class,'card')]")
                assert card.locator(".price").inner_text() == "12 000 €"
                assert not button.is_disabled()
                assert page.evaluate("JSON.stringify(window.__state)===window.__before")
                button.click()
                button.click()
                requests = page.evaluate("window.__requests")
                assert requests[-1] == {"a":"buy","id":"business"},requests
                assert not errors,errors
                results.append({"variant":variant,"encoding":encoding,"passed":True,
                                "buy_request":requests[-1]})
                page.close()
        browser.close()
    report = {"cases":results,"arma_runtime_tested":False}
    (reports/"license-ui.json").write_text(json.dumps(report,indent=2)+"\n")
    print(f"Passed {len(results)} actual license-page browser cases.")


if __name__ == "__main__":
    main()
