"""Renders the PNG, ICO and ICNS files of the kit from the SVGs (headless Chrome, transparent background). Run after generate_kit.py."""
import os, subprocess, tempfile
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); KIT = os.path.join(HERE, "kit")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
tmp = tempfile.mkdtemp()

def render(svg, w, h, out):
    html = os.path.join(tmp, "r.html")
    open(html, "w").write(f"<body style='margin:0;background:transparent'><img src='file://{os.path.join(KIT, svg)}' width={w} height={h} style='display:block'>")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--allow-file-access-from-files", "--hide-scrollbars", "--default-background-color=00000000",
                    f"--window-size={w},{h}", f"--screenshot={out}", html], capture_output=True)

render("app/icon.svg", 1024, 1024, os.path.join(KIT, "app/icon-1024.png"))
render("web/apple-touch-icon.svg", 180, 180, os.path.join(KIT, "web/apple-touch-icon.png"))
render("web/favicon.svg", 256, 256, os.path.join(tmp, "fav256.png"))
render("symbol/symbol-color.svg", 1024, 1024, os.path.join(KIT, "symbol/symbol-color-1024.png"))

fav = Image.open(os.path.join(tmp, "fav256.png")).convert("RGBA")
for n in (16, 32, 48): fav.resize((n, n), Image.LANCZOS).save(os.path.join(KIT, f"web/favicon-{n}.png"))
fav.resize((48, 48), Image.LANCZOS).save(os.path.join(KIT, "web/favicon.ico"), sizes=[(16, 16), (32, 32), (48, 48)])

icon = Image.open(os.path.join(KIT, "app/icon-1024.png")); iconset = os.path.join(tmp, "AppIcon.iconset"); os.makedirs(iconset)
for base in (16, 32, 128, 256, 512):
    for k in (1, 2): icon.resize((base * k, base * k), Image.LANCZOS).save(os.path.join(iconset, f"icon_{base}x{base}{'@2x' if k == 2 else ''}.png"))
subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(KIT, "app/AppIcon.icns")], check=True)
print("kit raster ok")
