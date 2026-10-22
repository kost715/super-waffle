#!/usr/bin/env python3
"""Parse all SQF and run baseline safety + persistent company/treasury scenarios.

Arma engine geometry, AI, CEF and RPC delivery remain modeled boundaries.
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
    p.add_argument("--transactions-only",action="store_true",help="Development probe: skip syntax pass")
    args=p.parse_args()
    reports=ROOT/'reports/stage1-0.7.1'
    reports.mkdir(parents=True,exist_ok=True)
    common=['--command-dummy-binary','4|ctrlWebBrowserAction','--command-dummy-unary','fromJSON','--command-dummy-unary','toJSON']
    config=ROOT/'addons/alspmc_core/config.cpp'
    report={'arma_runtime_tested':False,'scope':'baseline safety, M1 company transactions and 0.7.1 fixes','syntax':[]}
    for sqf in ([] if args.transactions_only else sorted((ROOT/'addons/alspmc_core/functions').glob('*.sqf'))):
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
    call ("tests/company_transactions.sqf" call TEST_fnc_load);
    call ("tests/fixes_071.sqf" call TEST_fnc_load);
    diag_log ("TEST_COMPLETE: " + str TEST_count + " assertions");
    ''')
    ok,output=run(args.vm,[*common,'--virtual',str(ROOT)+'|/','--virtual',str(ROOT/'addons/alspmc_core')+'|/alspmc_core','--virtual',str(args.lifesim)+'|/native','--input-config',str(config),'--input-config',str(ROOT/'tests/world_config.hpp'),'--input-sqf',str(entry)])
    (reports/'targeted-sqf.txt').write_text(output)
    match=re.search(r'TEST_COMPLETE: (\d+) assertions',output)
    report['targeted']={'passed':bool(ok and match),'assertions':int(match[1]) if match else 0}
    report['known_findings']={'property_cache_returns_newly_owned_building':False}
    for key in ['OWNER','MANAGER','MEMBER','INVITE']:
        marker='TEST_COMPANY_'+key+'_STATE: '
        rows=[json.loads(line.split(marker,1)[1]) for line in output.splitlines() if marker in line]
        (reports/('company-'+key.lower()+'-state.json')).write_text(json.dumps(rows,indent=2)+'\n')
    report['full_legacy_suite_port_pending']=True
    (reports/'targeted-checks.json').write_text(json.dumps(report,indent=2)+'\n')
    if not ok or not match:raise SystemExit(output[-6000:])
    print(f"Parsed {len(report['syntax'])} SQF functions; {match[1]} targeted assertions passed.")
    print('Known findings:',json.dumps(report['known_findings']))

if __name__=='__main__':main()
