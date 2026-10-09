"""The approved Brasa mark: the coal silhouette cut by a main fissure and seven veins of ember, all of variable thickness.
Two scales: FULL (48 px and up) and COMPACT (16 to 47 px, main fissure only). Run: python3 veins.py (writes a test sheet)."""
import os, sys
from shapely.geometry import LineString, Point
from shapely.ops import unary_union
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from coal import SILHOUETTE, svg

def _smooth(a, b, u): u = u * u * (3 - 2 * u); return a + (b - a) * u

def stroke(pts, profile, step=1.5):
    """variable-width stroke: profile = [(t, width)] with t from 0 to 1 along the path, smoothly interpolated"""
    line = LineString(pts); n = max(int(line.length / step), 8)
    def width(t):
        for (t0, w0), (t1, w1) in zip(profile, profile[1:]):
            if t0 <= t <= t1: return _smooth(w0, w1, (t - t0) / (t1 - t0) if t1 > t0 else 0)
        return profile[-1][1]
    ps = [(line.interpolate(i / n, normalized=True), width(i / n)) for i in range(n + 1)]
    caps = [unary_union([Point(a.x, a.y).buffer(wa / 2, resolution=8), Point(b.x, b.y).buffer(wb / 2, resolution=8)]).convex_hull
            for (a, wa), (b, wb) in zip(ps, ps[1:])]
    return unary_union(caps)

# main fissure: never thinner than 10, so the compact version survives at 16 px
FISSURE = stroke([(30, 130), (52, 128), (122, 104), (150, 150), (190, 176), (202, 183)],
                 [(0, 15), (.10, 21), (.28, 10), (.46, 22), (.60, 12), (.72, 24), (.86, 11), (1, 17)])
# veins: born thick at the fissure, thin out, swell again and end in a point
VEINS = [
    stroke([(122, 104), (146, 84), (158, 54)], [(0, 7), (.35, 3), (.62, 6.5), (1, 1.6)]),
    stroke([(146, 84), (182, 92), (214, 88)], [(0, 5), (.45, 2), (.78, 5), (1, 1.5)]),
    stroke([(122, 104), (98, 86), (86, 56)], [(0, 7), (.32, 2.5), (.7, 6), (1, 1.4)]),
    stroke([(150, 150), (180, 138), (214, 122)], [(0, 8), (.4, 3), (.76, 7), (1, 1.5)]),
    stroke([(150, 150), (134, 182), (122, 212)], [(0, 8), (.48, 3.5), (.8, 7), (1, 2)]),
    stroke([(86, 117), (82, 152), (66, 196)], [(0, 6), (.3, 2), (.62, 6.5), (1, 1.8)]),
    stroke([(134, 176), (104, 170), (84, 176)], [(0, 5), (.5, 2.2), (.85, 4), (1, 1.2)]),
]

def build(with_veins):
    ember = (unary_union([FISSURE, *VEINS]) if with_veins else FISSURE).intersection(SILHOUETTE)
    return [(SILHOUETTE.difference(ember), "base"), (ember, "ember")]
FULL, COMPACT = build(True), build(False)

if __name__ == "__main__":
    css = ("body{margin:0;padding:24px;display:flex;gap:24px;flex-wrap:wrap}.c{padding:22px;border-radius:16px;display:flex;gap:18px;align-items:flex-end}"
           ".l{background:#F3ECE4}.l .base{fill:#0E0D0D}.l .ember{fill:#FF5A14}.d{background:#232326}.d .base{fill:#0E0D0D}.d .ember{fill:#FF6A1A}"
           "svg.a{width:300px;height:300px}svg.b{width:96px;height:96px}svg.c1{width:48px;height:48px}svg.s{width:32px;height:32px}svg.t{width:24px;height:24px}svg.u{width:16px;height:16px}")
    h = f"<!doctype html><meta charset=utf-8><style>{css}</style>"
    for bg in ("l", "d"):
        sa, sb = svg(FULL), svg(COMPACT); v = lambda s, c: s.replace("<svg ", f'<svg class="{c}" ')
        h += f'<div class="c {bg}">{v(sa,"a")}{v(sa,"b")}{v(sa,"c1")}{v(sb,"s")}{v(sb,"t")}{v(sb,"u")}</div>'
    open(os.path.join(HERE, "test-sheet.html"), "w").write(h); print("test-sheet.html")
