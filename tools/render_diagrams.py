#!/usr/bin/env python3
"""Render/check manifest-bound PNG diagrams and their Markdown embeds.

Usage: render_diagrams.py [--render] path/to/manifest.json
Manifest: renderer (command array, scale), diagrams (name, source, image, alt),
pages (paths relative to the manifest). Each page uses <!-- diagram: NAME -->.
Generated embeds and source/renderer/image hashes are checked without rendering.
"""
import argparse
import hashlib
import html
import json
import os
from pathlib import Path
import re
import struct
import subprocess


def digest(data):
    return hashlib.sha256(data).hexdigest()


def dimensions(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError(f'Not a PNG: {path}')
    return struct.unpack('>II', data[16:24])


def embed(page, base, diagram, width):
    image = os.path.relpath(base / diagram['image'], page.parent)
    source = os.path.relpath(base / diagram['source'], page.parent)
    image += '?v=' + digest((base / diagram['image']).read_bytes())[:16]
    source += '?v=' + digest((base / diagram['source']).read_bytes())[:16]
    image, source, alt = map(lambda s: html.escape(s, quote=True), (image, source, diagram['alt']))
    return (f'<div class="diagram"><a href="{image}"><img src="{image}" alt="{alt}" width="{width}" loading="lazy"></a></div>\n'
            f'<p class="diagram-links"><a href="{image}">Open full size</a> · <a href="{source}">Mermaid source</a></p>')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    parser.add_argument('manifest', type=Path)
    args = parser.parse_args()
    base = args.manifest.resolve().parent
    manifest = json.loads(args.manifest.read_text())
    renderer = manifest['renderer']
    scale = renderer['scale']
    if not isinstance(scale, int) or scale < 1:
        raise ValueError('renderer.scale must be a positive integer')
    receipt_path = args.manifest.with_suffix('.rendered.json')
    previous = json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
    records, errors, embeds = {}, [], {}
    for diagram in manifest['diagrams']:
        name = diagram['name']
        if name in records:
            raise ValueError(f'Duplicate diagram {name}')
        source, image = base / diagram['source'], base / diagram['image']
        inputs = digest(source.read_bytes() + json.dumps(renderer, sort_keys=True).encode())
        if args.render:
            subprocess.run(renderer['command'] + ['-i', str(source), '-o', str(image), '-s', str(scale), '-b', 'white'], check=True)
        if not image.exists():
            errors.append(f'{name}: missing rendered image')
            continue
        width, height = dimensions(image)
        record = {'inputs': inputs, 'image': digest(image.read_bytes()), 'width': width, 'height': height}
        records[name] = record
        if not args.render and previous.get(name) != record:
            errors.append(f'{name}: stale source, renderer settings or image')
        embeds[name] = (diagram, max(1, round(width / scale)))
    references = set()
    for relative in manifest['pages']:
        page = (base / relative).resolve()
        content = page.read_text()
        for match in list(re.finditer(r'^<!-- diagram: ([\w-]+) -->$', content, re.M)):
            name = match[1]
            references.add(name)
            if name not in embeds:
                errors.append(f'{page}: unknown or missing diagram {name}')
                continue
            diagram, width = embeds[name]
            expected = match[0] + '\n' + embed(page, base, diagram, width)
            pattern = re.escape(match[0]) + r'(?:\n<div class="diagram">[^\n]*</div>\n<p class="diagram-links">[^\n]*</p>)?'
            if args.render:
                content = re.sub(pattern, lambda _: expected, content, count=1)
            elif expected not in content:
                errors.append(f'{page}: stale or missing embed for {name}')
        if args.render:
            page.write_text(content)
    for name in records.keys() - references:
        errors.append(f'{name}: unreferenced diagram')
    if errors:
        raise ValueError('\n'.join(errors))
    if args.render:
        receipt_path.write_text(json.dumps(records, indent=2) + '\n')
    print(f'{len(records)} diagrams: sources, renderer, images and embeds verified')


if __name__ == '__main__':
    main()
