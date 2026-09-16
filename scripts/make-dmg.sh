#!/bin/bash
#
# Builds the SiliCool disk image: a window with a background, the app on the
# left and an Applications shortcut on the right.
#
#   ./scripts/make-dmg.sh path/to/SiliCool.app [output.dmg]
#
# No third-party tooling — hdiutil and AppleScript ship with macOS, and a
# release pipeline is not the place for a dependency that can go unmaintained.

set -euo pipefail

APP_PATH="${1:?usage: make-dmg.sh <path to SiliCool.app> [output.dmg]}"
OUTPUT="${2:-build/SiliCool.dmg}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKGROUND="$ROOT/packaging/dmg-background.tiff"
VOLUME_NAME="SiliCool"
STAGING="$(mktemp -d)"
TEMP_DMG="$(mktemp -u).dmg"

cleanup() { rm -rf "$STAGING" "$TEMP_DMG"; }
trap cleanup EXIT

[ -d "$APP_PATH" ] || { echo "error: $APP_PATH is not an app bundle"; exit 1; }
[ -f "$BACKGROUND" ] || { echo "error: missing $BACKGROUND"; exit 1; }

echo "==> Staging"
mkdir -p "$STAGING/.background"
cp -R "$APP_PATH" "$STAGING/SiliCool.app"
cp "$BACKGROUND" "$STAGING/.background/background.tiff"
ln -s /Applications "$STAGING/Applications"

# A read-write image first, so the Finder view settings can be written into it.
# hdiutil intermittently reports "Resource busy" on attach and detach. A
# release should not fail because Spotlight happened to be looking.
retry() {
    local attempt=0
    until "$@"; do
        attempt=$((attempt + 1))
        [ $attempt -ge 5 ] && { echo "error: '$1' failed after 5 attempts"; return 1; }
        sleep $((2 ** attempt))
    done
}

echo "==> Creating writable image"
hdiutil create -srcfolder "$STAGING" -volname "$VOLUME_NAME" \
    -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW \
    -size 200m "$TEMP_DMG" >/dev/null

echo "==> Applying window layout"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT="/Volumes/$VOLUME_NAME"

# Give Finder a moment to notice the volume before scripting it.
for _ in $(seq 1 20); do [ -d "$MOUNT" ] && break; sleep 0.25; done

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- 660x420 content area, matching the background image
        set the bounds of container window to {200, 140, 860, 560}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 12
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "SiliCool.app" of container window to {165, 205}
        set position of item "Applications" of container window to {495, 205}
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT

# Make sure the .DS_Store carrying those settings is flushed to the image.
sync
retry hdiutil detach "$DEVICE" >/dev/null
sleep 1

echo "==> Compressing"
mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT" >/dev/null

# Signing the image itself is what lets Gatekeeper verify it before mounting.
if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "==> Signing disk image as $DEVELOPER_ID"
    codesign --force --sign "$DEVELOPER_ID" --timestamp "$OUTPUT"
fi

SIZE=$(du -h "$OUTPUT" | cut -f1)
echo "==> Built $OUTPUT ($SIZE)"
