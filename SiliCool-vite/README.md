# SiliCool — Vite + React

## Structure

- `src/App.jsx` — page composition only
- `src/components/` — reusable sections
- `src/styles.css` — responsive styling and animation
- `public/assets/` — static images/video/icons
- `public/downloads/` — DMG download
- `index.html` — Vite entry document

## Setup

```bash
npm install
npm run dev
```

Production:

```bash
npm run build
npm run preview
```

## Assets

Copy the existing SiliCool `assets/` directory into `public/assets/` so these paths exist:

`icon.png`, `poster.jpg`, `promo.mp4`, and `sf/antenna.png`, `wind.png`, `gauge.png`, `eye_slash.png`, `clock.png`, `halfcircle.png`, `bolt.png`, `chart.png`.

Put `SiliCool.dmg` in `public/downloads/`, or change the download links in `Button.jsx`.

`legacy.html` is included only as a reference copy of the original page.
