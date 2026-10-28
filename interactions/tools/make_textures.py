#!/usr/bin/env python3
"""Draw the PMC Interactions board textures as RGBA PNG, ready for ImageToPAA.

Interface parts (gauge, icons, metronome, panel) are flat drawings made here at 4x and
downscaled. The scenes and sprites (patient, arm, wound, gauze, wheel, nuts) are lit
renders from texture_scenes.py with CC0 materials from ambientCG, downloaded once into
tools/.cache. Noise uses fixed seeds, so the output is reproducible. Sizes are powers of
two; names end in _ca (colour + alpha, converted to DXT5). Greyscale "tint" images are
meant to be coloured in game with ctrlSetTextColor.
Usage: python3 tools/make_textures.py [output folder]
"""
from __future__ import annotations

import math
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from texture_scenes import bandage_scene, cpr_hands, cpr_scene, gauze_stage, nut, tq_scene, tq_windlass, wheel  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "textures"
SS = 4  # supersampling factor


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


# --- CPR metronome (the scenes are in texture_scenes.py) -----------------------------
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
    ("cpr_scene_ca.png", cpr_scene, "СЛР: пострадавший сверху, грудь крупно; место нажатия — (480, 256)"),
    ("cpr_hands_up_ca.png", lambda: cpr_hands(False), "СЛР: руки подняты (между нажатиями); точка нажатия — (128, 150)"),
    ("cpr_hands_down_ca.png", lambda: cpr_hands(True), "СЛР: руки нажимают"),
    ("cpr_beat_on_ca.png", lambda: cpr_beat(True), "СЛР: метроном, удар"),
    ("cpr_beat_off_ca.png", lambda: cpr_beat(False), "СЛР: метроном, пауза"),
    ("tq_scene_ca.png", tq_scene, "Жгут: рука с раной и наложенным жгутом; вороток ставится на (470, 144)"),
    *[(f"tq_windlass_{k}_ca.png", (lambda k=k: tq_windlass(k * 22.5)), f"Жгут: вороток, кадр {k} ({k * 22.5:g}°)") for k in range(8)],
    ("bandage_scene_ca.png", bandage_scene, "Перевязка: рана крупно, центр раны (512, 250)"),
    *[(f"bandage_gauze_{k}_ca.png", (lambda k=k: gauze_stage(k)), f"Перевязка: марля в ране, стадия {k} из 4 (центр картинки на центр раны)") for k in range(1, 5)],
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


def assembled():
    """The layers put together as the boards will show them, for review."""
    def img(name):
        return Image.open(OUT / name).convert("RGBA")

    sheet = Image.new("RGBA", (2048, 1024), (24, 24, 24, 255))
    cpr = img("cpr_scene_ca.png")
    cpr.alpha_composite(img("cpr_hands_down_ca.png"), (480 - 128, 256 - 150))
    tq = img("tq_scene_ca.png")
    tq.alpha_composite(img("tq_windlass_3_ca.png"), (470 - 128, 144 - 128))
    band = img("bandage_scene_ca.png")
    band.alpha_composite(img("bandage_gauze_2_ca.png"), (512 - 256, 250 - 128))
    wheel_img = Image.new("RGBA", (1024, 512), (24, 24, 24, 255))
    wheel_img.alpha_composite(img("wheel_old_ca.png"), (256, 0))
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        state = ["wheel_nut_done_ca.png", "wheel_nut_done_ca.png", "wheel_nut_next_ca.png", "wheel_nut_tight_ca.png", "wheel_nut_loose_ca.png"][k]
        wheel_img.alpha_composite(img(state), (int(512 + 150 * math.cos(a)) - 64, int(256 + 150 * math.sin(a)) - 64))
    for i, part in enumerate([cpr, tq, band, wheel_img]):
        sheet.alpha_composite(part, ((i % 2) * 1024, (i // 2) * 512))
    return sheet.convert("RGB")


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
    assembled().save(OUT / "_assembled.png")
    with open(OUT / "_list.tsv", "w", encoding="utf-8") as f:
        for r in rows:
            f.write("\t".join(map(str, r)) + "\n")
    print(f"{len(written)} textures in {OUT}")


if __name__ == "__main__":
    main()
