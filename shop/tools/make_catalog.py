#!/usr/bin/env python3
"""Builds the PMC Shop catalog (addons/pmc_shop/catalog.hpp) from the item tables.

source/items.xlsx   sheets "Оружие" (weapons) and "Патроны" (magazines by calibre)
source/prices.xlsx  sheet "Прайс по классам" (price per unit and per box by weapon type)

Only weapons in the state "базовый" go on sale. A weapon's price comes from its type in
the price list; types without a price there are left without one (the shop hides them
until a Zeus sets a price on the market laptop). Magazines have no prices in the tables
yet: they are hidden the same way. Every doubtful entry is reported and left out.
Usage: python3 tools/make_catalog.py [--check]   (--check: fail if catalog.hpp is stale)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "addons" / "pmc_shop" / "catalog.hpp"

# Price list rows -> keys used in the config.
PRICE_KEYS = {
    "Автомат": "assault",
    "Пистолет": "pistol",
    "Пистолет-пулемёт": "smg",
    "Болтовая винтовка": "bolt",
    "Полуавтоматическая винтовка (промежуточный калибр)": "semi_int",
    "Полуавтоматическая винтовка (винтовочный калибр)": "semi_full",
    "Пулемёт": "mg",
    "Гранатомёт": "launcher",
    "Гранаты": "grenade",
    "Дымовые гранаты": "smoke",
    "Мины противопехотные": "mine_ap",
    "Мины противотанковые": "mine_at",
    "Мины направленного действия": "mine_dir",
    "Мины с дистанционным подрывом": "mine_rc",
    "Одноразовые гранатомёты": "launcher_once",
}
# Short names of the price types as the shop shows them.
PRICE_LABELS = {
    "assault": "Автомат", "pistol": "Пистолет", "smg": "Пистолет-пулемёт", "bolt": "Болтовая винтовка",
    "semi_int": "Полуавтомат (промежуточный)", "semi_full": "Полуавтомат (винтовочный)", "mg": "Пулемёт",
    "launcher": "Гранатомёт", "grenade": "Гранаты", "smoke": "Дымовые гранаты", "mine_ap": "Мины ПП",
    "mine_at": "Мины ПТ", "mine_dir": "Мины направленного действия", "mine_rc": "Мины с дист. подрывом",
    "launcher_once": "Одноразовый гранатомёт",
}
# Weapon categories of the item table, spelled as they are there, folded to one spelling.
CATEGORY_FOLD = {"лёгкий пулемет": "легкий пулемет", "гранатомёт": "гранатомет", "ружье": "дробовик"}
CATEGORY_LABELS = {
    "штурмовая винтовка": "Штурмовые винтовки", "легкий пулемет": "Лёгкие пулемёты", "единый пулемет": "Единые пулемёты",
    "пехотная винтовка": "Пехотные винтовки", "dmr": "DMR", "снайперская винтовка": "Снайперские винтовки",
    "гранатомет": "Гранатомёты", "одноразовый гранатомет": "Одноразовые гранатомёты", "pdw": "PDW",
    "дробовик": "Ружья и дробовики",
}
INTERMEDIATE = ("5.45", "5.56", "7.62x39", "4.6x30", "9x39")
AMMO_TYPES = ["Ball", "Trace", "EPR", "EPT", "AP", "special"]
# Entries the user asked to leave out until they are clarified.
DROP_CLASSES = {"10Rnd_762x54_Mag"}
CLASS_RE = re.compile(r"^[A-Za-z0-9_*]+$")


def price_type(category: str, calibre: str) -> str:
    if category == "штурмовая винтовка":
        return "assault"
    if category in ("легкий пулемет", "единый пулемет"):
        return "mg"
    if category in ("dmr", "пехотная винтовка"):
        return "semi_int" if calibre.startswith(INTERMEDIATE) else "semi_full"
    if category == "снайперская винтовка":
        return "bolt"
    if category in ("гранатомет", "ручной гранатомет"):
        return "launcher"
    if category == "одноразовый гранатомет":
        return "launcher_once"
    if category == "pdw":
        return "smg"
    return ""


def text(value) -> str:
    return "" if value is None else str(value).strip()


def cfg(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def key_of(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "X", name)


def magazine_label(raw: str) -> str:
    return re.sub(r"^(\d+)rnd\s*", r"\1 патр. ", raw).strip()


def build() -> tuple[str, list[str]]:
    warnings: list[str] = []
    prices = openpyxl.load_workbook(ROOT / "source" / "prices.xlsx", data_only=True)["Прайс по классам"]
    types: dict[str, tuple[int, int, int, float]] = {}
    for row in prices.iter_rows(min_row=5, values_only=True):
        name = text(row[0])
        if name in PRICE_KEYS and isinstance(row[1], (int, float)) and isinstance(row[3], (int, float)):
            types[PRICE_KEYS[name]] = (int(row[1]), int(row[3]), int(row[2]), float(row[4] or 0))
    discounts = {round(v[3] * 100) for v in types.values()}
    if len(discounts) != 1:
        warnings.append(f"price list: box discounts differ {sorted(discounts)}; the shop uses one, the largest")
    box_discount = max(discounts) if discounts else 25

    book = openpyxl.load_workbook(ROOT / "source" / "items.xlsx", data_only=True)
    weapons = []
    keys: set[str] = set()
    for row in book["Оружие"].iter_rows(min_row=2, values_only=True):
        name, category, calibre, classes, state = (text(v) for v in row[:5])
        if not name or state != "базовый":
            continue
        category = CATEGORY_FOLD.get(category.lower(), category.lower())
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
        ptype = price_type(category, calibre)
        if ptype == "":
            warnings.append(f"weapon {name} ({category}): no type in the price list, left without a price")
        elif ptype not in types:
            warnings.append(f"weapon {name}: price type {ptype} missing from the price list")
        key = key_of(next((v for v in variants if "*" not in v), variants[0]))
        if key in keys:
            warnings.append(f"weapon {name}: duplicate key {key}, left out")
            continue
        keys.add(key)
        weapons.append((key, name, category, calibre, ptype, variants))

    magazines = []
    mag_keys: set[str] = set()
    calibres_used = {w[3] for w in weapons}
    for row in book["Патроны"].iter_rows(min_row=2, values_only=True):
        calibre, label = text(row[0]), text(row[1])
        if not calibre:
            continue
        if calibre not in calibres_used:
            warnings.append(f"magazines {calibre} / {label}: no weapon on sale with this calibre")
        for ammo, cls in zip(AMMO_TYPES, (text(v) for v in row[2:8])):
            if cls in ("", "NA"):
                continue
            if not CLASS_RE.match(cls) or "*" in cls or cls in DROP_CLASSES:
                warnings.append(f"magazines {calibre} / {label} / {ammo}: class {cls!r} left out")
                continue
            if cls in mag_keys:
                warnings.append(f"magazines {calibre} / {label} / {ammo}: {cls} listed twice, left out")
                continue
            mag_keys.add(cls)
            magazines.append((cls, calibre, magazine_label(label), ammo))
    for w in weapons:
        if not any(m[1] == w[3] for m in magazines) and w[4] != "launcher_once":
            warnings.append(f"weapon {w[1]}: no magazines for calibre {w[3]!r}")

    lines = [
        "// Generated by tools/make_catalog.py from source/items.xlsx and source/prices.xlsx.",
        "// Do not edit by hand: edit the tables and run the script again.",
        "class CfgPMCShop {",
        f"    boxDiscount = {box_discount};",
        "    class PriceTypes {",
    ]
    for key, (units, unit, box, _disc) in types.items():
        lines.append(f"        class {key} {{name = {cfg(PRICE_LABELS[key])}; unitPrice = {unit}; boxUnits = {units}; boxPrice = {box};}};")
    lines += ["    };", "    class Categories {"]
    for key, label in CATEGORY_LABELS.items():
        lines.append(f"        class {key_of(key) if key.isascii() else 'c' + str(list(CATEGORY_LABELS).index(key))} {{source = {cfg(key)}; name = {cfg(label)};}};")
    lines += ["    };", "    class Weapons {"]
    for key, name, category, calibre, ptype, variants in weapons:
        classes = ", ".join(cfg(v) for v in variants)
        lines.append(f"        class {key} {{name = {cfg(name)}; category = {cfg(category)}; caliber = {cfg(calibre)}; "
                     f"priceType = {cfg(ptype)}; classes[] = {{{classes}}};}};")
    lines += ["    };", "    class Magazines {"]
    for cls, calibre, label, ammo in magazines:
        lines.append(f"        class {cls} {{caliber = {cfg(calibre)}; magazine = {cfg(label)}; ammo = {cfg(ammo)}; price = 0;}};")
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
    print(f"wrote {OUT.relative_to(ROOT)}: {catalog.count('classes[]')} weapons, {catalog.count('price = 0')} magazines, {len(warnings)} warnings")


if __name__ == "__main__":
    main()
