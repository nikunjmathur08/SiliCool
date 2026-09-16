# Deploying the site

The site is static files in `site/` — no build step, no framework.

## Vercel

1. Push this repository to GitHub.
2. In Vercel, **Add New → Project**, import the repo.
3. Framework Preset: **Other**. Leave Build Command and Install Command empty.
4. Deploy.

`vercel.json` at the repo root points Vercel at `site/` as the output directory,
so nothing needs configuring in the dashboard. It also sets:

- `cleanUrls` — `/privacy` works without the `.html`
- a one-year immutable cache on `/assets/*` (the video and screenshots)
- a one-hour cache and `Content-Disposition: attachment` on `/downloads/*`, so
  the disk image downloads rather than trying to preview

Or from the CLI:

```bash
npx vercel --prod
```

## The download

`site/downloads/SiliCool.dmg` is what the download button serves, and the
release script tells you to copy it there:

```bash
./scripts/release.sh                       # builds build/SiliCool.dmg
cp build/SiliCool.dmg site/downloads/      # stage it for the site
```

Keeping the disk image in the repo means one deploy ships the site and the
build together, and nothing can point at a release that doesn't exist. The
trade-off is repo size — about 3 MB per release. If that becomes annoying, move
to GitHub Releases and change one line in `site/index.html`:

```js
const DOWNLOAD_URL = "https://github.com/<you>/SiliCool/releases/latest/download/SiliCool.dmg";
```

## Other hosts

Nothing here is Vercel-specific. Any static host works — Cloudflare Pages,
Netlify, GitHub Pages — as long as it serves `site/` as the web root. On GitHub
Pages you would move `site/` to `docs/` or use a Pages action, since it can't
serve a subdirectory as the root.
