#!/usr/bin/env python3
"""Verify preserved history, release hashes, baseline and active Markdown links."""
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads((ROOT / 'archive/PRESERVATION.json').read_text())
    rows = manifest['files']
    assert len(rows) == manifest['files_preserved']
    assert len({row['original_path'] for row in rows}) == len(rows)
    assert len({row['archived_path'] for row in rows}) == len(rows)
    for row in rows:
        assert digest(ROOT / row['archived_path']) == row['sha256'], row['archived_path']

    release_files = 0
    archives = 0
    folders = ['archive/lifesim-pmc-unused/dist',
               'archive/standalone-planning-v1-unused/dist', 'standalone/dist']
    for folder in folders:
        base = ROOT / folder
        for line in (base / 'SHA256SUMS.txt').read_text().splitlines():
            expected, name = line.split('  ', 1)
            path = base / name
            assert digest(path) == expected, path
            release_files += 1
            if path.suffix == '.zip':
                with zipfile.ZipFile(path) as z:
                    assert z.testzip() is None, path
                archives += 1

    legacy = ROOT / 'archive/lifesim-pmc-unused'
    baseline = json.loads((legacy / 'BASELINE.json').read_text())
    assert digest(legacy / baseline['archive']) == baseline['archive_sha256']

    docs = [ROOT / 'README.md', ROOT / 'CHANGELOG.md', ROOT / 'standalone/README.md',
            ROOT / 'archive/README.md', ROOT / 'archive/lifesim-pmc-unused/STATUS_RU.md',
            ROOT / 'archive/standalone-planning-v1-unused/README.md']
    docs += list((ROOT / 'docs/standalone').rglob('*.md'))
    links = 0
    for source in docs:
        for target in re.findall(r'\]\(([^\s)]+)\)', source.read_text()):
            parsed = urlsplit(target)
            if parsed.scheme or target.startswith('#'):
                continue
            dest = source.parent / unquote(parsed.path)
            assert dest.exists(), f'{source.relative_to(ROOT)} -> {target}'
            links += 1

    print(json.dumps({'preserved_files': len(rows), 'release_files': release_files,
                      'zip_integrity_checks': archives, 'baseline_sha256_valid': True,
                      'active_document_links': links, 'arma_runtime_tested': False}, indent=2))


if __name__ == '__main__':
    main()
