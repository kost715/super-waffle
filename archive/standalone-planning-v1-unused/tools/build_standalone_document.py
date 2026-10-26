#!/usr/bin/env python3
"""Build the Russian standalone-project concept PDF from its Markdown source."""
from __future__ import annotations

import hashlib
import html
import json
from pathlib import Path
import re
import subprocess

from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfdoc
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    BaseDocTemplate, CondPageBreak, Flowable, Frame, NextPageTemplate,
    PageBreak, PageTemplate, Paragraph, Spacer, Table, TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents

# Shared embedded Cyrillic fonts and Pandoc table decoding; no old cover/layout.
from build_team_document import table_rows

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/standalone/CONCEPT_RU.md"
OUTPUT = ROOT / "dist/PMC_Standalone_Concept_RU_v1.pdf"
REPORT = ROOT / "reports/standalone-document"
W, H = A4
M = 46
CW = W - 2 * M
NAVY = colors.HexColor("#142E3A")
TEAL = colors.HexColor("#087D6B")
MINT = colors.HexColor("#4DD9B2")
INK = colors.HexColor("#253B44")
MUTED = colors.HexColor("#5D717B")
LIGHT = colors.HexColor("#F1F6F6")
RULE = colors.HexColor("#D8E4E6")
TITLE = "ЧВК — самостоятельная кампания Arma 3"
STYLES = {
    "body": ParagraphStyle("StandaloneBody", fontName="Body", fontSize=9.7,
        leading=14.7, textColor=INK, spaceAfter=8, allowWidows=0, allowOrphans=0),
    "title": ParagraphStyle("StandaloneTitle", fontName="Display", fontSize=24,
        leading=31, textColor=NAVY, spaceAfter=17, keepWithNext=True),
    "chapter": ParagraphStyle("StandaloneChapter", fontName="Display", fontSize=21,
        leading=28, textColor=NAVY, spaceAfter=17, keepWithNext=True),
    "section": ParagraphStyle("StandaloneSection", fontName="Bold", fontSize=12,
        leading=17, textColor=TEAL, spaceBefore=12, spaceAfter=7, keepWithNext=True),
    "cell": ParagraphStyle("StandaloneCell", fontName="Body", fontSize=8.5,
        leading=12.6, textColor=INK),
    "cellhead": ParagraphStyle("StandaloneCellHead", fontName="Bold", fontSize=8.7,
        leading=12.8, textColor=colors.white),
    "small": ParagraphStyle("StandaloneSmall", fontName="Body", fontSize=8.8,
        leading=13.1, textColor=MUTED, spaceAfter=8),
}


def inline(nodes, formatted=True):
    out = []
    for node in nodes:
        kind, val = node["t"], node.get("c")
        if kind == "Str":
            value = html.escape(val) if formatted else val
            if formatted:
                value = value.replace("→", '<font name="Symbols">→</font>')
            out.append(value)
        elif kind in {"Space", "SoftBreak"}:
            out.append(" ")
        elif kind == "LineBreak":
            out.append("<br/>" if formatted else " ")
        elif kind in {"Strong", "Emph"}:
            text = inline(val, formatted)
            tag = "b" if kind == "Strong" else "i"
            out.append(f"<{tag}>{text}</{tag}>" if formatted else text)
        elif kind == "Code":
            out.append(html.escape(val[1]) if formatted else val[1])
        elif kind == "Quoted":
            out.append("«" + inline(val[1], formatted) + "»")
        elif kind == "Link":
            label = inline(val[1], formatted)
            target = val[2][0]
            if formatted and target.startswith("https://"):
                out.append(f'<link href="{html.escape(target, quote=True)}" color="#087D6B"><u>{label}</u></link>')
            else:
                out.append(label)
        else:
            raise ValueError(f"Unsupported inline: {kind}")
    return "".join(out)


def para(text, style="body", **kwargs):
    chosen = STYLES[style]
    if kwargs:
        chosen = ParagraphStyle(chosen.name + "Local", parent=chosen, **kwargs)
    return Paragraph(text, chosen)


def draw(c, text, x, top, width, size=10, font="Body", color=INK, leading=None):
    p = Paragraph(text, ParagraphStyle("CanvasText", fontName=font, fontSize=size,
        leading=leading or size * 1.45, textColor=color))
    _, height = p.wrap(width, H)
    p.drawOn(c, x, top - height)


class Cover(Flowable):
    def __init__(self):
        super().__init__()
        self.width, self.height = W, H

    def draw(self):
        c = self.canv
        c.bookmarkPage("cover")
        c.addOutlineEntry(TITLE, "cover", 0)
        c.setFillColor(NAVY)
        c.rect(0, 0, W, H, stroke=0, fill=1)
        c.setStrokeColor(colors.HexColor("#294B55"))
        for x, y, points in [(403, 694, [(0,0),(74,22),(110,-32),(58,-76),(-10,-40)]),
                             (473, 614, [(0,0),(78,20),(95,-48),(21,-87),(-29,-42)])]:
            path = c.beginPath()
            path.moveTo(x + points[0][0], y + points[0][1])
            for dx, dy in points[1:]: path.lineTo(x + dx, y + dy)
            path.close()
            c.drawPath(path)
        c.setFillColor(MINT)
        c.rect(M, H - 74, 42, 4, stroke=0, fill=1)
        draw(c, "ARMA 3 / PMC PROJECT", M, H - 34, CW, 10, "Bold", colors.white)
        draw(c, "КОНЦЕПЦИЯ САМОСТОЯТЕЛЬНОГО ПРОЕКТА", M, 695, CW, 9.3, "Bold", MINT)
        draw(c, "ЧВК", M, 647, CW, 69, "Display", colors.white, 78)
        draw(c, "Самостоятельная<br/>кампания Arma 3", M, 550, CW, 28, "Display", colors.white, 37)
        draw(c, "Контракты, снабжение, личный состав<br/>и противостояние компаний", M, 447, CW, 14,
             color=colors.HexColor("#CCE3E3"), leading=22)
        gap = 11
        width = (CW - 2 * gap) / 3
        for i, (number, label) in enumerate([
            ("1–3", "ЧВК игроков"), ("16", "Игроков на сервере"), ("PvE / PvP", "Формат кампании")
        ]):
            x = M + i * (width + gap)
            c.setFillColor(colors.HexColor("#244651"))
            c.roundRect(x, 239, width, 102, 7, stroke=0, fill=1)
            draw(c, number, x + 12, 324, width - 24, 25 if i < 2 else 18, "Display", MINT)
            draw(c, label, x + 12, 278, width - 24, 8.7, color=colors.white)
        draw(c, "Этап S0 · проектирование", M, 199, CW, 11, "Bold", MINT)
        draw(c, "Согласованные правила, идеи из референсов<br/>и последовательность разработки.", M, 170, CW, 10.2,
             color=colors.HexColor("#CCE3E3"), leading=17)
        c.setStrokeColor(colors.HexColor("#46646D"))
        c.line(M, 83, W - M, 83)
        draw(c, "Редакция 1.0 · 25 октября 2026 года", M, 65, CW, 9, color=colors.white)


class Cycle(Flowable):
    def __init__(self):
        super().__init__()
        self.width, self.height = CW, 204

    def draw(self):
        c = self.canv
        gap, height = 12, 87
        width = (CW - 2 * gap) / 3
        cards = [
            ("Компания", "Люди, роли и казна"), ("Контракт", "Задача и результат"),
            ("Доход", "Рейтинг и возможности"), ("Снабжение", "Имущество и персонал"),
            ("База", "Инфраструктура и сервис"), ("Влияние", "Регионы и отношения"),
        ]
        for i, (title, detail) in enumerate(cards):
            x = (i % 3) * (width + gap)
            y = self.height - (i // 3 + 1) * (height + gap)
            c.setFillColor(LIGHT)
            c.roundRect(x, y, width, height, 5, stroke=0, fill=1)
            draw(c, f"0{i + 1}", x + 11, y + 76, width - 22, 9, "Bold", TEAL)
            draw(c, title, x + 11, y + 54, width - 22, 12, "Bold", NAVY)
            draw(c, detail, x + 11, y + 31, width - 22, 8, color=MUTED, leading=12)


def footer(c, doc):
    c.saveState()
    c.setStrokeColor(RULE)
    c.setLineWidth(.5)
    c.line(M, H - 44, W - M, H - 44)
    c.line(M, 37, W - M, 37)
    c.setFont("Bold", 7.2)
    c.setFillColor(NAVY)
    c.drawString(M, H - 30, "PMC PROJECT / САМОСТОЯТЕЛЬНАЯ КАМПАНИЯ")
    c.setFont("Body", 7.2)
    c.setFillColor(MUTED)
    c.drawRightString(W - M, H - 30, "КОНЦЕПЦИЯ · РЕДАКЦИЯ 1.0")
    c.drawString(M, 23, "Проектирование · 25.10.2026")
    c.setFont("Bold", 8)
    c.drawRightString(W - M, 23, f"{doc.page:02d}")
    c.restoreState()


class ConceptCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.setTitle(TITLE)
        self.setAuthor("PMC project")
        self.setSubject("Концепция, референсы и этапы разработки; 1–3 ЧВК, до 16 игроков")
        self._doc.Catalog.Lang = pdfdoc.PDFString("ru-RU")


class ConceptDoc(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if hasattr(flowable, "bookmark"):
            self.canv.bookmarkPage(flowable.bookmark)
            self.canv.addOutlineEntry(flowable.getPlainText(), flowable.bookmark, flowable.level)
            if flowable.level == 0 and flowable.bookmark not in {"contents", "overview"}:
                self.notify("TOCEntry", (0, flowable.getPlainText(), self.page, flowable.bookmark))


def heading(text, key, level=0):
    p = para(text, "chapter" if level == 0 else "section")
    p.bookmark, p.level = key, level
    return p


def render(blocks, chapter=False):
    out = []
    for b in blocks:
        kind, value = b["t"], b.get("c")
        if kind in {"Para", "Plain"}:
            out.append(para(inline(value)))
        elif kind == "Header":
            level, attrs, nodes = value
            if level == 1: continue
            if level == 2:
                out.append(PageBreak())
                out.append(heading(inline(nodes), attrs[0]))
            else:
                out.append(CondPageBreak(110))
                out.append(heading(inline(nodes), attrs[0], 1))
        elif kind in {"BulletList", "OrderedList"}:
            items = value if kind == "BulletList" else value[1]
            for i, item in enumerate(items, 1):
                first, *rest = item
                if first["t"] not in {"Para", "Plain"}: raise ValueError("Unsupported list")
                style = ParagraphStyle("StandaloneList", parent=STYLES["body"], leftIndent=14,
                    bulletIndent=0, bulletFontName="Body", bulletFontSize=9, spaceAfter=5)
                out.append(Paragraph(inline(first["c"]), style, bulletText="•" if kind == "BulletList" else f"{i}."))
                out.extend(render(rest))
            out.append(Spacer(1, 4))
        elif kind == "Table":
            rows = table_rows(value)
            data = [[para("<br/>".join(inline(part["c"]) for part in cell[4]
                     if part["t"] in {"Para", "Plain"}), "cellhead" if i == 0 else "cell")
                     for cell in row[1]] for i, row in enumerate(rows)]
            n = len(data[0])
            ratios = {2: [.27, .73], 3: [.22, .40, .38], 4: [.18, .32, .32, .18]}[n]
            t = Table(data, colWidths=[CW * x for x in ratios], repeatRows=1, hAlign="LEFT")
            t.setStyle(TableStyle([
                ("BACKGROUND", (0,0), (-1,0), NAVY),
                ("ROWBACKGROUNDS", (0,1), (-1,-1), [LIGHT, colors.white]),
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("LEFTPADDING", (0,0), (-1,-1), 8), ("RIGHTPADDING", (0,0), (-1,-1), 8),
                ("TOPPADDING", (0,0), (-1,-1), 8), ("BOTTOMPADDING", (0,0), (-1,-1), 8),
                ("LINEBELOW", (0,-1), (-1,-1), .5, RULE),
            ]))
            t.spaceAfter = 13
            out.append(t)
        else:
            raise ValueError(f"Unsupported block: {kind}")
    return out


def segments(blocks):
    out = []
    for b in blocks:
        kind, value = b["t"], b.get("c")
        if kind in {"Para", "Plain"}: out.append(inline(value, False))
        elif kind == "Header":
            if value[0] > 1: out.append(inline(value[2], False))
        elif kind in {"BulletList", "OrderedList"}:
            for item in value if kind == "BulletList" else value[1]: out.extend(segments(item))
        elif kind == "Table":
            for row in table_rows(value):
                for cell in row[1]: out.extend(segments(cell[4]))
        else: raise ValueError(kind)
    return out


def main():
    OUTPUT.parent.mkdir(exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    ast = json.loads(subprocess.run(["pandoc", "-f", "gfm", "-t", "json", str(SOURCE)],
        check=True, capture_output=True, text=True).stdout)
    toc = TableOfContents()
    toc.dotsMinLevel = 0
    toc.levelStyles = [ParagraphStyle("StandaloneTOC", fontName="Body", fontSize=10.4,
        leading=16, textColor=INK, spaceBefore=9, rightIndent=28)]
    story = [Cover(), NextPageTemplate("body"), PageBreak(), heading("Кратко о проекте", "overview"),
        para("<b>1–3 компании · до 16 игроков · PvE и противостояние ЧВК.</b> Общая кампания с отдельной собственностью компаний и постоянными результатами."),
        Spacer(1, 8), Cycle(), Spacer(1, 10),
        para("Игра строится вокруг выбора контракта и развития организации. Командиры отвечают за людей, имущество и бюджет; игроки создают историю компании своими решениями."),
        para("<b>Опора концепции:</b> контрактный бизнес A3M PMC Simulator, управление и снабжение Antistasi Ultimate, территории и виртуальные патрули Frontlines &amp; Patrols."),
        para("<b>Первый технический результат:</b> собственный запуск без LifeSim и проверка отношений игроков и ИИ из разных ЧВК. Затем — цепочка от создания компании до контракта, награды и восстановления сохранения."),
        para("Сейчас выполнен разбор зависимостей и сформирован план. Самостоятельной игровой сборки ещё нет. Согласованные правила, предложения и открытые решения обозначены в тексте.", "small"),
        PageBreak(), heading("Содержание", "contents"),
        para("Нажмите на пункт содержания или используйте закладки PDF. Ссылки на референсы находятся в разделе 7.", "small"),
        toc, Spacer(1, 22),
        para("Документ подготовлен для обсуждения с будущими игроками и командой разработки. Редакция фиксирует решения на 25 октября 2026 года; календарные сроки реализации ещё не назначены.", "small")]
    story.extend(render(ast["blocks"]))
    doc = ConceptDoc(str(OUTPUT), pagesize=A4, leftMargin=M, rightMargin=M,
        topMargin=66, bottomMargin=54, pageCompression=1)
    doc.addPageTemplates([
        PageTemplate("cover", [Frame(0,0,W,H,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)]),
        PageTemplate("body", [Frame(M,54,CW,H-120,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)], onPage=footer),
    ])
    doc.multiBuild(story, canvasmaker=ConceptCanvas)
    reader = PdfReader(OUTPUT)
    page_texts = [p.extract_text() or "" for p in reader.pages]
    normalize = lambda s: re.sub(r"\s+", "", s)
    extracted = normalize("\n".join(page_texts))
    missing = [s for s in segments(ast["blocks"]) if normalize(s) not in extracted]
    if missing: raise ValueError(f"PDF text missing: {missing[:3]}")
    assert "1–3" in page_texts[0] and "16" in page_texts[0]
    assert "2–4" not in "\n".join(page_texts)
    assert all(len(t.strip()) > 80 for t in page_texts)
    links = sum(len(p.get("/Annots", [])) for p in reader.pages)
    assert links >= 15
    manifest = {"source": str(SOURCE.relative_to(ROOT)), "pdf": str(OUTPUT.relative_to(ROOT)),
        "edition": "1.0", "date": "2026-10-25", "pages": len(reader.pages),
        "source_text_segments": len(segments(ast["blocks"])), "all_source_segments_present": not missing,
        "link_annotations": links, "bytes": OUTPUT.stat().st_size,
        "sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest()}
    (REPORT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    (REPORT / "extracted.txt").write_text("\n\n".join(page_texts))
    (OUTPUT.parent / "SHA256SUMS.txt").write_text("".join(
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n"
        for p in sorted(OUTPUT.parent.iterdir()) if p.suffix in {".zip", ".pdf", ".docx"}
    ))
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
