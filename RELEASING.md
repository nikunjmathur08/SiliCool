# Releasing SiliCool

Everything here assumes you are in the repository root.

---

## 1. Cut a release

**Bump the version first.** Two numbers in `SiliCool.xcodeproj` — open it in
Xcode, select the SiliCool target, General tab:

| Field | Xcode label | Rule |
| --- | --- | --- |
| `MARKETING_VERSION` | Version | What people see: `1.1`, `1.2.1` |
| `CURRENT_PROJECT_VERSION` | Build | Increment every single build you publish |

Then build, sign and package in one command:

```bash
DEVELOPER_ID="Apple Development: nikunjmathur0810@gmail.com (7MDAV9F2X8)" ./scripts/release.sh
```

That builds Release, signs the helper and then the app, builds the disk image,
signs it, and verifies. It leaves you `build/SiliCool.dmg`.

If you are ever handed a Developer ID certificate, pass that instead and add
`NOTARY_PROFILE=silicool`; the same script then notarizes and staples, and the
Gatekeeper warning disappears for your users. Nothing else changes.

**Just want a disk image from an app you already built?**

```bash
./scripts/make-dmg.sh build/Release/SiliCool.app build/SiliCool.dmg
```

---

## 2. Publish it

```bash
./scripts/stage-release.sh          # copies the DMG into the site, stamps size + version
./scripts/build-site.sh             # refreshes the standalone preview
git add -A && git commit -m "Release 1.1" && git push
```

Vercel deploys on push. `stage-release.sh` rewrites the download line on the
page from the real file, so the size and version on the site can never drift
from what people actually download.

Check the result at `/` and `/privacy`, and click the download button once.

**Serving the disk image from GitHub Releases instead.** One line in
`site/index.html`:

```js
const DOWNLOAD_URL = "https://github.com/<you>/SiliCool/releases/latest/download/SiliCool.dmg";
```

Then upload `build/SiliCool.dmg` as a release asset and skip `stage-release.sh`
(or keep running it, and delete `site/downloads/` from the repo).

---

## 3. Change how things look

### The installer window

Everything about it lives in two files.

**The picture** — `tools/dmg-background/main.swift`. Edit the colours, the
title, the instruction text, then:

```bash
./tools/dmg-background/build.sh
```

That rewrites `packaging/dmg-background.tiff` with both a 1x and a 2x layer, so
it stays sharp on Retina. The small fan mark next to the title is the same
source artwork as the app icon — `icon.png` at the repo root. Rebuild the disk
image to see it.

**The window itself** — `scripts/make-dmg.sh`, in the AppleScript block:

| What | Line | Notes |
| --- | --- | --- |
| Window size | `set the bounds of container window to {200, 140, 860, 560}` | `{left, top, right, bottom}` — currently 660 × 420 |
| Icon size | `set icon size of viewOptions to 112` | points |
| App position | `set position of item "SiliCool.app" … to {165, 205}` | centre of the icon |
| Applications position | `set position of item "Applications" … to {495, 205}` | centre of the icon |
| Volume name | `VOLUME_NAME="SiliCool"` | what appears in the Finder sidebar |

**Keep the two files in agreement.** The background is drawn for a 660 × 420
window with icons at those exact coordinates — `tools/dmg-background/main.swift`
has them at the top as constants. Change the window size in one place and the
arrow will point at nothing.

After any change:

```bash
./scripts/make-dmg.sh build/Release/SiliCool.app build/SiliCool.dmg && open build/SiliCool.dmg
```

### The app icon

The source artwork is `icon.png` at the repo root — replace that file, then:

```bash
./tools/icon/build.sh
```

It composites the artwork onto the dark rounded plate, renders all ten sizes
into the asset catalog, writes `Contents.json`, and updates the copies the
website and README use. Check the small end before shipping: the Finder icon
and the ⌘-Tab switcher are where most people will see it. The same file feeds
the mark in the installer window, so run `./tools/dmg-background/build.sh` too
after a rebrand.

### The promo film

`tools/promo/main.swift` — captions, timings and scene order are near the top.

```bash
swiftc -O -o /tmp/promo $(cat tools/promo/sources.txt) tools/promo/main.swift
/tmp/promo docs/silicool-promo.mp4          # 1080p master
/tmp/promo site/assets/promo.mp4 --web      # 720p, ~3 MB, what the site loads
```

It renders from the app's own SwiftUI views with a live SMC read, so it is
footage of the real interface rather than a mockup. Re-run it whenever the UI
changes meaningfully, or the site will be showing an old app.

### The website

`site/index.html` is one self-contained file: styles at the top, content, then a
short script at the bottom. Text and layout are plain HTML — edit and reload.

- Colours are CSS custom properties in `:root`.
- `assets/` holds the screenshots, video and icon.
- `privacy.html` is a separate page, linked in the footer.
- The download line is stamped automatically — edit the format in
  `scripts/stage-release.sh`, not in the HTML, or your next release overwrites it.

Refresh the screenshots by re-rendering the panels and running
`sips -Z 1000 -s format jpeg -s formatOptions 78` over them into `site/assets/`.

---

## 4. Before you publish

- [ ] Version and build number bumped
- [ ] `./scripts/release.sh` finished without errors
- [ ] Mounted the DMG and dragged it to Applications yourself
- [ ] Launched from `/Applications`, not from the disk image
- [ ] Fan control still works, and fans return to automatic when you quit
- [ ] Slept the Mac with a fan held, and heard it go quiet
- [ ] Download button on the deployed site returns the new file
