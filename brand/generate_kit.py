"""Generates the Brasa brand kit from the approved geometry (veins.py). Run: python3 generate_kit.py
Output in kit/ (svg + brand.json); render_kit.py makes the PNG, ICO and ICNS files; generate_brandbook.py builds the brandbook."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from coal import SILHOUETTE, path
import veins

KIT = os.path.join(HERE, "kit")
for d in ("symbol", "logotype", "app", "web", "states", "animated"): os.makedirs(os.path.join(KIT, d), exist_ok=True)

# colors, by role
COLOR = dict(coal="#0E0D0D", ember="#FF5A14", ember_dark="#FF6A1A", ember_hot="#FFB020",
             paper="#F3ECE4", smoke="#9C9CA3", graphite="#2A2A2E", plate="#121216")
STATES = [("ok", "Safe", "#33CC80"), ("warn", "Warming up", "#FFB533"), ("pause", "Too hot", "#FF7A29"), ("critical", "Critical", "#FF4052")]

# geometry
x0, y0, x1, y1 = SILHOUETTE.bounds
PAD = 6
VIEWBOX = f"{x0-PAD:.1f} {y0-PAD:.1f} {x1-x0+2*PAD:.1f} {y1-y0+2*PAD:.1f}"
W, H = x1 - x0, y1 - y0
CX, CY = (x0 + x1) / 2, (y0 + y1) / 2
full = {"base": veins.FULL[0][0], "ember": veins.FULL[1][0]}
compact = {"base": veins.COMPACT[0][0], "ember": veins.COMPACT[1][0]}
vein_parts = [v.intersection(SILHOUETTE) for v in veins.VEINS]

def mark(g, base, ember, mono=False):
    s = f'<path fill="{base}" fill-rule="evenodd" d="{path(g["base"])}"/>'
    if not mono: s += f'<path fill="{ember}" fill-rule="evenodd" d="{path(g["ember"])}"/>'
    return s
def svg(body, vb=VIEWBOX, size=None, extra=""):
    attrs = f' width="{size[0]}" height="{size[1]}"' if size else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}"{attrs}{extra}>{body}</svg>'
def write(rel, text): open(os.path.join(KIT, rel), "w").write(text)

# symbol
for suffix, g in (("", full), ("-compact", compact)):
    write(f"symbol/symbol{suffix}-color.svg", svg(mark(g, COLOR["coal"], COLOR["ember"]), extra=' role="img" aria-label="Brasa"'))
    write(f"symbol/symbol{suffix}-color-dark.svg", svg(mark(g, COLOR["coal"], COLOR["ember_dark"])))
    write(f"symbol/symbol{suffix}-black.svg", svg(mark(g, "#000", "#000", mono=True)))
    write(f"symbol/symbol{suffix}-white.svg", svg(mark(g, "#fff", "#fff", mono=True)))

# logotype: symbol + "Brasa" with the letters converted to outlines
font = TTFont(os.path.join(HERE, "fonts", "BricolageGrotesque-Bold.ttf")); glyphs = font.getGlyphSet(); cmap = font.getBestCmap(); hmtx = font["hmtx"]
def word(text, tracking=-12):
    x, parts = 0, []
    for ch in text:
        n = cmap[ord(ch)]; pen = SVGPathPen(glyphs); glyphs[n].draw(pen)
        parts.append(f'<path transform="translate({x} 0)" d="{pen.getCommands()}"/>'); x += hmtx[n][0] + tracking
    return "".join(parts), x
outlines, text_w = word("Brasa")
CAP_HEIGHT = 660
def logotype(base, ember, text, mono=False):
    cap = H * 0.50                        # cap height = half the symbol height
    k = cap / CAP_HEIGHT; gap = H * 0.26
    tx = x1 + gap; baseline = CY + cap / 2
    body = mark(full, base, ember, mono=mono) + f'<g fill="{text}" transform="translate({tx:.2f} {baseline:.2f}) scale({k:.5f} {-k:.5f})">{outlines}</g>'
    vb = f"{x0-PAD:.1f} {y0-PAD:.1f} {(tx - x0) + text_w*k + 2*PAD:.1f} {H+2*PAD:.1f}"
    return svg(body, vb=vb, extra=' role="img" aria-label="Brasa"')
write("logotype/logotype-color.svg", logotype(COLOR["coal"], COLOR["ember"], COLOR["coal"]))
write("logotype/logotype-color-dark.svg", logotype(COLOR["coal"], COLOR["ember_dark"], COLOR["paper"]))
write("logotype/logotype-black.svg", logotype("#000", "#000", "#000", mono=True))
write("logotype/logotype-white.svg", logotype("#fff", "#fff", "#fff", mono=True))

# plate versions: work on any background (GitHub README light and dark, social media)
def plate(inner, vb, radius=40, pad=34):
    vx, vy, vw, vh = [float(v) for v in vb.split()]
    new_vb = f"{vx-pad:.1f} {vy-pad:.1f} {vw+2*pad:.1f} {vh+2*pad:.1f}"
    return svg(f'<rect x="{vx-pad:.1f}" y="{vy-pad:.1f}" width="{vw+2*pad:.1f}" height="{vh+2*pad:.1f}" rx="{radius}" fill="{COLOR["plate"]}"/>' + inner, vb=new_vb)
_lg = logotype(COLOR["coal"], COLOR["ember_dark"], COLOR["paper"])
_vb = _lg.split('viewBox="')[1].split('"')[0]
write("logotype/logotype-plate.svg", plate(_lg.split(">", 1)[1].rsplit("</svg>", 1)[0], _vb))

# states: the ember takes the color of the Mac's state
for key, _, color in STATES:
    write(f"states/state-{key}.svg", svg(mark(compact, COLOR["coal"], color)))
    write(f"states/state-{key}-dark.svg", svg(mark(compact, COLOR["coal"], color)))

# favicon (compact; the coal lightens in dark mode so the shape stays visible on dark tabs)
write("web/favicon.svg", svg(f'<style>.b{{fill:{COLOR["coal"]}}}.f{{fill:{COLOR["ember"]}}}@media (prefers-color-scheme:dark){{.b{{fill:#6B6B72}}.f{{fill:{COLOR["ember_dark"]}}}}}</style>'
                             f'<path class="b" fill-rule="evenodd" d="{path(compact["base"])}"/><path class="f" fill-rule="evenodd" d="{path(compact["ember"])}"/>'))

# app icon: macOS-style dark plate with the lit coal inside
def icon(size=1024, margin=100, radius=185):
    side = size - 2 * margin; target = side * 0.64; k = target / W
    tx, ty = size / 2 - CX * k, size / 2 - CY * k
    body = (f'<rect x="{margin}" y="{margin}" width="{side}" height="{side}" rx="{radius}" fill="{COLOR["plate"]}"/>'
            f'<rect x="{margin+3}" y="{margin+3}" width="{side-6}" height="{side-6}" rx="{radius-3}" fill="none" stroke="#FFFFFF" stroke-opacity=".07" stroke-width="3"/>'
            f'<g transform="translate({tx:.2f} {ty:.2f}) scale({k:.4f})">{mark(full, COLOR["coal"], COLOR["ember_dark"])}</g>')
    return svg(body, vb=f"0 0 {size} {size}", size=(size, size))
write("app/icon.svg", icon())
write("web/apple-touch-icon.svg", icon(180, 0, 0))

# animated: the veins heat up and cool down, each at its own pace (color only, never opacity)
anim_css = f"""
.b{{fill:{COLOR['coal']}}}.m{{fill:{COLOR['ember']}}}.v{{fill:#E8450A}}
.m{{animation:fissure 3.2s ease-in-out infinite}}
@keyframes fissure{{0%,100%{{fill:{COLOR['ember']}}}50%{{fill:{COLOR['ember_hot']}}}}}
@keyframes vein{{0%,100%{{fill:#E8450A}}50%{{fill:#FFA62B}}}}
@media (prefers-reduced-motion:reduce){{.m,.v{{animation:none!important}}}}"""
durations = [2.6, 3.4, 2.9, 3.8, 3.1, 4.2, 3.5]
vein_paths = "".join(f'<path class="v" style="animation:vein {durations[i % len(durations)]}s ease-in-out {-0.7*i:.1f}s infinite" fill-rule="evenodd" d="{path(g)}"/>'
                     for i, g in enumerate(vein_parts))
fissure = veins.FISSURE.intersection(SILHOUETTE)
live_inner = f'<style>{anim_css}</style><path class="b" fill-rule="evenodd" d="{path(full["base"])}"/>{vein_paths}<path class="m" fill-rule="evenodd" d="{path(fissure)}"/>'
write("animated/brasa-live.svg", svg(live_inner, extra=' role="img" aria-label="Brasa, animated"'))
write("animated/brasa-live-plate.svg", plate(live_inner, VIEWBOX, radius=44, pad=40).replace("<svg ", '<svg role="img" aria-label="Brasa, animated" ', 1))

# tokens
json.dump({"name": "Brasa", "colors": COLOR, "states": {k: {"name": n, "hex": h} for k, n, h in STATES},
           "fonts": {"display": "Bricolage Grotesque Bold (OFL)", "text": "Bricolage Grotesque Regular (OFL)", "data": "Geist Mono (OFL)"},
           "symbol": {"full_min_px": 48, "compact_min_px": 16, "widths": {"fissure": "10 to 24 (variable)", "vein": "1 to 8 (variable, ends in a point)"}}},
          open(os.path.join(KIT, "brand.json"), "w"), indent=2)
print("kit svg ok")
