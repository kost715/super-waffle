#!/usr/bin/env python3
"""Build only standalone sources; the S1 (1/2/3-company) and S2 (state machine) Altis test missions are packed into the mod."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.2.1_s2_alpha1"
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


MISSIONS = ROOT/"addons/pmcs_core/missions"


def make_mission(count):
    """Generate one test mission inside the mod (registered in CfgMissions).

    Layout follows a mission format known to load from a mod PBO: addons[],
    AddonsMetaData, randomSeed, ScenarioData, plain icon markers. Players respawn
    on their side's marker at start, so the engine puts them on the ground
    whatever the terrain height at the stored slot position.
    """
    name=f"PMCS_S1_{count}PMC.Altis"
    folder=MISSIONS/name
    folder.mkdir(parents=True,exist_ok=True)
    desc=f'''author = "PMC project";
briefingName = "PMC Standalone S1 - {count} PMC";
onLoadName = "PMC Standalone S1: {count} PMC, 16 slots";
onLoadMission = "Independent AI diplomacy test. No LifeSim required.";
overviewText = "S1 technical prototype. Host/admin changes relations at a camp computer.";
respawn = 3;
respawnDelay = 5;
respawnOnStart = 1;
respawnDialog = 0;
disabledAI = 1;
joinUnassigned = 1;
saving = 0;
class Header {{gameType = "Coop"; minPlayers = 1; maxPlayers = 16;}};
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
            attrs=f'description="{company.upper()} operator {i+1}";isPlayable=1;name="pmcs_{company}_{i+1}";init="if (local this) then {{this setPosATL [{px},{py},0]}}";'
            flags=5
            if first:attrs='isPlayer=1;'+attrs;first=False;flags=7
            objects.append(f'class Item{i} {{dataType="Object";class PositionInfo {{position[]={{{px},0,{py}}};}};side="{eden}";flags={flags};class Attributes {{{attrs}}};id={uid};type="{unit}";}};')
        groups.append(f'class Item{len(groups)} {{dataType="Group";side="{eden}";class Entities {{items={amount};{"".join(objects)}}};class Attributes {{}};id={group_id};}};')
    marker_entities=[]
    for i,(_,_,_,company,x,y,marker,color) in enumerate(sides):
        marker_entities.append(f'class Item{count+i} {{dataType="Marker";position[]={{{x},0,{y}}};name="{marker}";text="PMC {company.upper()}";type="mil_start";colorName="{color}";id={sequence};}};');sequence+=1
    marker_entities.append(f'class Item{2*count} {{dataType="Marker";position[]={{14500,0,16350}};name="PMCS_test_range";text="S1 AI test field";type="mil_warning";colorName="ColorOrange";id={sequence};}};')
    sqm=f'''version=54;
class EditorData {{}};
binarizationWanted=0;
addons[]={{"A3_Characters_F","pmcs_core"}};
class AddonsMetaData {{}};
randomSeed=1;
class ScenarioData {{author="PMC project";respawn=3;}};
class Mission {{
    class Intel {{briefingName="PMC Standalone S1 - {count} PMC";year=2035;month=6;day=24;hour=12;minute=0;startWeather=0;forecastWeather=0;}};
    class Entities {{items={2*count+1};{"".join(groups)}{"".join(marker_entities)}}};
}};
'''
    (folder/"mission.sqm").write_text(sqm)
    return folder


def make_s2_mission():
    """S2 state-machine stand: 8 players, each in an own civilian group (Override
    GDD: players start as civilians and never share a group). A respawn marker for
    every side sits at the camp because a recoloured player respawns by side."""
    name="PMCS_S2_State.Altis"
    folder=MISSIONS/name
    folder.mkdir(parents=True,exist_ok=True)
    desc='''author = "PMC project";
briefingName = "PMC Standalone S2 - state machine";
onLoadName = "PMC Standalone S2: state machine stand, 8 slots";
onLoadMission = "Dynamic sides and undercover test. No LifeSim required.";
overviewText = "S2 stand. Each player has an own group with two bots. Combat zone (orange) and gang control zone (green). Use the S2 console (action menu).";
respawn = 3;
respawnDelay = 5;
respawnOnStart = 1;
respawnDialog = 0;
disabledAI = 1;
joinUnassigned = 1;
saving = 0;
class Header {gameType = "Coop"; minPlayers = 1; maxPlayers = 8;};
class PMCS_S2 {enabled = 1; zone[] = {14500, 16500}; zoneRadius = 150; gangZone[] = {14750, 16300}; gangRadius = 60;};
class CfgRemoteExec {
    class Functions {
        mode = 1; jip = 0;
        class PMCS_fnc_s2Request {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_s2Event {allowedTargets = 2; jip = 0;};
        class PMCS_fnc_s2Captive {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_s2Receive {allowedTargets = 0; jip = 0;};
        class PMCS_fnc_s2Regroup {allowedTargets = 0; jip = 0;};
    };
    class Commands {mode = 0; jip = 0;};
};
'''
    (folder/"description.ext").write_text(desc)
    x,y=14500,16210
    groups=[];sequence=1
    for i in range(8):
        group_id=sequence;sequence+=1;uid=sequence;sequence+=1
        px=x-7+(i%4)*4;py=y-(i//4)*4
        attrs=f'description="PMC operator {i+1}";isPlayable=1;name="pmcs2_p{i+1}";init="if (local this) then {{this setPosATL [{px},{py},0]}}";'
        flags=5
        if i==0:attrs='isPlayer=1;'+attrs;flags=7
        unit=f'class Item0 {{dataType="Object";class PositionInfo {{position[]={{{px},0,{py}}};}};side="Civilian";flags={flags};class Attributes {{{attrs}}};id={uid};type="C_man_1";}};'
        groups.append(f'class Item{i} {{dataType="Group";side="Civilian";class Entities {{items=1;{unit}}};class Attributes {{}};id={group_id};}};')
    markers=[]
    for j,(marker,color) in enumerate([("respawn_west","ColorWEST"),("respawn_east","ColorEAST"),("respawn_guerrila","ColorGUER"),("respawn_civilian","ColorCIV")]):
        text=' text="PMC camp";' if j==0 else ''
        markers.append(f'class Item{8+j} {{dataType="Marker";position[]={{{x},0,{y}}};name="{marker}";{text}type="{"mil_start" if j==0 else "Empty"}";colorName="{color}";id={sequence};}};');sequence+=1
    sqm=f'''version=54;
class EditorData {{}};
binarizationWanted=0;
addons[]={{"A3_Characters_F","pmcs_core"}};
class AddonsMetaData {{}};
randomSeed=1;
class ScenarioData {{author="PMC project";respawn=3;}};
class Mission {{
    class Intel {{briefingName="PMC Standalone S2 - state machine";year=2035;month=6;day=24;hour=12;minute=0;startWeather=0;forecastWeather=0;}};
    class Entities {{items={8+len(markers)};{"".join(groups)}{"".join(markers)}}};
}};
'''
    (folder/"mission.sqm").write_text(sqm)
    return folder


def main():
    build=ROOT/"build";dist=ROOT/"dist"
    payload={}
    # Missions live inside the mod PBO; generate them before collecting files.
    for count in [1,2,3]:make_mission(count)
    make_s2_mission()
    source=ROOT/"addons/pmcs_core"
    game_files={p.relative_to(source).as_posix().replace("/","\\"):p.read_bytes() for p in sorted(source.rglob("*")) if p.is_file()}
    pbo=pack(game_files,"pmcs_core")
    payload[f"{MOD}/addons/pmcs_core.pbo"]=pbo
    for name in ["mod.cpp","README_RU.md","LICENSE","RELEASE.json"]:
        payload[f"{MOD}/{name}"]=(ROOT/name).read_bytes()
    for p in sorted((ROOT/"docs").glob("*.md")):
        payload[f"{MOD}/docs/{p.name}"]=p.read_bytes()
    for name,data in payload.items():
        p=build/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    ready=dist/f"PMC_Standalone_{VERSION}.zip"
    zip_write(ready,payload)
    sources={}
    for folder in ["addons","tools","tests","docs"]:
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
