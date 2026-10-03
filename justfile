default:
    @just --list

ci:
    ./tools/check-model.sh
    ./tools/check-docs.sh

docs:
    ./tools/check-docs.sh

serve:
    nix develop 'github:paolino/dev-assets/a9d7371c1118de4026ba6ee3a9c3b54614924b82?dir=mkdocs' --quiet -c mkdocs serve
