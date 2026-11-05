#!/usr/bin/env python3
"""Builds the PMC Shop catalog (addons/pmc_shop/catalog.hpp) from the item table.

source/items.xlsx  sheet "Оружие"  (weapons: name, category, calibre, classes, state, ..., price)
                   sheet "Патроны" (one row per calibre and magazine: base price of one
                   magazine, then a class per ammo type; each type column's header carries
                   its price factor, e.g. "Trace price x1.1")

Only weapons in the state "базовый" go on sale. A weapon's price is one piece in a box; a
magazine row's price is one magazine of the first type (factor x1), the other types cost
price x factor. Box sizes and single-piece surcharges are the mod's CBA settings. Rows
without a price are written with price 0: the shop hides them until a Zeus sets one.
Every doubtful entry is reported and left out.
Usage: python3 tools/make_catalog.py [--check]   (--check: fail if catalog.hpp is stale)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "addons" / "pmc_shop" / "catalog.hpp"

# Weapon categories of the item table, spelled as they are there, folded to one spelling.
CATEGORY_FOLD = {"лёгкий пулемет": "легкий пулемет", "гранатомёт": "гранатомет", "ружье": "дробовик"}
CATEGORY_LABELS = {
    "штурмовая винтовка": "Штурмовые винтовки", "легкий пулемет": "Лёгкие пулемёты", "единый пулемет": "Единые пулемёты",
    "пехотная винтовка": "Пехотные винтовки", "dmr": "DMR", "снайперская винтовка": "Снайперские винтовки",
    "гранатомет": "Гранатомёты", "одноразовый гранатомет": "Одноразовые гранатомёты", "pdw": "PDW",
    "дробовик": "Ружья и дробовики",
}
AMMO_TYPES = ["Ball", "Trace", "EPR", "EPT", "AP", "special"]
# Entries the user asked to leave out until they are clarified.
DROP_CLASSES: set[str] = set()
CLASS_RE = re.compile(r"^[A-Za-z0-9_*]+$")


def text(value) -> str:
    return "" if value is None else str(value).strip()


def cfg(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def number(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else f"{value:g}"


def key_of(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "X", name)


def magazine_label(raw: str) -> str:
    return re.sub(r"^(\d+)rnd\s*", r"\1 патр. ", raw).strip()


def price_of(value, what: str, warnings: list[str]) -> int:
    if isinstance(value, (int, float)) and value > 0:
        return int(round(value))
    warnings.append(f"{what}: no price, hidden until a Zeus sets one")
    return 0


def build() -> tuple[str, list[str]]:
    warnings: list[str] = []
    book = openpyxl.load_workbook(ROOT / "source" / "items.xlsx", data_only=True)

    weapons = []
    keys: set[str] = set()
    sheet = book["Оружие"]
    header = [text(v).lower() for v in next(sheet.iter_rows(max_row=1, values_only=True))]
    price_col = header.index("цена")
    for row in sheet.iter_rows(min_row=2, values_only=True):
        name, category, calibre, classes, state = (text(v) for v in row[:5])
        if not name or state != "базовый":
            continue
        category = CATEGORY_FOLD.get(category.lower(), category.lower())
        if category not in CATEGORY_LABELS:
            warnings.append(f"weapon {name}: category {category!r} has no label, shown as it is")
        variants = []
        for c in (c.strip() for c in classes.split(",")):
            if not c:
                continue
            if not CLASS_RE.match(c) or c in DROP_CLASSES:
                warnings.append(f"weapon {name}: class {c!r} left out")
                continue
            variants.append(c)
        if not variants:
            warnings.append(f"weapon {name}: no usable class, left out")
            continue
        key = key_of(next((v for v in variants if "*" not in v), variants[0]))
        if key in keys:
            warnings.append(f"weapon {name}: duplicate key {key}, left out")
            continue
        keys.add(key)
        weapons.append((key, name, category, calibre, price_of(row[price_col], f"weapon {name}", warnings), variants))

    # Ammunition: one row per calibre and magazine; the type columns' headers carry the factor.
    sheet = book["Патроны"]
    header = [text(v) for v in next(sheet.iter_rows(max_row=1, values_only=True))]
    factors = []
    for ammo, title in zip(AMMO_TYPES, header[3:9]):
        found = re.search(r"x\s*([0-9]+(?:[.,][0-9]+)?)", title)
        if not title.lower().startswith(ammo.lower()) or not found:
            raise SystemExit(f"Патроны: column {title!r} should be '{ammo} price x<factor>'")
        factors.append(float(found[1].replace(",", ".")))
    magazines = []
    mag_classes: set[str] = set()
    calibres_used = {w[3] for w in weapons}
    for row in sheet.iter_rows(min_row=2, values_only=True):
        calibre, label = text(row[0]), text(row[1])
        if not calibre:
            continue
        what = f"magazines {calibre} / {label}"
        types = []
        for ammo, factor, cls in zip(AMMO_TYPES, factors, (text(v) for v in row[3:9])):
            if cls in ("", "NA"):
                continue
            if not CLASS_RE.match(cls) or "*" in cls or cls in DROP_CLASSES or "_" not in cls:
                warnings.append(f"{what} / {ammo}: class {cls!r} left out")
                continue
            if cls in mag_classes:
                warnings.append(f"{what} / {ammo}: {cls} listed twice, left out")
                continue
            mag_classes.add(cls)
            types.append((ammo, factor, cls))
        if not types:
            warnings.append(f"{what}: no usable class, left out")
            continue
        if calibre not in calibres_used:
            warnings.append(f"{what}: no weapon on sale with this calibre")
        magazines.append((key_of(types[0][2]), calibre, magazine_label(label), price_of(row[2], what, warnings), types))
    for w in weapons:
        if not any(m[1] == w[3] for m in magazines) and w[2] != "одноразовый гранатомет":
            warnings.append(f"weapon {w[1]}: no magazines for calibre {w[3]!r}")

    lines = [
        "// Generated by tools/make_catalog.py from source/items.xlsx.",
        "// Do not edit by hand: edit the table and run the script again.",
        "class CfgPMCShop {",
        "    class Categories {",
    ]
    for i, (key, label) in enumerate(CATEGORY_LABELS.items()):
        lines.append(f"        class {key_of(key) if key.isascii() else 'c' + str(i)} {{source = {cfg(key)}; name = {cfg(label)};}};")
    lines += ["    };", "    class Weapons {"]
    for key, name, category, calibre, price, variants in weapons:
        classes = ", ".join(cfg(v) for v in variants)
        lines.append(f"        class {key} {{name = {cfg(name)}; category = {cfg(category)}; caliber = {cfg(calibre)}; "
                     f"price = {price}; classes[] = {{{classes}}};}};")
    lines += ["    };", "    class Magazines {"]
    for key, calibre, label, price, types in magazines:
        listed = ", ".join(f"{{{cfg(a)}, {number(f)}, {cfg(c)}}}" for a, f, c in types)
        lines.append(f"        class {key} {{caliber = {cfg(calibre)}; magazine = {cfg(label)}; price = {price}; types[] = {{{listed}}};}};")
    lines += ["    };", "};", ""]
    return "\n".join(lines), warnings


def main() -> None:
    catalog, warnings = build()
    for w in warnings:
        print("WARN", w)
    if "--check" in sys.argv:
        if not OUT.is_file() or OUT.read_text(encoding="utf-8") != catalog:
            raise SystemExit("catalog.hpp is stale: run python3 tools/make_catalog.py")
        print("catalog.hpp is up to date")
        return
    OUT.write_text(catalog, encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {catalog.count('classes[]')} weapons, {catalog.count('types[]')} magazine rows, "
          f"{len(warnings)} warnings")


if __name__ == "__main__":
    main()
