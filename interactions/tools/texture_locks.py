"""Lit scenes and sprites of the lock games (lockpick, safe, terminal), drawn with texture_render.

Geometry shared with the SQF (PMCI_fnc_boardMarks, PMCI_fnc_boardLayout):
  lock: keyhole and plug centre (512, 300); the plug picture 224 px wide is centred there,
        the 448 px pick picture too (its pick points up from the centre).
  safe: dial centre (400, 256), drawn 352 px wide; index mark above it; the listening
        device's lamp at (840, 152).
  terminal: the screen spans x 112-912, y 40-472.
"""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from texture_render import S, Canvas, blobs, blur, dome, flat, grid, mask, material, noise, shade
from texture_scenes import metal_part, tint, vignette

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
KEYHOLE = (512, 300)
DIAL = (400, 256)


def wood_back(c, seed, tone=(120, 84, 52)):
    """Planks of a wooden crate, running across."""
    x, y = grid(c)
    wood = material("Wood066", c.w, c.h, S(380), tint=tone, tint_mix=0.6, contrast=1.1)
    gaps = np.zeros((c.h, c.w), np.float32)
    for yy in (40, 170, 300, 430):
        gaps = np.maximum(gaps, np.clip(1 - np.abs(y - yy) / 3, 0, 1))
    h = noise(c.w, c.h, seed, S(40)) * 0.08 - gaps * 0.6
    c.put(shade(wood, h, strength=S(10), spec=0.12, ambient=0.42), np.ones((c.h, c.w)))
    tint(c, gaps, (0.05, 0.03, 0.02), 0.8)


def disc(c, cx, cy, r):
    return blobs(c, [(cx, cy, r)])


def text_mask(c, items, font_path, size):
    """Mask of texts [(string, x, y, angle deg)] centred on (x, y), turned by angle (clockwise)."""
    out = Image.new("L", (c.w, c.h), 0)
    font = ImageFont.truetype(font_path, int(S(size)))
    for text, tx, ty, angle in items:
        box = font.getbbox(text)
        w, h = box[2] - box[0] + 8, box[3] - box[1] + 8
        img = Image.new("L", (w, h), 0)
        ImageDraw.Draw(img).text((4 - box[0], 4 - box[1]), text, font=font, fill=255)
        img = img.rotate(-angle, resample=Image.BICUBIC, expand=True)
        out.paste(255, (int(S(tx) - img.width / 2), int(S(ty) - img.height / 2)), img)
    return np.asarray(out).astype(np.float32) / 255.0


# --- lock picking ----------------------------------------------------------------------
def lock_scene():
    """A steel lock plate on a crate, the keyhole housing at (512, 300)."""
    c = Canvas(1024, 512)
    wood_back(c, 501)
    x, y = grid(c)
    kx, ky = KEYHOLE
    plate = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((332, 60, 692, 486)), radius=S(26), fill=255)), S(0.8))
    metal_part(c, plate, (112, 112, 116), metal=0.7, rough=0.05, height=0.25, material_name="Metal046A")
    screws = blobs(c, [(362, 92, 11), (662, 92, 11), (362, 454, 11), (662, 454, 11)])
    metal_part(c, screws, (150, 150, 150), metal=0.8, height=0.9)
    for sx, sy in ((362, 92), (662, 92), (362, 454), (662, 454)):
        tint(c, ((np.abs(y - sy) < 2) & (np.abs(x - sx) < 8)).astype(np.float32), (0.1, 0.1, 0.1), 0.8)
    # Housing ring around the plug, a dark gap, and the half-circle the pick moves along.
    ring = np.clip(disc(c, kx, ky, 128) - disc(c, kx, ky, 112), 0, 1)
    metal_part(c, ring, (176, 140, 70), metal=0.85, height=0.7, material_name="Metal046A")
    tint(c, np.clip(disc(c, kx, ky, 113) - disc(c, kx, ky, 108), 0, 1), (0.02, 0.02, 0.02), 0.9)
    r = np.hypot(x - kx, y - ky)
    arc = (np.abs(r - 150) < 1.6) * (y < ky)
    tint(c, blur(arc.astype(np.float32), S(0.6)), (0.85, 0.82, 0.7), 0.35)
    tint(c, np.clip(1 - np.abs(r - 230) / 70, 0, 1) * 0.5 * (y < ky + 60), (0.0, 0.0, 0.0), 0.25)
    return vignette(c)


def lock_plug():
    """The brass plug with its keyway and the tension wrench in it; turns about its centre."""
    c = Canvas(256, 256)
    x, y = grid(c)
    face = disc(c, 128, 128, 110)
    metal_part(c, face, (196, 156, 80), metal=0.9, rough=0.05, height=0.35, material_name="Metal046A")
    for px in (88, 168):  # pin holes
        tint(c, disc(c, px, 128, 6), (0.12, 0.09, 0.04), 0.7)
    keyway = blur(mask(c.w, c.h, lambda d: d.polygon(S([(122, 70), (134, 70), (134, 150), (138, 160), (134, 186), (122, 186), (118, 160), (122, 150)]), fill=255)), S(0.6))
    tint(c, keyway, (0.02, 0.02, 0.02), 0.95)
    # Tension wrench: in the bottom of the keyway, bent out towards the lower right.
    wrench = blur(mask(c.w, c.h, lambda d: (d.rectangle(S((122, 164, 134, 204)), fill=255),
                                               d.polygon(S([(122, 192), (134, 202), (236, 232), (230, 246)]), fill=255))), S(0.5))
    c.shadow(wrench, S(3), S(4), S(3), 0.5)
    steel = material("Metal046A", c.w, c.h, S(60))
    steel["color"] = steel["color"] * 0.5 + 0.4
    c.put(shade(steel, dome(wrench, S(3)) * 0.6, strength=S(6), metal=0.9, spec=0.7), wrench)
    return c.image()


def lock_pick():
    """A pick from the centre (the keyhole) straight up, its handle at the top."""
    c = Canvas(512, 512)
    x, y = grid(c)
    shaft = ((np.abs(x - 256) < 5) & (y > 118) & (y < 262)).astype(np.float32)
    hook = ((np.abs(x - 249) < 5) & (y > 244) & (y < 268)).astype(np.float32)
    handle = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((240, 20, 272, 128)), radius=S(10), fill=255)), S(0.6))
    metal = blur(np.maximum(shaft, hook), S(0.5))
    c.shadow(np.maximum(metal, handle), S(4), S(6), S(4), 0.5)
    steel = material("Metal046A", c.w, c.h, S(60))
    steel["color"] = steel["color"] * 0.5 + 0.45
    c.put(shade(steel, dome(metal, S(3)) * 0.5, strength=S(6), metal=0.95, spec=0.8), metal)
    grip = flat(c.w, c.h, (34, 36, 40), rough=0.5)
    c.put(shade(grip, dome(handle, S(10)) * 0.8 + np.sin(y * 1.2) * 0.03 * handle, strength=S(10), spec=0.25), handle)
    return c.image()


# --- safe ----------------------------------------------------------------------------------
def safe_scene():
    """A safe door: dial housing at (400, 256) with the index above it, the handle, and the
    listening device clamped on the right with its lamp at (840, 152)."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    door = material("Metal041A", c.w, c.h, S(420), tint=(70, 78, 86), tint_mix=0.85, contrast=0.6)
    h = noise(c.w, c.h, 601, S(80)) * 0.05
    c.put(shade(door, h, strength=S(10), metal=0.5, spec=0.25), np.ones((c.h, c.w)))
    edge = np.clip(1 - np.minimum.reduce([x - 18, 1006 - x, y - 14, 498 - y]) / 6, 0, 1)
    tint(c, edge, (0.03, 0.03, 0.03), 0.6)
    dx, dy = DIAL
    housing = disc(c, dx, dy, 200)
    metal_part(c, housing, (150, 150, 156), metal=0.85, rough=0.05, height=0.3, material_name="Metal046A")
    tint(c, np.clip(disc(c, dx, dy, 182) - disc(c, dx, dy, 177), 0, 1), (0.02, 0.02, 0.02), 0.7)
    index = blur(mask(c.w, c.h, lambda d: d.polygon(S([(dx - 10, 60), (dx + 10, 60), (dx, 80)]), fill=255)), S(0.5))
    tint(c, index, (0.95, 0.15, 0.1), 0.95)
    # Handle: three spokes on a hub.
    hub = disc(c, 650, 256, 34)
    spokes = np.zeros((c.h, c.w), np.float32)
    for a in (0, 120, 240):
        ang = math.radians(a - 90)
        u = (x - 650) * math.cos(ang) + (y - 256) * math.sin(ang)
        v = -(x - 650) * math.sin(ang) + (y - 256) * math.cos(ang)
        spokes = np.maximum(spokes, ((u > 0) & (u < 96) & (np.abs(v) < 9)).astype(np.float32))
        spokes = np.maximum(spokes, disc(c, 650 + 100 * math.cos(ang), 256 + 100 * math.sin(ang), 16))
    metal_part(c, blur(spokes, S(0.6)), (180, 180, 186), metal=0.9, height=0.8, material_name="Metal046A")
    metal_part(c, hub, (160, 160, 166), metal=0.9, height=0.8, material_name="Metal046A")
    # The listening device: a dark box with a needle window and the lamp; its cable to the door.
    cable = blur(mask(c.w, c.h, lambda d: d.line(S([(800, 420), (740, 470), (620, 440), (560, 380)]), fill=255, width=S(8), joint="curve")), S(0.8))
    metal_part(c, cable, (30, 30, 30), metal=0.1, height=0.8)
    pad = disc(c, 560, 380, 22)
    metal_part(c, pad, (120, 120, 126), metal=0.8, height=0.9)
    box = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((770, 70, 990, 440)), radius=S(18), fill=255)), S(0.8))
    c.shadow(box, S(8), S(10), S(10), 0.6)
    plastic = material("Plastic018B", c.w, c.h, S(200), tint=(40, 44, 40), tint_mix=0.9)
    c.put(shade(plastic, dome(box, S(14)) * 0.4, strength=S(10), spec=0.3), box)
    window = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((792, 200, 968, 300)), radius=S(8), fill=255)), S(0.6))
    tint(c, window, (0.82, 0.8, 0.66), 0.95)
    for k in range(11):
        tx = 806 + 15 * k
        tint(c, ((np.abs(x - tx) < 1.2) & (y > 206) & (y < 222 + 8 * (k % 5 == 0))).astype(np.float32), (0.1, 0.1, 0.1), 0.9)
    tint(c, disc(c, 840, 152, 26), (0.05, 0.08, 0.05), 0.95)  # unlit lamp socket
    tint(c, np.clip(disc(c, 840, 152, 20) * 0.9, 0, 1), (0.1, 0.3, 0.12), 0.9)
    for kx in (900, 940):  # knobs
        metal_part(c, disc(c, kx, 152, 14), (60, 60, 64), metal=0.4, height=0.8)
    for gy in (330, 360, 390):  # speaker grille
        tint(c, ((np.abs(y - gy) < 3) & (x > 800) & (x < 960)).astype(np.float32), (0.02, 0.02, 0.02), 0.8)
    return vignette(c)


def safe_dial():
    """The dial: 100 marks, numbers every 10 going up anticlockwise (0 at the top), a grip
    ring and a knob. The board turns it 3.6 degrees per number."""
    c = Canvas(512, 512)
    x, y = grid(c)
    r = np.hypot(x - 256, y - 256)
    body = disc(c, 256, 256, 250)
    c.shadow(body, S(6), S(8), S(8), 0.6)
    face = material("Metal046A", c.w, c.h, S(120))
    face["color"] = face["color"] * 0.25 + 0.04
    knurl = (np.sin(np.arctan2(y - 256, x - 256) * 120) * 0.5 + 0.5) * np.clip((r - 222) / 6, 0, 1)
    c.put(shade(face, dome(body, S(18)) * 0.3 + knurl * 0.05, strength=S(10), metal=0.6, spec=0.4), body)
    ang = np.degrees(np.arctan2(x - 256, -(y - 256)))  # 0 at the top, clockwise
    for k in range(100):
        a = -k * 3.6  # number k sits anticlockwise from the top
        diff = np.abs(((ang - a) + 180) % 360 - 180)
        long = k % 10 == 0
        tick = (diff < (0.55 if long else 0.4)) & (r > (176 if long else 190)) & (r < 212)
        tint(c, blur(tick.astype(np.float32), S(0.4)), (0.92, 0.92, 0.88), 1)
    numbers = []
    for k in range(0, 100, 10):
        a = math.radians(-k * 3.6)
        numbers.append((str(k), 256 + 146 * math.sin(a), 256 - 146 * math.cos(a), -k * 3.6))
    tint(c, text_mask(c, numbers, FONT, 30), (0.95, 0.95, 0.9), 1)
    knob = disc(c, 256, 256, 92)
    metal_part(c, knob, (170, 170, 176), metal=0.9, rough=0.05, height=0.9, material_name="Metal046A")
    grip = (np.sin(np.arctan2(y - 256, x - 256) * 24) > 0.6) * (r > 64) * (r < 90)
    tint(c, blur(grip.astype(np.float32), S(0.5)), (0.15, 0.15, 0.16), 0.5)
    return c.image()


def safe_lamp():
    """The device's lamp, lit (its opacity follows the signal)."""
    c = Canvas(64, 64)
    x, y = grid(c)
    r = np.hypot(x - 32, y - 32)
    glow = np.clip(1 - r / 31, 0, 1) ** 1.5
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.35, 1.0, 0.4], np.float32), glow)
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.85, 1.0, 0.85], np.float32), np.clip(1 - r / 12, 0, 1))
    return c.image()


# --- terminal --------------------------------------------------------------------------------
def terminal_scene():
    """A rugged hacking terminal: the dark green screen spans x 112-912, y 40-472."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    case = material("Plastic018B", c.w, c.h, S(260), tint=(58, 60, 52), tint_mix=0.9)
    h = noise(c.w, c.h, 701, S(60)) * 0.05
    c.put(shade(case, h, strength=S(10), spec=0.25), np.ones((c.h, c.w)))
    bezel = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((92, 22, 932, 490)), radius=S(30), fill=255)), S(1))
    tint(c, bezel, (0.06, 0.06, 0.06), 0.9)
    screen = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((112, 40, 912, 472)), radius=S(26), fill=255)), S(1))
    # Phosphor: dark green, brighter in the middle, scan lines, a faint reflection.
    cx = (x - 512) / 400
    cy = (y - 256) / 216
    glow = np.clip(1 - (cx ** 2 + cy ** 2) * 0.45, 0, 1)
    rgb = np.dstack([0.01 + 0.02 * glow, 0.05 + 0.08 * glow, 0.02 + 0.03 * glow])
    scan = (np.sin(y * math.pi) * 0.5 + 0.5) * 0.25
    rgb = rgb * (1 - scan[:, :, None])
    c.put(rgb.astype(np.float32), screen)
    reflection = np.clip(1 - np.hypot(x - 300, y - 110) / 260, 0, 1) * 0.08
    tint(c, reflection * screen, (0.8, 1, 0.85), 1)
    tint(c, np.clip(1 - np.abs(x - 600) / 2, 0, 1) * (y > 56) * (y < 456) * screen, (0.2, 0.6, 0.25), 0.25)  # column divider
    # Side buttons and a status LED.
    for by in (120, 200, 280, 360):
        metal_part(c, blur(mask(c.w, c.h, lambda d, by=by: d.rounded_rectangle(S((952, by, 1004, by + 50)), radius=S(8), fill=255)), S(0.6)),
                   (70, 72, 66), metal=0.2, height=0.6)
    tint(c, disc(c, 978, 70, 9), (1.0, 0.55, 0.1), 0.95)
    return vignette(c)


# --- icons (flat, like the others) --------------------------------------------------------------
def _icon(draw_fn):
    ss = 4
    img = Image.new("RGBA", (128 * ss, 128 * ss), (0, 0, 0, 0))
    def scale(v):
        if isinstance(v, (tuple, list)):
            return type(v)(scale(t) for t in v)
        return v * ss
    draw_fn(ImageDraw.Draw(img), scale)
    return img.resize((128, 128), Image.LANCZOS)


def icon_lock():
    def draw(d, s):
        d.arc(s((34, 10, 94, 74)), 180, 360, fill=(200, 202, 208, 255), width=s(12))
        d.line(s((40, 42, 40, 60)), fill=(200, 202, 208, 255), width=s(12))
        d.line(s((88, 42, 88, 60)), fill=(200, 202, 208, 255), width=s(12))
        d.rounded_rectangle(s((22, 56, 106, 120)), radius=s(10), fill=(214, 168, 72, 255), outline=(120, 90, 30, 255), width=s(3))
        d.ellipse(s((56, 74, 72, 90)), fill=(40, 30, 10, 255))
        d.polygon(s([(60, 86), (68, 86), (71, 106), (57, 106)]), fill=(40, 30, 10, 255))
    return _icon(draw)


def icon_key():
    def draw(d, s):
        d.ellipse(s((10, 30, 62, 82)), fill=(214, 168, 72, 255), outline=(120, 90, 30, 255), width=s(3))
        d.ellipse(s((26, 46, 46, 66)), fill=(0, 0, 0, 0))
        d.rectangle(s((58, 50, 118, 62)), fill=(214, 168, 72, 255))
        for kx in (92, 108):
            d.rectangle(s((kx, 62, kx + 8, 80)), fill=(214, 168, 72, 255))
    return _icon(draw)


def icon_keypad():
    def draw(d, s):
        d.rounded_rectangle(s((22, 6, 106, 122)), radius=s(10), fill=(60, 64, 70, 255), outline=(150, 154, 160, 255), width=s(3))
        d.rectangle(s((32, 16, 96, 36)), fill=(40, 120, 60, 255))
        for row in range(4):
            for col in range(3):
                px, py = 34 + col * 22, 46 + row * 18
                d.rounded_rectangle(s((px, py, px + 16, py + 12)), radius=s(3), fill=(200, 202, 208, 255))
    return _icon(draw)


def icon_lockpick():
    def draw(d, s):
        d.ellipse(s((24, 24, 104, 104)), fill=(214, 168, 72, 255), outline=(120, 90, 30, 255), width=s(4))
        d.rectangle(s((58, 40, 70, 88)), fill=(30, 22, 8, 255))
        d.line(s((64, 64, 120, 8)), fill=(210, 214, 220, 255), width=s(6))
        d.line(s((64, 90, 120, 120)), fill=(150, 154, 160, 255), width=s(7))
    return _icon(draw)


def icon_terminal():
    def draw(d, s):
        d.rounded_rectangle(s((8, 16, 120, 104)), radius=s(10), fill=(40, 42, 38, 255), outline=(150, 154, 140, 255), width=s(4))
        d.rectangle(s((18, 26, 110, 94)), fill=(6, 30, 12, 255))
        font = ImageFont.truetype(MONO, s(18))
        d.text(s((24, 32)), ">4719", font=font, fill=(90, 255, 115, 255))
        d.text(s((24, 60)), "#2/4", font=font, fill=(90, 255, 115, 255))
    return _icon(draw)


def icon_safe():
    def draw(d, s):
        d.rounded_rectangle(s((10, 10, 118, 118)), radius=s(8), fill=(88, 94, 102, 255), outline=(40, 42, 46, 255), width=s(4))
        d.ellipse(s((30, 30, 86, 86)), fill=(30, 30, 34, 255), outline=(200, 202, 208, 255), width=s(4))
        d.ellipse(s((48, 48, 68, 68)), fill=(200, 202, 208, 255))
        d.polygon(s([(54, 22), (62, 22), (58, 32)]), fill=(230, 50, 40, 255))
        d.rectangle(s((96, 40, 104, 76)), fill=(200, 202, 208, 255))
    return _icon(draw)


TEXTURES = [
    ("icon_lock_ca.png", icon_lock, "Замок: значок модуля и действия «Взломать»"),
    ("icon_key_ca.png", icon_key, "Замок: действие «Открыть ключом»"),
    ("icon_keypad_ca.png", icon_keypad, "Замок: действие «Ввести код»"),
    ("icon_lockpick_ca.png", icon_lockpick, "Значок взлома отмычкой"),
    ("icon_terminal_ca.png", icon_terminal, "Значок взлома кодового замка"),
    ("icon_safe_ca.png", icon_safe, "Значок вскрытия сейфа"),
    ("lock_scene_ca.png", lock_scene, "Отмычка: накладка замка на ящике, скважина в (512, 300)"),
    ("lock_plug_ca.png", lock_plug, "Отмычка: цилиндр с натяжителем (вращается вокруг центра)"),
    ("lock_pick_ca.png", lock_pick, "Отмычка: отмычка вверх от центра (вращается вокруг центра)"),
    ("safe_scene_ca.png", safe_scene, "Сейф: дверца, диск в (400, 256), прибор с лампой в (840, 152)"),
    ("safe_dial_ca.png", safe_dial, "Сейф: диск 0–99 (вращается, 3,6° на деление)"),
    ("safe_lamp_ca.png", safe_lamp, "Сейф: горящая лампа прибора (прозрачность — сигнал)"),
    ("terminal_scene_ca.png", terminal_scene, "Терминал: экран x 112–912, y 40–472"),
]
