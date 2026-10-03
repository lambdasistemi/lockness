#!/usr/bin/env bash
set -euo pipefail
cd "${BASH_SOURCE[0]%/*}/.."
exec ./lean/env bash -euo pipefail -c '
  [[ -L ../docs/model.speech.json ]] || { echo "missing model speech delivery alias" >&2; exit 1; }
  [[ $(readlink ../docs/model.speech.json) = model/index.speech.json ]] || { echo "wrong model speech alias target" >&2; exit 1; }
  cmp ../docs/model.speech.json ../docs/model/index.speech.json
  exec bash checks/model.sh
'
