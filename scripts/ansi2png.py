#!/usr/bin/env python3
"""Render an ANSI capture (tmux capture-pane -e) to PNG. Usage: ansi2png.py in.ans out.png"""
import re, sys
from PIL import Image, ImageDraw, ImageFont

src, dst = sys.argv[1], sys.argv[2]
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
size = 15
f = ImageFont.truetype(FONT, size); fb = ImageFont.truetype(BOLD, size)
cw = int(f.getlength("M")); ch = size + 4
DEF_FG, DEF_BG = (192, 202, 245), (26, 27, 38)
BASE = [(0,0,0),(205,0,0),(0,205,0),(205,205,0),(0,0,238),(205,0,205),(0,205,205),(229,229,229),
        (127,127,127),(255,0,0),(0,255,0),(255,255,0),(92,92,255),(255,0,255),(0,255,255),(255,255,255)]
def c256(n):
    if n < 16: return BASE[n]
    if n < 232:
        n -= 16; s = [0, 95, 135, 175, 215, 255]; return (s[n // 36], s[(n // 6) % 6], s[n % 6])
    v = 8 + 10 * (n - 232); return (v, v, v)

lines = open(src, encoding="utf-8", errors="replace").read().split("\n")
while lines and not lines[-1].strip(): lines.pop()
cols = 0
cells = []
for line in lines:
    fg, bg, bold, rev = DEF_FG, DEF_BG, False, False
    row = []
    for tok in re.split(r"(\x1b\[[0-9;]*m)", line):
        m = re.fullmatch(r"\x1b\[([0-9;]*)m", tok)
        if m:
            p = [int(x) if x else 0 for x in m.group(1).split(";")] or [0]
            i = 0
            while i < len(p):
                v = p[i]
                if v == 0: fg, bg, bold, rev = DEF_FG, DEF_BG, False, False
                elif v == 1: bold = True
                elif v == 22: bold = False
                elif v == 7: rev = True
                elif v == 27: rev = False
                elif 30 <= v <= 37: fg = BASE[v - 30]
                elif 90 <= v <= 97: fg = BASE[v - 90 + 8]
                elif 40 <= v <= 47: bg = BASE[v - 40]
                elif 100 <= v <= 107: bg = BASE[v - 100 + 8]
                elif v == 39: fg = DEF_FG
                elif v == 49: bg = DEF_BG
                elif v in (38, 48):
                    if p[i + 1] == 2: col = tuple(p[i + 2:i + 5]); i += 4
                    else: col = c256(p[i + 2]); i += 2
                    if v == 38: fg = col
                    else: bg = col
                i += 1
            continue
        for chr_ in tok:
            row.append((chr_, (bg if rev else fg), (fg if rev else bg), bold))
    cells.append(row); cols = max(cols, len(row))
img = Image.new("RGB", (cols * cw, len(cells) * ch), DEF_BG)
d = ImageDraw.Draw(img)
for y, row in enumerate(cells):
    for x, (c, fg, bg, b) in enumerate(row):
        d.rectangle([x * cw, y * ch, (x + 1) * cw - 1, (y + 1) * ch - 1], fill=bg)
        if c.strip():
            d.text((x * cw, y * ch + 1), c, font=fb if b else f, fill=fg)
img.save(dst)
print(dst, img.size)
