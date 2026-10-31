#!/usr/bin/env python3
"""Parse every interactions SQF file and run its checks with SQF-VM.

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
ADDON = ROOT / "addons/pmc_interactions"
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
    shutil.copytree(ADDON, tree / "pmc_interactions")
    shutil.copytree(ROOT / "tests", tree / "tests")
    for path in (tree / "pmc_interactions").rglob("*"):
        if path.suffix in (".sqf", ".inc", ".hpp"):
            text = path.read_text(encoding="utf-8")
            text = re.sub(r'#include "([^"]+)"', lambda m: '#include "' + m[1].replace("\\", "/") + '"', text)
            path.write_text(text, encoding="utf-8")


def check_textures():
    """Every picture the addon names must be in data/ (Arma only shows an empty control)."""
    data = ADDON / "data"
    names = set()
    for path in ADDON.rglob("*"):
        if path.suffix in (".sqf", ".hpp", ".cpp"):
            text = path.read_text(encoding="utf-8")
            names |= {m for m in re.findall(r"\\pmc_interactions\\data\\([a-z0-9_]+_ca)\.paa", text)}
    look = (ADDON / "Board/fn_boardLook.sqf").read_text(encoding="utf-8")
    names |= {m + "_ca" for m in re.findall(r'"([a-z]+_[a-z0-9_]+)"', look)}
    names |= {f"tq_windlass_{k}_ca" for k in range(8)} | {f"bandage_gauze_{k}_ca" for k in range(1, 5)}
    names |= {f"dirt_{k}_ca" for k in range(1, 4)} | {f"weld_scene_{k}_ca" for k in range(1, 5)}
    names |= {f"icon_{g}_ca" for g in ("cpr", "tourniquet", "bandage", "pressure", "edges", "clean", "iv", "suture", "splint", "wheel",
                                         "diagnose", "weld", "track", "lockpick", "terminal", "safe")}
    names |= {f"icon_{a}_ca" for a in ("lock", "key", "keypad")}  # ACE actions of a locked box
    missing = sorted(n for n in names if not (data / f"{n}.paa").is_file())
    if missing:
        raise SystemExit(f"Textures missing from {data}: {', '.join(missing)}")
    return len(names)


def check_seams():
    """The cracks drawn on the hull plates (texture_scenes.WELD_SEAMS) must be the ones the
    game follows (PMCI_fnc_weldSeams)."""
    import ast
    source = (ROOT / "tools/texture_scenes.py").read_text(encoding="utf-8")
    node = next(n for n in ast.parse(source).body if isinstance(n, ast.Assign) and getattr(n.targets[0], "id", "") == "WELD_SEAMS")
    drawn = [[list(p) for p in seam] for seam in ast.literal_eval(node.value)]
    sqf = (ADDON / "Games/fn_weldSeams.sqf").read_text(encoding="utf-8")
    played = json.loads("".join(line for line in sqf.splitlines() if not line.lstrip().startswith("//")))
    if drawn != played:
        raise SystemExit("The weld cracks in tools/texture_scenes.py and Games/fn_weldSeams.sqf differ")
    return len(played)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--vm", type=Path, required=True)
    p.add_argument("--report", type=Path, help="write a JSON summary here")
    p.add_argument("--no-texture-check", action="store_true", help="skip the texture check (while drawing new ones)")
    args = p.parse_args()
    report = {"syntax": [], "arma_runtime_tested": False, "textures": 0 if args.no_texture_check else check_textures(),
              "weld_seams": check_seams()}
    with tempfile.TemporaryDirectory() as tmp:
        tree = Path(tmp)
        stage(tree)
        mount = ["--virtual", f"{tree}|/"]
        for sqf in sorted((tree / "pmc_interactions").rglob("*.sqf")):
            ok, output = run(args.vm, tree, [*mount, "--parse-only", "--input-sqf", str(sqf)])
            name = str(sqf.relative_to(tree))
            report["syntax"].append({"file": name, "passed": ok})
            if not ok:
                print(output)
                raise SystemExit(f"SQF syntax failure: {name}")
        # ACE stand-in classes first, then the addon's overrides of them.
        ok, output = run(args.vm, tree, [*mount, "--input-config", str(tree / "tests/fixture_config.hpp"),
                                         "--input-config", str(tree / "pmc_interactions/config.cpp"),
                                         "--input-sqf", str(tree / "tests/interactions.sqf")])
    print(output)
    match = re.search(r"TEST_COMPLETE: (\d+) assertions", output)
    report["server"] = {"passed": bool(ok and match), "assertions": int(match[1]) if match else 0}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    if not ok or not match:
        raise SystemExit("Interactions checks failed or did not complete")
    print(f"Parsed {len(report['syntax'])} SQF files; {match[1]} interaction assertions passed; "
          + (f"{report['textures']} textures referenced, all present." if report["textures"] else "texture check skipped."))


if __name__ == "__main__":
    main()
