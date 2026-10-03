#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec nix develop 'github:paolino/dev-assets/0328b73b71788bb83848fe407dd04136a52c3697?dir=mkdocs' --quiet -c bash -euo pipefail -c '
  python3 tools/check_presentation.py --front README.md README.md docs
  mkdocs build --strict --site-dir site
'
