#!/usr/bin/env python3
"""Builds the static Brasa site into site/dist (standard library only), on top of the Vértice design system.
Usage:  python3 site/build.py https://YOUR-URL      (used in canonical, hreflang, og:url and the sitemap)
Pages: / (English), /pt/ (Brazilian Portuguese) and /es/ (Spanish). Copy lives in copy.py. Donations: DONATIONS below (empty = section hidden)."""
import os, re, sys, json, shutil, datetime
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from copy import T, X
SITE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080").rstrip("/")
REPO = "https://github.com/renatoalves-me/brasa"
TODAY = datetime.date.today().isoformat()
DONATIONS = {"github_sponsors": "", "kofi": "https://ko-fi.com/H1T528G4KQ"}

# compact one-ink symbol (same as the brand kit) for the header and the kicker
_svg = open(os.path.join(HERE, "..", "brand", "kit", "symbol", "symbol-compact-black.svg")).read()
SYMBOL = re.search(r'viewBox="([^"]+)"', _svg).group(1), re.search(r' d="([^"]+)"', _svg).group(1)
def symbol(cls=""): return f'<svg viewBox="{SYMBOL[0]}" fill="currentColor" aria-hidden="true" {cls}><path fill-rule="evenodd" d="{SYMBOL[1]}"/></svg>'

ICONS = [  # one icon per feature (simple stroke, 24 px)
 '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3"/>',
 '<path d="M12 3 3 8l9 5 9-5-9-5Z"/><path d="m3 13 9 5 9-5"/>',
 '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
 '<path d="M4 18a8 8 0 1 1 16 0"/><path d="m12 18 4-6"/>',
 '<path d="M6 16V11a6 6 0 1 1 12 0v5l2 2H4l2-2Z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
 '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>']
LEVEL_CLASS = ["ok", "warn", "hot", "err"]

def support(t, x):
    d = DONATIONS; b = []
    if d["kofi"]: b.append(f'<a class="btn btn-primary btn-brilho" href="{d["kofi"]}" rel="noopener">{x["kofi"]}</a>')
    if d["github_sponsors"]: b.append(f'<a class="btn btn-secondary" href="{d["github_sponsors"]}" rel="noopener">GitHub Sponsors</a>')
    if not b: return ""
    return (f'<section class="ds-sec" id="apoie"><div class="ds-label"><b>05</b><i></i>{x["s5"]}</div><h2 class="ds-title">{x["t5"]}</h2>'
            f'<p class="ds-desc">{t["sup_p"]}</p><div class="card card-accent apoio" data-reveal><p>{x["fine"]}</p><div class="btn-row">{"".join(b)}</div></div></section>')

def page(key):
    t, x = T[key], X[key]; url = SITE + t["path"]
    ld = [{"@context": "https://schema.org", "@type": "SoftwareApplication", "name": "Brasa", "applicationCategory": "UtilitiesApplication",
           "operatingSystem": "macOS 14 or later (Apple Silicon)", "description": t["desc"], "url": url, "inLanguage": t["lang"], "image": SITE + "/assets/og.png",
           "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"}, "license": "https://opensource.org/license/mit", "codeRepository": REPO,
           "author": {"@type": "Person", "name": "Renato Alves", "url": "https://github.com/renatoalves-me"}},
          {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in t["faq"]]}]
    hreflangs = "".join(f'<link rel="alternate" hreflang="{v["lang"]}" href="{SITE}{v["path"]}">' for v in T.values())
    languages = "".join(f'<a href="{v["path"]}" hreflang="{v["lang"]}" lang="{v["lang"]}"' + (' aria-current="page"' if v is t else "") + f' title="{v["nome"]}">{v["lang"][:2].upper()}</a>' for v in T.values())
    menu = "".join(f'<a class="ds-app" href="#{i}">{n}</a>' for i, n in zip(["recursos", "como", "limites", "perguntas"], x["nav"][:4]))
    theme = "".join(f'<button type="button" data-set="{v}">{n}</button>' for v, n in zip(["", "dark", "light"], x["theme"]))
    stats = "".join(f'<div class="ds-stat"><b data-count="{n}" data-pre="{pre}" data-suf="{suf}">{pre}{n}{suf}</b><span>{lbl}</span></div>' for n, pre, suf, lbl in x["stats"])
    cards = "".join(f'<article class="card card-lift" data-reveal><div class="ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{ic}</svg></div><h4>{a}</h4><p>{b}</p></article>'
                    for (a, b), ic in zip(t["feats"], ICONS))
    levels = "".join(f'<div class="nivel" data-reveal><span class="badge {c}">{n}</span><p>{d}</p></div>' for (n, _, d), c in zip(t["levels"], LEVEL_CLASS))
    limits = "".join(f'<div class="metric" data-reveal><b>{v}<small>{u}</small></b><span>{l}</span></div>' for v, u, l in x["lim"])
    faq = "".join(f"<details><summary>{q}</summary><p>{a}</p></details>" for q, a in t["faq"])
    return f"""<!doctype html>
<html lang="{t['html']}" data-app="brasa"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>{t['title']}</title><meta name="description" content="{t['desc']}"><meta name="keywords" content="{t['kw']}">
<link rel="canonical" href="{url}">{hreflangs}<link rel="alternate" hreflang="x-default" href="{SITE}/">
<meta name="color-scheme" content="dark light"><meta name="theme-color" content="#0B0C0F" media="(prefers-color-scheme: dark)"><meta name="theme-color" content="#F9FAFE" media="(prefers-color-scheme: light)">
<meta name="robots" content="index,follow,max-image-preview:large">
<link rel="icon" href="/assets/favicon.svg" type="image/svg+xml"><link rel="icon" href="/assets/favicon.ico" sizes="48x48"><link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
<meta property="og:type" content="website"><meta property="og:site_name" content="Brasa"><meta property="og:title" content="{t['title']}"><meta property="og:description" content="{t['desc']}"><meta property="og:url" content="{url}">
<meta property="og:image" content="{SITE}/assets/og.png"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta property="og:locale" content="{t['lang'].replace('-', '_')}">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="{t['title']}"><meta name="twitter:description" content="{t['desc']}"><meta name="twitter:image" content="{SITE}/assets/og.png">
<link rel="preload" href="/assets/vertice/fonts/geist.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/assets/vertice/vertice.css"><link rel="stylesheet" href="/assets/vertice/vertice-ds.css"><link rel="stylesheet" href="/assets/brasa.css">
<noscript><style>[data-reveal]{{opacity:1;transform:none;filter:none}}</style></noscript>
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
<script src="/assets/vertice/vertice-ds.js" defer></script></head><body>
<header class="ds-nav"><div class="ds-nav-in"><a class="ds-brand" href="{t['path']}" aria-label="Brasa">{symbol()}<span>brasa</span></a>
<nav class="ds-apps" aria-label="Menu">{menu}</nav>
<div class="ds-theme" role="group" aria-label="Tema">{theme}</div><div class="langs" role="group" aria-label="{x['alt_lang']}">{languages}</div></div></header>
<main>
<section class="ds-hero"><div class="ds-hero-grid"></div><div class="ds-hero-glow"></div><div class="ds-hero-in">
<div><p class="ds-kicker">{symbol()}Brasa · {x['kicker']}</p><h1>Brasa<span>{x['tagline']}</span></h1>
<p class="ds-hero-sub">{t['lead']}</p>
<div class="btn-row"><a class="btn btn-primary btn-brilho" href="{REPO}" rel="noopener">{t['cta1']}</a><a class="btn btn-secondary" href="#como">{t['cta2']}</a></div>
<p class="note">{t['soon']}</p><div class="ds-stats">{stats}</div></div>
<div class="ds-hero-orb" role="img" aria-label="{x['alt_mark']}"><div class="coal"><img src="/assets/brasa-live.svg" alt="" width="420" height="420"></div></div></div></section>
<div class="ds-divider"><div></div></div>
<section class="ds-sec" id="recursos"><div class="ds-label"><b>01</b><i></i>{x['s1']}</div><h2 class="ds-title">{x['t1']}</h2><p class="ds-desc">{x['d1']}</p><div class="cards" data-reveal-group>{cards}</div></section>
<section class="ds-sec" id="como"><div class="ds-label"><b>02</b><i></i>{x['s2']}</div><h2 class="ds-title">{x['t2']}</h2><p class="ds-desc">{x['d2']}</p>
<div class="como"><div data-reveal-group>{levels}</div><div class="shot" data-reveal><img src="/assets/panel.webp" alt="{t['shot_alt']}" width="330" height="578" loading="lazy"></div></div></section>
<section class="ds-sec" id="limites"><div class="ds-label"><b>03</b><i></i>{x['s3']}</div><h2 class="ds-title">{x['t3']}</h2><p class="ds-desc">{x['d3']}</p><div class="metrics" data-reveal-group>{limits}</div></section>
<section class="ds-sec" id="perguntas"><div class="ds-label"><b>04</b><i></i>{x['s4']}</div><h2 class="ds-title">{x['t4']}</h2><div class="faq" data-reveal>{faq}</div></section>
{support(t, x)}
</main>
<footer class="foot"><span>{t['foot']} {x['badge_open']}</span><span><a href="{REPO}" rel="noopener">{t['gh']}</a></span></footer>
</body></html>"""

def main():
    dist = os.path.join(HERE, "dist")
    if os.path.isdir(dist): shutil.rmtree(dist)
    shutil.copytree(os.path.join(HERE, "assets"), os.path.join(dist, "assets"))
    for key, v in T.items():
        folder = os.path.join(dist, v["path"].strip("/")); os.makedirs(folder, exist_ok=True)
        open(os.path.join(folder, "index.html"), "w").write(page(key))
    open(os.path.join(dist, "robots.txt"), "w").write(f"User-agent: *\nAllow: /\n\nSitemap: {SITE}/sitemap.xml\n")
    alts = "".join(f'<xhtml:link rel="alternate" hreflang="{v["lang"]}" href="{SITE}{v["path"]}"/>' for v in T.values())
    open(os.path.join(dist, "sitemap.xml"), "w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        + "".join(f'<url><loc>{SITE}{v["path"]}</loc><lastmod>{TODAY}</lastmod>{alts}</url>\n' for v in T.values()) + "</urlset>\n")
    open(os.path.join(dist, "_headers"), "w").write("/assets/*\n  Cache-Control: public, max-age=31536000, immutable\n/*\n  X-Content-Type-Options: nosniff\n  Referrer-Policy: strict-origin-when-cross-origin\n")
    print("site ok:", dist, "for", SITE)
main()
