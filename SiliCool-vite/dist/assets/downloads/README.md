Put the built disk image here as `SiliCool.dmg`:

    ./scripts/make-dmg.sh build/Release/SiliCool.app site/downloads/SiliCool.dmg

Vercel serves this directory at /downloads/, which is where the site's download
button points. Swap `DOWNLOAD_URL` in index.html if you move to GitHub Releases.
