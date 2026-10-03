default:
    @just --list

ci:
    ./tools/check-docs.sh

docs: ci

serve:
    nix develop 'github:paolino/dev-assets/0328b73b71788bb83848fe407dd04136a52c3697?dir=mkdocs' --quiet -c mkdocs serve
