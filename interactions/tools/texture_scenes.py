"""Realistic scenes for the PMC Interactions boards, drawn with texture_render."""
from __future__ import annotations

import math

import numpy as np

from texture_render import (S, Canvas, blobs, blood_layer, blur, dome, fabric_olive, flat, grid, ground_layer, mask,
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

