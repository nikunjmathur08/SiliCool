import { Link } from "react-router-dom";
import Button from "./Button";
import { appleGlyphWhite } from "./glyphs";
import Frost from "./FrostStrips.jsx";
import { REVEAL, SITE } from "../variants";

export default function Footer() {
  return (
    <footer className="relative w-full overflow-x-clip">
      <div className={`relative z-[1] pt-[clamp(90px,15vw,240px)] max-[700px]:pt-20 ${SITE}`}>
        <h2 className={`m-0 text-left text-[clamp(44px,5vw,75px)] font-bold leading-[1.025] tracking-[-0.02em] text-black ${REVEAL}`}>
          <span className="block">SiliCool is open-source.</span>
        </h2>

        <span className="font-bold text-[50px] leading-[1.3] tracking-[-0.02em] text-black block">
          Your Mac. Your fans. Your control.
        </span>

        <div
          className={`mt-[19px] flex flex-wrap items-center justify-start gap-4 max-[700px]:mt-3.5 max-[700px]:gap-3 ${REVEAL} delay-[70ms]`}
        >
          <Button>Download for Mac</Button>
          <Button hug variant="secondary" href="https://github.com/nikunjmathur08/Silicool">
            GitHub
          </Button>
        </div>
      </div>

      <div className={`relative z-[1] mt-[clamp(64px,8vw,110px)] ${SITE}`}>
        <nav className="flex flex-wrap gap-x-8 gap-y-[14px] border-t border-line pt-8 max-[700px]:gap-x-5 max-[700px]:gap-y-3">
          <Link
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            to="/reads"
          >
            What it reads
          </Link>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="https://github.com/nikunjmathur08/Silicool"
          >
            GitHub
          </a>
          <Link
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            to="/install"
          >
            Install
          </Link>
          <a
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            href="https://github.com/nikunjmathur08/Silicool/releases"
          >
            Releases
          </a>
          <Link
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            to="/faq"
          >
            FAQ
          </Link>
          <Link
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            to="/privacy"
          >
            Privacy
          </Link>
          <Link
            className="text-[15px] font-medium tracking-[-0.01em] text-muted no-underline transition-colors duration-200 hover:text-accent"
            to="/terms"
          >
            Terms
          </Link>
        </nav>

        <div className="mt-3.5 flex flex-wrap gap-x-6 gap-y-2 text-[13px] text-caption max-[700px]:gap-x-5">
          <span>© 2026 SiliCool. MIT Licensed.</span>
          <span>Not affiliated with Apple Inc.</span>
        </div>
      </div>

      <Frost
        variant="flip"
        className="-mt-48"
      />
    </footer>
  );
}
