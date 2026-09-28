#!/usr/bin/env bash

set -o pipefail

BREW=/usr/local/bin/brew
[[ -x "$BREW" ]] || exit 69

"$BREW" update && "$BREW" upgrade
