#!/bin/sh
# Copies the live Herdr files back here. Run after changing a mod, a key or the layout in place, then commit.
set -eu
DST="$(cd "$(dirname "$0")" && pwd)"
SRC="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
for m in "$DST"/mods/*/; do
  rsync -a --delete --exclude 'jsconfig.json' --exclude '*.d.ts' "$SRC/mods/$(basename "$m")/" "$m"
done
for l in "$DST"/layouts/*.json; do cp "$SRC/layouts/$(basename "$l")" "$l"; done
cp "$SRC/keys.json" "$SRC/settings.json" "$DST/"
cd "$DST" && git status --short -- . || true
