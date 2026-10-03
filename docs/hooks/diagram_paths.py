"""Resolve diagram links and generate full-size viewers using the site palette.

Sources keep repository-relative PNG links so GitHub can render them too.
"""
import hashlib
import html as html_lib
import json
from pathlib import Path
import posixpath
import re
from urllib.parse import urlsplit

BLOCK = re.compile(r'<(div|p) class="(?:diagram|diagram-links)">.*?</\1>', re.S)
URL = re.compile(r'(href|src)="([^"]+)"')


def on_page_content(html, page, **kwargs):
    def block(match):
        def url(attribute):
            value = attribute[2]
            if value.startswith(('/', '#')) or '://' in value:
                return attribute[0]
            asset = posixpath.normpath(posixpath.join(posixpath.dirname(page.file.src_uri), value))
            if attribute[1] == 'href' and urlsplit(asset).path.endswith('.png'):
                asset = asset.replace('.png', '.html', 1)
            relative = posixpath.relpath(asset, posixpath.dirname(page.url))
            return f'{attribute[1]}="{relative}"'
        return URL.sub(url, match[0])
    return BLOCK.sub(block, html)


def on_post_build(config, **kwargs):
    """One static viewer per manifest image; no query-driven image loading."""
    site = Path(config['site_dir'])
    docs = Path(config['docs_dir'])
    manifest = json.loads((docs / 'diagrams/manifest.json').read_text())

    def version(path):
        return hashlib.sha256((docs / path).read_bytes()).hexdigest()[:16]

    css = version('stylesheets/diagrams.css')
    script = version('javascripts/palette.js')
    for diagram in manifest['diagrams']:
        image = diagram['image']
        image_hash = version('diagrams/' + image)
        title = html_lib.escape(diagram['name'].replace('-', ' ').capitalize())
        alt = html_lib.escape(diagram['alt'], quote=True)
        viewer = site / 'diagrams' / Path(image).with_suffix('.html')
        viewer.write_text(f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — Lockness diagram</title>
<link rel="stylesheet" href="../css/terminal.css">
<link rel="stylesheet" href="../stylesheets/diagrams.css?v={css}">
<link id="lockness-dark-palette" rel="stylesheet" href="../css/palettes/dark.css" media="(prefers-color-scheme: dark)">
<script src="../javascripts/palette.js?v={script}"></script>
<style>
body {{ padding: 1rem; }}
header {{ display: flex; align-items: center; justify-content: space-between; gap: 1rem; }}
button {{ color: var(--font-color); background: var(--background-color); padding: .5rem; cursor: pointer; }}
</style>
</head>
<body class="terminal">
<header><a href="../">Lockness</a><button id="lockness-palette-toggle" type="button" hidden>Dark mode</button></header>
<main>
<h1>{title}</h1>
<p>Full resolution. Scroll to explore the diagram.</p>
<div class="diagram" tabindex="0" role="region" aria-label="Full-size diagram">
<img src="{image}?v={image_hash}" alt="{alt}">
</div>
</main>
</body>
</html>
''')
