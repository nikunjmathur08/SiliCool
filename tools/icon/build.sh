#!/bin/bash
# Regenerates the app icon from the source artwork into the asset catalog, and
# the copies the website and README use. Source artwork: icon.png at the repo
# root — replace that file and re-run this script to rebrand.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SET="$ROOT/SiliCool/Assets.xcassets/AppIcon.appiconset"
SOURCE="$ROOT/icon.png"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

[ -f "$SOURCE" ] || { echo "error: missing $SOURCE (the app icon source artwork)"; exit 1; }

echo "==> Rendering"
swiftc -O -o "$TEMP/render" "$ROOT/tools/icon/main.swift"
"$TEMP/render" "$SET" "$SOURCE"

echo "==> Writing Contents.json"
python3 - "$SET" <<'PYEOF'
import json, sys, pathlib
entries = [("16x16","1x"),("16x16","2x"),("32x32","1x"),("32x32","2x"),
           ("128x128","1x"),("128x128","2x"),("256x256","1x"),("256x256","2x"),
           ("512x512","1x"),("512x512","2x")]
images = [{"filename": f"icon_{size}{'@2x' if scale == '2x' else ''}.png",
           "idiom": "mac", "scale": scale, "size": size} for size, scale in entries]
path = pathlib.Path(sys.argv[1]) / "Contents.json"
path.write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
PYEOF

# The website and README use the large one.
cp "$SET/icon_512x512.png" "$ROOT/docs/icon.png"
sips -Z 400 -s format png "$SET/icon_512x512.png" --out "$ROOT/site/assets/icon.png" >/dev/null

echo "==> Icon updated — rebuild the app to see it"
