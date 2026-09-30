import Button from "./Button";
import { appleGlyphWhite } from "./glyphs";
import Frost from "./FrostStrips.jsx";
import { REVEAL, SITE } from "../variants";

export default function Footer() {
  return (
    <footer className="relative w-full overflow-x-clip">
      <div className={`relative z-[1] pt-[clamp(90px,15vw,240px)] max-[700px]:pt-20 ${SITE}`}>
        <h2 className={`m-0 text-left text-[clamp(44px,5vw,75px)] font-bold leading-[1.025] tracking-[-0.02em] text-black ${REVEAL}`}>
          <span className="block">SiliCool is</span>
          <span className="block">open-source.</span>
        </h2>

        <div
          className={`mt-[19px] flex flex-wrap items-center justify-start gap-4 max-[700px]:mt-3.5 max-[700px]:gap-3 ${REVEAL} delay-[70ms]`}
        >
          <Button glyph={appleGlyphWhite}>Download for Mac</Button>
          <Button hug variant="secondary" href="https://github.com">
            GitHub
          </Button>
        </div>

        <p
          className={`mt-[26px] text-[15px] font-medium leading-[1.025] tracking-[-0.02em] text-muted ${REVEAL} delay-[120ms]`}
        >
          macOS 14 or later · Apple silicon · free and MIT licensed
        </p>
      </div>

      <div className={`relative z-[1] mt-[clamp(64px,8vw,110px)] ${SITE}`}>
        <nav className="flex flex-wrap gap-x-8 gap-y-[14px] border-t border-line pt-8 max-[700px]:gap-x-5 max-[700px]:gap-y-3">
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="#reads"
          >
            What it reads
          </a>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="https://github.com"
          >
            GitHub
          </a>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="#install"
          >
            Install
          </a>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="https://github.com/releases"
          >
            Releases
          </a>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="#faq"
          >
            FAQ
          </a>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="/privacy.html"
          >
            Privacy
          </a>
        </nav>

        <div className="mt-3.5 flex flex-wrap gap-x-6 gap-y-2 text-[13px] text-caption max-[700px]:gap-x-5">
          <span>© 2025 SiliCool. MIT Licensed.</span>
          <span>Not affiliated with Apple Inc.</span>
        </div>
      </div>

      <Frost
        variant="flip"
        className="mt-[clamp(48px,6vw,80px)] max-[700px]:mt-10"
      />
    </footer>
  );
}
