#!/usr/bin/env python3
"""Textures and model of the PMC Drugs injectors.

The Stim1f autoinjector reuses ACE3's epinephrine autoinjector model (tools/ace/epinephrine.p3d,
an MLOD from the ACE3 sources) with its own texture: a copy of the model that points to
pmc_drugs\\data\\stim1f_co.paa, and that texture repainted from ACE's epinephrine/morphine sheet
(tools/ace/epimorphine_co.png, the epinephrine half: u < 0.47). Both ACE files are ACE3's,
GPL-2.0 (see tools/ace/NOTICE). The inventory picture is drawn here from scratch.
Usage: python3 tools/make_textures.py
"""
from __future__ import annotations

from pathlib import Path
import struct

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ACE = ROOT / "tools" / "ace"
OUT = ROOT / "textures"
DATA = ROOT / "addons" / "pmc_drugs" / "data"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
CONDENSED = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Colours of the Stim1f: matte black body, orange bands and lettering.
BODY = (34, 36, 33)
BAND = (232, 118, 24)
TEXT = (240, 240, 232)
# Fentropil: off-white body, teal bands and lettering, dark small print.
FEN_BODY = (222, 224, 218)
FEN_BAND = (0, 138, 140)
FEN_TEXT = (40, 44, 48)


def fit(draw, text, size, width):
    """The font size (at most size) at which text fits in width."""
    while size > 8 and draw.textlength(text, font=ImageFont.truetype(BOLD, size)) > width:
        size -= 2
    return ImageFont.truetype(BOLD, size)


def injector_sheet(body, band, label, sub, text_colour=TEXT):
    """The epinephrine half of ACE's sheet repainted: body colour, a band at both ends of the
    body, the label along the barrel. Returns 512 x 512 RGB."""
    src = Image.open(ACE / "epimorphine_co.png").convert("RGB")
    arr = np.asarray(src).astype(np.int32)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    yellow = ((r > 170) & (g > 170) & (b < 120)).astype(np.uint8) * 255
    # Close the holes the old lettering leaves in the yellow, inside the barrel only.
    mask = Image.fromarray(yellow).filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.MinFilter(25))
    m = np.asarray(mask) > 0
    m[:, 400:] = False
    out = arr.copy()
    ys, xs = np.nonzero(m)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    # The barrel is a cylinder unwrapped across x: a little brighter in the middle.
    shade = 0.82 + 0.25 * np.sin(np.clip((np.arange(arr.shape[1]) - x0) / max(1, x1 - x0), 0, 1) * np.pi)
    rng = np.random.default_rng(7)
    grain = rng.normal(0, 3, arr.shape[:2])
    for c in range(3):
        layer = body[c] * shade[None, :] + grain
        out[..., c] = np.where(m, layer, out[..., c])
    # Orange bands just inside both ends of the barrel.
    for top in (y0 + 10, y1 - 60):
        rows = np.zeros_like(m)
        rows[top:top + 50, :] = True
        sel = m & rows
        for c in range(3):
            out[..., c] = np.where(sel, band[c] * shade[None, :], out[..., c])
    img = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
    # Lettering along the barrel (turned 90 degrees, reading from the cap end).
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    length = (y1 - y0) - 160
    strip = Image.new("RGBA", (length, x1 - x0), (0, 0, 0, 0))
    d = ImageDraw.Draw(strip)
    big = fit(d, label, 96, length - 20)
    small = fit(d, sub, 30, length - 20)
    w = d.textlength(label, font=big)
    d.text(((length - w) / 2, (x1 - x0) / 2 - 92), label, font=big, fill=band + (255,))
    w = d.textlength(sub, font=small)
    d.text(((length - w) / 2, (x1 - x0) / 2 + 20), sub, font=small, fill=text_colour + (255,))
    strip = strip.rotate(90, expand=True)
    img.paste(strip, (cx - strip.width // 2, cy - strip.height // 2), strip)
    return img.resize((512, 512), Image.LANCZOS)


def icon(body, band, label):
    """Inventory picture, 256 x 256: the autoinjector lying diagonally like ACE's, its cap at the
    upper left, in the drug's colours."""
    s = 4
    img = Image.new("RGBA", (256 * s, 256 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Along the axis from (30, 80) to (226, 176): u along, v across.
    ax, ay, bx, by = 30 * s, 80 * s, 226 * s, 176 * s
    ux, uy = (bx - ax), (by - ay)
    length = (ux * ux + uy * uy) ** 0.5
    ux, uy = ux / length, uy / length
    vx, vy = -uy, ux

    def quad(u0, u1, half):
        return [(ax + ux * u0 * length + vx * k * half * s, ay + uy * u0 * length + vy * k * half * s) for k in (-1, 1)] + \
               [(ax + ux * u1 * length + vx * k * half * s, ay + uy * u1 * length + vy * k * half * s) for k in (1, -1)]

    def shaded(u0, u1, half, colour):
        # Cylinder: dark edges, a highlight above the axis.
        for k in range(12, 0, -1):
            t = k / 12
            c = tuple(int(colour[i] * (0.55 + 0.6 * (1 - t) ** 0.5)) for i in range(3))
            d.polygon(quad(u0, u1, half * t), fill=c + (255,))
        d.polygon(quad(u0, u1, half * 0.18), fill=tuple(min(255, int(colour[i] * 1.6) + 30) for i in range(3)) + (110,))

    shaded(0.0, 0.1, 13, (110, 112, 118))       # safety cap
    shaded(0.1, 0.86, 15, body)                  # barrel
    shaded(0.16, 0.24, 15.4, band)               # bands
    shaded(0.76, 0.84, 15.4, band)
    shaded(0.86, 1.0, 14, (210, 214, 220))       # needle end, clear plastic
    # Label along the barrel.
    text = Image.new("RGBA", (int(0.5 * length), 20 * s), (0, 0, 0, 0))
    td = ImageDraw.Draw(text)
    font = fit(td, label, 15 * s, text.width)
    w = td.textlength(label, font=font)
    td.text(((text.width - w) / 2, 0), label, font=font, fill=band + (255,))
    import math
    angle = math.degrees(math.atan2(uy, ux))
    text = text.rotate(-angle, expand=True, resample=Image.BICUBIC)
    mx, my = ax + ux * 0.5 * length, ay + uy * 0.5 * length
    img.alpha_composite(text, (int(mx - text.width / 2), int(my - text.height / 2)))
    shadow = img.split()[3].filter(ImageFilter.GaussianBlur(6 * s))
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base.paste((0, 0, 0, 110), (6 * s, 8 * s), shadow)
    base.alpha_composite(img)
    return base.resize((256, 256), Image.LANCZOS)


def model(texture):
    """ACE's epinephrine MLOD with every face pointing to our texture. The format is read face by
    face (strings are variable length), so the file is rebuilt, not patched in place."""
    data = (ACE / "epinephrine.p3d").read_bytes()
    assert data[:4] == b"MLOD"
    out = bytearray(data[:12])
    i = 12
    for _ in range(struct.unpack("<i", data[8:12])[0]):
        assert data[i:i + 4] == b"P3DM"
        npts, nn, nf = struct.unpack("<3i", data[i + 12:i + 24])
        head = i + 28 + npts * 16 + nn * 12
        out += data[i:head]
        i = head
        for _ in range(nf):
            out += data[i:i + 72]
            i += 72
            end = data.index(b"\0", i)
            out += texture.encode("ascii") + b"\0"
            i = end + 1
            end = data.index(b"\0", i)
            out += data[i:end + 1]
            i = end + 1
        # Tags and the resolution go through unchanged.
        start = i
        assert data[i:i + 4] == b"TAGG"
        i += 4
        while True:
            i += 1
            end = data.index(b"\0", i)
            name = data[i:end]
            i = end + 1
            size = struct.unpack("<i", data[i:i + 4])[0]
            i += 4 + size
            if name == b"#EndOfFile#":
                break
        i += 4
        out += data[start:i]
    assert i == len(data)
    return bytes(out)


def hud_plate():
    """A soft light rounded square under each HUD icon (tinted translucent in game)."""
    s = 4
    img = Image.new("RGBA", (64 * s, 64 * s), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((2 * s, 2 * s, 62 * s, 62 * s), radius=14 * s, fill=(255, 255, 255, 255))
    return img.filter(ImageFilter.GaussianBlur(s)).resize((64, 64), Image.LANCZOS)


def hud_muscle():
    """White flexed arm (biceps), tinted by the muscle damage in game; a thin dark outline."""
    s = 4
    m = Image.new("L", (64 * s, 64 * s), 0)
    d = ImageDraw.Draw(m)
    # Upper arm across, the biceps bulging up, the forearm raised, the fist on top.
    d.rounded_rectangle((6 * s, 38 * s, 40 * s, 52 * s), radius=7 * s, fill=255)
    d.ellipse((14 * s, 26 * s, 38 * s, 46 * s), fill=255)
    d.polygon([(32 * s, 50 * s), (44 * s, 50 * s), (50 * s, 18 * s), (40 * s, 16 * s)], fill=255)
    d.ellipse((36 * s, 6 * s, 54 * s, 22 * s), fill=255)
    d.rectangle((2 * s, 40 * s, 8 * s, 50 * s), fill=255)  # the shoulder end
    outline = m.filter(ImageFilter.MaxFilter(9))
    img = Image.new("RGBA", m.size, (0, 0, 0, 0))
    img.paste((30, 30, 30, 200), (0, 0), outline)
    img.paste((255, 255, 255, 255), (0, 0), m)
    # A crease: where the biceps meets the forearm.
    ImageDraw.Draw(img).arc((24 * s, 30 * s, 44 * s, 50 * s), 200, 290, fill=(150, 150, 150, 255), width=2 * s)
    return img.resize((64, 64), Image.LANCZOS)


def hud_tired():
    """White "tired" sign: an empty battery with a "z" over it; a thin dark outline."""
    s = 4
    m = Image.new("L", (64 * s, 64 * s), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((6 * s, 26 * s, 52 * s, 50 * s), radius=4 * s, outline=255, width=4 * s)
    d.rectangle((52 * s, 33 * s, 58 * s, 43 * s), fill=255)
    d.rectangle((11 * s, 31 * s, 18 * s, 45 * s), fill=255)  # the last bar of charge
    font = ImageFont.truetype(BOLD, 22 * s)
    d.text((30 * s, -2 * s), "z", font=font, fill=255)
    d.text((44 * s, 6 * s), "z", font=ImageFont.truetype(BOLD, 14 * s), fill=255)
    outline = m.filter(ImageFilter.MaxFilter(9))
    img = Image.new("RGBA", m.size, (0, 0, 0, 0))
    img.paste((30, 30, 30, 200), (0, 0), outline)
    img.paste((255, 255, 255, 255), (0, 0), m)
    return img.resize((64, 64), Image.LANCZOS)


def main():
    OUT.mkdir(exist_ok=True)
    DATA.mkdir(parents=True, exist_ok=True)
    sheet = injector_sheet(BODY, BAND, "STIM-1F", "COMBAT STIMULANT · IM")
    sheet.save(OUT / "stim1f_co.png")
    icon(BODY, BAND, "STIM-1F").save(OUT / "stim1f_ca.png")
    (DATA / "stim1f.p3d").write_bytes(model(r"pmc_drugs\data\stim1f_co.paa"))
    fen = injector_sheet(FEN_BODY, FEN_BAND, "FENTROPIL", "COGNITIVE MODULATOR · IM", FEN_TEXT)
    fen.save(OUT / "fentropil_co.png")
    icon(FEN_BODY, FEN_BAND, "FENTROPIL").save(OUT / "fentropil_ca.png")
    (DATA / "fentropil.p3d").write_bytes(model(r"pmc_drugs\data\fentropil_co.paa"))
    for name, draw in (("hud_plate_ca.png", hud_plate), ("hud_muscle_ca.png", hud_muscle), ("hud_tired_ca.png", hud_tired)):
        draw().save(OUT / name)
    preview = Image.new("RGB", (1280, 512), (60, 60, 60))
    preview.paste(sheet, (0, 0))
    preview.paste(fen, (768, 0))
    fic = Image.open(OUT / "fentropil_ca.png")
    preview.paste(fic, (512, 256), fic)
    ic = Image.open(OUT / "stim1f_ca.png")
    preview.paste(ic, (512, 0), ic)
    # The HUD icons as the game shows them: plate, then the muscle icon at 0.2 / 0.5 / 0.7 / 0.9.
    plate = Image.open(OUT / "hud_plate_ca.png")
    muscle = Image.open(OUT / "hud_muscle_ca.png")
    tired = Image.open(OUT / "hud_tired_ca.png")
    def tint(img, rgba):
        r, g, b, a = img.split()
        return Image.merge("RGBA", (r.point(lambda v: v * rgba[0]), g.point(lambda v: v * rgba[1]),
                                     b.point(lambda v: v * rgba[2]), a.point(lambda v: v * rgba[3])))
    for k, colour in enumerate([(1, 0.775, 0.35), (0.9, 0.1, 0.08), (0.63, 0.06, 0.05), (0, 0, 0)]):
        cell = Image.new("RGBA", (64, 64), (60, 60, 60, 255))
        cell.alpha_composite(tint(plate, (1, 1, 1, 0.45)))
        cell.alpha_composite(tint(muscle, colour + (1,)))
        preview.paste(cell.convert("RGB"), (516 + 62 * k, 440))
    cell = Image.new("RGBA", (64, 64), (60, 60, 60, 255))
    cell.alpha_composite(tint(plate, (1, 1, 1, 0.45)))
    cell.alpha_composite(tired)
    preview.paste(cell.convert("RGB"), (516, 370))
    preview.save(OUT / "_preview.png")
    print("stim1f_co.png, stim1f_ca.png, data/stim1f.p3d, fentropil_co.png, fentropil_ca.png, data/fentropil.p3d")


if __name__ == "__main__":
    main()
