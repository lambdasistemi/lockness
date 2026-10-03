#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "${BASH_SOURCE[0]}")"
# Rehydrate exactly the committed Lake revisions; do not resolve moving branches.
export MATHLIB_NO_CACHE_ON_UPDATE=1
if [[ ! -f .lake/packages/mathlib/.lake/build/lib/lean/Mathlib/Data/Finset/Card.olean ]]; then
  lake exe cache get Mathlib.Data.Finset.Card
fi
