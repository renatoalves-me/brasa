# Brasa brand

A black piece of coal with veins of ember of varying thickness. The ember color is the information: orange day to day,
the state color (green, amber, orange, red) when the Mac heats up.

- **Symbol:** irregular coal silhouette, one main fissure (width 10 to 24) and seven veins (width 1 to 8, ending in a point).
  Two scales: **full** (48 px and up) and **compact** (16 to 47 px, main fissure only).
- **Colors:** coal `#0E0D0D`, ember `#FF5A14` (`#FF6A1A` on dark), hot ember `#FFB020`, paper `#F3ECE4`,
  plate `#121216` (the only background allowed behind the symbol: app icon, README, social), graphite `#2A2A2E` (interface), smoke `#9C9CA3`.
- **States** (ember color in the menu bar icon): ok `#33CC80` · warn `#FFB533` · pause `#FF7A29` · critical `#FF4052`.
- **Rules:** never a mid gray or a brown tone behind the symbol (only the near-black plate); animation changes the vein color only, never opacity.
- **Fonts (OFL):** Bricolage Grotesque Bold/Regular, Geist Mono, in `fonts/`.

## Files

- `kit/`: SVG (symbol, logotype, states, animated), PNG, `.icns`, `.ico` and `brand.json` (tokens).
- `brandbook/index.html`: the guidelines page (open it locally).
- `coal.py` (silhouette), `veins.py` (fissure and veins), `generate_kit.py`, `render_kit.py`, `generate_brandbook.py`,
  `generate_stone_swift.py` (the compact geometry used by the menu bar icon in `Brasa.swift`).

## Regenerate

```bash
python3 generate_kit.py && python3 render_kit.py && python3 generate_brandbook.py
```

Needs `shapely`, `fonttools`, `pillow` and Google Chrome (for the raster files).
