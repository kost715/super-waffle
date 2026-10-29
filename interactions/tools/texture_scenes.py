"""Realistic scenes for the PMC Interactions boards, drawn with texture_render."""
from __future__ import annotations

import math

import numpy as np

from texture_render import (S, Canvas, _box, blobs, blood_layer, blur, dome, fabric_olive, flat, grid, ground_layer, mask,
                            material, noise, ridges, shade, skin_material, wrinkles)

STUD_RADIUS = 150  # wheel: studs at this radius from the centre of the 512 px image, at -90 + 72*k degrees


# --- wheel ------------------------------------------------------------------------------
def wheel(worn):
    c = Canvas(512, 512)
    x, y = grid(c)
    cx = cy = 256
    r = np.hypot(x - cx, y - cy)
    ang = np.arctan2(y - cy, x - cx)
    tyre = (r <= 250).astype(np.float32)
    c.shadow(tyre, S(8), S(10), S(10), 0.6)
    # Tyre: a torus from radius 196 to 250 with tread blocks on the outer part.
    t = np.clip(1 - ((r - 223) / 27) ** 2, 0, 1) ** 0.5
    tread = ((np.sin(ang * 48) > 0.2) & (r > 236)).astype(np.float32)
    h_tyre = t * 0.9 + tread * 0.12 * t
    rubber = material("Rubber004", c.w, c.h, S(140))
    rubber["color"] = rubber["color"] * (0.55 if worn else 0.45) + (0.03 if worn else 0)
    rubber["color"] *= (1 - 0.45 * tread)[:, :, None]
    c.put(shade(rubber, h_tyre, strength=60, detail_strength=0.8, spec=0.18), tyre * (r > 190))
    # Rim: a dish sloping from its lip (r=196) to the hub, ten round openings.
    rim = (r <= 196).astype(np.float32)
    h_rim = np.clip(1 - r / 196, 0, 1) * 0.35 + np.clip((r - 170) / 26, 0, 1) * 0.5
    holes = np.zeros_like(r)
    for k in range(5):  # ventilation holes between the hub and the studs
        a = math.radians(-90 + 36 + 72 * k)
        hx, hy = cx + 108 * math.cos(a), cy + 108 * math.sin(a)
        holes = np.maximum(holes, (np.hypot((x - hx) * 1.0, (y - hy) * 1.0) < 17).astype(np.float32))
    studs = np.zeros_like(r)
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        sx, sy = cx + STUD_RADIUS * math.cos(a), cy + STUD_RADIUS * math.sin(a)
        studs = np.maximum(studs, np.clip(1 - np.hypot(x - sx, y - sy) / 26, 0, 1))
    hub = np.sqrt(np.clip(1 - (r / 54) ** 2, 0, 1))
    h_rim = h_rim - blur(holes, S(3)) * 0.5 + studs ** 1.5 * 0.18 + hub * 0.45 + np.clip(1 - np.abs(r - 62) / 4, 0, 1) * 0.06
    metal = material("Metal053C" if worn else "Metal041A", c.w, c.h, S(260), rough_bias=0.05 if worn else -0.05)
    if not worn:
        metal["color"] = np.clip(metal["color"] * 1.05, 0, 1)
    lit = shade(metal, h_rim, strength=90, detail_strength=0.5, metal=0.85, spec=0.6, ambient=0.42)
    lit *= (1 - 0.85 * holes)[:, :, None]
    seat = np.zeros_like(r)  # dark stud holes in the raised seats; the nut sprites cover them
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        seat = np.maximum(seat, (np.hypot(x - cx - STUD_RADIUS * math.cos(a), y - cy - STUD_RADIUS * math.sin(a)) < 9).astype(np.float32))
    lit *= (1 - 0.8 * blur(seat, S(1)))[:, :, None]
    c.put(lit, rim)
    if worn:  # mud on the rim and a tear in the tyre
        dirt = np.clip(noise(c.w, c.h, 91, S(8)) * 2 - 0.3, 0, 1) * rim * 0.6
        c.put(np.dstack([np.full_like(r, 0.24), np.full_like(r, 0.19), np.full_like(r, 0.13)]), dirt)
        tear = mask(c.w, c.h, lambda d: d.line(S((400, 440, 470, 360)), fill=255, width=S(7)))
        c.put(np.zeros((c.h, c.w, 3)), blur(tear, S(1)))
    return c.image()


def nut(state):
    c = Canvas(128, 128)
    x, y = grid(c)
    loose = state == "loose"
    if state in ("next", "done"):
        ring = np.clip(1 - np.abs(np.hypot(x - 64, y - 64) - 56) / 5, 0, 1)
        col = np.array((1.0, 0.78, 0.25) if state == "next" else (0.33, 0.85, 0.42), np.float32)
        c.put(np.ones((c.h, c.w, 3)) * col, blur(ring, S(3)) * 0.8)
        c.put(np.ones((c.h, c.w, 3)) * col, ring)
    if loose:  # the threaded stud the nut has backed off
        sx, sy = 80, 82
        d = np.hypot(x - sx, y - sy)
        stud = (d < 17).astype(np.float32)
        thread = (np.sin(d * 2.2) * 0.5 + 0.5) * 0.15
        steel = material("Metal041A", c.w, c.h, S(90))
        steel["color"] *= 0.8
        c.put(shade(steel, np.clip(1 - d / 17, 0, 1) ** 0.5 * 0.5 + thread * 0.4, strength=40, metal=0.6, spec=0.4), stud)
    cx, cy, size, turn = (50, 46, 35, 15) if loose else (64, 64, 38, 0)
    hexagon = [(cx + size * math.cos(math.radians(30 + turn + 60 * k)), cy + size * math.sin(math.radians(30 + turn + 60 * k))) for k in range(6)]
    m = mask(c.w, c.h, lambda d: d.polygon(S(hexagon), fill=255))
    c.shadow(m, S(9) if loose else S(3), S(11) if loose else S(4), S(6) if loose else S(3), 0.7)
    d = np.hypot(x - cx, y - cy)
    h = dome(m, S(4)) * 0.7 + np.clip(1 - np.abs(d - 30) / 4, 0, 1) * -0.06 - np.clip(1 - d / 14, 0, 1) * 0.5
    h += (np.sin(d * 3.2) * 0.012) * (d < 14)
    steel = material("Metal041A", c.w, c.h, S(110), rough_bias=0.05)
    steel["color"] = np.clip(steel["color"] * (1.0 if loose else 0.88), 0, 1)
    c.put(shade(steel, h, strength=60, metal=0.6, spec=0.5, ambient=0.5), m)
    return c.image()


# --- tourniquet --------------------------------------------------------------------------
def arm_outline(x, centre, half_w, sleeve_to, length):
    """Centre line and half width of a forearm: full at the elbow, slimmer at the wrist."""
    t = np.clip((x - sleeve_to) / max(1, length - sleeve_to), 0, 1)
    half = half_w * (1 + 0.07 * np.sin(t * math.pi * 1.1) - 0.24 * t ** 1.5)
    return centre + 5 * np.sin(x / 260), half


def arm(c, centre, half_w, sleeve_to, seed):
    """A bare forearm across the image (off the right edge), sleeve rolled up on the left."""
    x, y = grid(c)
    mid, half = arm_outline(x, centre, half_w, sleeve_to, c.out[0])
    v = (y - mid) / half
    limb = blur(((np.abs(v) < 1) & (x > sleeve_to - 40)).astype(np.float32), S(0.8))
    c.shadow(limb, S(10), S(16), S(16), 0.7)
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1))
    h += noise(c.w, c.h, seed, S(20)) * 0.02 + np.clip(1 - np.abs(v + 0.35) / 0.15, 0, 1) * 0.015 * (x > sleeve_to + 200)
    skin = skin_material(c, seed)
    skin["color"] *= (1 - 0.06 * np.clip(-v, 0, 1) + 0.03 * np.clip(v, 0, 1))[:, :, None]  # paler on the inner side
    curve = 0.5 + 0.5 * np.sqrt(np.clip(h, 0, 1))  # the sides turn away from the light and the camera
    c.put(shade(skin, h * limb, strength=S(half_w) * 0.9, detail_strength=0.35, spec=0.22, occlusion=curve), limb)
    rng = np.random.default_rng(seed)
    n = 260
    hair = mask(c.w, c.h, lambda d: [d.line(S((px, py, px + 9 * math.cos(a), py + 9 * math.sin(a))), fill=255, width=S(1))
                                     for px, py, a in zip(rng.uniform(sleeve_to, c.out[0], n), rng.uniform(centre - half_w, centre + half_w, n),
                                                          rng.uniform(-0.4, 0.4, n))])
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.25, 0.17, 0.12]), hair * limb * (np.abs(v) < 0.8) * 0.35)
    # Sleeve: wider than the arm, rolled into a thick cuff at its end.
    sv = (y - mid) / (half * 1.28)
    sleeve = blur(((np.abs(sv) < 1) & (x < sleeve_to)).astype(np.float32), S(0.8))
    c.shadow(sleeve, S(8), S(12), S(12), 0.65)
    cuff = np.clip(1 - np.abs(x - (sleeve_to - 24)) / 24, 0, 1) ** 0.6
    folds = ridges(c.w, c.h, seed + 5, (S(18), S(7)), (1.0, 0.4)) * 0.35
    hs = np.sqrt(np.clip(1 - sv ** 2, 0, 1)) * (1 + cuff * 0.25) + folds * (1 - cuff) + np.sin((y - mid) / 7) * 0.03 * cuff
    cloth = fabric_olive(c)
    cloth["color"] *= (1 - 0.25 * np.clip(1 - np.abs(x - (sleeve_to - 48)) / 4, 0, 1))[:, :, None]  # seam of the roll
    curve = 0.55 + 0.45 * np.sqrt(np.clip(1 - sv ** 2, 0, 1))
    c.put(shade(cloth, hs * sleeve, strength=S(half_w), detail_strength=1.0, spec=0.06, occlusion=curve), sleeve)
    return limb, mid, half


def drips(c, starts, seed):
    """Blood running down from the given points: tapering streaks ending in a drop."""
    rng = np.random.default_rng(seed)
    pts = []
    for sx, sy, width, length in starts:
        sway = rng.uniform(-0.12, 0.12)
        for t in np.linspace(0, 1, 60):
            r = width * (1 - 0.55 * t) + width * 0.5 * math.exp(-((t - 1) / 0.06) ** 2)
            pts.append((sx + sway * length * t + 2 * math.sin(t * 7), sy + length * t, r))
    return blobs(c, pts)


def wound(c, cx, cy, rx, ry, seed, depth=1.0, n_drips=3):
    """An open wound: reddened skin, smeared blood, pale torn edge, raw tissue, a pool of blood."""
    x, y = grid(c)
    rng = np.random.default_rng(seed)
    edge = 1 + noise(c.w, c.h, seed, S(5)) * 0.3
    d = np.hypot((x - cx) / rx, (y - cy) / ry) / edge
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.6, 0.18, 0.16], np.float32), np.clip(1 - (d - 1) / 1.1, 0, 1) ** 2 * 0.35)
    smear = np.clip(noise(c.w, c.h, seed + 5, S(10)) * 1.6 + 0.1, 0, 1) * np.clip(1 - (d - 0.9) / 0.9, 0, 1)
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.32, 0.03, 0.04], np.float32), smear * 0.6)
    cavity = blur((d < 1).astype(np.float32), S(0.8))
    tissue = material("Leather035D", c.w, c.h, S(70), tint=(150, 34, 34), tint_mix=0.95, contrast=1.8, rough_bias=-0.35)
    margin = np.clip((d - 0.8) / 0.2, 0, 1) ** 2
    tissue["color"] = tissue["color"] * (1 - margin[:, :, None]) + np.array([0.82, 0.62, 0.5], np.float32) * margin[:, :, None]
    tissue["color"] *= (0.55 + 0.45 * np.clip(d, 0, 1))[:, :, None]
    h = -np.clip(1 - d, 0, 1) ** 0.6 * depth + noise(c.w, c.h, seed + 1, S(4)) * 0.06
    c.put(shade(tissue, h, strength=S(min(rx, ry)) * 0.5, detail_strength=0.8, spec=0.6, ambient=0.45), cavity)
    dp = np.hypot((x - cx) / rx, (y - cy - ry * 0.22) / ry) / (1 + noise(c.w, c.h, seed + 2, S(12)) * 0.45)
    pool = blur((dp < 0.6).astype(np.float32), S(0.8))
    blood_layer(c, pool * np.clip(blur(pool, S(10)) * 1.3, 0.35, 0.93), seed + 2)  # thin film at the edge shows the tissue
    starts = []
    for a in rng.uniform(0.45, math.pi - 0.45, n_drips):
        starts.append((cx + rx * 0.85 * math.cos(a), cy + ry * 0.85 * math.sin(a), rng.uniform(3.5, 6) * depth ** 0.5,
                       rng.uniform(30, 75) * depth))
    blood_layer(c, drips(c, starts, seed + 3), seed + 4)


def tq_scene():
    c = Canvas(1024, 512)
    ground_layer(c, seed=31, dark=0.6)
    x, y = grid(c)
    centre, half_w, strap_x = 252, 86, 470
    webbing = material("Fabric030", c.w, c.h, S(60), tint=(40, 40, 42), tint_mix=0.9, contrast=1.5)
    # Free end of the strap lying on the ground below the arm.
    u = x - strap_x - (y - 300) * 0.25
    tail = blur(((np.abs(u) < 28) & (y > 300)).astype(np.float32), S(0.8))
    c.shadow(tail, S(3), S(4), S(4), 0.6)
    c.put(shade(webbing, np.cos(np.clip(u / 28, -1, 1) * 1.2) * 0.3, strength=S(20), detail_strength=1.4, spec=0.12), tail)
    limb, mid, half = arm(c, centre, half_w, 290, 32)
    wound(c, 790, 250, 52, 28, 33)
    # Strap: nylon webbing hugging the arm, a little wider than it.
    v = (y - mid) / (half * 1.07)
    band = np.abs(x - strap_x) < 30
    strap = blur(((np.abs(v) < 1) & band).astype(np.float32), S(0.8))
    c.shadow(strap, S(5), S(7), S(6), 0.7)
    hs = np.sqrt(np.clip(1 - v ** 2, 0, 1)) * 1.07 + np.cos((x - strap_x) / 30 * 1.3) * 0.04
    stitch = (np.abs(np.abs(x - strap_x) - 25) < 1.2) * (np.sin(y * 1.6) > 0)
    webbing["color"] *= (1 - 0.35 * stitch)[:, :, None]
    c.put(shade(webbing, hs * strap, strength=S(half_w), detail_strength=1.4, spec=0.12), strap)
    # Windlass clip on top of the arm (the rod itself is the tq_windlass sprite) and the time label.
    clip = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((strap_x - 44, 126, strap_x + 44, 162)), radius=S(8), fill=255)), S(0.8))
    plastic = material("Plastic018B", c.w, c.h, S(200), tint=(34, 34, 36), tint_mix=0.9)
    c.shadow(clip, S(4), S(6), S(5), 0.7)
    hc = dome(clip, S(8)) * 0.6 - (np.abs(x - strap_x) < 30) * (y > 138) * 0.25 * clip
    c.put(shade(plastic, hc, strength=S(10), spec=0.5), clip)
    label = blur(((np.abs(x - strap_x) < 22) & (y > 300) & (y < 336)).astype(np.float32), S(0.6))
    paper = flat(c.w, c.h, (225, 222, 210), rough=0.7)
    lines = (np.abs(((y - 306) % 9) - 4.5) < 0.8) * (y > 304) * (np.abs(x - strap_x) < 16)
    paper["color"] *= (1 - 0.7 * lines)[:, :, None]
    c.put(shade(paper, hs * 0.3, strength=S(30), spec=0.1), label * 0.95)
    return c.image()


def tq_windlass(angle):
    """The windlass rod seen from above, rotated; lit after rotation so light stays fixed."""
    size = 256
    c = Canvas(size, size)
    x, y = grid(c)
    a = math.radians(angle)
    u = (x - 128) * math.cos(a) + (y - 128) * math.sin(a)
    v = -(x - 128) * math.sin(a) + (y - 128) * math.cos(a)
    rod = ((np.abs(u) < 112) & (np.abs(v) < 14)).astype(np.float32)
    rod *= np.clip((112 - np.abs(u)) / 2, 0, 1)
    rod = blur(rod, S(0.6))
    c.shadow(rod, S(7), S(9), S(6), 0.7)
    h = np.sqrt(np.clip(1 - (v / 14) ** 2, 0, 1)) * rod
    h += (np.abs(u) > 60) * (np.abs(u) < 100) * (np.sin(u * 1.1) > 0.5) * 0.08  # grip ridges
    plastic = material("Plastic018B", c.w, c.h, S(160), tint=(36, 36, 38), tint_mix=0.9)
    plastic["color"][np.abs(u) > 100] = np.array([0.62, 0.12, 0.09])  # red end caps
    c.put(shade(plastic, h, strength=S(14), spec=0.5), rod)
    # Strap twisted around the rod's middle, then the steel rivet.
    knot = blur(((np.abs(u) < 26) & (np.abs(v) < 19)).astype(np.float32), S(0.8))
    webbing = material("Fabric030", c.w, c.h, S(50), tint=(40, 40, 42), tint_mix=0.9, contrast=1.5)
    hk = np.sqrt(np.clip(1 - (v / 19) ** 2, 0, 1)) * 1.1 + np.sin(u * 0.35 + v * 0.5) * 0.08
    c.shadow(knot, S(2), S(3), S(3), 0.5)
    c.put(shade(webbing, hk * knot, strength=S(18), detail_strength=1.3, spec=0.1), knot)
    hub = blur((np.hypot(x - 128, y - 128) < 9).astype(np.float32), S(0.6))
    steel = material("Metal046A", c.w, c.h, S(120))
    c.put(shade(steel, dome(hub, S(4)) * 0.8 + 0.6, strength=S(8), metal=0.8, spec=0.6), hub)
    return c.image()


# --- CPR ---------------------------------------------------------------------------------
CPR_TARGET = (480, 256)  # lower half of the sternum in cpr_scene, output pixels


def cpr_scene():
    """Close-up of a casualty on his back, seen from above: jaw at the left edge, shirt, arms at the sides."""
    c = Canvas(1024, 512)
    ground_layer(c, seed=11, dark=0.62)
    x, y = grid(c)
    folds = ridges(c.w, c.h, 15, (S(46), S(16)), (1.0, 0.35))
    # Upper arms along both sides, half under the torso.
    for cy in (20, 492):
        m = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((236, cy - 52, 1150, cy + 52)), radius=S(50), fill=255)), S(0.8))
        c.shadow(m, S(8), S(12), S(12), 0.6)
        v = np.clip((y - cy) / 52, -1, 1)
        h = np.sqrt(1 - v ** 2) * 0.7 + folds * 0.35
        c.put(shade(fabric_olive(c, tile=170), h * m, strength=S(40), detail_strength=1.0, spec=0.05, occlusion=0.6 + 0.4 * np.sqrt(1 - v ** 2)), m)
    skin = skin_material(c, 12)
    # Neck, and the jaw of the tilted-back head at the left edge (with stubble).
    neck = blur(((np.abs(y - 256) < 56) & (x < 240)).astype(np.float32), S(0.8))
    c.shadow(neck, S(8), S(10), S(10), 0.6)
    v = np.clip((y - 256) / 56, -1, 1)
    hn = np.sqrt(1 - v ** 2) + np.exp(-((x - 128) / 16) ** 2 - (v / 0.3) ** 2) * 0.12
    c.put(shade(skin, hn * neck, strength=S(50), detail_strength=0.3, spec=0.2, occlusion=0.5 + 0.5 * np.sqrt(1 - v ** 2)), neck)
    # Helmet on the head, which lies off the left edge; chin strap across the neck.
    helmet = blur(mask(c.w, c.h, lambda d: d.ellipse(S((-170, 136, 112, 376)), fill=255)), S(0.8))
    c.shadow(helmet, S(8), S(12), S(14), 0.7)
    hh = dome(helmet, S(70)) * 0.9 + dome(helmet, S(6)) * 0.1
    rim = np.clip(1 - np.abs(np.hypot((x + 29) / 141, (y - 256) / 120) - 0.93) / 0.03, 0, 1)
    shell = material("Plastic018B", c.w, c.h, S(240), tint=(132, 116, 84), tint_mix=0.9, contrast=0.8, rough_bias=0.25)
    shell["color"] *= (1 + noise(c.w, c.h, 18, S(20))[:, :, None] * 0.08)
    c.put(shade(shell, hh - rim * 0.04, strength=S(90), detail_strength=0.4, spec=0.12, occlusion=0.6 + 0.4 * hh), helmet)
    strap = blur(((np.abs(x - 160 + (y - 256) * 0.08) < 7) & (np.abs(y - 256) < 60)).astype(np.float32), S(0.6)) * (1 - helmet)
    c.shadow(strap, S(2), S(3), S(2), 0.5)
    v2 = np.clip((y - 256) / 58, -1, 1)
    c.put(shade(material("Fabric030", c.w, c.h, S(40), tint=(60, 56, 44), tint_mix=0.9), np.sqrt(1 - v2 ** 2) * 0.6, strength=S(40), spec=0.05), strap)
    # Torso: a broad, gently rounded plateau, narrower towards the waist.
    half = 180 - 18 * np.clip((x - 300) / 700, 0, 1)
    ay = np.abs(y - 256)
    corner = np.clip((ay - (half - 80)) / 80, 0, 1)
    start = 200 + 80 * (1 - np.sqrt(np.clip(1 - corner ** 2, 0, 1)))
    torso = blur(((ay < half) & (x > start)).astype(np.float32), S(0.8))
    c.shadow(torso, S(10), S(14), S(16), 0.7)
    ht = dome(torso, S(110)) * 0.9
    for py in (172, 340):  # chest muscles under the shirt
        ht += np.exp(-((x - 430) / 100) ** 2 - ((y - py) / 75) ** 2) * 0.1
    ht += folds * 0.25
    # Chest pockets with flaps; quarter zip from the collar down the sternum.
    pockets = mask(c.w, c.h, lambda d: [d.rectangle(S((384, a, 548, a + 90)), fill=255) for a in (124, 298)])
    flaps = mask(c.w, c.h, lambda d: [d.rounded_rectangle(S((376, a - 8, 556, a + 30)), radius=S(10), fill=255) for a in (124, 298)])
    ht += blur(pockets, S(3)) * 0.05 + blur(flaps, S(1.5)) * 0.05
    edge = lambda m: np.clip(blur(m, S(1.2)) * (1 - blur(m, S(1.2))) * 4, 0, 1)
    stitch = lambda m: edge(blur(m, S(5)) > 0.5) * (np.sin((x + y) * 2.4) > 0)
    cloth = fabric_olive(c, tile=170)
    cloth["color"] *= (1 - 0.3 * np.clip(edge(pockets) + edge(flaps), 0, 1) - 0.15 * np.clip(stitch(flaps), 0, 1))[:, :, None]
    c.put(shade(cloth, ht * torso, strength=S(120), detail_strength=1.0, spec=0.05, occlusion=0.55 + 0.45 * np.sqrt(np.clip(ht, 0, 1))), torso)
    zip_line = (np.abs(y - 256) < 4) & (x > 228) & (x < 560)
    teeth = (np.abs(y - 256) < 3.5) * (np.sin(x * 2.6) > 0) * (x > 228) * (x < 560)
    c.put(np.ones((c.h, c.w, 3)) * 0.1, blur(zip_line.astype(np.float32), S(0.5)) * 0.8)
    c.put(np.ones((c.h, c.w, 3)) * 0.3, teeth.astype(np.float32))
    pull = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((232, 249, 262, 263)), radius=S(4), fill=255)), S(0.6))
    c.shadow(pull, S(2), S(3), S(2), 0.6)
    c.put(shade(material("Metal046A", c.w, c.h, S(80)), dome(pull, S(3)), strength=S(6), metal=0.7, spec=0.5), pull)
    # Crew collar where the neck enters the shirt.
    d = np.hypot((x - 196) / 46, (y - 256) / 70)
    collar = blur(((d > 0.82) & (d < 1.12) & (x > 196)).astype(np.float32), S(0.8))
    c.shadow(collar, S(3), S(4), S(4), 0.5)
    rib = np.sin(np.arctan2(y - 256, x - 196) * 60) * 0.04
    hc = np.clip(1 - np.abs(d - 0.97) / 0.15, 0, 1) ** 0.5 * 0.6 + rib
    c.put(shade(fabric_olive(c, tile=90, tone=(80, 86, 58)), hc * collar, strength=S(12), detail_strength=0.8, spec=0.05), collar)
    return c.image()


def cpr_hands(pressed):
    """Rescuer's hands seen from his eyes (256 x 512): fingers laced, forearms running to the bottom edge."""
    c = Canvas(256, 512)
    x, y = grid(c)
    k = 0.95 if pressed else 1.0
    cx, cy = 128, 120

    def T(pts):
        return [(cx + (px - cx) * k, cy + (py - cy) * k) for px, py in pts]

    def poly(pts):
        return blur(mask(c.w, c.h, lambda d: d.polygon(S(T(pts)), fill=255)), S(0.8))

    def capsule(x0, y0, x1, y1, r0, r1=None):
        (a, b), (e, f) = T([(x0, y0), (x1, y1)])
        r1 = r0 if r1 is None else r1
        return blobs(c, [(a + (e - a) * t, b + (f - b) * t, (r0 + (r1 - r0) * t) * k) for t in np.linspace(0, 1, 40)])

    skin = skin_material(c, 21, tone=(205, 158, 128), tile=200)
    if pressed:  # flushed skin, blanched knuckles under pressure
        skin["color"] = np.clip(skin["color"] * np.array([1.05, 0.95, 0.93]), 0, 1)

    def lay(m, h, strength, occlusion=None):
        c.put(shade(skin, h * m, strength=S(strength), detail_strength=0.3, spec=0.2, occlusion=occlusion), m)

    left = capsule(112, 188, 22, 540, 26, 42)
    right = capsule(144, 188, 234, 540, 26, 42)
    back = poly([(98, 196), (158, 196), (174, 150), (178, 104), (168, 94), (88, 94), (78, 104), (82, 150)])
    lower_thumb = capsule(168, 158, 182, 120, 11, 9)
    top_thumb = capsule(88, 160, 76, 118, 12, 10)
    lower_fingers = np.maximum.reduce([capsule(102 + 24 * i, 98, 102 + 24 * i, 80, 6) for i in range(3)])
    top_fingers = np.maximum.reduce([capsule(91 + 24 * i, 104, 91 + 24 * i, tip, 10.5, 9.5) for i, tip in enumerate((76, 69, 71, 80))])
    whole = np.maximum.reduce([left, right, back, lower_thumb, top_thumb, top_fingers])
    lift = 0.3 if pressed else 1.0
    c.shadow(whole, S(5 + 9 * lift), S(6 + 13 * lift), S(5 + 7 * lift), 0.75 - 0.25 * lift)
    for arm_m in (right, left):
        ha = dome(arm_m, S(18))
        lay(arm_m, ha, 30, occlusion=0.65 + 0.35 * ha)
    lay(lower_thumb, dome(lower_thumb, S(6)), 12, occlusion=0.8 + 0.2 * dome(lower_thumb, S(6)))
    lay(lower_fingers, dome(lower_fingers, S(3)) * 0.6, 8, occlusion=np.full_like(x, 0.5))
    hb = dome(back, S(24))
    knuckle_y = cy + (100 - cy) * k
    knuckles = sum(np.exp(-(((x - cx - (91 + 24 * i - cx) * k) / 9) ** 2 + ((y - knuckle_y) / 7) ** 2)) for i in range(4))
    tendons = sum(np.exp(-((x - (128 + (91 + 24 * i - 128) * np.clip((196 - y) / 96, 0, 1) * k)) / 4) ** 2)
                  * np.clip((196 - y) / 96, 0, 1) ** 2 for i in range(4))
    lay(back, hb + tendons * 0.015 + knuckles * 0.12, 18, occlusion=0.78 + 0.22 * hb)
    hf = dome(top_fingers, S(6))
    tips = np.clip((cy + (84 - cy) * k - y) / 12, 0, 1)  # fingertips curl down over the lower hand
    crease = np.exp(-((y - cy - (86 - cy) * k) / 1.4) ** 2) * top_fingers
    lay(top_fingers, hf + knuckles * 0.2 - tips * 0.35, 14, occlusion=(1 - 0.35 * tips) * (1 - 0.2 * crease))
    lay(top_thumb, dome(top_thumb, S(6)), 12, occlusion=0.8 + 0.2 * dome(top_thumb, S(6)))
    # Rolled-up sleeves from the middle of the forearms to the bottom edge.
    sleeves = np.clip(capsule(68, 400, 14, 580, 46, 52) + capsule(188, 400, 242, 580, 46, 52), 0, 1) * (y > 390)
    sleeves = blur(sleeves.astype(np.float32), S(0.8))
    c.shadow(sleeves, S(3), S(5), S(5), 0.5)
    folds = ridges(c.w, c.h, 23, (S(10), S(4)), (1.0, 0.4))
    hs = dome(sleeves, S(14)) + folds * 0.3 + np.exp(-((y - 410) / 10) ** 2) * 0.3
    c.put(shade(fabric_olive(c, tile=110), hs * sleeves, strength=S(16), spec=0.05, occlusion=0.6 + 0.4 * dome(sleeves, S(14))), sleeves)
    return c.image()


# --- bandage ------------------------------------------------------------------------------
def bandage_scene():
    """A wide wound on a thigh or forearm, filling the board."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    skin = skin_material(c, 41, tile=320)
    v = (y - 256) / 330
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1)) + noise(c.w, c.h, 42, S(60)) * 0.05
    c.put(shade(skin, h, strength=S(330), detail_strength=0.45, spec=0.2, occlusion=0.6 + 0.4 * np.sqrt(np.clip(1 - v ** 2, 0, 1))),
          np.ones((c.h, c.w)))
    rng = np.random.default_rng(43)
    hair = mask(c.w, c.h, lambda d: [d.line(S((px, py, px + 10 * math.cos(a), py + 10 * math.sin(a))), fill=255, width=S(1))
                                     for px, py, a in zip(rng.uniform(0, 1024, 260), rng.uniform(0, 512, 260), rng.uniform(-0.5, 0.5, 260))])
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.28, 0.19, 0.14]), hair * 0.4)
    wound(c, 512, 250, 150, 74, 44, depth=1.4, n_drips=4)
    vign = np.clip(((x / 1024 - 0.5) ** 2 + (y / 512 - 0.5) ** 2) * 1.6, 0, 0.5)
    c.put(np.zeros((c.h, c.w, 3)), vign)
    return c.image()


GAUZE_STRIPS = 18


def gauze_strips():
    """Folded strips of gauze, the same for every stage: stage n shows the first strips_for(n)."""
    rng = np.random.default_rng(57)
    strips = []
    for i in range(GAUZE_STRIPS):
        spread = 0.25 + 0.75 * i / (GAUZE_STRIPS - 1)
        ang = rng.uniform(0, 2 * math.pi)
        strips.append((256 + math.cos(ang) * rng.uniform(0, 95) * spread, 128 + math.sin(ang) * rng.uniform(0, 38) * spread,
                       rng.uniform(-0.6, 0.6), rng.uniform(110, 180), rng.uniform(46, 58), int(rng.integers(1000))))
    return strips


def strips_for(stage):
    return 2 + 4 * stage


def gauze_stage(stage):
    """Gauze packed into the wound: folded strips pile up; the newer ones stay cleaner."""
    c = Canvas(512, 256)
    x, y = grid(c)
    weave = (np.sin(x * math.pi / 2) * np.sin(y * math.pi / 2)) * 0.5
    count = strips_for(stage)
    for i, (sx, sy, ang, length, width, seed) in enumerate(gauze_strips()[:count]):
        u = (x - sx) * math.cos(ang) + (y - sy) * math.sin(ang)
        v = -(x - sx) * math.sin(ang) + (y - sy) * math.cos(ang)
        fray = noise(c.w, c.h, seed, S(1.5)) * 3 + noise(c.w, c.h, seed + 2, S(8)) * 5
        m = blur(((np.abs(v) < width / 2 + fray) & (np.abs(u) < length / 2 + fray * 2)).astype(np.float32), S(1.2))
        c.shadow(m, S(2), S(3), S(4), 0.45)
        folds = np.sin(u / length * math.pi * (1 + seed % 3)) * 0.15 + ridges(c.w, c.h, seed, (S(14), S(6), S(3)), (1.0, 0.6, 0.3)) * 0.5
        h = np.cos(np.clip(v / (width / 2), -1, 1) * 1.2) * 0.22 + folds * 1.3 + weave * 0.04
        gauze = material("Fabric061", c.w, c.h, S(36), tint=(246, 244, 238), tint_mix=0.85, contrast=1.1)
        lit = shade(gauze, h * m, strength=S(10), detail_strength=1.0, spec=0.04, ambient=0.6,
                    occlusion=0.8 + 0.2 * np.cos(np.clip(v / (width / 2), -1, 1) * 1.2))
        # Blood from the wound: heavy on the first strips, fading on the ones packed on top.
        d = np.hypot((x - 256) / 150, (y - 128) / 70)
        soak = np.clip(1.3 - d, 0, 1) * (0.45 + 0.9 * (1 - i / count) ** 1.5)
        soak = np.clip(soak * (0.6 + noise(c.w, c.h, seed + 1, S(8)) * 0.6), 0, 1)
        col = np.array([0.9, 0.5, 0.5], np.float32) * (1 - soak[:, :, None]) + np.array([0.5, 0.03, 0.05], np.float32) * soak[:, :, None]
        a = np.clip(soak * 2, 0, 1)[:, :, None]
        c.put(np.clip(lit * (1 - a) + lit * col * 1.4 * a, 0, 1), m)
    return c.image()



# --- wound types (bandaging games) ------------------------------------------------------------
def skin_close(seed):
    """Close-up of skin filling a 1024 x 512 board: a gently rounded limb with fine hair."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    skin = skin_material(c, seed, tile=320)
    v = (y - 256) / 330
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1)) + noise(c.w, c.h, seed + 1, S(60)) * 0.05
    c.put(shade(skin, h, strength=S(330), detail_strength=0.45, spec=0.2, occlusion=0.6 + 0.4 * np.sqrt(np.clip(1 - v ** 2, 0, 1))),
          np.ones((c.h, c.w)))
    rng = np.random.default_rng(seed + 2)
    hair = mask(c.w, c.h, lambda d: [d.line(S((px, py, px + 10 * math.cos(a), py + 10 * math.sin(a))), fill=255, width=S(1))
                                     for px, py, a in zip(rng.uniform(0, 1024, 260), rng.uniform(0, 512, 260), rng.uniform(-0.5, 0.5, 260))])
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.28, 0.19, 0.14]), hair * 0.4)
    return c


def vignette(c):
    x, y = grid(c)
    c.put(np.zeros((c.h, c.w, 3)), np.clip(((x / 1024 - 0.5) ** 2 + (y / 512 - 0.5) ** 2) * 1.6, 0, 0.5))
    return c.image()


def tint(c, m, rgb, alpha):
    c.put(np.ones((c.h, c.w, 3)) * np.array(rgb, np.float32), np.clip(m, 0, 1) * alpha)


def raw_tissue(c, m, seed, depth, scale, pale_edge=True):
    """Open tissue inside mask m: dark red, wet, a pale torn margin, deeper towards the middle."""
    inner = blur(m, S(scale * 0.35))
    tissue = material("Leather035D", c.w, c.h, S(60), tint=(150, 34, 34), tint_mix=0.95, contrast=1.8, rough_bias=-0.35)
    if pale_edge:
        margin = np.clip((0.75 - inner) / 0.35, 0, 1) * m
        tissue["color"] = tissue["color"] * (1 - margin[:, :, None]) + np.array([0.82, 0.62, 0.5], np.float32) * margin[:, :, None]
    tissue["color"] *= (1 - 0.45 * inner)[:, :, None]
    h = -inner ** 0.7 * depth + noise(c.w, c.h, seed, S(4)) * 0.06
    c.put(shade(tissue, h * m, strength=S(scale) * 0.6, detail_strength=0.8, spec=0.6, ambient=0.45), blur(m, S(0.8)))


def wound_velocity():
    """Gunshot entry wound: a round hole with a dark abrasion collar, bruising, blood run down."""
    c = skin_close(101)
    x, y = grid(c)
    cx, cy = 512, 248
    d = np.hypot(x - cx, y - cy) / (1 + noise(c.w, c.h, 102, S(3)) * 0.12)
    tint(c, np.clip(1 - (d - 45) / 120, 0, 1) ** 1.5, (0.45, 0.16, 0.2), 0.55)
    smear = np.clip(noise(c.w, c.h, 103, S(9)) * 1.6 + 0.2, 0, 1) * np.clip(1 - (d - 36) / 80, 0, 1)
    tint(c, smear, (0.32, 0.03, 0.04), 0.55)
    collar = np.clip(1 - np.abs(d - 50) / 12, 0, 1)
    tint(c, collar, (0.36, 0.12, 0.1), 0.85)
    hole = (d < 40).astype(np.float32)
    raw_tissue(c, hole, 104, 1.6, 40, pale_edge=False)
    tint(c, blur(hole, S(2)) * np.clip(1 - d / 32, 0, 1), (0.05, 0.0, 0.0), 0.9)
    blood_layer(c, blur((np.hypot(x - cx, y - cy - 14) < 22).astype(np.float32), S(1)) * 0.7, 107)
    blood_layer(c, drips(c, [(cx - 14, cy + 34, 8, 150), (cx + 18, cy + 32, 6, 100), (cx - 34, cy + 22, 5, 60)], 105), 106)
    return vignette(c)


def wound_puncture():
    """Stab wound: a short slit, slightly gaping, with a little blood running from it."""
    c = skin_close(111)
    x, y = grid(c)
    cx, cy, ang = 512, 250, math.radians(-12)
    u = (x - cx) * math.cos(ang) + (y - cy) * math.sin(ang)
    v = -(x - cx) * math.sin(ang) + (y - cy) * math.cos(ang)
    d = np.hypot(u / 95, v / 15) / (1 + noise(c.w, c.h, 115, S(3)) * 0.1)
    tint(c, np.clip(1 - np.hypot(u / 180, v / 90), 0, 1) ** 1.5, (0.5, 0.16, 0.2), 0.45)
    slit = (d < 1).astype(np.float32)
    raw_tissue(c, slit, 112, 1.2, 15, pale_edge=False)
    tint(c, blur(slit, S(1)) * np.clip(1 - d, 0, 1), (0.08, 0.0, 0.0), 0.8)
    lips = np.clip(1 - np.abs(d - 1.05) / 0.12, 0, 1)
    tint(c, lips, (0.62, 0.32, 0.3), 0.45)
    blood_layer(c, drips(c, [(cx - 30, cy + 14, 7, 140), (cx + 20, cy + 8, 5, 90), (cx + 60, cy, 4, 50)], 113), 114)
    return vignette(c)


def wound_avulsion():
    """Avulsion: a large patch of skin torn away: raw tissue, yellow fat at the torn margin, blood."""
    c = skin_close(121)
    x, y = grid(c)
    cx, cy = 500, 250
    edge = 1 + noise(c.w, c.h, 122, S(14)) * 0.35 + noise(c.w, c.h, 123, S(4)) * 0.08
    d = np.hypot((x - cx) / 210, (y - cy) / 120) / edge
    tint(c, np.clip(1 - (d - 1) / 0.7, 0, 1) ** 2, (0.55, 0.16, 0.16), 0.45)
    smear = np.clip(noise(c.w, c.h, 124, S(12)) * 1.6 + 0.2, 0, 1) * np.clip(1 - (d - 0.9) / 0.6, 0, 1)
    tint(c, smear, (0.3, 0.03, 0.04), 0.6)
    hole = (d < 1).astype(np.float32)
    raw_tissue(c, hole, 125, 1.4, 110)
    # Yellow fat lobules exposed along the torn margin, glistening.
    lobes = (noise(c.w, c.h, 126, S(6)) > 0.25).astype(np.float32) * np.clip((d - 0.55) / 0.3, 0, 1) * hole
    lobes = blur(lobes, S(1))
    c.put(shade(flat(c.w, c.h, (226, 186, 96), rough=0.25), dome(lobes, S(5)) * 0.6, strength=S(8), spec=0.6, ambient=0.5), lobes * 0.9)
    pool = blur((np.hypot((x - cx + 20) / 110, (y - cy - 40) / 45) / (1 + noise(c.w, c.h, 127, S(12)) * 0.4) < 1).astype(np.float32), S(1))
    blood_layer(c, pool * np.clip(blur(pool, S(14)) * 1.2, 0.3, 0.85), 128)
    blood_layer(c, drips(c, [(cx - 150, cy + 80, 6, 90), (cx - 40, cy + 110, 7, 120), (cx + 60, cy + 115, 5, 80)], 131), 132)
    return vignette(c)


def wound_crush():
    """Crush wound: a wide swollen bruise, the skin split and abraded in the middle."""
    c = skin_close(141)
    x, y = grid(c)
    cx, cy = 512, 250
    d = np.hypot((x - cx) / 280, (y - cy) / 170) / (1 + noise(c.w, c.h, 142, S(30)) * 0.3)
    swell = np.clip(1 - d, 0, 1)
    bruise = swell ** 0.8 * np.clip(noise(c.w, c.h, 143, S(25)) * 0.6 + 0.8, 0, 1)
    tint(c, bruise, (0.32, 0.14, 0.32), 0.7)
    tint(c, np.clip(1 - d * 1.7, 0, 1) * np.clip(noise(c.w, c.h, 144, S(15)) + 0.5, 0, 1), (0.2, 0.06, 0.18), 0.6)
    tint(c, np.clip(1 - np.abs(d - 0.92) / 0.2, 0, 1) * np.clip(noise(c.w, c.h, 151, S(20)) + 0.4, 0, 1), (0.45, 0.45, 0.2), 0.15)  # yellowish rim
    scrape = np.clip(noise(c.w, c.h, 145, S(6)) * 2 + 0.2, 0, 1) * np.clip(1 - d * 1.8, 0, 1)
    tint(c, scrape, (0.6, 0.12, 0.12), 0.6)
    u, v = x - cx, y - cy
    split_d = np.hypot(u / 150, (v - 12 * np.sin(u / 40)) / 16) / (1 + noise(c.w, c.h, 146, S(4)) * 0.4)
    split = (split_d < 1).astype(np.float32)
    raw_tissue(c, split, 147, 1.3, 16)
    blood_layer(c, blur((split_d < 0.6).astype(np.float32), S(0.8)) * 0.85, 148)
    blood_layer(c, drips(c, [(cx - 60, cy + 24, 6, 100), (cx + 40, cy + 26, 5, 70), (cx + 110, cy + 18, 4, 50)], 149), 150)
    return vignette(c)


WOUND_LINE = (232, 792, 256)  # cut and laceration: x from, x to, y (PMCI_fnc_boardMarks)


def wound_cut():
    """A clean straight cut along the wound line: thin, gaping in the middle, beads of blood."""
    c = skin_close(161)
    x, y = grid(c)
    x0, x1, cy = WOUND_LINE
    t = np.clip((x - x0) / (x1 - x0), 0, 1)
    inside = (x > x0) & (x < x1)
    half = 12 * np.sqrt(np.clip(t * (1 - t) * 4, 0, 1)) + 0.5
    line = cy + 4 * np.sin(t * math.pi * 1.3)
    v = (y - line) / half
    gap = ((np.abs(v) < 1) & inside).astype(np.float32)
    tint(c, np.clip(1 - np.abs(y - line) / 30, 0, 1) * inside, (0.6, 0.2, 0.2), 0.3)
    raw_tissue(c, gap, 162, 1.0, 12, pale_edge=False)
    tint(c, blur(gap, S(1)) * np.clip(1 - np.abs(v), 0, 1), (0.1, 0.0, 0.0), 0.6)
    lips = np.clip(1 - np.abs(np.abs(y - line) - half - 1.5) / 2.5, 0, 1) * inside
    tint(c, lips, (0.72, 0.42, 0.38), 0.5)
    rng = np.random.default_rng(163)
    beads = [(px, cy + 4 * math.sin((px - x0) / (x1 - x0) * math.pi * 1.3) + rng.uniform(4, 10), rng.uniform(3, 5)) for px in rng.uniform(x0 + 40, x1 - 40, 9)]
    blood_layer(c, blobs(c, beads), 164)
    blood_layer(c, drips(c, [(330, 266, 4, 70), (520, 268, 5, 110), (680, 266, 4, 60)], 165), 166)
    return vignette(c)


def wound_laceration():
    """A laceration along the wound line: torn, ragged and gaping, bruised edges, more blood."""
    c = skin_close(171)
    x, y = grid(c)
    x0, x1, cy = WOUND_LINE
    t = np.clip((x - x0) / (x1 - x0), 0, 1)
    inside = (x > x0 - 10) & (x < x1 + 10)
    soft = np.clip(np.minimum(x - x0 + 60, x1 + 60 - x) / 80, 0, 1)
    rag = noise(c.w, c.h, 172, S(6)) * 0.5 + noise(c.w, c.h, 173, S(2)) * 0.25
    half = (26 * np.sqrt(np.clip(t * (1 - t) * 4, 0, 1)) + 2) * (1 + rag)
    line = cy + 10 * np.sin(t * math.pi * 2.1) + 6 * noise(c.w, c.h, 174, S(30))
    v = (y - line) / np.maximum(half, 1)
    tint(c, np.clip(1 - np.abs(y - line) / 80, 0, 1) * soft * np.clip(noise(c.w, c.h, 175, S(20)) + 0.6, 0, 1), (0.4, 0.13, 0.2), 0.55)
    smear = np.clip(noise(c.w, c.h, 176, S(10)) * 1.6, 0, 1) * np.clip(1 - np.abs(y - line) / 60, 0, 1) * soft
    tint(c, smear, (0.3, 0.03, 0.04), 0.55)
    gap = ((np.abs(v) < 1) & inside).astype(np.float32)
    raw_tissue(c, gap, 177, 1.3, 26)
    pooled = ((np.abs(v - 0.25) < 0.4) & inside).astype(np.float32) * np.clip(noise(c.w, c.h, 181, S(14)) * 2 + 0.6, 0, 1)
    blood_layer(c, blur(pooled, S(0.8)) * 0.75, 178)
    blood_layer(c, drips(c, [(300, 280, 6, 90), (420, 290, 7, 130), (560, 292, 6, 100), (700, 280, 5, 80)], 179), 180)
    return vignette(c)


ABRASION_SPOTS = [(372, 208), (528, 196), (672, 222), (330, 304), (480, 292), (622, 318), (740, 296), (430, 352)]  # PMCI_fnc_boardOpen


def wound_abrasion():
    """A wide scrape: skin rubbed off in patches and streaks, raw and wet, pinpoint bleeding, grit."""
    c = skin_close(181)
    x, y = grid(c)
    cx, cy = 535, 275
    d = np.hypot((x - cx) / 280, (y - cy) / 135) / (1 + noise(c.w, c.h, 182, S(12)) * 0.45 + noise(c.w, c.h, 188, S(4)) * 0.12)
    area = blur((d < 1).astype(np.float32), S(2))
    tint(c, np.clip(1 - (d - 1) / 0.45, 0, 1), (0.62, 0.22, 0.2), 0.35)
    # How deep the scrape went: raw where the skin is gone, paler where some is left.
    rng0 = np.random.default_rng(183)
    raw_n = rng0.random((c.h, c.w)).astype(np.float32)
    streaks = _box(_box(_box(_box(raw_n, S(30), 1), S(30), 1), S(5), 0), S(5), 0)
    streaks = np.clip((streaks - streaks.mean()) / (streaks.std() + 1e-6) * 0.3 + 0.5, 0, 1)
    depth = np.clip(noise(c.w, c.h, 184, S(16)) * 1.2 + 0.75 + (streaks - 0.5) * 0.6, 0, 1) * np.clip((1 - d) * 3, 0, 1)
    raw = material("Leather035D", c.w, c.h, S(70), tint=(215, 72, 66), tint_mix=0.9, contrast=1.3, rough_bias=-0.3)
    pale = np.array([0.86, 0.5, 0.44], np.float32)
    raw["color"] = raw["color"] * depth[:, :, None] + pale * (1 - depth[:, :, None])
    raw["color"] *= (0.92 + 0.16 * streaks)[:, :, None]
    h = (-depth * 0.08 + streaks * 0.02) * area
    c.put(shade(raw, h, strength=S(14), detail_strength=0.6, spec=0.5, ambient=0.5), area * 0.95)
    rng = np.random.default_rng(185)
    centres = rng.normal([cx, cy], [110, 45], (6, 2))
    dots = []
    for px, py in centres:
        dots += [(qx, qy, rng.uniform(1.2, 2.6)) for qx, qy in zip(rng.normal(px, 28, 14), rng.normal(py, 14, 14))]
    blood_layer(c, blobs(c, dots) * area * depth * 0.85, 186)
    grit = blur(((noise(c.w, c.h, 187, 0) > 0.95) * area).astype(np.float32), S(0.6))
    tint(c, grit, (0.2, 0.17, 0.12), 0.8)
    return vignette(c)


# --- sprites of the wound games -------------------------------------------------------------------
def gauze_pad_layer(c, m, seed, soak):
    """A folded gauze pad on mask m, blood soaked into its middle by `soak` (0-1)."""
    x, y = grid(c)
    gauze = material("Fabric061", c.w, c.h, S(36), tint=(246, 244, 238), tint_mix=0.85, contrast=1.1)
    crumple = ridges(c.w, c.h, seed, (S(16), S(6)), (1.0, 0.5))
    h = dome(m, S(10)) * 0.5 + crumple * 0.25
    lit = shade(gauze, h * m, strength=S(10), detail_strength=1.0, spec=0.04, ambient=0.6)
    centre = blur(m, S(30))
    stain = np.clip((centre - 0.35) * 2.2 * soak + noise(c.w, c.h, seed + 1, S(8)) * 0.25 * soak, 0, 1)
    col = np.array([0.5, 0.03, 0.05], np.float32) * stain[:, :, None] + np.array([0.9, 0.5, 0.5], np.float32) * (1 - stain[:, :, None])
    a = np.clip(stain * 1.8, 0, 1)[:, :, None]
    c.put(np.clip(lit * (1 - a) + lit * col * 1.4 * a, 0, 1), m)


def pressure_hand(firm):
    """A gloveless hand pressing a gauze pad onto the wound (wound centre = sprite centre)."""
    c = Canvas(512, 512)
    x, y = grid(c)
    k = 0.96 if firm else 1.0
    cx, cy = 256, 250

    def T(pts):
        return [(cx + (px - cx) * k, cy + (py - cy) * k) for px, py in pts]

    def capsule(x0, y0, x1, y1, r0, r1=None):
        (a, b), (e, f) = T([(x0, y0), (x1, y1)])
        r1 = r0 if r1 is None else r1
        return blobs(c, [(a + (e - a) * t, b + (f - b) * t, (r0 + (r1 - r0) * t) * k) for t in np.linspace(0, 1, 40)])

    pad = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((150, 160, 362, 342)), radius=S(14), fill=255)), S(1))
    pad *= np.clip(1 + noise(c.w, c.h, 201, S(3)) * 0.3, 0, 1)
    c.shadow(pad, S(4), S(5), S(6), 0.45)
    gauze_pad_layer(c, pad, 202, 0.9 if firm else 0.5)
    skin = skin_material(c, 203, tone=(205, 158, 128), tile=200)
    if firm:  # pressing hard whitens the knuckles and fingertips
        skin["color"] = np.clip(skin["color"] * np.array([1.06, 1.0, 0.98]), 0, 1)
    arm = capsule(258, 360, 300, 600, 52, 62)
    back = blur(mask(c.w, c.h, lambda d: d.polygon(S(T([(200, 380), (318, 380), (340, 300), (336, 220), (184, 220), (178, 300)])), fill=255)), S(1))
    thumb = capsule(190, 320, 140, 262, 22, 18)
    fingers = np.maximum.reduce([capsule(200 + 44 * i, 226, 196 + 46 * i - 4, tip, 21, 19) for i, tip in enumerate((126, 108, 112, 136))])
    whole = np.maximum.reduce([arm, back, thumb, fingers])
    lift = 0.3 if firm else 1.0
    c.shadow(whole, S(6 + 14 * lift), S(8 + 18 * lift), S(8 + 10 * lift), 0.7 - 0.2 * lift)

    def lay(m, radius, strength):
        h = dome(m, S(radius))
        c.put(shade(skin, h * m, strength=S(strength), detail_strength=0.3, spec=0.2, occlusion=0.7 + 0.3 * h), m)

    lay(arm, 34, 40)
    lay(thumb, 12, 16)
    lay(back, 40, 12)
    knuckle_y = cy + (226 - cy) * k
    knuckles = sum(np.exp(-(((x - cx - (200 + 44 * i - cx) * k) / 16) ** 2 + ((y - knuckle_y) / 12) ** 2)) for i in range(4))
    hf = dome(fingers, S(10))
    joints = sum(np.exp(-((y - cy - (yy - cy) * k) / 2.2) ** 2) for yy in (186, 152)) * fingers
    c.put(shade(skin, (hf + knuckles * 0.25) * fingers, strength=S(18), detail_strength=0.3, spec=0.22, occlusion=(0.75 + 0.25 * hf) * (1 - 0.2 * joints)), fingers)
    nails = np.maximum.reduce([capsule(196 + 46 * i - 4, tip + 14, 196 + 46 * i - 4, tip + 4, 11) for i, tip in enumerate((126, 108, 112, 136))])
    c.put(shade(flat(c.w, c.h, (236, 200, 188) if firm else (225, 180, 168), rough=0.2), dome(nails, S(4)) * 0.4, strength=S(6), spec=0.5), nails * 0.85)
    sleeve = np.clip(capsule(258, 470, 300, 640, 68, 72), 0, 1) * (y > 455)
    sleeve = blur(sleeve.astype(np.float32), S(0.8))
    c.shadow(sleeve, S(3), S(5), S(5), 0.5)
    folds = ridges(c.w, c.h, 204, (S(14), S(5)), (1.0, 0.4))
    c.put(shade(fabric_olive(c, tile=130), (dome(sleeve, S(18)) + folds * 0.3) * sleeve, strength=S(20), spec=0.05), sleeve)
    return c.image()


def pressure_seep():
    """Blood squeezing out from under the pad (pad = 200 x 180 in the middle of 512 x 256)."""
    c = Canvas(512, 256)
    x, y = grid(c)
    u = np.maximum(np.abs(x - 256) - 100, 0)
    v = np.maximum(np.abs(y - 128) - 90, 0)
    out = np.hypot(u, v)
    # Uneven: more on the lower side (it runs down), in tongues rather than an even rim.
    reach = 8 + np.clip(noise(c.w, c.h, 211, S(9)) * 1.4 + 0.3, 0, 1) * 34 + np.clip((y - 128) / 100, 0, 1) * 18
    m = ((out < reach) & ((u > 0) | (v > 0))).astype(np.float32)
    m = blur(m, S(1))
    streams = drips(c, [(170, 214, 6, 40), (280, 220, 7, 34), (360, 210, 5, 44)], 212)
    blood_layer(c, np.clip(np.maximum(m, streams), 0, 1), 213)
    return c.image()


def edges_strip():
    """An adhesive skin-closure strip lying across the wound."""
    c = Canvas(128, 256)
    m = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((42, 14, 86, 242)), radius=S(5), fill=255)), S(0.6))
    c.shadow(m, S(2), S(3), S(3), 0.5)
    tape = material("Fabric061", c.w, c.h, S(20), tint=(255, 250, 236), tint_mix=0.9, contrast=0.6)
    x, y = grid(c)
    h = dome(m, S(3)) * 0.3 + np.sin(y * 0.6) * 0.01
    tape["color"] *= (1 - 0.18 * np.exp(-((y - 128) / 14) ** 2))[:, :, None]  # the wound shows through a little
    c.put(np.clip(shade(tape, h, strength=S(8), detail_strength=0.6, spec=0.15, ambient=0.75) * 1.35, 0, 1), m * 0.96)
    return c.image()


def edges_target():
    """A soft highlight around a still open stretch of the wound (stretched to its width)."""
    c = Canvas(128, 256)
    x, y = grid(c)
    box = mask(c.w, c.h, lambda d: d.rounded_rectangle(S((8, 8, 120, 248)), radius=S(18), fill=255))
    ring = np.clip(blur(box, S(3)) * (1 - blur(box, S(3))) * 4, 0, 1)
    glow = np.ones((c.h, c.w, 3)) * np.array([1.0, 0.85, 0.35], np.float32)
    c.put(glow, box * 0.12 + ring * 0.9)
    return c.image()


def edges_runner():
    """The runner moving along the wound: a bright line with pointers at both ends."""
    c = Canvas(64, 256)
    x, y = grid(c)
    m = mask(c.w, c.h, lambda d: (d.rectangle(S((29, 18, 35, 238)), fill=255),
                                  d.polygon(S([(14, 0), (50, 0), (32, 22)]), fill=255),
                                  d.polygon(S([(14, 255), (50, 255), (32, 233)]), fill=255)))
    c.put(np.zeros((c.h, c.w, 3)), blur(m, S(3)) * 0.6)
    c.put(np.ones((c.h, c.w, 3)) * np.array([1.0, 0.95, 0.75], np.float32), blur(m, S(0.6)))
    return c.image()


def dirt(seed):
    """A patch of grit and soil stuck in a scrape."""
    c = Canvas(128, 128)
    x, y = grid(c)
    d = np.hypot(x - 64, y - 64) / (40 * (1 + noise(c.w, c.h, seed, S(8)) * 0.4))
    soil = np.clip(1 - d, 0, 1) ** 0.6
    ground = material("Ground110", c.w, c.h, S(90))
    ground["color"] *= np.array([0.95, 0.75, 0.52], np.float32)
    c.put(shade(ground, soil * 0.3 + noise(c.w, c.h, seed + 1, S(2)) * 0.1, strength=S(10), detail_strength=1.5, ambient=0.45), soil * 0.85)
    rng = np.random.default_rng(seed)
    stones = blobs(c, [(px, py, rng.uniform(2, 5.5)) for px, py in zip(rng.normal(64, 18, 16), rng.normal(64, 18, 16))]) * np.clip(1.2 - d, 0, 1)
    rock = material("Ground110", c.w, c.h, S(40))
    rock["color"] = rock["color"] * np.array([0.7, 0.62, 0.5], np.float32) + 0.18
    c.put(shade(rock, dome(stones, S(2)), strength=S(4), spec=0.3), stones)
    return c.image()


def abrasion_swab():
    """A wet gauze swab, bunched up for scrubbing."""
    c = Canvas(128, 128)
    x, y = grid(c)
    d = np.hypot(x - 64, y - 64) / (42 * (1 + noise(c.w, c.h, 221, S(6)) * 0.25))
    m = blur((d < 1).astype(np.float32), S(1))
    c.shadow(m, S(4), S(6), S(5), 0.5)
    gauze = material("Fabric061", c.w, c.h, S(30), tint=(246, 244, 238), tint_mix=0.85, contrast=1.1)
    crumple = ridges(c.w, c.h, 222, (S(10), S(4)), (1.0, 0.6))
    h = dome(m, S(12)) * 0.6 + crumple * 0.5
    lit = shade(gauze, h * m, strength=S(10), detail_strength=1.0, spec=0.25, ambient=0.55)
    wet = np.clip((d - 0.6) / 0.4, 0, 1)[:, :, None]
    lit = lit * (1 - 0.25 * wet) + lit * np.array([0.95, 0.65, 0.62], np.float32) * 0.25 * wet
    c.put(np.clip(lit, 0, 1), m)
    return c.image()


def abrasion_pad():
    """A sterile non-adherent dressing with an adhesive border, laid over the cleaned scrape."""
    c = Canvas(512, 256)
    x, y = grid(c)
    border = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((40, 22, 472, 234)), radius=S(22), fill=255)), S(0.8))
    c.shadow(border, S(3), S(5), S(6), 0.45)
    tape = material("Fabric061", c.w, c.h, S(24), tint=(255, 250, 240), tint_mix=0.9, contrast=0.6)
    c.put(np.clip(shade(tape, dome(border, S(4)) * 0.2, strength=S(6), detail_strength=0.5, spec=0.1, ambient=0.75) * 1.3, 0, 1), border * 0.97)
    pad = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((86, 52, 426, 204)), radius=S(10), fill=255)), S(0.8))
    quilt = (np.sin(x * 0.35) * np.sin(y * 0.35)) * 0.03
    cotton = material("Fabric061", c.w, c.h, S(40), tint=(250, 248, 244), tint_mix=0.9, contrast=1.0)
    lit = shade(cotton, (dome(pad, S(10)) * 0.4 + quilt) * pad, strength=S(10), detail_strength=1.0, spec=0.04, ambient=0.6)
    seep = np.clip(blur(pad, S(40)) * 1.2 - 0.6, 0, 1) * np.clip(noise(c.w, c.h, 231, S(14)) + 0.6, 0, 1)
    lit = lit * (1 - 0.35 * seep[:, :, None]) + lit * np.array([0.95, 0.55, 0.55], np.float32) * 0.35 * seep[:, :, None]
    c.put(np.clip(lit, 0, 1), pad)
    return c.image()


# --- IV, suture, splint ------------------------------------------------------------------------------
IV_VEIN = (300, 262, 760, 238)  # PMCI_fnc_boardOpen: the vein the needle must stay on


def iv_scene():
    """The inner forearm with a rubber tourniquet and a raised vein along IV_VEIN."""
    c = Canvas(1024, 512)
    ground_layer(c, seed=301, dark=0.6)
    x, y = grid(c)
    limb, mid, half = arm(c, 252, 92, 150, 302)
    # Inner side: paler, a little pink.
    tint(c, limb * np.clip(1 - np.abs((y - mid) / half), 0, 1), (0.95, 0.82, 0.76), 0.25)
    x0, y0, x1, y1 = IV_VEIN
    t = np.clip(((x - x0) * (x1 - x0) + (y - y0) * (y1 - y0)) / ((x1 - x0) ** 2 + (y1 - y0) ** 2), 0, 1)
    vx, vy = x0 + t * (x1 - x0), y0 + t * (y1 - y0)
    d = np.hypot(x - vx, y - vy + 3 * np.sin(t * 9))
    vein = np.clip(1 - d / 9, 0, 1) * limb * np.clip(np.minimum(t, 1 - t) * 12, 0, 1)
    tint(c, blur(vein, S(2)), (0.28, 0.34, 0.62), 0.75)
    skin = skin_material(c, 303)
    c.put(shade(skin, dome(vein, S(3)) * 0.5 + 0.4, strength=S(10), detail_strength=0.3, spec=0.35), vein * 0.4)
    # Rubber tourniquet above the site.
    band = ((np.abs(x - 230) < 16) & (np.abs(y - mid) < half * 1.06)).astype(np.float32)
    c.shadow(blur(band, S(0.8)), S(4), S(6), S(5), 0.6)
    rubber = flat(c.w, c.h, (70, 110, 170), rough=0.35)
    v = np.clip((y - mid) / (half * 1.06), -1, 1)
    c.put(shade(rubber, np.sqrt(1 - v ** 2) * band, strength=S(60), spec=0.4), blur(band, S(0.8)))
    # Alcohol-wiped patch: slightly wet and glossy.
    wipe = np.clip(1 - np.hypot((x - 530) / 150, (y - 250) / 45), 0, 1) ** 0.5 * limb
    c.put(shade(flat(c.w, c.h, (215, 170, 150), rough=0.1), dome(wipe, S(10)) * 0.2 + 0.5, strength=S(20), spec=0.4), wipe * 0.12)
    return c.image()


def iv_needle():
    """An IV cannula coming in from the upper right; the needle tip is at (20, 236)."""
    c = Canvas(256, 256)
    x, y = grid(c)
    a = math.radians(40)
    u = (x - 20) * math.cos(a) - (y - 236) * math.sin(a)  # along the needle, from the tip up and to the right
    v = (x - 20) * math.sin(a) + (y - 236) * math.cos(a)
    needle = ((u > 0) & (u < 110) & (np.abs(v) < 4 * np.clip(u / 14, 0.25, 1))).astype(np.float32)
    sheath = ((u > 36) & (u < 116) & (np.abs(v) < 7.5)).astype(np.float32)
    hub = ((u > 110) & (u < 212) & (np.abs(v) < 17)).astype(np.float32)
    wings = ((u > 120) & (u < 150) & (np.abs(v) < 40)).astype(np.float32)
    cap = ((u > 210) & (u < 252) & (np.abs(v) < 12)).astype(np.float32)
    whole = np.maximum.reduce([needle, sheath, hub, wings, cap])
    c.shadow(blur(whole, S(0.8)), S(6), S(9), S(5), 0.5)
    steel = material("Metal046A", c.w, c.h, S(60))
    c.put(shade(steel, np.sqrt(np.clip(1 - (v / 4) ** 2, 0, 1)) * needle, strength=S(5), metal=0.9, spec=0.8), blur(needle, S(0.5)))
    c.put(shade(flat(c.w, c.h, (235, 235, 240), rough=0.1), np.sqrt(np.clip(1 - (v / 7.5) ** 2, 0, 1)) * sheath, strength=S(8), spec=0.8),
          blur(sheath, S(0.5)) * 0.55)
    plastic = flat(c.w, c.h, (90, 170, 90), rough=0.25)  # 18 G green
    c.put(shade(plastic, np.sqrt(np.clip(1 - (v / 40) ** 2, 0, 1)) * wings * 0.3, strength=S(14), spec=0.6), blur(wings, S(0.5)))
    c.put(shade(flat(c.w, c.h, (225, 225, 230), rough=0.15), np.sqrt(np.clip(1 - (v / 17) ** 2, 0, 1)) * hub, strength=S(16), spec=0.7),
          blur(hub, S(0.5)) * 0.85)
    c.put(shade(plastic, np.sqrt(np.clip(1 - (v / 12) ** 2, 0, 1)) * cap, strength=S(12), spec=0.6), blur(cap, S(0.5)))
    return c.image()


def iv_bruise():
    """A blown vein: a small bruise with a drop of blood."""
    c = Canvas(128, 128)
    x, y = grid(c)
    d = np.hypot(x - 64, y - 64) / (1 + noise(c.w, c.h, 311, S(6)) * 0.3)
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.35, 0.12, 0.3], np.float32), np.clip(1 - d / 40, 0, 1) ** 1.2 * 0.75)
    blood_layer(c, blobs(c, [(66, 62, 5)]), 312)
    return c.image()


def suture_point():
    """The next stitch point: a soft glowing ring."""
    c = Canvas(64, 64)
    x, y = grid(c)
    d = np.hypot(x - 32, y - 32)
    ring = np.clip(1 - np.abs(d - 18) / 3, 0, 1)
    c.put(np.ones((c.h, c.w, 3)) * np.array([1.0, 0.85, 0.35], np.float32), blur(ring, S(2)) * 0.6 + ring)
    c.put(np.ones((c.h, c.w, 3)) * np.array([1.0, 0.95, 0.7], np.float32), np.clip(1 - d / 4, 0, 1))
    return c.image()


def suture_stitch():
    """One finished stitch across the cut: dark nylon thread with a knot on top."""
    c = Canvas(128, 256)
    x, y = grid(c)
    path = np.abs(x - 64 - (y - 128) * 0.12) < 6
    loop = path & (y > 40) & (y < 216)
    m = blur(loop.astype(np.float32), S(0.6))
    knot = blobs(c, [(58, 48, 14), (72, 42, 11)])
    tails = mask(c.w, c.h, lambda d: (d.line(S((64, 44, 100, 10)), fill=255, width=S(7)), d.line(S((60, 46, 26, 14)), fill=255, width=S(7))))
    whole = np.maximum.reduce([m, knot, blur(tails, S(0.6))])
    c.shadow(whole, S(2), S(3), S(2), 0.55)
    thread = flat(c.w, c.h, (30, 40, 80), rough=0.3)
    c.put(shade(thread, dome(whole, S(2)) * 0.6, strength=S(4), spec=0.6), whole)
    # The thread dips into the skin at both ends.
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.45, 0.12, 0.12], np.float32), blobs(c, [(57, 40, 7), (71, 216, 7)]) * 0.7)
    return c.image()


def suture_needle():
    """A curved suture needle in a needle driver; the needle point is at (12, 116)."""
    c = Canvas(128, 128)
    x, y = grid(c)
    # Curved needle: an arc from the point up to the driver jaws.
    d = np.hypot(x - 46, y - 116)
    ang = np.degrees(np.arctan2(y - 116, x - 46))
    arc = (np.abs(d - 34) < 3.2) & (ang > -180) & (ang < -60)
    jaws = mask(c.w, c.h, lambda dr: dr.polygon(S([(56, 76), (70, 70), (124, 4), (112, 0)]), fill=255))
    handle = blur(jaws, S(0.6))
    needle = blur(arc.astype(np.float32), S(0.5))
    c.shadow(np.maximum(needle, handle), S(4), S(6), S(4), 0.5)
    steel = material("Metal046A", c.w, c.h, S(50))
    c.put(shade(steel, dome(handle, S(3)) * 0.6, strength=S(6), metal=0.9, spec=0.7), handle)
    c.put(shade(steel, dome(needle, S(1.5)) * 0.6, strength=S(3), metal=0.9, spec=0.9), needle)
    return c.image()


def splint_scene():
    """A forearm broken at (512, 256): the upper part and an orange splint lying straight."""
    c = Canvas(1024, 512)
    ground_layer(c, seed=321, dark=0.6)
    x, y = grid(c)
    splint = blur(((x > 180) & (x < 980) & (np.abs(y - 256) < 50)).astype(np.float32), S(1))
    c.shadow(splint, S(5), S(7), S(6), 0.6)
    foam = material("Fabric030", c.w, c.h, S(60), tint=(230, 120, 40), tint_mix=0.9, contrast=1.0)
    ridges_ = np.cos((y - 256) / 50 * math.pi * 1.5) * 0.15
    c.put(shade(foam, (dome(splint, S(10)) * 0.3 + ridges_) * splint, strength=S(20), detail_strength=0.8, spec=0.1), splint)
    # Upper part of the forearm, ending in a swollen, bruised break.
    v = (y - 256) / 82
    upper = blur(((np.abs(v) < 1) & (x < 520)).astype(np.float32), S(1)) * np.clip((540 - x) / 30, 0, 1)
    c.shadow(upper, S(8), S(12), S(12), 0.65)
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1)) + np.exp(-((x - 500) / 30) ** 2) * 0.25 * (np.abs(v) < 1)
    skin = skin_material(c, 322)
    c.put(shade(skin, h * upper, strength=S(70), detail_strength=0.35, spec=0.22, occlusion=0.5 + 0.5 * np.sqrt(np.clip(1 - v ** 2, 0, 1))), upper)
    tint(c, upper * np.exp(-((x - 505) / 40) ** 2), (0.4, 0.15, 0.3), 0.5)
    sv = (y - 256) / 100
    sleeve = blur(((np.abs(sv) < 1) & (x < 200)).astype(np.float32), S(1))
    c.shadow(sleeve, S(6), S(10), S(10), 0.6)
    c.put(shade(fabric_olive(c), (np.sqrt(np.clip(1 - sv ** 2, 0, 1)) + ridges(c.w, c.h, 323, (S(16), S(6)), (1, 0.4)) * 0.3) * sleeve,
                strength=S(80), spec=0.05), sleeve)
    return c.image()


def splint_limb(frame):
    """The broken lower forearm and hand, turned by (frame - 3) x 10 degrees about (0, 256)."""
    angle = (frame - 3) * 10
    c = Canvas(512, 512)
    x, y = grid(c)
    a = math.radians(angle)
    u = x * math.cos(a) + (y - 256) * math.sin(a)
    v = -x * math.sin(a) + (y - 256) * math.cos(a)
    half = 78 * (1 - 0.22 * np.clip(u / 330, 0, 1))
    vv = v / half
    fore = ((np.abs(vv) < 1) & (u > -6) & (u < 340)).astype(np.float32)
    def capsule(u0, u1, vc, r):
        return (np.hypot(np.maximum(np.maximum(u0 - u, 0), u - u1), v - vc) < r).astype(np.float32)

    # Back of the hand, four fingers and the thumb, in the forearm's frame.
    palm = (np.hypot((u - 385) / 62, v / 60) < 1).astype(np.float32)
    fingers = np.maximum.reduce([capsule(420, 492 - abs(k) * 6, k * 26, 12) for k in (-1.5, -0.5, 0.5, 1.5)])
    thumb = capsule(350, 410, -66, 14)
    hand = np.maximum.reduce([palm, fingers, thumb])
    whole = blur(np.maximum(fore, hand), S(1))
    c.shadow(whole, S(8), S(12), S(12), 0.65)
    h = (np.sqrt(np.clip(1 - vv ** 2, 0, 1)) * fore + dome(palm, S(26)) * 0.6 * palm + dome(fingers, S(8)) * 0.5
         + dome(thumb, S(8)) * 0.5 + np.exp(-(u / 25) ** 2) * 0.25 * fore)
    skin = skin_material(c, 331)
    c.put(shade(skin, h * whole, strength=S(60), detail_strength=0.35, spec=0.22, occlusion=0.55 + 0.45 * np.clip(h, 0, 1)), whole)
    tint(c, whole * np.exp(-(u / 40) ** 2), (0.4, 0.15, 0.3), 0.5)
    return c.image()


# --- repair -----------------------------------------------------------------------------------------
DIAG_PARTS = [(230, 190), (420, 330), (560, 170), (720, 320), (860, 200)]  # PMCI_fnc_boardOpen


def metal_part(c, m, base, metal=0.7, rough=0.0, height=0.6, seed=0, material_name="Metal041A"):
    mat = material(material_name, c.w, c.h, S(200), rough_bias=rough)
    mat["color"] = np.clip(mat["color"] * np.array(base, np.float32) / 128.0, 0, 1)
    c.shadow(m, S(5), S(7), S(6), 0.6)
    c.put(shade(mat, dome(m, S(6)) * height, strength=S(14), detail_strength=0.6, metal=metal, spec=0.5), m)


def repair_engine():
    """A vehicle's engine bay from above, five parts to test (DIAG_PARTS)."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    bay = material("Metal053C", c.w, c.h, S(300))
    bay["color"] *= 0.35
    c.put(shade(bay, noise(c.w, c.h, 401, S(40)) * 0.2, strength=S(10), metal=0.5, spec=0.3), np.ones((c.h, c.w)))
    # Engine block in the middle with its valve cover.
    block = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((300, 120, 700, 400)), radius=S(30), fill=255)), S(1))
    metal_part(c, block, (110, 112, 118), height=0.7)
    cover = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((340, 170, 660, 350)), radius=S(24), fill=255)), S(1))
    metal_part(c, cover, (60, 64, 70), metal=0.4, height=0.5)
    ribs = ((np.abs(((x - 340) % 40) - 20) < 3) & (cover > 0.5)).astype(np.float32)
    c.put(np.ones((c.h, c.w, 3)) * 0.12, ribs * 0.5)
    # Hoses and wiring between the parts.
    hoses = mask(c.w, c.h, lambda d: [d.line(S(seg), fill=255, width=S(14)) for seg in
                                     ((260, 230, 340, 260), (420, 300, 420, 260), (560, 200, 560, 230), (720, 290, 660, 270), (830, 220, 700, 200))])
    metal_part(c, blur(hoses, S(1)), (25, 25, 27), metal=0.0, rough=0.3, height=0.5, material_name="Rubber004")
    wires = mask(c.w, c.h, lambda d: [d.line(S(seg), fill=255, width=S(5)) for seg in ((230, 160, 560, 140), (560, 140, 860, 170), (420, 360, 720, 350))])
    tint(c, blur(wires, S(0.6)), (0.6, 0.1, 0.08), 0.9)
    # The five parts: battery, alternator, fuel filter, injection rail, cooling fan sensor.
    shapes = [
        lambda d: d.rounded_rectangle(S((170, 140, 290, 240)), radius=S(8), fill=255),
        lambda d: d.ellipse(S((370, 285, 470, 375)), fill=255),
        lambda d: d.rounded_rectangle(S((530, 115, 590, 225)), radius=S(25), fill=255),
        lambda d: d.rounded_rectangle(S((640, 300, 800, 340)), radius=S(10), fill=255),
        lambda d: d.ellipse(S((810, 150, 910, 250)), fill=255),
    ]
    colours = [(40, 40, 44), (175, 175, 180), (220, 170, 40), (150, 152, 160), (70, 72, 78)]
    for k, (shape, colour) in enumerate(zip(shapes, colours)):
        # The battery is a plastic box; the rest are metal.
        metal_part(c, blur(mask(c.w, c.h, shape), S(1)), colour, metal=[0.1, 0.8, 0.5, 0.8, 0.6][k], height=0.7,
                   material_name=["Plastic018B", "Metal041A", "Plastic018B", "Metal041A", "Metal041A"][k])
    terminals = blobs(c, [(195, 158, 12), (265, 158, 12)])
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.75, 0.15, 0.1], np.float32), terminals * np.array(x < 230, np.float32))
    c.put(np.ones((c.h, c.w, 3)) * 0.2, terminals * np.array(x >= 230, np.float32))
    pulley = np.clip(1 - np.abs(np.hypot(x - 420, y - 330) - 24) / 4, 0, 1)
    c.put(np.ones((c.h, c.w, 3)) * 0.15, pulley)
    fan = (np.sin(np.arctan2(y - 200, x - 860) * 7) > 0.2) & (np.hypot(x - 860, y - 200) < 44) & (np.hypot(x - 860, y - 200) > 12)
    c.put(np.ones((c.h, c.w, 3)) * 0.12, blur(fan.astype(np.float32), S(0.6)) * 0.7)
    for k in range(4):  # injectors along the rail
        c.put(np.ones((c.h, c.w, 3)) * 0.18, blobs(c, [(665 + 37 * k, 320, 8)]))
    return vignette(c)


def diag_light(ok):
    """A tester's lamp over a part: green for good, red for the fault."""
    c = Canvas(64, 64)
    x, y = grid(c)
    d = np.hypot(x - 32, y - 32)
    col = np.array((0.3, 0.95, 0.4) if ok else (1.0, 0.25, 0.2), np.float32)
    c.put(np.ones((c.h, c.w, 3)) * col, np.clip(1 - d / 30, 0, 1) ** 2 * 0.8)
    c.put(np.ones((c.h, c.w, 3)) * (col * 0.5 + 0.5), np.clip(1 - d / 11, 0, 1) ** 0.5)
    return c.image()


WELD_SEAM = [(200, 262), (330, 250), (460, 268), (590, 248), (720, 264), (824, 252)]  # PMCI_fnc_boardOpen


def weld_scene():
    """A painted hull plate with rivets and a crack along WELD_SEAM."""
    c = Canvas(1024, 512)
    x, y = grid(c)
    plate = material("Metal041A", c.w, c.h, S(400), tint=(110, 114, 82), tint_mix=0.85, contrast=0.6)
    wear = np.clip(noise(c.w, c.h, 414, S(18)) * 2 - 0.9, 0, 1)  # paint worn to bare steel in places
    plate["color"] = plate["color"] * (1 - wear[:, :, None]) + np.array([0.45, 0.43, 0.4], np.float32) * wear[:, :, None]
    h = noise(c.w, c.h, 411, S(60)) * 0.1
    c.put(shade(plate, h, strength=S(10), metal=0.3, spec=0.2), np.ones((c.h, c.w)))
    for yy in (60, 452):  # seams and rivets of the plates
        tint(c, (np.abs(y - yy) < 2).astype(np.float32), (0.1, 0.1, 0.08), 0.6)
        rivets = blobs(c, [(px, yy + 22 * (1 if yy < 256 else -1), 7) for px in range(40, 1024, 70)])
        metal_part(c, rivets, (100, 102, 78), metal=0.3, height=0.8)
    # The crack: dark, jagged, scorched and rusty around it.
    d = np.full((c.h, c.w), 1e9, np.float32)
    for (ax, ay), (bx, by) in zip(WELD_SEAM, WELD_SEAM[1:]):
        t = np.clip(((x - ax) * (bx - ax) + (y - ay) * (by - ay)) / ((bx - ax) ** 2 + (by - ay) ** 2), 0, 1)
        d = np.minimum(d, np.hypot(x - ax - t * (bx - ax), y - ay - t * (by - ay)))
    jag = d + noise(c.w, c.h, 412, S(3)) * 3
    tint(c, np.clip(1 - jag / 40, 0, 1) * np.clip(noise(c.w, c.h, 413, S(10)) + 0.6, 0, 1), (0.42, 0.22, 0.1), 0.55)
    crack = (jag < 6).astype(np.float32)
    tint(c, blur(crack, S(0.6)), (0.03, 0.03, 0.03), 0.95)
    tint(c, np.clip(1 - np.abs(jag - 7) / 2, 0, 1), (0.85, 0.85, 0.75), 0.25)
    return vignette(c)


def weld_bead():
    """A piece of weld bead (stretched along the seam): rippled, cooling from orange."""
    c = Canvas(256, 64)
    x, y = grid(c)
    v = (y - 32) / 22
    m = blur((np.abs(v) < 1).astype(np.float32), S(1))
    ripples = np.sin(x * 0.35 - np.abs(v) * 2.5) * 0.08
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1)) * 0.6 + ripples
    steel = material("Metal046A", c.w, c.h, S(80))
    steel["color"] = steel["color"] * 0.7 + np.array([0.08, 0.05, 0.02], np.float32)
    lit = shade(steel, h * m, strength=S(10), metal=0.8, spec=0.6)
    heat = np.clip(1 - np.abs(v) * 1.2, 0, 1) * 0.35
    lit = lit * (1 - heat[:, :, None]) + np.array([1.0, 0.45, 0.1], np.float32) * heat[:, :, None]
    c.put(np.clip(lit, 0, 1), m)
    return c.image()


def weld_torch():
    """A welding torch coming in from the upper right; the arc is at (24, 232)."""
    c = Canvas(256, 256)
    x, y = grid(c)
    a = math.radians(40)
    u = (x - 24) * math.cos(a) - (y - 232) * math.sin(a)
    v = (x - 24) * math.sin(a) + (y - 232) * math.cos(a)
    nozzle = ((u > 14) & (u < 80) & (np.abs(v) < 6 + u * 0.12)).astype(np.float32)
    neck = ((u > 80) & (u < 140) & (np.abs(v) < 10)).astype(np.float32)
    grip = ((u > 140) & (u < 260) & (np.abs(v) < 17)).astype(np.float32)
    whole = blur(np.maximum.reduce([nozzle, neck, grip]), S(0.8))
    c.shadow(whole, S(8), S(10), S(6), 0.5)
    copper = material("Metal046A", c.w, c.h, S(60))
    copper["color"] = np.clip(copper["color"] * np.array([1.2, 0.75, 0.45], np.float32), 0, 1)
    c.put(shade(copper, np.sqrt(np.clip(1 - (v / 14) ** 2, 0, 1)) * nozzle, strength=S(8), metal=0.9, spec=0.7), blur(nozzle, S(0.6)))
    steel = material("Metal046A", c.w, c.h, S(60))
    c.put(shade(steel, np.sqrt(np.clip(1 - (v / 10) ** 2, 0, 1)) * neck, strength=S(8), metal=0.9, spec=0.7), blur(neck, S(0.6)))
    c.put(shade(flat(c.w, c.h, (30, 30, 34), rough=0.6), np.sqrt(np.clip(1 - (v / 17) ** 2, 0, 1)) * grip + np.sin(u * 0.5) * 0.04 * grip,
                strength=S(14), spec=0.2), blur(grip, S(0.6)))
    d = np.hypot(x - 24, y - 232)
    c.put(np.ones((c.h, c.w, 3)) * np.array([1.0, 0.75, 0.4], np.float32), np.clip(1 - d / 44, 0, 1) ** 2 * 0.8)
    c.put(np.ones((c.h, c.w, 3)) * np.array([0.85, 0.9, 1.0], np.float32), np.clip(1 - d / 12, 0, 1) ** 0.6)
    return c.image()


def track_links(c, x0, x1, seed):
    """Track shoes side by side from x0 to x1 (scene pixels), centred on y 256."""
    x, y = grid(c)
    for k, lx in enumerate(range(x0, x1, 64)):
        shoe = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((lx + 2, 150, lx + 62, 362)), radius=S(8), fill=255)), S(0.8))
        metal_part(c, shoe, (78, 76, 70), metal=0.6, rough=0.15, height=0.4, seed=seed + k, material_name="Metal053C")
        grouser = blur(((np.abs(x - lx - 32) < 9) & (np.abs(y - 256) < 100)).astype(np.float32) * shoe, S(0.6))
        metal_part(c, grouser, (70, 68, 62), metal=0.6, height=0.6)
        for py in (176, 336):  # end connectors
            metal_part(c, blobs(c, [(lx + 32, py, 12)]), (60, 60, 62), metal=0.8, height=0.8)


def track_scene():
    """A broken tank track on the ground with a gap at x 512 where a link is missing."""
    c = Canvas(1024, 512)
    ground_layer(c, seed=421, dark=0.6)
    track_links(c, -40, 448, 422)
    track_links(c, 576, 1080, 440)
    x, y = grid(c)
    for px in (448, 576):  # empty pin holes at the gap
        c.put(np.ones((c.h, c.w, 3)) * 0.05, blobs(c, [(px, 256, 8)]))
    return c.image()


def track_link():
    """The loose track link that goes into the gap (centre of the picture = centre of the gap)."""
    c = Canvas(256, 256)
    x, y = grid(c)
    shoe = blur(mask(c.w, c.h, lambda d: d.rounded_rectangle(S((66, 22, 190, 234)), radius=S(10), fill=255)), S(0.8))
    metal_part(c, shoe, (96, 92, 84), metal=0.6, rough=0.15, height=0.4, material_name="Metal053C")
    grouser = blur(((np.abs(x - 128) < 12) & (np.abs(y - 128) < 100)).astype(np.float32) * shoe, S(0.6))
    metal_part(c, grouser, (74, 72, 66), metal=0.6, height=0.6)
    for px in (64, 192):  # its pin holes, on the line of the track's holes
        c.put(np.ones((c.h, c.w, 3)) * 0.05, blobs(c, [(px + (8 if px < 128 else -8), 128, 9)]))
    return c.image()


def track_pin():
    """A track pin, driven in from the right."""
    c = Canvas(256, 64)
    x, y = grid(c)
    v = (y - 32) / 9
    pin = ((np.abs(v) < 1) & (x > 4) & (x < 236)).astype(np.float32)
    head = (np.hypot(x - 236, y - 32) < 16).astype(np.float32) * (x > 228)
    whole = blur(np.maximum(pin, head), S(0.6))
    c.shadow(whole, S(3), S(4), S(3), 0.5)
    steel = material("Metal046A", c.w, c.h, S(60))
    h = np.sqrt(np.clip(1 - v ** 2, 0, 1)) * pin + dome(head, S(4)) * head
    c.put(shade(steel, h * whole, strength=S(8), metal=0.9, spec=0.7), whole)
    return c.image()
