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
Every doubtful entry is reported and left out. Items of the MMM mod (classes "MMM_...")
are left out everywhere: weapons, magazines, upgrades. Single-use launchers have no
ammunition, so they get no calibre (no calibre filter row, no ammunition block).

source/upgrades.xlsx  the gunsmith's upgrades ("Техник"): one row per arrow of the upgrade
                   tree (built here from the weapons sheet's grenade launcher and upgrade
                   columns), with its cost in money and weapon parts (low, medium, high).
                   Rows are matched by the hidden "Ключ" column; an arrow without a cost
                   is not offered.
source/gear_upgrades.xlsx  the same for equipment: the vest tree of the sheet "Жилеты" (a
                   family's base vest -> its role versions, and a version -> the same with a
                   belt from the "добавление пояса" rows), costs in money, warbelts, old
                   uniforms and an item named by the table (6Sh92, 6Sh48).
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
SINGLE_USE = "одноразовый гранатомет"


def is_mmm(cls: str) -> bool:
    return cls.strip().lower().startswith("mmm_")


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


NOPE = {"", "na", "невозможно", "гп не совместим", "уже установлен", "установка гп-25 невозможна"}


def norm(s: str) -> str:
    return re.sub(r"\s+", "", s.lower())


def upgrade_edges(sheet, warnings: list[str]) -> list[dict]:
    """The arrows of the upgrade tree: [{from, to, kind, op, pairs, key}], where pairs maps
    each class (or MMM pattern) of the source to the class (or pattern) it becomes."""
    rows = []
    for row in sheet.iter_rows(min_row=2, values_only=True):
        r = [text(v) for v in row[:9]]
        if r[0]:
            rows.append(dict(name=r[0], classes=[c.strip() for c in r[3].split(",") if c.strip() and not is_mmm(c)], gl=(r[5], r[6]), up=(r[7], r[8])))
    by_class = {}
    for i, n in enumerate(rows):
        for c in n["classes"]:
            by_class.setdefault(c.lower(), i)
    by_name = {norm(n["name"]): i for i, n in enumerate(rows)}
    edges = []
    for n in rows:
        if not n["classes"]:
            continue
        for kind, (name, cell) in (("gl", n["gl"]), ("up", n["up"])):
            if name.lower() in NOPE and cell.upper() in ("", "NA"):
                continue
            explicit, bare = [], []
            for part in (p.strip() for p in cell.split(",")):
                if not part or part.upper() == "NA" or is_mmm(part):
                    continue
                if "->" in part:
                    a, b = (x.strip() for x in part.split("->", 1))
                    explicit.append((a, b))
                else:
                    bare.append(part)
            target = None
            for t in [b for _, b in explicit] + bare:
                if t.lower() in by_class:
                    target = rows[by_class[t.lower()]]; break
                if norm(t) in by_name:
                    target = rows[by_name[norm(t)]]; break
            if target is None and not explicit and not bare and norm(name) in by_name:
                target = rows[by_name[norm(name)]]
            names = {norm(t) for t in bare}
            classes = [t for t in bare if norm(t) not in by_name or t.lower() in by_class]
            if target is not None and not target["classes"]:
                continue
            if target is not None:
                to_classes = target["classes"]
                to_name = target["name"]
            elif explicit or classes:
                to_classes = [b for _, b in explicit] + classes
                looks = name.lower().startswith(n["name"].split()[0].lower())
                to_name = name if looks else to_classes[0]
            else:
                warnings.append(f"upgrade {n['name']}: {name!r} / {cell!r} leads nowhere, left out")
                continue
            # Which source class becomes which: the table's "a -> b" first, then the source's
            # remaining classes in order against the target's remaining ones; a target with one
            # class takes them all.
            pairs = list(explicit)
            done = {a.lower() for a, _ in pairs}
            left = [c for c in to_classes if c.lower() not in {b.lower() for _, b in pairs}]
            for c in n["classes"]:
                if c.lower() in done:
                    continue
                if len(to_classes) == 1:
                    pairs.append((c, to_classes[0]))
                elif left:
                    pairs.append((c, left.pop(0)))
                else:
                    warnings.append(f"upgrade {n['name']} -> {to_name}: no target class for {c}, left out")
            if not pairs:
                continue
            label = name if norm(name) != norm(to_name) and name.lower() not in NOPE else ""
            key = re.sub(r"[^A-Za-z0-9_\-.~:@+]", "x", n["classes"][0] + "__" + to_classes[0])
            edges.append(dict(src=n["name"], dst=to_name, kind=kind, op=label or to_name, pairs=pairs, key=key))
    return edges


GEAR_ROLES = ["Base", "RFL", "RFL_GL", "MG", "MDC", "LDR", "ENG"]


def gear_edges(sheet, warnings: list[str]) -> dict[str, tuple]:
    """The vest tree: key -> (source class, target class, kind "role" | "belt")."""
    head = [text(v) for v in next(sheet.iter_rows(max_row=1, values_only=True))]
    col = {h: i for i, h in enumerate(head)}
    rows = [r for r in sheet.iter_rows(min_row=2, values_only=True) if text(r[0])]
    cls = lambda r, k: "" if text(r[col[k]]).upper() in ("", "NA") else text(r[col[k]])
    for r in rows:
        for k in GEAR_ROLES:
            raw = r[col[k]]
            if isinstance(raw, str) and raw != raw.strip() and raw.strip():
                warnings.append(f"vest {text(r[0])} / {k}: class {raw!r} has spaces around it, read as {raw.strip()!r}")
    edges = {}
    by_family = {text(r[0]): r for r in rows}
    for r in rows:
        if text(r[1]).lower() == "добавление пояса":
            parent = next((by_family[f] for f, p in by_family.items() if text(p[col["add_belt"]]) == text(r[0])), None)
            if parent is None:
                warnings.append(f"vest {text(r[0])}: no row names it in add_belt, left out")
                continue
            for k in GEAR_ROLES:
                if cls(r, k) and cls(parent, k):
                    edges[key_of(cls(parent, k) + "__" + cls(r, k))] = (cls(parent, k), cls(r, k), "belt")
        elif cls(r, "Base"):
            for k in GEAR_ROLES[1:]:
                if cls(r, k):
                    edges[key_of(cls(r, "Base") + "__" + cls(r, k))] = (cls(r, "Base"), cls(r, k), "role")
    return edges


def build() -> tuple[str, list[str]]:
    warnings: list[str] = []
    book = openpyxl.load_workbook(ROOT / "source" / "items.xlsx", data_only=True)

    weapons = []
    keys: set[str] = set()
    dropped_mmm: set[str] = set()
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
            if is_mmm(c):
                dropped_mmm.add(c)
                continue
            if not CLASS_RE.match(c) or c in DROP_CLASSES:
                warnings.append(f"weapon {name}: class {c!r} left out")
                continue
            variants.append(c)
        if not variants:
            warnings.append(f"weapon {name}: no usable class (MMM left out), not on sale")
            continue
        if category == SINGLE_USE:
            calibre = ""
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
            if is_mmm(cls):
                dropped_mmm.add(cls)
                continue
            if not CLASS_RE.match(cls) or "*" in cls or cls in DROP_CLASSES:
                warnings.append(f"{what} / {ammo}: class {cls!r} left out")
                continue
            if cls in mag_classes:
                warnings.append(f"{what} / {ammo}: {cls} listed twice, left out")
                continue
            mag_classes.add(cls)
            types.append((ammo, factor, cls))
        if not types:
            warnings.append(f"{what}: no usable class (MMM left out), not on sale")
            continue
        if calibre not in calibres_used:
            warnings.append(f"{what}: no weapon on sale with this calibre")
        magazines.append((key_of(types[0][2]), calibre, magazine_label(label), price_of(row[2], what, warnings), types))
    for w in weapons:
        if not any(m[1] == w[3] for m in magazines) and w[2] != SINGLE_USE:
            warnings.append(f"weapon {w[1]}: no magazines for calibre {w[3]!r}")
    if dropped_mmm:
        warnings.append(f"{len(dropped_mmm)} MMM classes left out of the shop")

    # The gunsmith's upgrades and their costs.
    edges = upgrade_edges(book["Оружие"], warnings)
    costs = {}
    up_book = openpyxl.load_workbook(ROOT / "source" / "upgrades.xlsx", data_only=True)
    sheet = up_book["Стоимость улучшений"]
    head = [text(v) for v in next(sheet.iter_rows(max_row=1, values_only=True))]
    col = {h: i for i, h in enumerate(head)}
    for row in sheet.iter_rows(min_row=2, values_only=True):
        key = text(row[col["Ключ"]])
        vals = [row[col[h]] for h in ("Деньги, $", "Детали низ.", "Детали сред.", "Детали выс.")]
        if key and any(isinstance(v, (int, float)) for v in vals):
            costs[key] = [int(v) if isinstance(v, (int, float)) and v >= 0 else 0 for v in vals]
    upgrades = []
    for e in edges:
        if e["key"] not in costs:
            warnings.append(f"upgrade {e['src']} -> {e['dst']}: no cost in upgrades.xlsx, not offered")
            continue
        upgrades.append((e, costs[e["key"]]))
    for key in sorted(set(costs) - {e["key"] for e in edges}):
        if "MMM_" not in key:
            warnings.append(f"upgrades.xlsx: {key} matches no arrow of the tree, ignored")

    # The vest upgrades and their costs.
    tree = gear_edges(book["Жилеты"], warnings)
    gear = []
    sheet = openpyxl.load_workbook(ROOT / "source" / "gear_upgrades.xlsx", data_only=True)["Стоимость улучшений"]
    head = [text(v).split("\n")[0] for v in next(sheet.iter_rows(max_row=1, values_only=True))]
    col = {h: i for i, h in enumerate(head)}
    seen = set()
    for row in sheet.iter_rows(min_row=2, values_only=True):
        key = text(row[col["Ключ"]])
        if not key:
            continue
        if key not in tree:
            warnings.append(f"gear_upgrades.xlsx: {key} matches no arrow of the vest tree, ignored")
            continue
        seen.add(key)
        num = lambda h: int(row[col[h]]) if isinstance(row[col[h]], (int, float)) and row[col[h]] > 0 else 0
        item = text(row[col["Предмет: класс"]])
        if item and is_mmm(item):
            warnings.append(f"gear_upgrades.xlsx: {key}: MMM item {item} left out")
            item = ""
        if item and not CLASS_RE.match(item):
            warnings.append(f"gear_upgrades.xlsx: {key}: item {item!r} is not a class, ignored")
            item = ""
        src, dst, kind = tree[key]
        gear.append((key, text(row[col["Из (жилет)"]]), text(row[col["В (жилет)"]]), src, dst, kind,
                     num("Деньги, $"), num("Варбелт, шт."), num("Старая форма, шт."), item, num("Предмет, шт.") if item else 0))
    for key in sorted(set(tree) - seen):
        warnings.append(f"vest upgrade {tree[key][0]} -> {tree[key][1]}: no cost in gear_upgrades.xlsx, not offered")

    # Every class pattern of the table (all states, the upgrade columns' "a -> b" too): a class
    # of the game belongs to the most specific one that fits it, so "MMM_weap_AK74_H1S1_GP25"
    # is the GP-25 version's, not the plain AK-74's "MMM_weap_AK74_H*S*".
    patterns = []
    for row in book["Оружие"].iter_rows(min_row=2, values_only=True):
        cells = [text(v) for v in row[:9]]
        for cell in (cells[3], cells[6], cells[8]):
            for part in re.split(r",|->", cell):
                part = part.strip()
                if "*" in part and CLASS_RE.match(part) and part not in patterns and not is_mmm(part):
                    patterns.append(part)

    lines = [
        "// Generated by tools/make_catalog.py from source/items.xlsx and source/upgrades.xlsx.",
        "// Do not edit by hand: edit the table and run the script again.",
        "class CfgPMCShop {",
        "    patterns[] = {" + ", ".join(cfg(x) for x in patterns) + "};",
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
    lines += ["    };", "    class Upgrades {"]
    for i, (e, (price, low, med, high)) in enumerate(upgrades):
        pairs = ", ".join(f"{{{cfg(a)}, {cfg(b)}}}" for a, b in e["pairs"])
        lines.append(f"        class u{i} {{key = {cfg(e['key'])}; from = {cfg(e['src'])}; to = {cfg(e['dst'])}; kind = {cfg(e['kind'])}; "
                     f"op = {cfg(e['op'])}; price = {price}; parts[] = {{{low}, {med}, {high}}}; pairs[] = {{{pairs}}};}};")
    lines += ["    };", "    class GearUpgrades {"]
    for i, (key, src_name, dst_name, src, dst, kind, price, belt, uniform, item, count) in enumerate(gear):
        lines.append(f"        class g{i} {{key = {cfg(key)}; from = {cfg(src_name)}; to = {cfg(dst_name)}; fromClass = {cfg(src)}; "
                     f"toClass = {cfg(dst)}; kind = {cfg(kind)}; price = {price}; belt = {belt}; uniform = {uniform}; "
                     f"item = {cfg(item)}; itemCount = {count};}};")
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
          f"{catalog.count('pairs[]')} upgrades, {catalog.count('itemCount')} vest upgrades, {len(warnings)} warnings")


if __name__ == "__main__":
    main()
