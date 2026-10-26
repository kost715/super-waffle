#!/usr/bin/env python3
"""Review the adopted 0.6.3 with existing VM engine fixtures and targeted probes.

This is a limited baseline check, not a port of the older full regression suite.
The cache diagnostic records a reproduced issue separately from assertions.
"""
import argparse
import json
from pathlib import Path
import re
from check_sqf import run

ROOT=Path(__file__).resolve().parents[1]

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--vm',type=Path,required=True)
    p.add_argument('--lifesim',type=Path,required=True)
    args=p.parse_args()
    reports=ROOT/'reports/baseline-0.6.3'
    reports.mkdir(parents=True,exist_ok=True)
    common=['--command-dummy-binary','4|ctrlWebBrowserAction','--command-dummy-unary','fromJSON','--command-dummy-unary','toJSON']
    config=ROOT/'addons/alspmc_core/config.cpp'
    report={'arma_runtime_tested':False,'scope':'syntax and targeted 0.6.3 probes','syntax':[]}
    for sqf in sorted((ROOT/'addons/alspmc_core/functions').glob('*.sqf')):
        ok,output=run(args.vm,[*common,'--parse-only','--input-config',str(config),'--input-sqf',str(sqf)])
        report['syntax'].append({'file':sqf.name,'passed':ok})
        if not ok:raise SystemExit(output)
    fixture=(ROOT/'tests/transactions.sqf').read_text()
    marker='\ncall TEST_fnc_reset;\n'
    if marker not in fixture:raise SystemExit('Cannot locate existing fixture initialization')
    prefix=fixture.split(marker,1)[0]
    entry=reports/'review_entry.sqf'
    entry.write_text(prefix+'''\n{
        missionNamespace setVariable ["ALSPMC_fnc_" + _x,
            ("addons/alspmc_core/functions/fn_" + _x + ".sqf") call TEST_fnc_load];
    } forEach ["contractBoss","stateSet"];
    call ("tests/baseline_063_review.sqf" call TEST_fnc_load);
    diag_log ("TEST_COMPLETE: " + str TEST_count + " assertions");
    ''')
    ok,output=run(args.vm,[*common,'--virtual',str(ROOT)+'|/','--virtual',str(ROOT/'addons/alspmc_core')+'|/alspmc_core','--virtual',str(args.lifesim)+'|/native','--input-config',str(config),'--input-config',str(ROOT/'tests/world_config.hpp'),'--input-sqf',str(entry)])
    (reports/'targeted-sqf.txt').write_text(output)
    match=re.search(r'TEST_COMPLETE: (\d+) assertions',output)
    report['targeted']={'passed':bool(ok and match),'assertions':int(match[1]) if match else 0}
    report['known_findings']={'property_cache_returns_newly_owned_building':'REVIEW_FINDING_CACHED_PROPERTY: true' in output}
    report['full_legacy_suite_port_pending']=True
    (reports/'targeted-checks.json').write_text(json.dumps(report,indent=2)+'\n')
    if not ok or not match:raise SystemExit(output[-6000:])
    print(f"Parsed {len(report['syntax'])} SQF functions; {match[1]} targeted assertions passed.")
    print('Known findings:',json.dumps(report['known_findings']))

if __name__=='__main__':main()
