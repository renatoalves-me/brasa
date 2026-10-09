"""Silhouette of the Brasa coal and the shared SVG helpers.
Canvas 256, footprint 160 (48..208). Everything is solid fill: no strokes, filters or text."""
from shapely.geometry import Polygon
from shapely.ops import unary_union

# irregular 7-point silhouette, split into triangles around two inner points
P = [(100, 50), (170, 56), (208, 112), (190, 176), (140, 208), (78, 194), (52, 128)]
Ia, Ib = (122, 104), (150, 150)
poly = lambda *pts: Polygon(pts)
T = {
  1: poly(P[0], P[1], Ia), 2: poly(P[1], P[2], Ib, Ia), 3: poly(P[2], P[3], Ib), 4: poly(P[3], P[4], Ib),
  5: poly(P[4], P[5], Ia, Ib), 6: poly(P[5], P[6], Ia), 7: poly(P[6], P[0], Ia),
}

def soften(g, r=7):
    """round the convex corners only"""
    return g.buffer(-r, join_style=1, resolution=32).buffer(r, join_style=1, resolution=32)

SILHOUETTE = soften(unary_union(list(T.values())))

def path(g):
    """SVG path data for a (multi)polygon, even-odd"""
    geoms = list(g.geoms) if hasattr(g, "geoms") else [g]
    d = []
    for p in geoms:
        if p.is_empty or p.geom_type != "Polygon": continue
        for ring in [p.exterior, *p.interiors]:
            pts = list(ring.coords)[:-1]
            d.append("M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + "Z")
    return " ".join(d)

def svg(parts):
    """parts: list of (geometry, css class)"""
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">'
            + "".join(f'<path class="{r}" fill-rule="evenodd" d="{path(g)}"/>' for g, r in parts if not g.is_empty) + "</svg>")
