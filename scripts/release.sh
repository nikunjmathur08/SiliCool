#!/bin/bash
#
# Builds, signs, notarizes and packages SiliCool for public distribution.
#
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=silicool \
#   ./scripts/release.sh
#
# One-time setup for the notary credentials (stores them in the keychain):
#
#   xcrun notarytool store-credentials silicool \
#       --apple-id you@example.com --team-id TEAMID \
#       --password <app-specific-password from appleid.apple.com>
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/Release/SiliCool.app"
DMG="$BUILD/SiliCool.dmg"
DEVELOPER_ID="${DEVELOPER_ID:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

fail() { echo "error: $*" >&2; exit 1; }

# --- preflight -------------------------------------------------------------
# Fail here rather than three minutes into a build that cannot be shipped.

[ -n "$DEVELOPER_ID" ] || fail "set DEVELOPER_ID to a signing identity. List them with:
           security find-identity -v -p codesigning"

security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID" \
    || fail "no such signing identity in the keychain: $DEVELOPER_ID"

# Notarization needs a Developer ID certificate, which needs the paid program.
# Without one the build still ships — it just arrives with a Gatekeeper warning
# the user has to clear once in System Settings.
case "$DEVELOPER_ID" in
    "Developer ID Application:"*)
        NOTARIZE=1
        [ -n "$NOTARY_PROFILE" ] || fail "set NOTARY_PROFILE to a notarytool keychain profile (see header)."
        ;;
    *)
        NOTARIZE=0
        echo "note: '$DEVELOPER_ID' is not a Developer ID certificate."
        echo "      Building an unnotarized release. Users will see \"Apple could not verify\""
        echo "      on first launch and must allow it once in System Settings > Privacy &"
        echo "      Security. Ad-hoc signing is not an option: it carries no team identifier,"
        echo "      and fan control would never connect."
        echo
        ;;
esac

# --- build -----------------------------------------------------------------
echo "==> Building Release"
rm -rf "$BUILD/Release"
xcodebuild -project "$ROOT/SiliCool.xcodeproj" -scheme SiliCool \
    -configuration Release -derivedDataPath "$BUILD/dd" \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
    CODE_SIGN_STYLE=Manual \
    OTHER_CODE_SIGN_FLAGS="--timestamp -o runtime" \
    build > "$BUILD/build.log" 2>&1 || { tail -30 "$BUILD/build.log"; fail "build failed"; }

mkdir -p "$BUILD/Release"
cp -R "$BUILD/dd/Build/Products/Release/SiliCool.app" "$APP"

# --- sign ------------------------------------------------------------------
# Inside out: the embedded daemon first, then the app that contains it.
echo "==> Signing"
codesign --force --timestamp --options runtime \
    --sign "$DEVELOPER_ID" \
    --identifier "Nikunj.SiliCool.Helper" \
    "$APP/Contents/MacOS/SiliCoolHelper"

codesign --force --timestamp --options runtime \
    --sign "$DEVELOPER_ID" \
    "$APP"

codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | sed 's/^/    /'

# --- package ---------------------------------------------------------------
echo "==> Building disk image"
DEVELOPER_ID="$DEVELOPER_ID" "$ROOT/scripts/make-dmg.sh" "$APP" "$DMG"

if [ "$NOTARIZE" = "1" ]; then
    # Only the outermost container is notarized: the ticket covers every nested
    # file, including the app and its daemon, and each submission counts against
    # a 75-per-day cap. (Add a separate app submission if you adopt Sparkle,
    # which ships an already-stapled .app inside a zip.)
    echo "==> Notarizing disk image"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait \
    | tee "$BUILD/notarize-dmg.log"
grep -q "status: Accepted" "$BUILD/notarize-dmg.log" || {
    SUBMISSION=$(awk '/id:/ {print $2; exit}' "$BUILD/notarize-dmg.log")
    xcrun notarytool log "$SUBMISSION" --keychain-profile "$NOTARY_PROFILE" || true
    fail "disk image notarization was not accepted"
}

xcrun stapler staple "$DMG"
fi

# --- verify like a first-time user ----------------------------------------
echo "==> Verifying"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG" 2>&1 | sed 's/^/    /' || true
if [ "$NOTARIZE" = "1" ]; then
    xcrun stapler validate "$DMG" 2>&1 | sed 's/^/    /'
else
    echo "    (rejected is expected without notarization — see the install page)"
fi

VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)
echo
echo "==> SiliCool $VERSION ready: $DMG"
if [ "$NOTARIZE" = "1" ]; then
    echo "    Notarized and stapled. Publish it anywhere."
else
    echo "    Not notarized. Copy it to site/downloads/ so the website serves it:"
    echo "      cp \"$DMG\" site/downloads/SiliCool.dmg"
fi
