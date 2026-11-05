#!/usr/bin/env python3
"""Textures of the PMC Shop laptop (desktop A): wallpaper, desktop icons, the picture shown
for goods without one. Drawn here from scratch; PNGs go to textures/, then
tools/paa_online.js converts them into addons/pmc_shop/data/*.paa.
Usage: python3 tools/make_textures.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "textures"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
NAVY = (31, 42, 51)
ORANGE = (217, 130, 43)


def wallpaper() -> Image.Image:
    w, h = 2048, 1024
    img = Image.new("RGB", (w, h), NAVY)
    d = ImageDraw.Draw(img)
    sx, sy = w / 1600, h / 856
    pts = lambda seq: [(x * sx, y * sy) for x, y in seq]
    d.polygon(pts([(0, 640), (380, 520), (720, 600), (1100, 470), (1600, 560), (1600, 856), (0, 856)]), fill=(36, 51, 65))
    d.polygon(pts([(0, 720), (420, 640), (860, 700), (1260, 610), (1600, 680), (1600, 856), (0, 856)]), fill=(40, 58, 73))
    big = ImageFont.truetype(BOLD, 300)
    small = ImageFont.truetype(REGULAR, 38)
    text = "I O N"
    tw = d.textlength(text, font=big)
    d.text((1500 * sx - tw, 230 * sy), text, font=big, fill=(43, 58, 71))
    sub = "ORGANISATION  ·  LOGISTICS"
    d.text((1490 * sx - d.textlength(sub, font=small), 480 * sy), sub, font=small, fill=(58, 76, 91))
    return img


def icon(draw_fn) -> Image.Image:
    s = 4
    img = Image.new("RGBA", (128 * s, 128 * s), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(img), s)
    return img.resize((128, 128), Image.LANCZOS)


def pc(d, s):
    d.rectangle([14 * s, 22 * s, 114 * s, 88 * s], outline=(214, 221, 227), width=7 * s // 2)
    d.rectangle([22 * s, 30 * s, 106 * s, 80 * s], fill=(59, 82, 102))
    d.line([64 * s, 88 * s, 64 * s, 104 * s], fill=(214, 221, 227), width=7 * s // 2)
    d.line([44 * s, 106 * s, 84 * s, 106 * s], fill=(214, 221, 227), width=7 * s // 2)


def folder(d, s):
    d.polygon([(12 * s, 34 * s), (50 * s, 34 * s), (58 * s, 44 * s), (116 * s, 44 * s), (116 * s, 104 * s), (12 * s, 104 * s)], fill=(233, 196, 106))
    d.rectangle([12 * s, 52 * s, 116 * s, 104 * s], fill=(244, 211, 128))


def browser(d, s):
    d.ellipse([12 * s, 12 * s, 108 * s, 108 * s], fill=NAVY, outline=ORANGE, width=6 * s)
    d.line([12 * s, 60 * s, 108 * s, 60 * s], fill=ORANGE, width=4 * s)
    d.arc([36 * s, 12 * s, 84 * s, 108 * s], 0, 360, fill=ORANGE, width=4 * s)
    d.arc([22 * s, 32 * s, 98 * s, 88 * s], 180, 360, fill=ORANGE, width=3 * s)
    d.rounded_rectangle([68 * s, 70 * s, 122 * s, 120 * s], radius=8 * s, fill=ORANGE)
    f = ImageFont.truetype(BOLD, 20 * s)
    d.text((95 * s - d.textlength("ION", font=f) / 2, 82 * s), "ION", font=f, fill=(29, 33, 37))


def bin_(d, s):
    c = (214, 221, 227)
    d.line([24 * s, 34 * s, 104 * s, 34 * s], fill=c, width=6 * s)
    d.line([50 * s, 24 * s, 78 * s, 24 * s], fill=c, width=6 * s)
    d.polygon([(32 * s, 40 * s), (96 * s, 40 * s), (90 * s, 110 * s), (38 * s, 110 * s)], outline=c, width=6 * s)
    for x in (52, 64, 76):
        d.line([x * s, 52 * s, x * s, 98 * s], fill=c, width=4 * s)


def noimage() -> Image.Image:
    s = 4
    img = Image.new("RGBA", (256 * s, 64 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = [(4, 26), (60, 24), (64, 18), (120, 18), (124, 22), (178, 22), (178, 26), (214, 26), (214, 30), (178, 30), (176, 34),
           (128, 34), (118, 52), (104, 52), (110, 34), (84, 34), (80, 46), (62, 46), (66, 34), (40, 36), (8, 44), (4, 40)]
    d.polygon([((x + 20) * s, (y + 4) * s) for x, y in pts], fill=(125, 133, 140, 255))
    return img.resize((256, 64), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(exist_ok=True)
    wallpaper().save(OUT / "wallpaper_co.png")
    for name, fn in (("icon_pc_ca", pc), ("icon_folder_ca", folder), ("icon_browser_ca", browser), ("icon_bin_ca", bin_)):
        icon(fn).save(OUT / f"{name}.png")
    noimage().save(OUT / "noimage_ca.png")
    sheet = Image.new("RGB", (1024 + 660, 512), (42, 44, 47))
    sheet.paste(wallpaper().resize((1024, 512)), (0, 0))
    for i, name in enumerate(["icon_pc_ca", "icon_folder_ca", "icon_browser_ca", "icon_bin_ca"]):
        ic = Image.open(OUT / f"{name}.png")
        sheet.paste(ic, (1060 + (i % 2) * 150, 40 + (i // 2) * 150), ic)
    ni = Image.open(OUT / "noimage_ca.png")
    sheet.paste(ni, (1060, 380), ni)
    sheet.save(OUT / "_preview.png")
    print("textures written")


if __name__ == "__main__":
    main()
