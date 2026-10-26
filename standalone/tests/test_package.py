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

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('standalone_build',ROOT/'tools/build.py')
build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)


def unpack(data):
    assert data[-21:-20]==b'\0' and hashlib.sha1(data[:-21]).digest()==data[-20:]
    at=0
    def z():
        nonlocal at
        end=data.index(0,at);out=data[at:end].decode('ascii');at=end+1;return out
    assert z()==''
    assert struct.unpack_from('<5I',data,at)==(0x56657273,0,0,0,0);at+=20
    props={}
    while name:=z():props[name]=z()
    entries=[]
    while True:
        name=z();row=struct.unpack_from('<5I',data,at);at+=20
        if name=='':assert row==(0,0,0,0,0);break
        assert row[0]==row[2]==row[3]==0 and row[1]==row[4]
        entries.append((name,row[4]))
    files={}
    for name,n in entries:
        assert name not in files;files[name]=data[at:at+n];at+=n
    assert at==len(data)-21
    return props,files


class StandalonePackage(unittest.TestCase):
    def test_independent_dependencies_and_source_namespace(self):
        config=(ROOT/'addons/pmcs_core/config.cpp').read_text()
        deps=re.search(r'requiredAddons\[\] = \{([^}]+)\}',config)[1]
        self.assertEqual(set(re.findall(r'"([^"]+)"',deps)),{'A3_Characters_F','A3_Structures_F','A3_UI_F'})
        code='\n'.join(p.read_text() for p in (ROOT/'addons').rglob('*.sqf'))
        self.assertNotRegex(code,r'\bALS_fnc_|\bALS_ready|\bCBA_fnc_|\bACE_fnc_')
        self.assertNotIn('doFire',code)
        self.assertNotIn('doTarget',code)

    def test_registered_functions_and_localization(self):
        addon=ROOT/'addons/pmcs_core'
        names={p.stem.removeprefix('fn_') for p in (addon/'functions').glob('fn_*.sqf')}
        config=(addon/'config.cpp').read_text()
        registered=set(re.findall(r'class (\w+) \{(?:postInit = 1;)?\};',config))
        self.assertEqual(names,registered)
        code='\n'.join(p.read_text() for p in addon.rglob('*') if p.is_file())
        self.assertLessEqual(set(re.findall(r'PMCS_fnc_(\w+)',code)),names)
        keys=ET.parse(addon/'stringtable.xml').findall('.//Key')
        ids=[k.attrib['ID'] for k in keys]
        self.assertEqual(len(ids),len(set(ids)))
        self.assertLessEqual(set(re.findall(r'STR_PMCS_\w+',code)),set(ids))
        for key in keys:
            self.assertTrue(all(key.findtext(x) for x in ['Original','English','Russian']))

    def test_missions_slots_and_isolation(self):
        for count in [1,2,3]:
            folder=ROOT/'missions'/f'PMCS_S1_{count}PMC.Altis'
            sqm=(folder/'mission.sqm').read_text();desc=(folder/'description.ext').read_text()
            self.assertIn('version=54;',sqm)
            self.assertEqual(sqm.count('isPlayable=1;'),16)
            self.assertEqual(sqm.count('isPlayer=1;'),1)
            self.assertEqual(sqm.count('dataType="Group"'),count)
            self.assertEqual(len(re.findall(r'name="respawn_',sqm)),count)
            ids=re.findall(r'\bid=(\d+);',sqm)
            self.assertEqual(len(ids),len(set(ids)))
            self.assertEqual(sqm.count('this setPosATL'),16)
            self.assertIn(f'enabled = 1; companies = {count};',desc)
            self.assertIn('disabledAI = 1;',desc)
            self.assertIn('class Commands {mode = 0;',desc)
            self.assertEqual(set(re.findall(r'class (PMCS_fnc_\w+)',desc)),{'PMCS_fnc_request','PMCS_fnc_receiveState'})

    def test_ui_controls_and_endpoint_contract(self):
        ui=(ROOT/'addons/pmcs_core/ui.hpp').read_text()
        ids=[int(x) for x in re.findall(r'\bidc = (\d+)',ui)]
        self.assertEqual(len(ids),len(set(ids)))
        self.assertLessEqual({1100,1101,1102,1500,2100,2101,3100,3101,3102,3103,3104,3105,3106},set(ids))
        msg=(ROOT/'addons/pmcs_core/functions/fn_uiAction.sqf').read_text()
        self.assertIn('PMCS_clientPrefix + ":" + str PMCS_sequence',msg)
        self.assertNotIn('900000000',msg)
        self.assertIn('PMCS_fnc_request',msg)

    def test_pbo_payload_and_mission_packages(self):
        archive=ROOT/'dist'/f'PMC_Standalone_{build.VERSION}.zip'
        with zipfile.ZipFile(archive) as z:
            self.assertIsNone(z.testzip())
            props,payload=unpack(z.read('@PMC_Standalone/addons/pmcs_core.pbo'))
            self.assertEqual(props,{'prefix':'pmcs_core'})
            expected={p.relative_to(ROOT/'addons/pmcs_core').as_posix().replace('/','\\'):p.read_bytes()
                for p in (ROOT/'addons/pmcs_core').rglob('*') if p.is_file()}
            self.assertEqual(expected,payload)
            for count in [1,2,3]:
                name=f'PMCS_S1_{count}PMC.Altis'
                _,mission=unpack(z.read(f'MPMissions/{name}.pbo'))
                self.assertEqual(mission,{p.name:p.read_bytes() for p in (ROOT/'missions'/name).iterdir() if p.is_file()})
            self.assertNotIn('als_main.pbo','\n'.join(z.namelist()))

    def test_source_archive_rebuild_and_crc(self):
        name=f'PMC_Standalone_{build.VERSION}.zip'
        with tempfile.TemporaryDirectory() as dest:
            with zipfile.ZipFile(ROOT/'dist'/f'PMC_Standalone_{build.VERSION}_sources.zip') as z:
                self.assertIsNone(z.testzip());self.assertFalse(any('/.git/' in n for n in z.namelist()))
                z.extractall(dest)
            source=Path(dest)/'PMC_Standalone_sources'
            subprocess.run(['python3','tools/build.py'],cwd=source,check=True,capture_output=True)
            self.assertEqual((source/'dist'/name).read_bytes(),(ROOT/'dist'/name).read_bytes())


if __name__=='__main__':unittest.main()
