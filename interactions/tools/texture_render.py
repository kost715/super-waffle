"""Small lit-surface renderer for the PMC Interactions textures.

Every object is a mask, a height field and a material (colour, normal and roughness
maps from ambientCG, CC0). Normals come from the height field plus the material's
detail normal; one light from the upper left gives diffuse, ambient and specular light,
so flat shapes read as solid objects. Images are rendered at 2x and downscaled.
Materials are downloaded once into tools/.cache (see fetch()).
"""
from __future__ import annotations

import math
from pathlib import Path
import subprocess
import zipfile

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

CACHE = Path(__file__).resolve().parent / ".cache"
SCALE = 2
LIGHT = np.array([-0.45, -0.6, 0.66], np.float32)
LIGHT /= np.linalg.norm(LIGHT)
HALF = LIGHT + np.array([0, 0, 1], np.float32)
HALF /= np.linalg.norm(HALF)
MATERIALS = ["Fabric066", "Fabric061", "Fabric030", "Rubber004", "Metal041A", "Metal053C", "Metal046A", "Ground110",
             "Leather035D", "Plastic018B"]


# --- materials ---------------------------------------------------------------------
def fetch(name):
    folder = CACHE / name
    if not folder.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        archive = CACHE / f"{name}.zip"
        subprocess.run(["curl", "-sS", "-L", "-m", "300", "-o", str(archive), f"https://ambientcg.com/get?file={name}_1K-JPG.zip"], check=True)
        zipfile.ZipFile(archive).extractall(folder)
        archive.unlink()
    return folder


def _map(name, kind, w, h, tile, mode):
    path = fetch(name) / f"{name}_1K-JPG_{kind}.jpg"
    if not path.exists():
        return None
    img = Image.open(path).convert(mode)
    size = max(8, int(round(tile)))
    img = img.resize((size, size), Image.LANCZOS)
    arr = np.asarray(img).astype(np.float32) / 255.0
    reps = (math.ceil(h / size) + 1, math.ceil(w / size) + 1) + ((1,) if arr.ndim == 3 else ())
    return np.tile(arr, reps)[:h, :w]


def material(name, w, h, tile, tint=None, tint_mix=1.0, contrast=1.0, rough_bias=0.0):
    """Material maps tiled over w x h; tile = size of one repeat in pixels."""
    color = _map(name, "Color", w, h, tile, "RGB")
    if tint is not None:
        lum = color.mean(axis=2, keepdims=True)
        lum = (lum - lum.mean()) * contrast + 0.5
        tinted = np.clip(lum * 2 * np.array(tint, np.float32) / 255.0, 0, 1)
        color = color * (1 - tint_mix) + tinted * tint_mix
    normal = _map(name, "NormalGL", w, h, tile, "RGB")
    normal = normal * 2 - 1
    normal[:, :, 1] *= -1  # GL normals point y up; image rows go down
    rough = _map(name, "Roughness", w, h, tile, "L")
    rough = np.full((h, w), 0.8, np.float32) if rough is None else np.clip(rough + rough_bias, 0.03, 1)
    ao = _map(name, "AmbientOcclusion", w, h, tile, "L")
    ao = np.ones((h, w), np.float32) if ao is None else ao
    return {"color": color, "normal": normal, "rough": rough, "ao": ao}


def flat(w, h, rgb, rough=0.6):
    return {"color": np.ones((h, w, 3), np.float32) * np.array(rgb, np.float32) / 255.0,
            "normal": np.dstack([np.zeros((h, w)), np.zeros((h, w)), np.ones((h, w))]).astype(np.float32),
            "rough": np.full((h, w), rough, np.float32), "ao": np.ones((h, w), np.float32)}


# --- geometry -----------------------------------------------------------------------
def mask(w, h, draw):
    m = Image.new("L", (w, h), 0)
    draw(ImageDraw.Draw(m))
    return np.asarray(m).astype(np.float32) / 255.0


def _box(arr, r, axis):
    if r < 1:
        return arr
    pad = [(0, 0)] * arr.ndim
    pad[axis] = (r + 1, r)
    c = np.cumsum(np.pad(arr, pad, mode="edge"), axis=axis, dtype=np.float64)
    hi = np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis)
    lo = np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)
    return ((hi - lo) / (2 * r + 1)).astype(np.float32)


def blur(arr, radius):
    """Gaussian-like blur in float precision: three box passes per axis."""
    r = max(0, int(round(radius * 0.8)))
    out = arr.astype(np.float32)
    for _ in range(3):
        out = _box(_box(out, r, 0), r, 1)
    return out


def shift(arr, dx, dy):
    """Move an array by whole pixels; what moves in from outside is zero (no wrap-around)."""
    out = np.zeros_like(arr)
    h, w = arr.shape[:2]
    dx, dy = int(round(dx)), int(round(dy))
    out[max(0, dy):h + min(0, dy), max(0, dx):w + min(0, dx)] = arr[max(0, -dy):h - max(0, dy), max(0, -dx):w - max(0, dx)]
    return out


def ridges(w, h, seed, radii, weights):
    """Crumpled-cloth height: sharp creases where several noise octaves cross zero."""
    out = np.zeros((h, w), np.float32)
    for k, (r, wt) in enumerate(zip(radii, weights)):
        out += (1 - np.abs(noise(w, h, seed + k, r))) * wt
    return out / sum(weights)


def dome(m, radius):
    """Rounded height for a flat shape: 0 at the edge, 1 well inside."""
    b = blur(m, radius)
    return np.sqrt(np.clip((b - 0.5) * 2, 0, 1)) * m


def noise(w, h, seed, radius):
    rng = np.random.default_rng(seed)
    n = rng.random((h, w)).astype(np.float32)
    n = blur(n, radius) if radius else n
    n -= n.mean()
    return n / (np.abs(n).max() + 1e-6)


# --- lighting -----------------------------------------------------------------------
def normals(height, strength, detail=None, detail_strength=1.0):
    gy, gx = np.gradient(height * strength)
    n = np.dstack([-gx, -gy, np.ones_like(height)])
    if detail is not None:
        n[:, :, 0] += detail[:, :, 0] * detail_strength
        n[:, :, 1] += detail[:, :, 1] * detail_strength
    return n / np.linalg.norm(n, axis=2, keepdims=True)


def shade(mat, height, strength=40, detail_strength=1.0, metal=0.0, spec=0.35, ambient=0.38, occlusion=None):
    n = normals(height, strength, mat["normal"], detail_strength)
    diff = np.clip(n @ LIGHT, 0, 1)
    rough = mat["rough"]
    power = 4 + (1 - rough) ** 2 * 160
    hl = np.clip(n @ HALF, 0, 1) ** power * (1 - rough) ** 1.5
    albedo = mat["color"]
    ao = mat["ao"] * (1 if occlusion is None else occlusion)
    lit = albedo * (ambient + (1 - ambient) * diff[:, :, None] * (1 - 0.7 * metal)) * ao[:, :, None]
    spec_color = albedo * metal + (1 - metal) * np.ones(3, np.float32)
    lit += spec * (1 + 2 * metal) * hl[:, :, None] * spec_color
    return np.clip(lit, 0, 1)


class Canvas:
    """RGBA float canvas with straight-alpha 'over' compositing."""

    def __init__(self, w, h):
        self.w, self.h = w * SCALE, h * SCALE
        self.out = (w, h)
        self.rgb = np.zeros((self.h, self.w, 3), np.float32)
        self.a = np.zeros((self.h, self.w), np.float32)

    def put(self, rgb, alpha):
        alpha = np.clip(alpha, 0, 1)
        out_a = alpha + self.a * (1 - alpha)
        safe = np.where(out_a > 1e-6, out_a, 1)
        self.rgb = (rgb * alpha[:, :, None] + self.rgb * (self.a * (1 - alpha))[:, :, None]) / safe[:, :, None]
        self.a = out_a

    def shadow(self, m, dx, dy, radius, opacity):
        self.put(np.zeros((self.h, self.w, 3), np.float32), shift(blur(m, radius), dx, dy) * opacity)

    def image(self):
        arr = np.dstack([self.rgb, self.a]) * 255
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
        return img.resize(self.out, Image.LANCZOS)


def grid(c):
    y, x = np.mgrid[0:c.h, 0:c.w].astype(np.float32)
    return x / SCALE, y / SCALE  # coordinates in output pixels


def S(v):
    if isinstance(v, (tuple, list)):
        return type(v)(S(x) for x in v)
    return v * SCALE


# --- shared pieces -------------------------------------------------------------------
def ground_layer(c, seed=1, dark=0.75, tile=420):
    g = material("Ground110", c.w, c.h, S(tile))
    patches = noise(c.w, c.h, seed + 7, S(90))[:, :, None]  # breaks up the visible tiling
    g["color"] *= dark * (1 + patches * 0.25)
    height = noise(c.w, c.h, seed, S(30)) * 0.4
    c.put(shade(g, height, strength=20, detail_strength=1.2, ambient=0.45), np.ones((c.h, c.w)))
    x, y = grid(c)
    vign = np.clip(((x / c.out[0] - 0.5) ** 2 + (y / c.out[1] - 0.5) ** 2) * 1.8, 0, 0.55)
    c.put(np.zeros((c.h, c.w, 3)), vign)


def skin_material(c, seed, tone=(198, 150, 120), tile=260):
    m = material("Leather035D", c.w, c.h, S(tile), tint=tone, tint_mix=0.92, contrast=0.35)
    blotch = noise(c.w, c.h, seed, S(25))[:, :, None]
    m["color"] = np.clip(m["color"] * (1 + blotch * np.array([0.06, -0.02, -0.03])), 0, 1)
    m["rough"] = np.clip(m["rough"] * 0.7 + 0.2, 0, 1)
    return m


def fabric_olive(c, tile=150, tone=(92, 98, 66)):
    m = material("Fabric066", c.w, c.h, S(tile), tint=tone, tint_mix=0.85, contrast=0.9)
    m["rough"] = np.clip(m["rough"] + 0.1, 0, 1)
    return m


def wrinkles(c, seed, scale, amount):
    x, y = grid(c)
    n = noise(c.w, c.h, seed, S(scale))
    return (np.sin(x / scale * 2.3 + n * 6) * 0.5 + n) * amount


def blood_layer(c, m, seed, gloss=True):
    """Fresh blood on a mask: a thin, glossy film, darker where it is deep."""
    mat = flat(c.w, c.h, (110, 6, 10), rough=0.1 if gloss else 0.45)
    depth = blur(m, S(8))
    mat["color"] *= (0.5 + 0.5 * (1 - depth) ** 1.5)[:, :, None]
    h = dome(m, S(10)) * 0.35 + noise(c.w, c.h, seed, S(4)) * 0.03 * m
    c.put(shade(mat, h, strength=S(14), spec=0.8 if gloss else 0.2, ambient=0.5), m)


def blobs(c, pts):
    """Union of discs [(x, y, r), ...] in output pixels, anti-aliased."""
    m = mask(c.w, c.h, lambda d: [d.ellipse(S((x - r, y - r, x + r, y + r)), fill=255) for x, y, r in pts])
    return blur(m, S(0.7))
