"""Builds brandbook/index.html (a local page; it links to kit/ and fonts/ by relative path). Run: python3 generate_brandbook.py"""
import os, json
HERE = os.path.dirname(os.path.abspath(__file__))
B = json.load(open(os.path.join(HERE, "kit/brand.json"))); C = B["colors"]; S = B["states"]

def luminance(h):
    r, g, b = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    f = lambda v: v / 12.92 if v <= .03928 else ((v + .055) / 1.055) ** 2.4
    return .2126 * f(r) + .7152 * f(g) + .0722 * f(b)
def contrast(a, b): la, lb = sorted((luminance(a), luminance(b)), reverse=True); return (la + .05) / (lb + .05)
def swatch(name, hexa, role):
    cp, cg = contrast(hexa, C["paper"]), contrast(hexa, C["graphite"])
    txt = "#15110F" if luminance(hexa) > .35 else "#F3ECE4"
    return f'<div class=sw><div class=chip style="background:{hexa};color:{txt}">{hexa}</div><b>{name}</b><span>{role}</span><small>{cp:.1f}:1 on paper · {cg:.1f}:1 on graphite</small></div>'

colors = "".join([
    swatch("Coal", C["coal"], "the stone; text on light"), swatch("Ember", C["ember"], "veins and accents on light"),
    swatch("Ember (dark)", C["ember_dark"], "veins and accents on dark"), swatch("Paper", C["paper"], "light background; text on dark"),
    swatch("Plate", C["plate"], "behind the symbol: app icon, README, social"), swatch("Graphite", C["graphite"], "dark interface background"),
    swatch("Smoke", C["smoke"], "secondary text, captions")])
states = "".join(f'<div class=st><img src="../kit/states/state-{k}-dark.svg" height=84><b>{v["name"]}</b><span>{v["hex"]}</span></div>' for k, v in S.items())
def dont(title, style, img="../kit/symbol/symbol-color.svg", bg="#F3ECE4", h=110, extra=""):
    return f'<div class=dont><div class=box style="background:{bg}"><img src="{img}" height={h} style="{style}">{extra}</div><span>{title}</span></div>'
donts = "".join([
    dont("Do not stretch or squash", "transform:scaleX(1.5)"), dont("Do not recolor the veins", "filter:hue-rotate(200deg)"),
    dont("Do not add shadows or glows", "filter:drop-shadow(0 0 14px #FF5A14)"), dont("Do not rotate", "transform:rotate(28deg)"),
    dont("Do not place it on a color that fights the ember", "", bg="#FF5A14"),
    dont("Do not use the full version small", "", h=20, extra=' <small style="font:12px Geist,monospace;color:#777">20 px: use the compact one</small>')])
files = "".join(f'<li><a href="../kit/{os.path.relpath(os.path.join(r, f), os.path.join(HERE, "kit"))}">{os.path.relpath(os.path.join(r, f), os.path.join(HERE, "kit"))}</a></li>'
                for r, _, fs in sorted(os.walk(os.path.join(HERE, "kit"))) for f in sorted(fs))

html = f"""<!doctype html><html lang=en><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><title>Brasa · brand guidelines</title>
<link rel=icon href="../kit/web/favicon.svg" type="image/svg+xml">
<style>
@font-face{{font-family:BG;src:url(../fonts/BricolageGrotesque-Bold.ttf);font-weight:700}}
@font-face{{font-family:BG;src:url(../fonts/BricolageGrotesque-Regular.ttf);font-weight:400}}
@font-face{{font-family:GM;src:url(../fonts/GeistMono-Regular.ttf)}}
:root{{--dark:{C['graphite']};--floor:#17171A;--paper:{C['paper']};--ember:{C['ember_dark']};--smoke:{C['smoke']};--line:#37373D}}
*{{box-sizing:border-box;margin:0}}body{{background:var(--floor);color:var(--paper);font:400 17px/1.6 BG,system-ui,sans-serif}}
.wrap{{max-width:1080px;margin:0 auto;padding:0 28px}}
section{{padding:64px 0;border-top:1px solid var(--line)}}
h1{{font:700 clamp(56px,10vw,120px)/.95 BG;letter-spacing:-.03em}}h2{{font:700 34px/1.1 BG;letter-spacing:-.02em;margin-bottom:8px}}
.k{{font:400 12px GM,monospace;letter-spacing:.14em;text-transform:uppercase;color:var(--ember);margin-bottom:14px}}
p{{color:#d9d9de;max-width:640px;margin-top:12px}}.mono{{font-family:GM,monospace}}small,.note{{font:400 12.5px GM,monospace;color:var(--smoke)}}
.hero{{display:grid;grid-template-columns:1.1fr .9fr;gap:40px;align-items:center;padding:72px 0 64px}}.plate{{background:{C['plate']};border-radius:36px;padding:34px;justify-self:center;width:min(100%,430px)}}.plate img{{width:100%;display:block}}
.sub{{font-size:22px;color:#d9d9de;margin-top:18px;max-width:460px}}
.grid{{display:grid;gap:18px;margin-top:26px}}.g2{{grid-template-columns:repeat(2,1fr)}}.g3{{grid-template-columns:repeat(3,1fr)}}.g4{{grid-template-columns:repeat(4,1fr)}}
.card{{background:var(--dark);border:1px solid var(--line);border-radius:18px;padding:26px}}.light{{background:var(--paper);color:#15110F;border-color:#d9cfc5}}
.light p,.light small{{color:#554a43}}.card h3{{font:700 20px BG;margin-bottom:4px}}
.row{{display:flex;align-items:flex-end;gap:22px;margin-top:20px;flex-wrap:wrap}}
.sw .chip{{height:84px;border-radius:12px;padding:10px;font:400 13px GM,monospace;display:flex;align-items:flex-end;border:1px solid #ffffff22}}.sw b{{display:block;margin-top:10px}}.sw span,.sw small{{display:block;color:#b6b6bd;font-size:13.5px}}.sw small{{font-size:11.5px;color:var(--smoke)}}
.st{{text-align:center;background:var(--dark);border:1px solid var(--line);border-radius:16px;padding:20px}}.st b{{display:block;margin-top:10px}}.st span{{font:400 12.5px GM,monospace;color:var(--smoke)}}
.dont .box{{height:170px;border-radius:14px;display:flex;align-items:center;justify-content:center;gap:10px;position:relative;overflow:hidden}}.dont .box:after{{content:"×";position:absolute;top:8px;right:12px;font:700 26px BG;color:#E5384B}}.dont span{{display:block;margin-top:8px;font-size:14px;color:#cfcfd5}}
.claim{{font:700 clamp(28px,4.4vw,44px)/1.15 BG;letter-spacing:-.02em;max-width:820px}}.claim em{{font-style:normal;color:var(--ember)}}
.specimen{{font-size:56px;line-height:1.05;font-weight:700;letter-spacing:-.02em}}
a{{color:var(--ember)}}ul.files{{list-style:none;padding:0;columns:2;gap:30px;font:400 13.5px/2 GM,monospace}}ul.files a{{text-decoration:none;color:#d9d9de}}ul.files a:hover{{color:var(--ember)}}
@media(max-width:820px){{.hero,.g2,.g3,.g4{{grid-template-columns:1fr}}ul.files{{columns:1}}}}
</style>
<div class=wrap>
<div class=hero><div><div class=k>Brand guidelines · v1</div><h1>Brasa</h1><p class=sub>A piece of coal that shows how hot your Mac is. The hotter it gets, the brighter it glows.</p></div>
<div class=plate><img src="../kit/animated/brasa-live.svg" alt="Brasa symbol, animated"></div></div>

<section><div class=k>01 · Concept</div><div class=claim>A piece of coal with heat <em>leaking</em> through it.</div>
<p>The app watches the chip, battery and SSD temperature and warns before the Mac suffers. The symbol shows that as a dark stone cut by veins of ember: calm outside, heat inside.</p>
<p>One mechanism: an irregular stone (no hexagon, no gem), a main fissure and thinner veins, all of variable thickness. The ember color is the information: orange day to day, the state color when the Mac heats up.</p></section>

<section><div class=k>02 · Symbol</div><h2>Two scales, the same stone</h2><p>Thin veins do not survive at small sizes, so there are two versions and one simple rule.</p>
<div class="grid g2"><div class="card light"><h3>Full</h3><small>48 px and up</small><div class=row><img src="../kit/symbol/symbol-color.svg" height=190><img src="../kit/symbol/symbol-color.svg" height=96><img src="../kit/symbol/symbol-color.svg" height=48></div></div>
<div class="card light"><h3>Compact</h3><small>16 to 47 px · main fissure only</small><div class=row><img src="../kit/symbol/symbol-compact-color.svg" height=96><img src="../kit/symbol/symbol-compact-color.svg" height=48><img src="../kit/symbol/symbol-compact-color.svg" height=32><img src="../kit/symbol/symbol-compact-color.svg" height=24><img src="../kit/symbol/symbol-compact-color.svg" height=16></div></div></div>
<div class="grid g4"><div class=card><small>color, dark background</small><div class=row><img src="../kit/symbol/symbol-color-dark.svg" height=90></div></div><div class="card light"><small>black (one ink)</small><div class=row><img src="../kit/symbol/symbol-black.svg" height=90></div></div><div class=card><small>white (one ink)</small><div class=row><img src="../kit/symbol/symbol-white.svg" height=90></div></div><div class="card light"><small>compact black</small><div class=row><img src="../kit/symbol/symbol-compact-black.svg" height=90></div></div></div></section>

<section><div class=k>03 · Logotype</div><h2>Symbol + word</h2><p>The word is Bricolage Grotesque Bold converted to outlines. The cap height is half the symbol height. Clear space around it: a quarter of the symbol height.</p>
<div class="grid g2"><div class="card light"><div class=row><img src="../kit/logotype/logotype-color.svg" height=96></div></div><div class=card><div class=row><img src="../kit/logotype/logotype-color-dark.svg" height=96></div></div><div class="card light"><div class=row><img src="../kit/logotype/logotype-black.svg" height=70></div></div><div class=card><div class=row><img src="../kit/logotype/logotype-white.svg" height=70></div></div></div></section>

<section><div class=k>04 · Colors</div><h2>Coal, ember and paper</h2><p>The ember orange lives in the veins and in accents. Body text is coal on paper or paper on graphite; orange on light only in large titles. Behind the symbol, only the near-black plate ({C['plate']}): the stone stands out by its veins. Never a mid gray, never brown.</p><div class="grid g4">{colors}</div></section>

<section><div class=k>05 · Typography</div><h2>Two families, both free (OFL)</h2>
<div class="grid g3"><div class=card><small>display · Bricolage Grotesque Bold</small><div class=specimen style="margin-top:14px">Aa Brasa</div></div><div class=card><small>text · Bricolage Grotesque Regular</small><p style="margin-top:14px">Chip at 87 °C. Avoid starting a render or export now.</p></div><div class=card><small>data · Geist Mono</small><div class=mono style="font-size:26px;margin-top:14px">42 °C · 5.1 GB</div></div></div></section>

<section><div class=k>06 · States</div><h2>The ember changes color with the Mac</h2><p>The stone stays the same; only the fissure changes color. Used for the menu bar icon and any indicator in the app.</p><div class="grid g4">{states}</div></section>

<section><div class=k>07 · App and web</div><h2>App icon and favicon</h2>
<div class="grid g2"><div class=card><small>macOS icon · 1024 px, with .icns</small><div class=row><img src="../kit/app/icon-1024.png" width=200><img src="../kit/app/icon-1024.png" width=96><img src="../kit/app/icon-1024.png" width=48><img src="../kit/app/icon-1024.png" width=32></div></div>
<div class=card><small>favicon · compact, switches color in dark mode</small><div class=row><img src="../kit/web/favicon.svg" width=64><img src="../kit/web/favicon-48.png"><img src="../kit/web/favicon-32.png"><img src="../kit/web/favicon-16.png"></div></div></div></section>

<section><div class=k>08 · Motion</div><h2>The veins light up and cool down</h2><p>Each vein heats and cools at its own pace, from dark orange to amber; the main fissure goes from orange to amber. Color only (never opacity), and it respects the system's reduced-motion setting. File: <span class=mono>kit/animated/brasa-live.svg</span> (pure CSS, no JavaScript).</p><div class="card" style="margin-top:22px;display:flex;justify-content:center"><img src="../kit/animated/brasa-live.svg" height=240></div></section>

<section><div class=k>09 · Misuse</div><h2>What not to do</h2><div class="grid g3">{donts}</div></section>

<section><div class=k>10 · Files</div><h2>Kit</h2><ul class=files>{files}</ul>
<p class=note style="margin-top:30px">Fonts in <span class=mono>fonts/</span> with their OFL licenses. To regenerate everything: <span class=mono>python3 generate_kit.py && python3 render_kit.py && python3 generate_brandbook.py</span>.</p></section>
</div></html>"""
os.makedirs(os.path.join(HERE, "brandbook"), exist_ok=True)
open(os.path.join(HERE, "brandbook", "index.html"), "w").write(html); print("brandbook ok")
