#!/bin/bash
# Regenerates packaging/dmg-background.tiff from main.swift.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

echo "==> Rendering"
swiftc -O -o "$TEMP/render" "$ROOT/tools/dmg-background/main.swift"
"$TEMP/render" "$TEMP"

# Finder picks the @2x layer on Retina only if both live in one TIFF.
echo "==> Combining into a Retina TIFF"
tiffutil -cathidpicheck "$TEMP/dmg-bg.png" "$TEMP/dmg-bg@2x.png" \
    -out "$ROOT/packaging/dmg-background.tiff"

echo "==> packaging/dmg-background.tiff updated — rebuild the DMG to see it"
