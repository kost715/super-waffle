import hashlib
import importlib.util
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("build", ROOT / "tools/build.py")
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


def read_pbo(data):
    assert data[-21:-20] == b"\0"
    assert hashlib.sha1(data[:-21]).digest() == data[-20:]
    offset = 0

    def zstr():
        nonlocal offset
        end = data.index(0, offset)
        text = data[offset:end].decode("ascii")
        offset = end + 1
        return text

    assert zstr() == ""
    assert struct.unpack_from("<5I", data, offset) == (0x56657273, 0, 0, 0, 0)
    offset += 20
    properties = {}
    while key := zstr():
        properties[key] = zstr()
    entries = []
    while True:
        name = zstr()
        method, original, reserved, stamp, size = struct.unpack_from("<5I", data, offset)
        offset += 20
        if not name:
            assert (method, original, reserved, stamp, size) == (0,0,0,0,0)
            break
        assert method == reserved == stamp == 0
        assert original == size
        entries.append((name, size))
    files = {}
    for name, size in entries:
        assert name not in files
        files[name] = data[offset:offset+size]
        offset += size
    assert offset == len(data) - 21
    return properties, files


class PackageChecks(unittest.TestCase):
    def test_pbo_paths_prefix_and_payloads(self):
        source = ROOT / "addons/alspmc_core"
        expected = {p.relative_to(source).as_posix().replace("/", "\\"): build.game_payload(p.name,p.read_bytes())
                    for p in sorted(source.rglob("*")) if p.is_file()}
        blob = build.pack_pbo(expected, "alspmc_core")
        props, actual = read_pbo(blob)
        self.assertEqual(props, {"prefix":"alspmc_core"})
        self.assertEqual(expected, actual)
        self.assertNotIn("als_main.pbo", actual)

    def test_function_registration_and_paths(self):
        root = ROOT / "addons/alspmc_core"
        config = (root / "config.cpp").read_text()
        registered = set(re.findall(r"class (\w+) \{(?:postInit = 1;)?\};", config))
        files = {p.stem.removeprefix("fn_") for p in (root / "functions").glob("fn_*.sqf")}
        self.assertEqual(registered, files)
        code = "\n".join(p.read_text() for p in (root / "functions").glob("*.sqf"))
        references = set(re.findall(r"ALSPMC_fnc_(\w+)", code))
        self.assertLessEqual(references, files)
        self.assertIn('requiredAddons[] = {"als_main", "cba_main"}', config)
        self.assertNotIn("class als_main", config)

    def test_all_localization_keys_exist_and_languages_match(self):
        root = ROOT / "addons/alspmc_core"
        keys = ET.parse(root / "stringtable.xml").findall(".//Key")
        ids = [k.attrib["ID"] for k in keys]
        self.assertEqual(len(ids), len(set(ids)))
        for key in keys:
            texts = [key.findtext(lang) for lang in ["Original","English","Russian"]]
            self.assertTrue(texts[0])
            self.assertEqual(len(set(texts)),1)
        code = "\n".join(p.read_text() for p in (root / "functions").glob("*.sqf"))
        used = set(re.findall(r'"(STR_ALSPMC_\w+)"', code))
        self.assertLessEqual(used, set(ids))

    def test_license_moves_to_phone_without_changing_other_licenses(self):
        js = ROOT / "addons/alspmc_core/ui/licensePhoneOnly.js"
        self.assertTrue(js.read_bytes().isascii())
        labels = {k.attrib["ID"]:k.findtext("Russian")
                  for k in ET.parse(js.parents[1]/"stringtable.xml").findall(".//Key")}
        script = r'''
const fs = require("node:fs"), vm = require("node:vm"), assert = require("node:assert/strict");
const src = fs.readFileSync(process.argv[1], "utf8");
const name = process.argv[2], desc = process.argv[3];
for (const text of [name, Buffer.from(name).toString("latin1"), Buffer.from(Buffer.from(name).toString("latin1")).toString("latin1")]) {
  let received;
  const lic = {set(s){assert.equal(this,lic); received=s;}};
  const context = {window:{lic}};
  vm.runInNewContext(src,context);
  const first = lic.set;
  vm.runInNewContext(src,context);
  assert.equal(lic.set,first,"installation must be idempotent");
  const other = ["business","Existing license",12000,"Native description",false,0,"Courier",[]];
  const row = ["alspmc_pmc",text,1,text,false,0,"Courier",[]];
  const state = {cash:1,bank:2,list:[other,row],kit:true};
  const before = JSON.stringify(state);
  lic.set(state);
  assert.equal(JSON.stringify(state),before,"must not mutate incoming state");
  assert.equal(received.list[0],other,"must not change other licences");
  assert.equal(received.list.length,1,"PMC management moved to phone");
  assert.equal(received.cash,1);
  assert.equal(received.bank,2);
}
console.log("native licenses unchanged, PMC license hidden from old office UI");
'''
        result = subprocess.run(["node","-e",script,str(js),labels["STR_ALSPMC_license_name"],
                                 labels["STR_ALSPMC_license_desc"]],text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_phone_payload_is_ascii_and_actions_belong_only_to_computer(self):
        root=ROOT/"addons/alspmc_core"
        js=(root/"ui/phone.js").read_bytes()
        self.assertTrue(build.game_payload("phone.js",js).isascii())
        code="\n".join(p.read_text() for p in (root/"functions").glob("*.sqf"))
        self.assertNotIn("player addAction",code)
        self.assertEqual(code.count("addAction ["),1)
        self.assertIn('_computer addAction [',code)
        self.assertNotIn("ALSPMC_fnc_addActions",code)
        self.assertNotIn("ALSPMC_fnc_showStatus",code)
        self.assertIn('data-alspmc-op',js.decode())

    def test_archives_crc_and_reproducible_pbo(self):
        for name in [f"LifeSim_PMC_{build.VERSION}.zip", f"LifeSim_PMC_{build.VERSION}_sources.zip"]:
            archive = ROOT / "dist" / name
            self.assertTrue(archive.is_file(),"run tools/build.py first")
            with zipfile.ZipFile(archive) as z:
                self.assertIsNone(z.testzip())
                names = z.namelist()
                self.assertEqual(len(names),len(set(names)))
                self.assertFalse(any("als_main.pbo" in n for n in names))
                self.assertFalse(any("/.git/" in n for n in names))
        archive = ROOT / "dist" / f"LifeSim_PMC_{build.VERSION}_sources.zip"
        with tempfile.TemporaryDirectory() as temp:
            with zipfile.ZipFile(archive) as z:
                z.extractall(temp)
            source = Path(temp)/"LifeSim_PMC_sources"
            subprocess.run(["python3","tools/build.py"],cwd=source,check=True,capture_output=True)
            expected = ROOT/"build/@LifeSim_PMC/addons/alspmc_core.pbo"
            actual = source/"build/@LifeSim_PMC/addons/alspmc_core.pbo"
            self.assertEqual(expected.read_bytes(),actual.read_bytes())
            ready = f"LifeSim_PMC_{build.VERSION}.zip"
            self.assertEqual((ROOT/"dist"/ready).read_bytes(),(source/"dist"/ready).read_bytes())

    def test_server_owns_prices_and_does_not_accept_client_money(self):
        root = ROOT/"addons/alspmc_core"
        config = (root/"config.cpp").read_text()
        self.assertRegex(config,r"price = 1;")
        self.assertRegex(config,r"basePrice = 1;")
        buy = (root/"functions/fn_buyBase.sqf").read_text()
        self.assertIn('configFile >> "ALSPMC_Settings" >> "basePrice"',buy)
        self.assertIn('remoteExecutedOwner != owner _unit', (root/"functions/fn_requestAllowed.sqf").read_text())

    def test_native_phone_keeps_one_browser_dispatcher(self):
        root = ROOT/"addons/alspmc_core/functions"
        tick = (root/"fn_clientTick.sqf").read_text()
        self.assertEqual(tick.count('ctrlAddEventHandler ["JSDialog"'),1)
        self.assertIn('ctrlRemoveEventHandler ["JSDialog", 0]',tick)
        self.assertNotIn('ctrlRemoveAllEventHandlers', tick)
        bridge = (root/"fn_phoneBridge.sqf").read_text()
        self.assertIn('_this call ALSPMC_nativePhoneMsg', bridge)
        init = (root/"fn_clientInit.sqf").read_text()
        self.assertIn('ALSPMC_nativePhoneMsg = ALS_fnc_phoneMsg', init)
        self.assertNotIn('ALS_fnc_phoneMsg =',init)


if __name__ == "__main__":
    unittest.main()
