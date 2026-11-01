#!/usr/bin/env python3
"""Parse every PMC Drugs SQF file and run its checks with SQF-VM.

SQF-VM does not resolve backslash include paths, so the addon is copied to a
temporary tree with forward-slash includes. The shipped files are not changed.
"""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons/pmc_drugs"
DUMMIES = ["--command-dummy-unary", "modParams"]


def run(vm, cwd, args):
    result = subprocess.run([str(vm), "-a", "--suppress-welcome", "--no-execute-print", "--no-work-print",
                             "--max-runtime", "60000", *DUMMIES, *args],
                            cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
    # SQF-VM sometimes exits 0 on a VM error. Never use status alone as proof.
    bad = result.returncode != 0 or re.search(
        r"\[(?:ERR|FAT)\]|TEST_FAIL|NOT IMPLEMENTED|could not be located|Failed to include", result.stdout)
    return not bad, result.stdout


def stage(tree):
    shutil.copytree(ADDON, tree / "pmc_drugs")
    shutil.copytree(ROOT / "tests", tree / "tests")
    for path in (tree / "pmc_drugs").rglob("*"):
        if path.suffix in (".sqf", ".inc", ".hpp"):
            text = path.read_text(encoding="utf-8")
            text = re.sub(r'#include "([^"]+)"', lambda m: '#include "' + m[1].replace("\\", "/") + '"', text)
            path.write_text(text, encoding="utf-8")


def check_files():
    """Every picture or model the addon names must be in the addon (Arma shows nothing otherwise)."""
    names = set()
    for path in ADDON.rglob("*"):
        if path.suffix in (".sqf", ".hpp", ".cpp"):
            names |= set(re.findall(r"\\pmc_drugs\\(data\\[A-Za-z0-9_]+\.(?:paa|p3d))", path.read_text(encoding="utf-8")))
    for p3d in (ADDON / "data").glob("*.p3d"):
        names |= {m.decode().split("pmc_drugs\\", 1)[1] for m in re.findall(rb"pmc_drugs\\data\\[a-z0-9_]+\.paa", p3d.read_bytes())}
    missing = sorted(n for n in names if not (ADDON / n.replace("\\", "/")).is_file())
    if missing:
        raise SystemExit(f"Files missing from the addon: {', '.join(missing)}")
    return len(names)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--vm", type=Path, required=True)
    p.add_argument("--report", type=Path, help="write a JSON summary here")
    args = p.parse_args()
    report = {"syntax": [], "arma_runtime_tested": False, "files": check_files()}
    with tempfile.TemporaryDirectory() as tmp:
        tree = Path(tmp)
        stage(tree)
        mount = ["--virtual", f"{tree}|/"]
        for sqf in sorted((tree / "pmc_drugs").rglob("*.sqf")):
            ok, output = run(args.vm, tree, [*mount, "--parse-only", "--input-sqf", str(sqf)])
            name = str(sqf.relative_to(tree))
            report["syntax"].append({"file": name, "passed": ok})
            if not ok:
                print(output)
                raise SystemExit(f"SQF syntax failure: {name}")
        # ACE stand-in classes first, then the addon's overrides of them.
        ok, output = run(args.vm, tree, [*mount, "--input-config", str(tree / "tests/fixture_config.hpp"),
                                         "--input-config", str(tree / "pmc_drugs/config.cpp"),
                                         "--input-sqf", str(tree / "tests/drugs.sqf")])
    print(output)
    match = re.search(r"TEST_COMPLETE: (\d+) assertions", output)
    report["server"] = {"passed": bool(ok and match), "assertions": int(match[1]) if match else 0}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    if not ok or not match:
        raise SystemExit("Drugs checks failed or did not complete")
    print(f"Parsed {len(report['syntax'])} SQF files; {match[1]} drug assertions passed; {report['files']} data files named, all present.")


if __name__ == "__main__":
    main()
