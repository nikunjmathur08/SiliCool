#!/bin/bash
#
# Publishes a built disk image to the website: copies it in, and stamps the
# real size and version into the download line so the page can never advertise
# a figure that stopped being true three releases ago.
#
#   ./scripts/stage-release.sh [path/to/SiliCool.dmg]
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG="${1:-$ROOT/build/SiliCool.dmg}"
APP="$ROOT/build/Release/SiliCool.app"
PAGE="$ROOT/site/index.html"

[ -f "$DMG" ] || { echo "error: no disk image at $DMG — run ./scripts/release.sh first"; exit 1; }

mkdir -p "$ROOT/site/downloads"
cp "$DMG" "$ROOT/site/downloads/SiliCool.dmg"

SIZE=$(du -h "$DMG" | cut -f1 | tr -d ' ' | sed 's/M/ MB/; s/K/ KB/')
VERSION="unknown"
[ -d "$APP" ] && VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)

python3 - "$PAGE" "$SIZE" "$VERSION" <<'PYEOF'
import pathlib, re, sys
page, size, version = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
html = page.read_text()
line = (f'<b>{size}</b> · version {version} · macOS 14 or later · '
        f'Apple silicon · free and MIT licensed')
updated, count = re.subn(r'(<p class="req" id="download-meta">).*?(</p>)',
                         lambda m: m.group(1) + line + m.group(2), html, flags=re.S)
if count == 0:
    print('  ! could not find <p class="req" id="download-meta"> — stamp it by hand')
else:
    page.write_text(updated)
    print(f'  stamped: {line}')
PYEOF

echo "==> Staged site/downloads/SiliCool.dmg ($SIZE, version $VERSION)"
echo "    Next: ./scripts/build-site.sh to refresh the standalone preview,"
echo "          then commit and push — Vercel deploys on push."
