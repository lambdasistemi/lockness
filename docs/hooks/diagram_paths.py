"""Resolve raw diagram HTML links for MkDocs directory URLs.

Sources keep repository-relative links so GitHub can render them too.
"""
import posixpath
import re

BLOCK = re.compile(r'<(div|p) class="(?:diagram|diagram-links)">.*?</\1>', re.S)
URL = re.compile(r'(href|src)="([^"]+)"')


def on_page_content(html, page, **kwargs):
    def block(match):
        def url(attribute):
            value = attribute[2]
            if value.startswith(('/', '#')) or '://' in value:
                return attribute[0]
            asset = posixpath.normpath(posixpath.join(posixpath.dirname(page.file.src_uri), value))
            relative = posixpath.relpath(asset, posixpath.dirname(page.url))
            return f'{attribute[1]}="{relative}"'
        return URL.sub(url, match[0])
    return BLOCK.sub(block, html)
