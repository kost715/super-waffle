#!/usr/bin/env python3
"""Draw the PMC Interactions board textures as RGBA PNG, ready for ImageToPAA.

Every image is drawn at 4x and downscaled for smooth edges. Noise uses fixed seeds, so
the output is reproducible. Sizes are powers of two; names end in _ca (colour + alpha,
converted to DXT5). Greyscale "tint" images are meant to be coloured in game with
ctrlSetTextColor. Usage: python3 tools/make_textures.py [output folder]
"""
from __future__ import annotations

import math
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "textures"
SS = 4  # supersampling factor
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


# --- helpers ---------------------------------------------------------------------
def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def s(v):
    """Scale a coordinate or a tuple of coordinates to the supersampled canvas."""
    if isinstance(v, (tuple, list)):
        return type(v)(s(x) for x in v)
    return v * SS


def noise(w, h, seed, scale=1.0, blur=0):
    rng = np.random.default_rng(seed)
    a = rng.random((h, w)).astype(np.float32)
    img = Image.fromarray((a * 255).astype(np.uint8), "L")
    if blur:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    arr = np.asarray(img).astype(np.float32) / 255.0
    return (arr - arr.mean()) * scale


def vgradient(w, h, top, bottom):
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    top = np.array(top, np.float32)
    bottom = np.array(bottom, np.float32)
    arr = top + (bottom - top) * t
    arr = np.repeat(arr, w, axis=1)
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")


def radial(w, h, inner, outer, cx=0.5, cy=0.5, radius=0.5):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((x / w) - cx) ** 2 + ((y / h) - cy) ** 2) / radius
    d = d.clip(0, 1)[:, :, None]
    inner = np.array(inner, np.float32)
    outer = np.array(outer, np.float32)
    arr = inner + (outer - inner) * d
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")


def masked(fill, mask):
    """fill (RGBA image) cut to mask (L image)."""
    out = fill.copy()
    a = ImageChops.multiply(out.getchannel("A"), mask)
    out.putalpha(a)
    return out


def shape_mask(size, draw_fn):
    m = Image.new("L", size, 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def shadow(mask, offset, blur, opacity):
    sh = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    a = mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * opacity))
    black = Image.new("RGBA", mask.size, (0, 0, 0, 255))
    black.putalpha(a)
    sh.alpha_composite(black, dest=offset) if offset != (0, 0) else sh.alpha_composite(black)
    return sh


def add_noise(img, amount, seed, blur=0):
    arr = np.asarray(img).astype(np.float32)
    n = noise(img.width, img.height, seed, amount, blur)[:, :, None]
    arr[:, :, :3] = (arr[:, :, :3] + n * 255).clip(0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def save(img, name):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name)
    return name


# --- tintable gauge parts (greyscale) --------------------------------------------
def gauge_frame():
    w, h = 512, 64
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((2, 2, w - 3, h - 3)), radius=s(14), outline=(215, 215, 215, 255), width=s(4))
    inner = shape_mask(img.size, lambda m: m.rounded_rectangle(s((6, 6, w - 7, h - 7)), radius=s(10), fill=255))
    glow = inner.filter(ImageFilter.GaussianBlur(s(6)))
    edge = ImageChops.subtract(inner, glow).point(lambda v: min(255, v * 2))
    dark = Image.new("RGBA", img.size, (0, 0, 0, 255))
    dark.putalpha(edge.point(lambda v: int(v * 0.6)))
    img.alpha_composite(dark)
    return finish(img, w, h)


def gauge_fill():
    w, h = 512, 64
    grad = vgradient(w * SS, h * SS, (255, 255, 255, 255), (165, 165, 165, 255))
    mask = shape_mask(grad.size, lambda m: m.rounded_rectangle(s((0, 0, w - 1, h - 1)), radius=s(12), fill=255))
    img = masked(grad, mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((6, 5, w - 7, 17)), radius=s(6), fill=(255, 255, 255, 110))
    return finish(img, w, h)


def gauge_band():
    w, h = 256, 64
    x = np.linspace(-1, 1, w, dtype=np.float32)
    a = (1 - np.abs(x) ** 6) * 210
    arr = np.zeros((h, w, 4), np.uint8)
    arr[:, :, :3] = 255
    arr[:, :, 3] = a[None, :].clip(0, 255).astype(np.uint8)
    img = Image.fromarray(arr, "RGBA")
    d = ImageDraw.Draw(img)
    for xx in (int(w * 0.03), int(w * 0.97)):
        d.line((xx, 4, xx, h - 5), fill=(255, 255, 255, 255), width=3)
    return img


def gauge_marker():
    w, h = 32, 64
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    cx = w / 2
    outline = (20, 20, 20, 255)
    d.rectangle(s((cx - 3, 8, cx + 3, h - 9)), fill=(255, 255, 255, 255), outline=outline, width=s(1))
    d.polygon(s([(cx - 12, 0), (cx + 12, 0), (cx, 14)]), fill=(255, 255, 255, 255), outline=outline)
    d.polygon(s([(cx - 12, h - 1), (cx + 12, h - 1), (cx, h - 15)]), fill=(255, 255, 255, 255), outline=outline)
    return finish(img, w, h)


# --- icons -------------------------------------------------------------------------
def heart_mask(size, box):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0

    def draw(m):
        r = w * 0.27
        m.ellipse((x0 + w * 0.02, y0 + h * 0.05, x0 + w * 0.02 + 2 * r, y0 + h * 0.05 + 2 * r), fill=255)
        m.ellipse((x1 - w * 0.02 - 2 * r, y0 + h * 0.05, x1 - w * 0.02, y0 + h * 0.05 + 2 * r), fill=255)
        m.polygon([(x0 + w * 0.04, y0 + h * 0.38), (x1 - w * 0.04, y0 + h * 0.38), (x0 + w / 2, y1)], fill=255)

    return shape_mask(size, draw)


def icon_cpr():
    w = h = 128
    img = canvas(w, h)
    m = heart_mask(img.size, s((14, 18, 114, 112)))
    img.alpha_composite(shadow(m, (0, s(3)), s(4), 0.6))
    img.alpha_composite(masked(radial(img.width, img.height, (240, 80, 70, 255), (150, 20, 25, 255), 0.4, 0.35, 0.6), m))
    d = ImageDraw.Draw(img)
    pts = [(18, 66), (44, 66), (52, 50), (62, 86), (72, 40), (80, 66), (110, 66)]
    d.line(s(pts), fill=(255, 255, 255, 255), width=s(6), joint="curve")
    return finish(img, w, h)


def icon_tourniquet():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((10, 50, 118, 78)), radius=s(10), fill=(35, 35, 38, 255), outline=(90, 90, 95, 255), width=s(3))
    for x in range(20, 112, 12):
        d.line(s((x, 54, x, 74)), fill=(60, 60, 64, 255), width=s(2))
    d.rounded_rectangle(s((50, 20, 78, 108)), radius=s(8), fill=(200, 60, 40, 255), outline=(120, 30, 20, 255), width=s(3))
    d.rounded_rectangle(s((30, 58, 98, 70)), radius=s(6), fill=(150, 150, 155, 255))
    return finish(img, w, h)


def icon_bandage():
    w = h = 128
    img = canvas(w, h)
    m = shape_mask(img.size, lambda m: m.ellipse(s((14, 24, 84, 104)), fill=255))
    img.alpha_composite(shadow(m, (s(3), s(4)), s(4), 0.5))
    d = ImageDraw.Draw(img)
    d.rectangle(s((49, 24, 114, 104)), fill=(235, 235, 228, 255))
    d.ellipse(s((14, 24, 84, 104)), fill=(245, 245, 240, 255), outline=(170, 170, 160, 255), width=s(3))
    d.ellipse(s((36, 46, 62, 82)), fill=(190, 190, 182, 255))
    d.rectangle(s((88, 52, 104, 76)), fill=(210, 40, 40, 255))
    d.rectangle(s((84, 58, 108, 70)), fill=(210, 40, 40, 255))
    return finish(img, w, h)


def icon_wheel():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.ellipse(s((6, 6, 122, 122)), fill=(30, 30, 32, 255))
    d.ellipse(s((28, 28, 100, 100)), fill=(185, 188, 195, 255), outline=(110, 112, 118, 255), width=s(3))
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        cx, cy = 64 + 22 * math.cos(a), 64 + 22 * math.sin(a)
        d.ellipse(s((cx - 6, cy - 6, cx + 6, cy + 6)), fill=(70, 70, 75, 255))
    d.ellipse(s((54, 54, 74, 74)), fill=(130, 132, 140, 255))
    return finish(img, w, h)


# --- CPR -----------------------------------------------------------------------------
def ground(w, h, seed, base=(42, 46, 38)):
    img = Image.new("RGBA", (w, h), base + (255,))
    img = add_noise(img, 0.25, seed, blur=3)
    img = add_noise(img, 0.08, seed + 1)
    vign = radial(w, h, (0, 0, 0, 0), (0, 0, 0, 150), radius=0.75)
    img.alpha_composite(vign)
    return img


def cpr_scene():
    w, h = 1024, 512
    img = ground(w * SS // 2, h * SS // 2, 11).resize((w * SS, h * SS), Image.BICUBIC)
    body = shape_mask(img.size, lambda m: (
        m.ellipse(s((70, 170, 230, 340)), fill=255),                       # head
        m.rounded_rectangle(s((210, 215, 260, 295)), radius=s(14), fill=255),  # neck
        m.rounded_rectangle(s((245, 90, 760, 420)), radius=s(110), fill=255),  # torso
        m.rounded_rectangle(s((300, 40, 640, 110)), radius=s(35), fill=255),   # upper arm
        m.rounded_rectangle(s((300, 400, 640, 470)), radius=s(35), fill=255),  # lower arm
        m.rounded_rectangle(s((720, 150, 1024, 360)), radius=s(60), fill=255),  # hips
    ))
    img.alpha_composite(shadow(body, (s(10), s(14)), s(18), 0.7))
    cloth = vgradient(img.width, img.height, (96, 104, 74, 255), (62, 68, 48, 255))
    cloth = add_noise(cloth, 0.12, 12, blur=2)
    img.alpha_composite(masked(cloth, body))
    skin = radial(img.width, img.height, (214, 170, 140, 255), (160, 118, 92, 255), cx=0.14, cy=0.5, radius=0.12)
    head = shape_mask(img.size, lambda m: m.ellipse(s((70, 170, 230, 340)), fill=255))
    img.alpha_composite(masked(skin, head))
    hair = shape_mask(img.size, lambda m: m.chord(s((70, 170, 230, 340)), 100, 260, fill=255))
    img.alpha_composite(masked(Image.new("RGBA", img.size, (55, 40, 30, 255)), hair))
    d = ImageDraw.Draw(img)
    for x0, y0, x1, y1 in [(330, 150, 420, 200), (360, 330, 470, 380), (560, 140, 660, 210), (590, 300, 700, 360)]:
        d.arc(s((x0, y0, x1, y1)), 200, 340, fill=(48, 54, 36, 255), width=s(4))
    d.line(s((505, 100, 505, 410)), fill=(52, 58, 40, 255), width=s(5))  # zip line
    cx, cy = 470, 255  # sternum target
    for r, a in ((70, 60), (44, 110)):
        d.ellipse(s((cx - r, cy - r, cx + r, cy + r)), outline=(255, 255, 255, a), width=s(4))
    d.line(s((cx - 18, cy, cx + 18, cy)), fill=(255, 255, 255, 140), width=s(4))
    d.line(s((cx, cy - 18, cx, cy + 18)), fill=(255, 255, 255, 140), width=s(4))
    return finish(img, w, h)


def cpr_hands(pressed):
    """Top-down: two forearms in sleeves meet at hands stacked on the sternum."""
    w = h = 256
    img = canvas(w, h)
    k = 0.93 if pressed else 1.0
    cx, cy = 128, 118

    def tr(pts):
        return [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in pts]

    def ell(x0, y0, x1, y1):
        (a, b), (c, d) = tr([(x0, y0), (x1, y1)])
        return (a, b, c, d)

    arms_left = [(10, 256), (78, 256), (128, 150), (92, 128)]
    arms_right = [(178, 256), (246, 256), (164, 128), (128, 150)]
    whole = shape_mask(img.size, lambda m: (
        m.polygon(s(tr(arms_left)), fill=255), m.polygon(s(tr(arms_right)), fill=255),
        m.ellipse(s(ell(66, 62, 190, 176)), fill=255)))
    off = (s(4), s(5)) if pressed else (s(14), s(20))
    img.alpha_composite(shadow(whole, off, s(5) if pressed else s(12), 0.75 if pressed else 0.5))
    skin = radial(img.width, img.height, (228, 184, 152, 255), (172, 126, 98, 255), cx=0.48, cy=0.4, radius=0.5)
    skin = add_noise(skin, 0.04, 21, blur=2)
    img.alpha_composite(masked(skin, whole))
    sleeves = shape_mask(img.size, lambda m: (
        m.polygon(s(tr([(10, 256), (78, 256), (104, 205), (44, 190)])), fill=255),
        m.polygon(s(tr([(178, 256), (246, 256), (212, 190), (152, 205)])), fill=255)))
    cloth = vgradient(img.width, img.height, (100, 108, 78, 255), (62, 68, 48, 255))
    img.alpha_composite(masked(add_noise(cloth, 0.1, 22, blur=2), sleeves))
    d = ImageDraw.Draw(img)
    # Top hand: fingers wrap over the lower hand, knuckles and thumb.
    d.ellipse(s(ell(78, 76, 178, 168)), fill=(236, 194, 162, 255), outline=(170, 124, 96, 255), width=s(2))
    for i in range(4):
        x = 92 + 22 * i
        d.rounded_rectangle(s(ell(x, 58, x + 20, 100)), radius=s(9 * k), fill=(232, 190, 158, 255), outline=(165, 120, 92, 255), width=s(2))
        d.arc(s(ell(x + 3, 84, x + 17, 98)), 200, 340, fill=(160, 115, 88, 255), width=s(2))
    d.ellipse(s(ell(168, 112, 204, 150)), fill=(230, 188, 156, 255), outline=(165, 120, 92, 255), width=s(2))
    if pressed:
        d.ellipse(s(ell(62, 56, 194, 182)), outline=(255, 230, 120, 150), width=s(5))
    return finish(img, w, h)


def cpr_beat(on):
    w = h = 128
    img = canvas(w, h)
    m = heart_mask(img.size, s((10, 14, 118, 116)))
    if on:
        glow = m.filter(ImageFilter.GaussianBlur(s(10)))
        g = Image.new("RGBA", img.size, (255, 70, 60, 255))
        g.putalpha(glow.point(lambda v: int(v * 0.9)))
        img.alpha_composite(g)
        fill = radial(img.width, img.height, (255, 120, 105, 255), (190, 25, 25, 255), 0.4, 0.35, 0.6)
    else:
        fill = radial(img.width, img.height, (90, 70, 70, 255), (45, 35, 35, 255), 0.4, 0.35, 0.6)
    img.alpha_composite(masked(fill, m))
    d = ImageDraw.Draw(img)
    d.ellipse(s((30, 32, 52, 50)), fill=(255, 255, 255, 120 if on else 40))
    return finish(img, w, h)


# --- tourniquet ------------------------------------------------------------------------
def limb(img, box, sleeve_to, seed):
    x0, y0, x1, y1 = box
    m = shape_mask(img.size, lambda m: m.rounded_rectangle(s(box), radius=s((y1 - y0) / 2), fill=255))
    img.alpha_composite(shadow(m, (s(8), s(14)), s(14), 0.7))
    skin = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hgt = int(s(y1 - y0))
    band = vgradient(img.width, hgt, (150, 108, 84, 255), (150, 108, 84, 255))
    t = np.linspace(-1, 1, hgt, dtype=np.float32)
    shade = (1 - t ** 2) ** 0.5  # cylinder
    arr = np.asarray(band).astype(np.float32)
    arr[:, :, :3] = np.array([120, 84, 64], np.float32) + np.array([110, 86, 70], np.float32) * shade[:, None, None]
    skin.paste(Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA"), (0, int(s(y0))))
    skin = add_noise(skin, 0.04, seed, blur=2)
    img.alpha_composite(masked(skin, m))
    sleeve = shape_mask(img.size, lambda mm: mm.rounded_rectangle(s((x0 - 40, y0 - 14, sleeve_to, y1 + 14)), radius=s(30), fill=255))
    cloth = vgradient(img.width, img.height, (96, 104, 74, 255), (58, 64, 44, 255))
    cloth = add_noise(cloth, 0.12, seed + 3, blur=2)
    img.alpha_composite(shadow(sleeve, (s(6), s(10)), s(10), 0.6))
    img.alpha_composite(masked(cloth, sleeve))
    return m


def wound(img, cx, cy, rx, ry, seed, depth=1.0):
    rng = np.random.default_rng(seed)
    pts = []
    for k in range(18):
        a = 2 * math.pi * k / 18
        r = 1 + rng.uniform(-0.25, 0.25)
        pts.append((cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)))
    m = shape_mask(img.size, lambda mm: mm.polygon(s(pts), fill=255)).filter(ImageFilter.GaussianBlur(s(1.5)))
    bruise = m.filter(ImageFilter.GaussianBlur(s(18))).point(lambda v: int(v * 0.55))
    b = Image.new("RGBA", img.size, (120, 40, 50, 255))
    b.putalpha(bruise)
    img.alpha_composite(b)
    inner = radial(img.width, img.height, (60, 5, 8, 255), (150, 20, 20, 255), cx=cx / (img.width / SS), cy=cy / (img.height / SS),
                   radius=max(rx, ry) * 1.2 / (img.width / SS))
    img.alpha_composite(masked(inner, m))
    d = ImageDraw.Draw(img)
    for _ in range(int(14 * depth)):  # glossy blood highlights and drops
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0.1, 0.8)
        px, py = cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)
        rr = rng.uniform(2, 6)
        d.ellipse(s((px - rr, py - rr * 0.6, px + rr, py + rr * 0.6)), fill=(255, 150, 150, 90))
    for _ in range(6):
        a = rng.uniform(0.2, 2.9)
        px, py = cx + rx * 1.3 * math.cos(a), cy + ry * 1.2 * math.sin(a) + 10
        rr = rng.uniform(3, 8)
        d.ellipse(s((px - rr, py - rr, px + rr, py + rr * 1.4)), fill=(130, 15, 18, 230))


def tq_scene():
    w, h = 1024, 512
    img = ground(w * SS // 2, h * SS // 2, 31, (36, 38, 40)).resize((w * SS, h * SS), Image.BICUBIC)
    limb(img, (60, 170, 1000, 330), 300, 32)
    wound(img, 800, 250, 60, 34, 33)
    d = ImageDraw.Draw(img)
    # Tourniquet strap around the limb at x=470, with buckle clip.
    strap = shape_mask(img.size, lambda m: m.rounded_rectangle(s((440, 150, 500, 350)), radius=s(10), fill=255))
    img.alpha_composite(shadow(strap, (s(6), s(8)), s(8), 0.7))
    tex = vgradient(img.width, img.height, (40, 40, 44, 255), (22, 22, 24, 255))
    tex = add_noise(tex, 0.15, 34)
    img.alpha_composite(masked(tex, strap))
    for y in range(160, 345, 10):
        d.line(s((444, y, 496, y)), fill=(55, 55, 60, 255), width=s(2))
    d.rounded_rectangle(s((430, 135, 510, 160)), radius=s(6), fill=(200, 60, 40, 255), outline=(110, 30, 20, 255), width=s(3))
    d.text(s((444, 136)), "TQ", font=ImageFont.truetype(FONT, s(20)), fill=(255, 255, 255, 255))
    return finish(img, w, h)


def tq_windlass(angle):
    w = h = 256
    big = canvas(w, h)
    d = ImageDraw.Draw(big)
    cx = cy = 128
    rod = shape_mask(big.size, lambda m: m.rounded_rectangle(s((cx - 110, cy - 14, cx + 110, cy + 14)), radius=s(14), fill=255))
    big.alpha_composite(shadow(rod, (s(5), s(7)), s(6), 0.6))
    grad = vgradient(big.width, big.height, (210, 70, 50, 255), (120, 30, 22, 255))
    t = np.linspace(0, 1, big.height, dtype=np.float32)
    arr = np.asarray(grad).astype(np.float32)
    shine = np.exp(-((t - 0.5 + 0.035) / 0.02) ** 2)[:, None] * 90
    arr[:, :, :3] += shine[:, :, None]
    grad = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    big.alpha_composite(masked(grad, rod))
    for x in (cx - 90, cx - 70, cx + 70, cx + 90):  # grip ridges
        d.line(s((x, cy - 12, x, cy + 12)), fill=(90, 20, 15, 255), width=s(3))
    d.ellipse(s((cx - 22, cy - 22, cx + 22, cy + 22)), fill=(30, 30, 33, 255), outline=(80, 80, 86, 255), width=s(3))
    big = big.rotate(-angle, resample=Image.BICUBIC, center=(s(cx), s(cy)))
    return finish(big, w, h)


# --- bandage -----------------------------------------------------------------------------
def bandage_scene():
    w, h = 1024, 512
    img = Image.new("RGBA", (w * SS, h * SS), (196, 150, 122, 255))
    img = add_noise(img, 0.10, 41, blur=6)
    img = add_noise(img, 0.05, 42, blur=1)
    shade = radial(img.width, img.height, (0, 0, 0, 0), (60, 30, 20, 120), radius=0.8)
    img.alpha_composite(shade)
    rng = np.random.default_rng(43)
    d = ImageDraw.Draw(img)
    for _ in range(160):  # fine hair
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        a = rng.uniform(-0.6, 0.6)
        d.line(s((x, y, x + 9 * math.cos(a), y + 9 * math.sin(a))), fill=(120, 85, 65, 120), width=s(1))
    wound(img, 512, 256, 150, 80, 44, depth=2.0)
    return finish(img, w, h)


def gauze_stage(stage):
    w, h = 512, 256
    img = canvas(w, h)
    rng = np.random.default_rng(50 + stage)
    cx, cy = 256, 128
    rx, ry = 70 + 45 * stage, 38 + 22 * stage
    pts = []
    for k in range(22):
        a = 2 * math.pi * k / 22
        r = 1 + rng.uniform(-0.18, 0.12)
        pts.append((cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)))
    m = shape_mask(img.size, lambda mm: mm.polygon(s(pts), fill=255)).filter(ImageFilter.GaussianBlur(s(2)))
    img.alpha_composite(shadow(m, (s(3), s(5)), s(6), 0.45))
    fabric = Image.new("RGBA", img.size, (240, 238, 230, 255))
    d = ImageDraw.Draw(fabric)
    for x in range(0, w * SS, s(6)):  # weave
        d.line((x, 0, x, h * SS), fill=(215, 212, 202, 255), width=s(1))
    for y in range(0, h * SS, s(6)):
        d.line((0, y, w * SS, y), fill=(220, 217, 207, 255), width=s(1))
    fabric = add_noise(fabric, 0.06, 60 + stage, blur=2)
    folds = ImageDraw.Draw(fabric)
    for _ in range(5 + 2 * stage):
        x, y = rng.uniform(cx - rx, cx + rx), rng.uniform(cy - ry, cy + ry)
        folds.arc(s((x - 30, y - 12, x + 30, y + 12)), rng.uniform(0, 180), rng.uniform(200, 360), fill=(185, 182, 172, 255), width=s(2))
    img.alpha_composite(masked(fabric, m))
    stain = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(stain)
    for _ in range(6 - stage):  # blood soaking through, less as more gauze is packed
        x, y = rng.uniform(cx - rx * 0.5, cx + rx * 0.5), rng.uniform(cy - ry * 0.4, cy + ry * 0.4)
        r = rng.uniform(10, 26)
        sd.ellipse(s((x - r, y - r * 0.7, x + r, y + r * 0.7)), fill=(170, 25, 30, 150))
    stain = stain.filter(ImageFilter.GaussianBlur(s(5)))
    stain.putalpha(ImageChops.multiply(stain.getchannel("A"), m))
    img.alpha_composite(stain)
    return finish(img, w, h)


# --- wheel -----------------------------------------------------------------------------------
STUD_RADIUS = 150  # px from the centre of the 512 px wheel; studs at -90 + 72*k degrees


def wheel(worn):
    w = h = 512
    img = canvas(w, h)
    cx = cy = 256
    tire = shape_mask(img.size, lambda m: m.ellipse(s((6, 6, 506, 506)), fill=255))
    img.alpha_composite(shadow(tire, (s(8), s(10)), s(10), 0.6))
    rubber = radial(img.width, img.height, (48, 48, 50, 255), (18, 18, 19, 255), radius=0.5)
    rubber = add_noise(rubber, 0.08, 70)
    img.alpha_composite(masked(rubber, tire))
    d = ImageDraw.Draw(img)
    for k in range(48):  # tread blocks
        a = 2 * math.pi * k / 48
        r0, r1 = 236, 252
        p = [(cx + r0 * math.cos(a - 0.04), cy + r0 * math.sin(a - 0.04)), (cx + r1 * math.cos(a - 0.03), cy + r1 * math.sin(a - 0.03)),
             (cx + r1 * math.cos(a + 0.03), cy + r1 * math.sin(a + 0.03)), (cx + r0 * math.cos(a + 0.04), cy + r0 * math.sin(a + 0.04))]
        d.polygon(s(p), fill=(12, 12, 13, 255))
    rim = shape_mask(img.size, lambda m: m.ellipse(s((cx - 196, cy - 196, cx + 196, cy + 196)), fill=255))
    metal = radial(img.width, img.height, (215, 218, 224, 255) if not worn else (150, 140, 128, 255),
                   (120, 124, 132, 255) if not worn else (82, 74, 66, 255), cx=0.42, cy=0.4, radius=0.5)
    metal = add_noise(metal, 0.05 if not worn else 0.14, 71, blur=1)
    img.alpha_composite(masked(metal, rim))
    d.ellipse(s((cx - 196, cy - 196, cx + 196, cy + 196)), outline=(70, 72, 78, 255), width=s(6))
    for k in range(10):  # spoke openings
        a = 2 * math.pi * (k + 0.5) / 10
        x, y = cx + 175 * math.cos(a), cy + 175 * math.sin(a)
        d.ellipse(s((x - 16, y - 16, x + 16, y + 16)), fill=(28, 28, 30, 255))
    d.ellipse(s((cx - 190, cy - 190, cx + 190, cy + 190)), outline=(90, 92, 98, 160), width=s(3))
    d.ellipse(s((cx - 52, cy - 52, cx + 52, cy + 52)), fill=(95, 98, 106, 255), outline=(60, 62, 68, 255), width=s(4))
    d.ellipse(s((cx - 24, cy - 24, cx + 24, cy + 24)), fill=(60, 62, 68, 255))
    for k in range(5):  # stud holes where the nut sprites sit
        a = math.radians(-90 + 72 * k)
        x, y = cx + STUD_RADIUS * math.cos(a), cy + STUD_RADIUS * math.sin(a)
        d.ellipse(s((x - 20, y - 20, x + 20, y + 20)), fill=(55, 57, 62, 255), outline=(150, 152, 160, 255), width=s(2))
    if worn:
        rng = np.random.default_rng(72)
        for _ in range(40):  # rust and dirt
            a, r = rng.uniform(0, 2 * math.pi), rng.uniform(60, 190)
            x, y = cx + r * math.cos(a), cy + r * math.sin(a)
            rr = rng.uniform(4, 14)
            d.ellipse(s((x - rr, y - rr, x + rr, y + rr)), fill=(110, 60, 30, 110))
        d.line(s((cx + 150, cy + 190, cx + 230, cy + 120)), fill=(5, 5, 5, 255), width=s(6))  # tear in the tyre
    return finish(img, w, h)


def nut(state):
    w = h = 128
    img = canvas(w, h)
    cx = cy = 64
    loose = state == "loose"
    if loose:  # the stud shows where the nut has backed off it
        d0 = ImageDraw.Draw(img)
        sx, sy = 78, 80
        d0.ellipse(s((sx - 18, sy - 18, sx + 18, sy + 18)), fill=(120, 122, 128, 255), outline=(60, 62, 68, 255), width=s(2))
        for r in (14, 10, 6):
            d0.ellipse(s((sx - r, sy - r, sx + r, sy + r)), outline=(165, 167, 173, 255), width=s(1))
        cx, cy = 50, 46
    size, turn = (34, 15) if loose else (38, 0)
    hexagon = [(cx + size * math.cos(math.radians(30 + turn + 60 * k)), cy + size * math.sin(math.radians(30 + turn + 60 * k))) for k in range(6)]
    m = shape_mask(img.size, lambda mm: mm.polygon(s(hexagon), fill=255))
    if state in ("next", "done"):
        ring = shape_mask(img.size, lambda mm: mm.ellipse(s((4, 4, 124, 124)), outline=255, width=s(8)))
        col = (255, 200, 60, 255) if state == "next" else (80, 210, 100, 255)
        g = Image.new("RGBA", img.size, col)
        g.putalpha(ring.filter(ImageFilter.GaussianBlur(s(4))))
        img.alpha_composite(g)
        g2 = Image.new("RGBA", img.size, col)
        g2.putalpha(ring)
        img.alpha_composite(g2)
    img.alpha_composite(shadow(m, (s(10), s(12)) if loose else (s(3), s(4)), s(7) if loose else s(3), 0.7))
    metal = radial(img.width, img.height, (232, 234, 238, 255) if loose else (190, 194, 200, 255), (110, 114, 122, 255),
                   cx=cx / 128 - 0.1, cy=cy / 128 - 0.12, radius=0.6)
    img.alpha_composite(masked(metal, m))
    d = ImageDraw.Draw(img)
    d.polygon(s(hexagon), outline=(70, 72, 78, 255), width=s(3))
    d.ellipse(s((cx - 16, cy - 16, cx + 16, cy + 16)), fill=(80, 82, 90, 255))
    for r in (12, 8, 4):  # thread
        d.ellipse(s((cx - r, cy - r, cx + r, cy + r)), outline=(130, 132, 140, 255), width=s(1))
    return finish(img, w, h)


# --- board panel -----------------------------------------------------------------------------
def board_bg():
    w = h = 1024
    img = Image.new("RGBA", (w, h), (18, 22, 28, 255))
    img = add_noise(img, 0.05, 80)
    arr = np.asarray(img).astype(np.float32)
    streaks = noise(1, h, 82, 0.4)[:, 0]  # brushed metal: one brightness per row
    arr[:, :, :3] += streaks[:, None, None] * 30
    img = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w - 1, h - 1), outline=(70, 90, 110, 255), width=6)
    d.rectangle((10, 10, w - 11, h - 11), outline=(30, 40, 52, 255), width=2)
    img.alpha_composite(radial(w, h, (0, 0, 0, 0), (0, 0, 0, 110), radius=0.75))
    return img


TEXTURES = [
    ("ui_gauge_frame_ca.png", gauge_frame, "Рамка шкалы (серая, окрашивается в игре)"),
    ("ui_gauge_fill_ca.png", gauge_fill, "Заливка шкалы: давление, набивка, глубина нажатия (серая)"),
    ("ui_gauge_band_ca.png", gauge_band, "Зелёная зона шкалы (серая, окрашивается)"),
    ("ui_gauge_marker_ca.png", gauge_marker, "Стрелка на шкале"),
    ("ui_board_bg_ca.png", board_bg, "Фон окна"),
    ("icon_cpr_ca.png", icon_cpr, "Значок СЛР в заголовке"),
    ("icon_tourniquet_ca.png", icon_tourniquet, "Значок жгута"),
    ("icon_bandage_ca.png", icon_bandage, "Значок перевязки"),
    ("icon_wheel_ca.png", icon_wheel, "Значок замены колеса"),
    ("cpr_scene_ca.png", cpr_scene, "СЛР: пациент сверху, цель на грудине"),
    ("cpr_hands_up_ca.png", lambda: cpr_hands(False), "СЛР: руки подняты (между нажатиями)"),
    ("cpr_hands_down_ca.png", lambda: cpr_hands(True), "СЛР: руки нажимают"),
    ("cpr_beat_on_ca.png", lambda: cpr_beat(True), "СЛР: метроном, удар"),
    ("cpr_beat_off_ca.png", lambda: cpr_beat(False), "СЛР: метроном, пауза"),
    ("tq_scene_ca.png", tq_scene, "Жгут: рука с раной и наложенным жгутом"),
    *[(f"tq_windlass_{k}_ca.png", (lambda k=k: tq_windlass(k * 22.5)), f"Жгут: вороток, кадр {k} ({k * 22.5:g}°)") for k in range(8)],
    ("bandage_scene_ca.png", bandage_scene, "Перевязка: рана крупно"),
    *[(f"bandage_gauze_{k}_ca.png", (lambda k=k: gauze_stage(k)), f"Перевязка: бинт, стадия {k} из 4") for k in range(1, 5)],
    ("wheel_old_ca.png", lambda: wheel(True), "Колесо: старое (пробитое)"),
    ("wheel_new_ca.png", lambda: wheel(False), "Колесо: новое"),
    ("wheel_nut_tight_ca.png", lambda: nut("tight"), "Гайка затянута"),
    ("wheel_nut_loose_ca.png", lambda: nut("loose"), "Гайка ослаблена"),
    ("wheel_nut_next_ca.png", lambda: nut("next"), "Гайка: следующая по «звезде» (подсказка)"),
    ("wheel_nut_done_ca.png", lambda: nut("done"), "Гайка: готова"),
]


def preview(files):
    cell = 220
    cols = 6
    rows = math.ceil(len(files) / cols)
    sheet = Image.new("RGB", (cols * cell, rows * (cell + 30)), (30, 30, 30))
    checker = Image.new("RGB", (cell - 20, cell - 20), (60, 60, 60))
    cd = ImageDraw.Draw(checker)
    for y in range(0, cell, 20):
        for x in range(0, cell, 20):
            if (x // 20 + y // 20) % 2:
                cd.rectangle((x, y, x + 19, y + 19), fill=(80, 80, 80))
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    for i, name in enumerate(files):
        img = Image.open(OUT / name).convert("RGBA")
        img.thumbnail((cell - 20, cell - 20))
        x, y = (i % cols) * cell + 10, (i // cols) * (cell + 30) + 10
        sheet.paste(checker, (x, y))
        sheet.paste(img, (x + (cell - 20 - img.width) // 2, y + (cell - 20 - img.height) // 2), img)
        ImageDraw.Draw(sheet).text((x, y + cell - 16), f"{name} {Image.open(OUT / name).size[0]}x{Image.open(OUT / name).size[1]}", font=font, fill=(220, 220, 220))
    return sheet


def main():
    written = []
    rows = []
    for name, fn, desc in TEXTURES:
        img = fn()
        w, h = img.size
        assert w & (w - 1) == 0 and h & (h - 1) == 0, (name, img.size)
        save(img, name)
        written.append(name)
        rows.append((name, w, h, desc))
    preview(written).save(OUT / "_preview.png")
    with open(OUT / "_list.tsv", "w", encoding="utf-8") as f:
        for r in rows:
            f.write("\t".join(map(str, r)) + "\n")
    print(f"{len(written)} textures in {OUT}")


if __name__ == "__main__":
    main()
