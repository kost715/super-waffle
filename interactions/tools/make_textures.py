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
from texture_scenes import (abrasion_pad, abrasion_swab, bandage_scene, cpr_hands, cpr_scene, dirt, edges_runner, edges_strip,  # noqa: E402
                            edges_target, gauze_stage, nut, pressure_hand, pressure_seep, tq_scene, tq_windlass, wheel, wound_abrasion,
                            wound_avulsion, wound_crush, wound_cut, wound_laceration, wound_puncture, wound_velocity,
                            iv_scene, iv_needle, iv_bruise, suture_point, suture_stitch, suture_needle, splint_scene, splint_limb,
                            repair_engine, diag_light, weld_scene, weld_bead, weld_torch, track_scene, track_link, track_pin)

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


def icon_pressure():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((22, 70, 106, 114)), radius=s(6), fill=(240, 240, 234, 255), outline=(170, 170, 160, 255), width=s(3))
    d.ellipse(s((48, 80, 80, 104)), fill=(200, 40, 40, 255))
    for x in (40, 64, 88):  # pressing down
        d.line(s((x, 14, x, 48)), fill=(255, 255, 255, 255), width=s(6))
        d.polygon(s([(x - 11, 44), (x + 11, 44), (x, 60)]), fill=(255, 255, 255, 255))
    return finish(img, w, h)


def icon_edges():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.line(s((10, 66, 118, 62)), fill=(170, 25, 30, 255), width=s(8))
    for x in (32, 64, 96):
        d.rounded_rectangle(s((x - 8, 26, x + 8, 102)), radius=s(4), fill=(245, 242, 232, 255), outline=(150, 150, 140, 255), width=s(2))
    return finish(img, w, h)


def icon_clean():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.ellipse(s((10, 50, 100, 112)), fill=(220, 90, 85, 255))
    for x, y in ((34, 76), (52, 92), (70, 70), (44, 64)):
        d.ellipse(s((x - 4, y - 4, x + 4, y + 4)), fill=(90, 70, 50, 255))
    d.ellipse(s((64, 18, 118, 66)), fill=(245, 245, 240, 255), outline=(170, 170, 160, 255), width=s(3))
    for x, y in ((26, 30), (44, 16)):  # sparkle
        d.line(s((x - 7, y, x + 7, y)), fill=(255, 255, 255, 255), width=s(3))
        d.line(s((x, y - 7, x, y + 7)), fill=(255, 255, 255, 255), width=s(3))
    return finish(img, w, h)


def icon_iv():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((34, 10, 82, 70)), radius=s(10), fill=(200, 40, 40, 255), outline=(120, 20, 20, 255), width=s(3))
    d.rectangle(s((44, 22, 72, 30)), fill=(255, 255, 255, 200))
    d.line(s((58, 70, 58, 92, 96, 110)), fill=(220, 220, 225, 255), width=s(4), joint="curve")
    d.line(s((96, 110, 118, 120)), fill=(190, 190, 195, 255), width=s(3))
    return finish(img, w, h)


def icon_suture():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.line(s((10, 70, 118, 66)), fill=(170, 25, 30, 255), width=s(6))
    for x in (30, 58, 86):
        d.line(s((x - 4, 46, x + 4, 90)), fill=(40, 50, 110, 255), width=s(5))
    d.arc(s((70, 10, 120, 60)), 180, 330, fill=(210, 210, 215, 255), width=s(5))
    return finish(img, w, h)


def icon_splint():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((8, 52, 120, 80)), radius=s(8), fill=(235, 125, 40, 255), outline=(150, 70, 20, 255), width=s(3))
    d.line(s((16, 66, 60, 66)), fill=(240, 235, 225, 255), width=s(10))
    d.line(s((66, 66, 112, 52)), fill=(240, 235, 225, 255), width=s(10))
    for x in (34, 92):
        d.rectangle(s((x - 6, 44, x + 6, 88)), fill=(60, 60, 64, 255))
    return finish(img, w, h)


def icon_diagnose():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s((16, 40, 96, 110)), radius=s(10), fill=(120, 124, 132, 255), outline=(70, 72, 78, 255), width=s(3))
    for x in (34, 56, 78):
        d.rectangle(s((x - 6, 26, x + 6, 42)), fill=(90, 92, 98, 255))
    d.ellipse(s((84, 10, 118, 44)), fill=(240, 70, 50, 255), outline=(255, 200, 190, 255), width=s(3))
    d.line(s((40, 76, 52, 88, 76, 60)), fill=(80, 220, 110, 255), width=s(6), joint="curve")
    return finish(img, w, h)


def icon_weld():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    d.rectangle(s((6, 70, 122, 110)), fill=(110, 114, 82, 255))
    d.line(s((14, 90, 70, 88)), fill=(200, 120, 50, 255), width=s(8))
    d.line(s((70, 88, 116, 92)), fill=(20, 20, 20, 255), width=s(3))
    d.line(s((74, 84, 116, 30)), fill=(40, 40, 44, 255), width=s(10))
    d.ellipse(s((62, 74, 84, 96)), fill=(255, 240, 200, 255))
    return finish(img, w, h)


def icon_track():
    w = h = 128
    img = canvas(w, h)
    d = ImageDraw.Draw(img)
    for x in (8, 36, 74, 102):
        d.rounded_rectangle(s((x, 34, x + 22, 94)), radius=s(4), fill=(110, 106, 98, 255), outline=(60, 58, 54, 255), width=s(2))
    d.rounded_rectangle(s((52, 20, 74, 80)), radius=s(4), fill=(160, 150, 120, 255), outline=(90, 84, 70, 255), width=s(2))
    d.line(s((70, 64, 122, 64)), fill=(200, 200, 205, 255), width=s(6))
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
    ("icon_pressure_ca.png", icon_pressure, "Значок прижатия раны"),
    ("icon_edges_ca.png", icon_edges, "Значок сведения краёв раны"),
    ("icon_clean_ca.png", icon_clean, "Значок обработки ссадины"),
    ("icon_iv_ca.png", icon_iv, "Значок капельницы"),
    ("icon_suture_ca.png", icon_suture, "Значок зашивания"),
    ("icon_splint_ca.png", icon_splint, "Значок шины"),
    ("icon_wheel_ca.png", icon_wheel, "Значок замены колеса"),
    ("icon_diagnose_ca.png", icon_diagnose, "Значок ремонта узла"),
    ("icon_weld_ca.png", icon_weld, "Значок заплатки корпуса"),
    ("icon_track_ca.png", icon_track, "Значок ремонта гусеницы"),
    ("cpr_scene_ca.png", cpr_scene, "СЛР: пострадавший сверху, грудь крупно; место нажатия — (480, 256)"),
    ("cpr_hands_up_ca.png", lambda: cpr_hands(False), "СЛР: руки подняты (между нажатиями); точка нажатия — (128, 150)"),
    ("cpr_hands_down_ca.png", lambda: cpr_hands(True), "СЛР: руки нажимают"),
    ("cpr_beat_on_ca.png", lambda: cpr_beat(True), "СЛР: метроном, удар"),
    ("cpr_beat_off_ca.png", lambda: cpr_beat(False), "СЛР: метроном, пауза"),
    ("tq_scene_ca.png", tq_scene, "Жгут: рука с раной и наложенным жгутом; вороток ставится на (470, 144)"),
    *[(f"tq_windlass_{k}_ca.png", (lambda k=k: tq_windlass(k * 22.5)), f"Жгут: вороток, кадр {k} ({k * 22.5:g}°)") for k in range(8)],
    ("bandage_scene_ca.png", bandage_scene, "Перевязка: рана крупно, центр раны (512, 250)"),
    *[(f"bandage_gauze_{k}_ca.png", (lambda k=k: gauze_stage(k)), f"Перевязка: марля в ране, стадия {k} из 4 (центр картинки на центр раны)") for k in range(1, 5)],
    ("wound_velocity_ca.png", wound_velocity, "Тампонада: огнестрельное ранение (центр (512, 248))"),
    ("wound_puncture_ca.png", wound_puncture, "Тампонада: колотая рана"),
    ("wound_avulsion_ca.png", wound_avulsion, "Прижатие: авульсия (сорванный участок кожи)"),
    ("wound_crush_ca.png", wound_crush, "Прижатие: размозжение"),
    ("pressure_hand_light_ca.png", lambda: pressure_hand(False), "Прижатие: рука на салфетке, давит слабо (центр на центр раны)"),
    ("pressure_hand_firm_ca.png", lambda: pressure_hand(True), "Прижатие: рука давит в зоне"),
    ("pressure_seep_ca.png", pressure_seep, "Прижатие: кровь из-под салфетки (прозрачность — от недожима)"),
    ("wound_cut_ca.png", wound_cut, "Сведение краёв: порез по линии x 232–792, y 256"),
    ("wound_laceration_ca.png", wound_laceration, "Сведение краёв: рваная рана по той же линии"),
    ("edges_strip_ca.png", edges_strip, "Сведение краёв: наложенная полоска"),
    ("edges_target_ca.png", edges_target, "Сведение краёв: подсветка открытого участка (растягивается)"),
    ("edges_runner_ca.png", edges_runner, "Сведение краёв: бегунок"),
    ("wound_abrasion_ca.png", wound_abrasion, "Обработка: ссадина"),
    *[(f"dirt_{k}_ca.png", (lambda k=k: dirt(239 + k)), f"Обработка: грязь, вариант {k}") for k in range(1, 4)],
    ("abrasion_swab_ca.png", abrasion_swab, "Обработка: тампон (идёт за мышью)"),
    ("abrasion_pad_ca.png", abrasion_pad, "Обработка: повязка на очищенной ссадине"),
    ("iv_scene_ca.png", iv_scene, "Капельница: рука с жгутом и веной (линия (300, 262)–(760, 238))"),
    ("iv_needle_ca.png", iv_needle, "Капельница: катетер, кончик иглы в (20, 236)"),
    ("iv_bruise_ca.png", iv_bruise, "Капельница: лопнувшая вена"),
    ("suture_point_ca.png", suture_point, "Зашивание: следующая точка"),
    ("suture_stitch_ca.png", suture_stitch, "Зашивание: готовый стежок"),
    ("suture_needle_ca.png", suture_needle, "Зашивание: игла в иглодержателе, острие в (12, 116)"),
    ("splint_scene_ca.png", splint_scene, "Шина: рука с переломом в (512, 256) и шина"),
    *[(f"splint_limb_{k}_ca.png", (lambda k=k: splint_limb(k)), f"Шина: сломанная часть, угол {(k - 3) * 10}°") for k in range(7)],
    ("repair_engine_ca.png", repair_engine, "Ремонт узла: моторный отсек, 5 деталей"),
    ("diag_ok_ca.png", lambda: diag_light(True), "Ремонт узла: деталь исправна"),
    ("diag_bad_ca.png", lambda: diag_light(False), "Ремонт узла: неисправность"),
    ("weld_scene_ca.png", weld_scene, "Заплатка: лист корпуса с трещиной"),
    ("weld_bead_ca.png", weld_bead, "Заплатка: кусок шва (растягивается)"),
    ("weld_torch_ca.png", weld_torch, "Заплатка: горелка, дуга в (24, 232)"),
    ("track_scene_ca.png", track_scene, "Гусеница: разрыв в x 512"),
    ("track_link_ca.png", track_link, "Гусеница: болтающееся звено"),
    ("track_pin_ca.png", track_pin, "Гусеница: палец"),
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

    sheet = Image.new("RGBA", (2048, 2048), (24, 24, 24, 255))
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
    pressure = img("wound_avulsion_ca.png")
    pressure.alpha_composite(img("pressure_seep_ca.png"), (256, 128))
    pressure.alpha_composite(img("pressure_hand_firm_ca.png"), (256, 0))
    edges = img("wound_laceration_ca.png")
    for k, (lo, hi) in enumerate([(0.08, 0.17), (0.25, 0.31), (0.38, 0.46), (0.5, 0.56), (0.62, 0.69), (0.74, 0.8), (0.86, 0.94)]):
        if k < 3:
            centre = 232 + 560 * (lo + hi) / 2
            edges.alpha_composite(img("edges_strip_ca.png").resize((72, 212)), (round(centre - 36), 150))
        else:
            edges.alpha_composite(img("edges_target_ca.png").resize((round(560 * (hi - lo)), 120)), (round(232 + 560 * lo), 196))
    edges.alpha_composite(img("edges_runner_ca.png").resize((40, 212)), (round(232 + 560 * 0.48 - 20), 150))
    clean = img("wound_abrasion_ca.png")
    for k, (x, y) in enumerate([(372, 208), (528, 196), (672, 222), (330, 304), (480, 292), (622, 318)]):
        clean.alpha_composite(img(f"dirt_{k % 3 + 1}_ca.png").resize((130, 130)), (x - 65, y - 65))
    clean.alpha_composite(img("abrasion_swab_ca.png").resize((96, 96)), (440, 250))
    gunshot = img("wound_velocity_ca.png")
    gunshot.alpha_composite(img("bandage_gauze_1_ca.png"), (512 - 256, 250 - 128))
    for i, part in enumerate([cpr, tq, band, wheel_img, pressure, edges, clean, gunshot]):
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
