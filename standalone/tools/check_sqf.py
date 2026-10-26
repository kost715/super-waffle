#!/usr/bin/env python3
"""Parse standalone SQF and execute its own VM fixture, without LifeSim."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def run(vm, args):
    p=subprocess.run([str(vm),'-a','--suppress-welcome','--no-execute-print','--no-work-print',
        '--max-runtime','30000',*args],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=45)
    bad=p.returncode!=0 or re.search(r'\[(?:ERR|FAT)\]|TEST_FAIL|NOT IMPLEMENTED|could not be found|could not be located',p.stdout)
    return not bad,p.stdout


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--vm',type=Path,required=True)
    parser.add_argument('--transactions-only',action='store_true',help='Development probe: skips syntax pass')
    args=parser.parse_args()
    report={'arma_runtime_tested':False,'original_mod_loaded':False,'syntax':[]}
    config=ROOT/'addons/pmcs_core/config.cpp'
    # Fixture UI bases/vehicle identities; none are original-mod resources.
    common=['--input-config',str(ROOT/'tests/world_config.hpp'),'--input-config',str(config)]
    for p in ([] if args.transactions_only else sorted((ROOT/'addons/pmcs_core/functions').glob('*.sqf'))):
        ok,output=run(args.vm,[*common,'--parse-only','--input-sqf',str(p)])
        report['syntax'].append({'file':p.name,'passed':ok})
        if not ok:raise SystemExit(output)
    report['mission_configs']=[]
    if not args.transactions_only:
        dest=ROOT/'reports';dest.mkdir(exist_ok=True)
        for path in sorted((ROOT/'missions').glob('*/*')):
            if path.suffix not in {'.sqm','.ext'}:continue
            # The VM accepts only classes at root; Arma missions also have
            # root fields. Check grammar through a fixture, without editing missions.
            wrapped=dest/'mission-config-fixture.hpp'
            wrapped.write_text('class MissionFixture {\n'+path.read_text()+'\n};\n')
            ok,output=run(args.vm,['--parse-only','--input-config',str(wrapped)])
            report['mission_configs'].append({'file':str(path.relative_to(ROOT)),'passed':ok,'root_wrapped_for_vm':True})
            if not ok:raise SystemExit(output)
    ok,output=run(args.vm,[*common,'--virtual',str(ROOT)+'|/','--input-sqf',str(ROOT/'tests/entry.sqf')])
    match=re.search(r'TEST_COMPLETE: (\d+) assertions',output)
    report['transactions']={'passed':bool(ok and match),'assertions':int(match[1]) if match else 0}
    report['modeled_boundaries']=['group creation/membership','AI skills/behavior/targeting','directional side relations',
        'player UID/owner/admin authority','RPC dispatch/capture','public variable flag','UI null display','flat positions/findEmptyPosition geometry']
    dest=ROOT/'reports';dest.mkdir(exist_ok=True)
    (dest/'sqf-run.txt').write_text(output)
    (dest/'sqf-checks.json').write_text(json.dumps(report,indent=2)+'\n')
    if not ok or not match:raise SystemExit(output[-9000:])
    print(f"Parsed {len(report['syntax'])} SQF files; {match[1]} transaction assertions passed. No LifeSim loaded.")


if __name__=='__main__':main()
