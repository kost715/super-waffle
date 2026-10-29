#!/usr/bin/env python3
"""Reproducible, standard-library-only PBO and ZIP builder for PMC Interactions."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.5.0_alpha1"
MOD = "@PMC_Interactions"
PREFIX = "pmc_interactions"
STAMP = (2026, 10, 30, 12, 0, 0)


def pack_pbo(files: dict[str, bytes], prefix: str) -> bytes:
    header = bytearray(b"\0" + struct.pack("<5I", 0x56657273, 0, 0, 0, 0))
    header.extend(b"prefix\0" + prefix.encode("ascii") + b"\0\0")
    for name, data in files.items():
        header.extend(name.encode("ascii") + b"\0")
        header.extend(struct.pack("<5I", 0, len(data), 0, 0, len(data)))
    header.extend(b"\0" + bytes(20))
    blob = bytes(header) + b"".join(files.values())
    return blob + b"\0" + hashlib.sha1(blob).digest()


def write_zip(path: Path, files: dict[str, bytes]) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, STAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)


def main() -> None:
    source = ROOT / "addons" / PREFIX
    files = {
        str(p.relative_to(source)).replace("/", "\\"): p.read_bytes()
        for p in sorted(source.rglob("*")) if p.is_file()
    }
    pbo = pack_pbo(files, PREFIX)
    build = ROOT / "build" / MOD
    (build / "addons").mkdir(parents=True, exist_ok=True)
    (build / "addons" / f"{PREFIX}.pbo").write_bytes(pbo)
    package = {f"{MOD}/addons/{PREFIX}.pbo": pbo}
    for name in ["mod.cpp", "README_RU.md", "LICENSE", "CHANGELOG.md"]:
        data = (ROOT / name).read_bytes()
        (build / name).parent.mkdir(parents=True, exist_ok=True)
        (build / name).write_bytes(data)
        package[f"{MOD}/{name}"] = data
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    ready = dist / f"PMC_Interactions_{VERSION}.zip"
    write_zip(ready, package)
    source_files = {}
    for folder in ["addons", "tools", "tests"]:
        for p in sorted((ROOT / folder).rglob("*")):
            if p.is_file() and "__pycache__" not in p.parts and ".cache" not in p.parts:
                source_files[f"PMC_Interactions_sources/{p.relative_to(ROOT).as_posix()}"] = p.read_bytes()
    for name in ["mod.cpp", "README_RU.md", "LICENSE", "CHANGELOG.md", ".gitignore"]:
        source_files[f"PMC_Interactions_sources/{name}"] = (ROOT / name).read_bytes()
    sources = dist / f"PMC_Interactions_{VERSION}_sources.zip"
    write_zip(sources, source_files)
    report = {
        "version": VERSION,
        "pbo_files": len(files),
        "prefix": PREFIX,
        "pbo_sha256": hashlib.sha256(pbo).hexdigest(),
        "archives": {p.name: {"size": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                     for p in [ready, sources]},
        "arma_runtime_tested": False,
    }
    (dist / "SHA256SUMS.txt").write_text("".join(
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n"
        for p in sorted(dist.iterdir()) if p.suffix == ".zip"
    ))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
