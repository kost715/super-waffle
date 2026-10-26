#!/usr/bin/env python3
"""Build only standalone sources, plus 1/2/3-company Altis test missions."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.1_s1_alpha1"
STAMP = (2026,10,26,0,0,0)
MOD = "@PMC_Standalone"


def pack(files, prefix=None):
    out = bytearray(b"\0" + struct.pack("<5I",0x56657273,0,0,0,0))
    out.extend(b"prefix\0" + prefix.encode("ascii") + b"\0\0" if prefix is not None else b"\0")
    for name,data in sorted(files.items()):
        out.extend(name.encode("ascii") + b"\0" + struct.pack("<5I",0,len(data),0,0,len(data)))
    out.extend(b"\0"+bytes(20))
    out.extend(b"".join(data for _,data in sorted(files.items())))
    return bytes(out)+b"\0"+hashlib.sha1(out).digest()


def zip_write(path, files):
    path.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(path,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,data in sorted(files.items()):
            info=zipfile.ZipInfo(name,STAMP)
            info.compress_type=zipfile.ZIP_DEFLATED; info.external_attr=0o100644<<16
            z.writestr(info,data,compresslevel=9)


def make_mission(count):
    name=f"PMCS_S1_{count}PMC.Altis"
    folder=ROOT/"missions"/name
    folder.mkdir(parents=True,exist_ok=True)
    desc=f'''author = "PMC project";
onLoadName = "PMC Standalone S1: {count} PMC, 16 slots";
onLoadMission = "Independent AI diplomacy test. No LifeSim required.";
overviewText = "S1 technical prototype. Host/admin changes relations at a camp computer.";
respawn = 3;
respawnDelay = 5;
respawnOnStart = -1;
disabledAI = 1;
joinUnassigned = 1;
class Header {{gameType = Coop; minPlayers = 1; maxPlayers = 16;}};
class PMCS_Prototype {{enabled = 1; companies = {count};}};
class CfgRemoteExec {{
    class Functions {{
        mode = 1; jip = 0;
        class PMCS_fnc_request {{allowedTargets = 2; jip = 0;}};
        class PMCS_fnc_receiveState {{allowedTargets = 0; jip = 0;}};
    }};
    class Commands {{mode = 0; jip = 0;}};
}};
'''
    (folder/"description.ext").write_text(desc)
    sides=[("West","WEST","B_Soldier_F","alpha",14450,16210,"respawn_west","ColorWEST"),
           ("East","EAST","O_Soldier_F","bravo",14550,16210,"respawn_east","ColorEAST"),
           ("Independent","GUER","I_Soldier_F","charlie",14500,16150,"respawn_guerrila","ColorGUER")][:count]
    amounts={1:[16],2:[8,8],3:[6,5,5]}[count]
    groups=[]; sequence=1; first=True
    for (eden,legacy,unit,company,x,y,marker,color),amount in zip(sides,amounts):
        group_id=sequence;sequence+=1;objects=[]
        for i in range(amount):
            uid=sequence;sequence+=1
            px=x-4+(i%4)*2;py=y-4-(i//4)*2
            attrs=f'skill=0.6;isPlayable=1;description="{company.upper()} operator {i+1}";name="pmcs_{company}_{i+1}";init="if (local this) then {{this setPosATL [{px},{py},0]}}";'
            if first:attrs+='isPlayer=1;';first=False
            objects.append(f'''class Item{i} {{dataType="Object";class PositionInfo {{position[]={{{px},20,{py}}};}};side="{eden}";flags=7;class Attributes {{{attrs}}};id={uid};type="{unit}";atlOffset=0;}};''')
        groups.append(f'''class Item{len(groups)} {{dataType="Group";side="{eden}";class Entities {{items={amount};{''.join(objects)}}};class Attributes {{}};id={group_id};}};''')
    # Markers are mission-owned and do not use any foreign cleanup prefix.
    marker_entities=[]
    for i,(_,_,_,company,x,y,marker,color) in enumerate(sides):
        marker_entities.append(f'class Item{count+i} {{dataType="Marker";position[]={{{x},20,{y}}};name="{marker}";text="PMC {company.upper()}";markerType="ICON";a=1;b=1;type="mil_start";colorName="{color}";id={sequence};}};');sequence+=1
    marker_entities.append(f'class Item{2*count} {{dataType="Marker";position[]={{14500,20,16350}};name="PMCS_test_range";text="S1 AI test field";markerType="ICON";a=1;b=1;type="mil_warning";colorName="ColorOrange";id={sequence};}};')
    sqm=f'''version=54;
class EditorData {{moveGridStep=1;angleGridStep=0.2617994;scaleGridStep=1;autoGroupingDist=10;}};
binarizationWanted=0;
sourceName="PMC Standalone S1 - {count} PMC";
class ScenarioData {{author="PMC project";}};
class Mission {{
    class Intel {{briefingName="PMC Standalone S1 - {count} PMC";year=2035;month=6;day=24;hour=12;minute=0;startWeather=0;forecastWeather=0;}};
    class Entities {{items={2*count+1};{''.join(groups)}{''.join(marker_entities)}}};
}};
'''
    (folder/"mission.sqm").write_text(sqm)
    return folder


def main():
    build=ROOT/"build";dist=ROOT/"dist"
    payload={}
    source=ROOT/"addons/pmcs_core"
    game_files={p.relative_to(source).as_posix().replace("/","\\"):p.read_bytes() for p in sorted(source.rglob("*")) if p.is_file()}
    pbo=pack(game_files,"pmcs_core")
    payload[f"{MOD}/addons/pmcs_core.pbo"]=pbo
    for name in ["mod.cpp","README_RU.md","LICENSE","RELEASE.json"]:
        payload[f"{MOD}/{name}"]=(ROOT/name).read_bytes()
    for p in sorted((ROOT/"docs").glob("*.md")):
        payload[f"{MOD}/docs/{p.name}"]=p.read_bytes()
    for count in [1,2,3]:
        folder=make_mission(count)
        files={p.name:p.read_bytes() for p in sorted(folder.iterdir()) if p.is_file()}
        mission_pbo=pack(files)
        payload[f"MPMissions/{folder.name}.pbo"]=mission_pbo
    for name,data in payload.items():
        p=build/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    ready=dist/f"PMC_Standalone_{VERSION}.zip"
    zip_write(ready,payload)
    sources={}
    for folder in ["addons","missions","tools","tests","docs"]:
        for p in sorted((ROOT/folder).rglob("*")):
            if p.is_file() and "__pycache__" not in p.parts:
                sources["PMC_Standalone_sources/"+p.relative_to(ROOT).as_posix()]=p.read_bytes()
    for name in [".gitignore","LICENSE","mod.cpp","RELEASE.json","README_RU.md"]:
        sources["PMC_Standalone_sources/"+name]=(ROOT/name).read_bytes()
    src=dist/f"PMC_Standalone_{VERSION}_sources.zip"
    zip_write(src,sources)
    manifest={"version":VERSION,"game_files":len(game_files),"pbo_sha256":hashlib.sha256(pbo).hexdigest(),
        "archives":{p.name:{"bytes":p.stat().st_size,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in [ready,src]},"arma_runtime_tested":False}
    # Keep the hashes of earlier releases kept in dist/; replace only this version's rows.
    sums=dist/"SHA256SUMS.txt"
    rows={}
    if sums.exists():
        for line in sums.read_text().splitlines():
            digest,name=line.split("  ",1)
            if (dist/name).exists():rows[name]=digest
    rows.update({name:row['sha256'] for name,row in manifest['archives'].items()})
    sums.write_text(''.join(f"{rows[name]}  {name}\n" for name in sorted(rows)))
    reports=ROOT/"reports";reports.mkdir(exist_ok=True)
    (reports/"build.json").write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(manifest,indent=2))


if __name__=="__main__":main()
