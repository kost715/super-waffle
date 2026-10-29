#!/usr/bin/env python3
"""Mock-up of the four boards at 1920 x 1080 for review: board_preview.png.

Composites the PNG textures with the layout of ui.hpp / PMCI_fnc_boardLayout (safe zone
taken as the whole screen). Fonts, buttons and the progress bar only approximate Arma's.
Usage: python3 tools/board_preview.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
TEX = ROOT / "textures"
SW, SH = 1920, 1080
WIN_X, WIN_Y = 0.21, 0.1
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def box(px, py, pw, ph):
    return (round(SW * (WIN_X + px)), round(SH * (WIN_Y + py)), round(SW * pw), round(SH * ph))


def tex(name):
    return Image.open(TEX / f"{name}_ca.png").convert("RGBA")


def put(img, name, rect, tint=None):
    x, y, w, h = rect
    pic = tex(name).resize((max(1, w), max(1, h)), Image.LANCZOS)
    if tint:
        r, g, b, a = pic.split()
        r = r.point(lambda v: v * tint[0])
        g = g.point(lambda v: v * tint[1])
        b = b.point(lambda v: v * tint[2])
        a = a.point(lambda v: v * tint[3])
        pic = Image.merge("RGBA", (r, g, b, a))
    img.alpha_composite(pic, (x, y))


def button(d, rect, text, enabled=True):
    x, y, w, h = rect
    d.rectangle((x, y, x + w, y + h), fill=(46, 77, 107, 242) if enabled else (60, 60, 60, 200))
    font = ImageFont.truetype(FONT, 20)
    tw = d.textlength(text, font=font)
    d.text((x + (w - tw) / 2, y + h / 2 - 12), text, font=font, fill=(255, 255, 255, 255) if enabled else (150, 150, 150, 255))


def board(game, look, gauge, status, help_text, title, time, buttons):
    img = Image.new("RGBA", (SW, SH), (40, 44, 40, 255))
    d = ImageDraw.Draw(img)
    x, y, w, h = box(0, 0, 0.58, 0.8)
    img.alpha_composite(tex("ui_board_bg").resize((w, h), Image.LANCZOS), (x, y))
    x, y, w, h = box(0, 0, 0.58, 0.045)
    d.rectangle((x, y, x + w, y + h), fill=(36, 66, 97, 242))
    put(img, f"icon_{game}", box(0.006, 0.0045, 0.02, 0.036))
    d.text(box(0.03, 0, 0, 0)[:2], " " + title, font=ImageFont.truetype(BOLD, 28), fill=(255, 255, 255, 255))
    d.multiline_text(box(0.015, 0.055, 0, 0)[:2], help_text, font=ImageFont.truetype(FONT, 19), fill=(235, 235, 235, 255), spacing=6)
    # Scene: 2:1 fit inside the scene area, as PMCI_fnc_boardLayout does.
    ax, ay, aw, ah = box(0.015, 0.12, 0.55, 0.47)
    d.rectangle((ax, ay, ax + aw, ay + ah), fill=(0, 0, 0, 90))
    sw, sh = aw, aw / 2
    if sh > ah:
        sh, sw = ah, ah * 2
    ox, oy = ax + (aw - sw) / 2, ay + (ah - sh) / 2
    scene = Image.new("RGBA", (round(sw), round(sh)), (0, 0, 0, 0))
    for name, (px, py, pw, ph) in look:
        k = sw / 1024
        pic = tex(name).resize((round(pw * k), round(ph * k)), Image.LANCZOS)
        layer = Image.new("RGBA", scene.size, (0, 0, 0, 0))
        layer.paste(pic, (round(px * k), round(py * k)))  # paste clips, like the controls group
        scene.alpha_composite(layer)
    img.alpha_composite(scene, (round(ox), round(oy)))
    d.text(box(0.015, 0.598, 0, 0)[:2], status, font=ImageFont.truetype(FONT, 22), fill=(255, 255, 255, 255))
    gx, gy, gw, gh = box(0.04, 0.64, 0.5, 0.05)
    if gauge:
        d.rectangle((gx, gy, gx + gw, gy + gh), fill=(13, 15, 18, 230))
        band, fill, inset, color, marker = gauge
        if band:
            put(img, "ui_gauge_band", (gx + round(gw * band[0]), gy, round(gw * (band[1] - band[0])), gh), (0.35, 0.85, 0.4, 0.8))
        fi = round(SH * inset)
        put(img, "ui_gauge_fill", (gx, gy + fi, max(1, round(gw * fill)), gh - 2 * fi), color)
        put(img, "ui_gauge_frame", (gx, gy, gw, gh), (0.8, 0.84, 0.88, 1))
        if marker is not None:
            put(img, "ui_gauge_marker", (gx + round(gw * (marker - 0.014)), gy, round(gw * 0.028), gh))
    tx, ty, tw, th = box(0.04, 0.70, 0.5, 0.02)
    d.rectangle((tx, ty, tx + tw, ty + th), outline=(102, 102, 102, 255))
    d.rectangle((tx + 1, ty + 1, tx + 1 + round((tw - 2) * time), ty + th - 1), fill=(77, 140, 204, 255))
    for rect, text, enabled in buttons:
        button(d, box(*rect), text, enabled)
    x, y, w, h = box(0, 0, 0.58, 0.8)
    return img.crop((x - 20, y - 20, x + w + 20, y + h + 20))


def nuts(states):
    out = []
    for k, state in enumerate(states):
        cx = 512 + 150 * math.cos(math.radians(-90 + 72 * k))
        cy = 256 + 150 * math.sin(math.radians(-90 + 72 * k))
        out.append((f"wheel_nut_{state}", (cx - 64, cy - 64, 128, 128)))
    return out


STRETCHES = [(0.08, 0.17), (0.25, 0.31), (0.38, 0.46), (0.5, 0.56), (0.62, 0.69), (0.74, 0.8), (0.86, 0.94)]
EDGES = [("edges_strip", (232 + 560 * (lo + hi) / 2 - 36, 150, 72, 212)) for lo, hi in STRETCHES[:3]] + \
        [("edges_target", (232 + 560 * lo, 196, 560 * (hi - lo), 120)) for lo, hi in STRETCHES[3:]] + \
        [("edges_runner", (232 + 560 * 0.48 - 20, 150, 40, 212))]
DIRT = [(f"dirt_{k % 3 + 1}", (x - 65, y - 65, 130, 130)) for k, (x, y) in
        enumerate([(372, 208), (528, 196), (672, 222), (330, 304), (480, 292), (622, 318)])]
STITCHES = [("suture_stitch", (232 + 560 * (k + 0.5) / 5 - 24, 200, 48, 112)) for k in range(2)] + \
           [("suture_point", (232 + 560 * 2.5 / 5 - 6 - 20, 210, 40, 40)), ("suture_needle", (232 + 560 * 2.5 / 5 - 6 - 18, 230 - 174, 192, 192))]
BEADS = [("weld_bead", (x0, y0 - 14, 66, 28)) for x0, y0 in ((200, 257), (266, 252), (332, 252))]
HOLD, FIX, CANCEL = (0.015, 0.74, 0.2, 0.045), (0.225, 0.74, 0.17, 0.045), (0.405, 0.74, 0.16, 0.045)
BOARDS = [
    board("cpr", [("cpr_scene", (0, 0, 1024, 512)), ("cpr_hands_down", (352, 106, 256, 512)), ("cpr_beat_on", (896, 16, 112, 112))],
          ((0.75, 1), 0.92, 0.0125, (0.9, 0.3, 0.25, 0.95), None),
          "Правильных нажатий: 14 из ~26. Качество: 54%  Хруст! Сломано ребро (1)",
          "Жмите Пробел (или кнопку) на каждое нажатие, примерно два раза в секунду:\n100–120 в минуту. Сердце показывает темп. Сильно чаще — можно сломать ребро.",
          "Сердечно-лёгочная реанимация", 0.55, [(HOLD, "Жать / держать", True), (CANCEL, "Прекратить", True)]),
    board("tourniquet", [("tq_scene", (0, 0, 1024, 512)), ("tq_windlass_5", (342, 16, 256, 256))],
          ((0.62, 0.8), 0.68, 0.0125, (0.95, 0.55, 0.2, 0.95), 0.68), "Давление: 68%. Осталось срывов: 2",
          "Держите Пробел, чтобы затягивать. Остановитесь в зелёной зоне и нажмите\nEnter, чтобы зафиксировать. Перетянете — соскользнёт.",
          "Жгут", 0.3, [(HOLD, "Жать / держать", True), (FIX, "Зафиксировать", True), (CANCEL, "Прекратить", True)]),
    board("bandage", [("wound_velocity", (0, 0, 1024, 512)), ("bandage_gauze_2", (256, 122, 512, 256))],
          ((0.38, 0.62), 0.46, 0.0175, (0.45, 0.7, 0.95, 0.95), 0.52), "Набито: 46%. Качество: 81%",
          "Держите белую стрелку в движущейся зелёной зоне: Пробел — давить сильнее,\nотпустить — ослабить.",
          "Перевязка — огнестрельное ранение", 0.4, [(HOLD, "Жать / держать", True), (CANCEL, "Прекратить", True)]),
    board("wheel", [("wheel_new", (256, 0, 512, 512))] + nuts(["done", "loose", "done", "next", "loose"]),
          None, "Затяните гайки. Ошибок: 0",
          "Щёлкайте по гайкам: ослабьте их «звездой» (через одну, с любой), смените колесо,\nзатем затяните «звездой».",
          "Замена колеса", 0, [(CANCEL, "Прекратить", True)]),
    board("pressure", [("wound_avulsion", (0, 0, 1024, 512)), ("pressure_seep", (256, 128, 512, 256)), ("pressure_hand_firm", (256, 0, 512, 512))],
          ((0.58, 0.78), 0.55, 0.0175, (0.9, 0.3, 0.25, 0.95), 0.66), "Прижато: 55%. Качество: 74%",
          "Прижмите рану: держите Пробел, чтобы давить сильнее. Каждый удар пульса\nсбивает давление: держите стрелку в зелёной зоне, пока шкала не заполнится.",
          "Прижатие раны — авульсия", 0.35, [(HOLD, "Жать / держать", True), (CANCEL, "Прекратить", True)]),
    board("edges", [("wound_laceration", (0, 0, 1024, 512))] + EDGES, (None, 3 / 7, 0.0125, (0.9, 0.9, 0.85, 0.95), None),
          "Сведено: 3 из 7. Промахов в запасе: 2",
          "Сведите края раны полосками: жмите Пробел, когда бегунок над подсвеченным\nучастком. Нажатие мимо — промах.",
          "Сведение краёв раны — рваная рана", 0.45, [(HOLD, "Наложить полоску", True), (CANCEL, "Прекратить", True)]),
    board("clean", [("wound_abrasion", (0, 0, 1024, 512))] + DIRT + [("abrasion_swab", (452, 250, 96, 96))],
          (None, 0.38, 0.0125, (0.45, 0.7, 0.95, 0.95), None), "Очищено: 38%",
          "Очистите ссадину: зажмите левую кнопку мыши и стирайте грязь. Когда станет\nчисто, держите Пробел, чтобы наложить повязку.",
          "Обработка ссадины — ссадина", 0.3, [(CANCEL, "Прекратить", True)]),
    board("iv", [("iv_scene", (0, 0, 1024, 512)), ("iv_bruise", (380, 212, 96, 96)), ("iv_needle", (500, 16, 256, 256))],
          (None, 0.45, 0.0125, (0.45, 0.7, 0.95, 0.95), None), "Игла введена: 45%. Промахов в запасе: 1",
          "Наведите иглу мышью на вену и держите левую кнопку мыши, чтобы ввести её.\nРука дрожит: держите кончик на вене, иначе вена лопнет.",
          "Постановка капельницы", 0.4, [(CANCEL, "Прекратить", True)]),
    board("suture", [("wound_cut", (0, 0, 1024, 512))] + STITCHES, (None, 0.4, 0.0125, (0.9, 0.9, 0.85, 0.95), None),
          "Стежков: 2 из 5. Промахов в запасе: 3",
          "Щёлкайте по светящейся точке, чтобы провести через неё иглу, точка за точкой\nпоперёк раны. Чем точнее, тем ровнее шов.",
          "Зашивание раны", 0.35, [(CANCEL, "Прекратить", True)]),
    board("splint", [("splint_scene", (0, 0, 1024, 512)), ("splint_limb_2", (512, 0, 512, 512))],
          ((0.5 - 4 / 90, 0.5 + 4 / 90), 0.0, 0.0175, (0.45, 0.7, 0.95, 0.95), 0.5 - 10 / 90), "Угол: -10°. Удержано ровно: 0%",
          "Зажмите левую кнопку мыши и ведите в сторону, чтобы выпрямить сломанную часть.\nМышцы тянут её обратно: держите в зелёной зоне, пока шкала не заполнится.",
          "Наложение шины", 0.25, [(CANCEL, "Прекратить", True)]),
    board("diagnose", [("repair_engine", (0, 0, 1024, 512)), ("diag_ok", (206, 98, 48, 48)), ("diag_ok", (536, 78, 48, 48))],
          None, "Проверено: 2 из 5. Неверных: 2",
          "Найдите неисправность: щёлкните по детали, чтобы проверить её (исправная —\nпотеря времени). Потом держите Пробел, удерживая усилие в зелёной зоне.",
          "Ремонт узла — двигатель", 0.3, [(CANCEL, "Прекратить", True)]),
    board("weld", [("weld_scene", (0, 0, 1024, 512))] + BEADS + [("weld_torch", (395, 25, 256, 256))],
          (None, 0.35, 0.0125, (1, 0.75, 0.3, 0.95), None), "Шов: 35%. Нагрев: 20%. Качество: 90%",
          "Зажмите левую кнопку мыши и ведите горелку вдоль трещины слева направо.\nСлишком быстро — слабый шов, слишком медленно — прожжёте лист.",
          "Заплатка корпуса — корпус", 0.3, [(CANCEL, "Прекратить", True)]),
    board("track", [("track_scene", (0, 0, 1024, 512)), ("track_link", (384, 150, 256, 256)), ("track_pin", (600, 224, 256, 64))],
          ((0.5 - 6 / 80, 0.5 + 6 / 80), 0.0, 0.0175, (0.95, 0.55, 0.2, 0.95), 0.78), "Совместите звено. Промахов в запасе: 3",
          "Жмите Пробел, когда болтающееся звено совпадёт с гусеницей. Потом забейте\nпалец: жмите, когда стрелка в зелёной зоне.",
          "Ремонт гусеницы", 0.2, [(HOLD, "Ударить", True), (CANCEL, "Прекратить", True)]),
]


def main():
    w, h = BOARDS[0].size
    sheet = Image.new("RGB", (w * 2, h * ((len(BOARDS) + 1) // 2)), (30, 30, 30))
    for i, b in enumerate(BOARDS):
        sheet.paste(b.convert("RGB"), ((i % 2) * w, (i // 2) * h))
    sheet = sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS)
    sheet.save(ROOT / "board_preview.png")
    print("board_preview.png", sheet.size)


if __name__ == "__main__":
    main()
