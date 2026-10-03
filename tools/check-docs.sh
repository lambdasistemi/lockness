#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec nix develop --impure --expr 'import ./nix/docs-shell.nix' --quiet -c bash -euo pipefail -c '
  python3 tools/render_diagrams.py docs/diagrams/manifest.json
  python3 tools/check_presentation.py --front README.md README.md docs
  mkdocs build --strict --site-dir site
'
