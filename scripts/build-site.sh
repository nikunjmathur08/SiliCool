#!/bin/bash
#
# Produces a single self-contained HTML file with every asset inlined as a
# data URI — for previewing or sharing the page without hosting.
#
# The real site is site/index.html plus site/assets/, deployed as static files.
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT/build/site-standalone.html}"
mkdir -p "$(dirname "$OUTPUT")"

python3 - "$ROOT/site/index.html" "$OUTPUT" <<'PYEOF'
import base64, pathlib, re, sys

source, output = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
root = source.parent
html = source.read_text()

TYPES = {".mp4": "video/mp4", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
         ".png": "image/png", ".svg": "image/svg+xml"}

def inline(match):
    attr, path = match.group(1), match.group(2)
    if path.startswith(("http", "data:", "#")):
        return match.group(0)
    asset = root / path
    if not asset.exists():
        print(f"  ! missing {path}", file=sys.stderr)
        return match.group(0)
    mime = TYPES.get(asset.suffix.lower(), "application/octet-stream")
    encoded = base64.b64encode(asset.read_bytes()).decode()
    print(f"  inlined {path} ({asset.stat().st_size / 1024:.0f} KB)")
    return f'{attr}="data:{mime};base64,{encoded}"'

html = re.sub(r'\b(src|poster)="([^"]+)"', inline, html)
output.write_text(html)
print(f"\nwrote {output} ({output.stat().st_size / 1048576:.1f} MB)")
PYEOF
