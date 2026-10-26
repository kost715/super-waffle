#!/usr/bin/env python3
"""Parse shipped SQF/config and execute transaction fixtures with SQF-VM."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def run(vm, args):
    result = subprocess.run([str(vm), "-a", "--suppress-welcome", "--no-execute-print",
                             "--no-work-print", "--max-runtime", "30000", *args],
                            cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=45)
    # SQF-VM sometimes exits 0 on a VM error. Never use status alone as proof.
    bad = result.returncode != 0 or re.search(r"\[(?:ERR|FAT)\]|TEST_FAIL|NOT IMPLEMENTED|File '.+' could not be located", result.stdout)
    return not bad, result.stdout


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--vm", type=Path, required=True)
    p.add_argument("--lifesim", type=Path, required=True)
    args = p.parse_args()
    config = ROOT / "addons/alspmc_core/config.cpp"
    common = ["--command-dummy-binary", "4|ctrlWebBrowserAction",
              "--command-dummy-unary", "fromJSON", "--command-dummy-unary", "toJSON"]
    report = {"syntax": [], "arma_runtime_tested": False}
    for sqf in sorted((ROOT / "addons/alspmc_core/functions").glob("*.sqf")):
        ok, output = run(args.vm, [*common, "--parse-only", "--input-config", str(config),
                                   "--input-sqf", str(sqf)])
        report["syntax"].append({"file": sqf.name, "passed": ok})
        if not ok:
            print(output)
            raise SystemExit(f"SQF syntax failure: {sqf.name}")
    # Fixture vehicle classes allow object lifecycle assertions without assets.
    # Native functions are supplied from the user's unmodified files.
    ok, output = run(args.vm, [*common, "--virtual", f"{ROOT}|/", "--virtual", f"{ROOT / 'addons/alspmc_core'}|/alspmc_core", "--virtual", f"{args.lifesim}|/native",
                               "--input-config", str(config), "--input-config", str(ROOT / "tests/world_config.hpp"),
                               "--input-sqf", str(ROOT / "tests/transactions.sqf")])
    print(output)
    match = re.search(r"TEST_COMPLETE: (\d+) assertions", output)
    report["transactions"] = {"passed": bool(ok and match), "assertions": int(match[1]) if match else 0}
    report["compatibility_shims"] = ["isServer", "hasInterface", "isRemoteExecuted", "remoteExecutedOwner",
                                      "getOrDefault", "hashmap toArray", "hashmap forEach", "hashmap values", "remoteExec",
                                      "remoteExecCall", "publicVariable", "setVariable public flag", "getVariable default after nil removal", "isPlayer", "owner", "localize", "mapGridPosition", "toArray signed char", "saveProfileNamespace",
                                      "createVehicle array signature", "boundingBoxReal fixture", "enableSimulationGlobal",
                                      "allowDamage", "setPosASL flat fixture world", "setDir",
                                      "fromJSON packet lookup", "toJSON fixture serializer", "ctrlWebBrowserAction capture",
                                      "addPublicVariableEventHandler fixture", "date/daytime/serverTime fixture",
                                      "getPosATL flat fixture", "vehicle on-foot fixture", "allPlayers/entities/items fixture",
                                      "objectParent/customWaypointPosition fixture", "trim", "typeOf/configOf fixture",
                                      "fuel/getPlateNumber fixture"]
    report["compatibility_shims"] += ["createGroup/createUnit fixture", "AI skill/behaviour/combat/path/rating fixture",
                                       "EntityKilled registration/delivery fixture", "array insert", "worldSize/getPos polar/nearestObjects flat-world fixture",
                                       "directed getFriend/setFriend and createCenter fixture", "group membership and rating-handler fixture",
                                       "uniform dressing fixture", "toLowerANSI adapter"]
    reports = ROOT / "reports"
    reports.mkdir(exist_ok=True)
    (reports / "sqf-run.txt").write_text(output)
    (reports / "sqf-checks.json").write_text(json.dumps(report, indent=2) + "\n")
    states = [json.loads(line.split("TEST_PHONE_STATE: ",1)[1]) for line in output.splitlines()
              if "TEST_PHONE_STATE: " in line]
    (reports / "native-phone-states.json").write_text(json.dumps(states,indent=2)+"\n")
    contracts = [json.loads(line.split("TEST_CONTRACT_STATE: ",1)[1]) for line in output.splitlines()
                 if "TEST_CONTRACT_STATE: " in line]
    (reports / "contract-phone-states.json").write_text(json.dumps(contracts,indent=2)+"\n")
    patrol = [json.loads(line.split("TEST_PATROL_STATE: ",1)[1]) for line in output.splitlines()
              if "TEST_PATROL_STATE: " in line]
    (reports / "patrol-phone-states.json").write_text(json.dumps(patrol,indent=2)+"\n")
    if not ok or not match:
        raise SystemExit("SQF transaction checks failed or did not complete")
    print(f"Parsed {len(report['syntax'])} SQF files; {match[1]} transaction assertions passed.")


if __name__ == "__main__":
    main()
