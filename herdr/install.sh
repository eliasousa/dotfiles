#!/bin/sh
# Puts this folder's Herdr files into ~/.config/herdr-app (the app reads them live).
# Run after cloning the dotfiles on a new Mac, or after `git pull`. Herdr must be installed.
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
DST="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
[ -d "$DST" ] || { echo "no $DST: open Herdr once first" >&2; exit 1; }
mkdir -p "$DST/mods" "$DST/layouts"
for m in "$SRC"/mods/*/; do
  rsync -a --delete --exclude 'jsconfig.json' --exclude '*.d.ts' "$m" "$DST/mods/$(basename "$m")/"
done
cp "$SRC"/layouts/*.json "$DST/layouts/"
cp "$SRC/keys.json" "$SRC/settings.json" "$DST/"
echo "herdr: installed into $DST. Quit and reopen Herdr to load mods; then: herdr-app do layout.switch '{\"name\":\"my-main\"}'"
