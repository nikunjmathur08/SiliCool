import Button from "./Button";
import { appleGlyph, appleGlyphWhite } from "./glyphs";
import Frost from "./FrostStrips.jsx";
import { REVEAL, FRAME, FRAME_MEDIA } from "../variants";

export default function Hero() {
  return (
    <section className="relative mx-auto flex w-[var(--site-width)] flex-col items-start pt-[191px] pb-[126px] min-[1600px]:pt-[260px] max-[700px]:pt-[160px] max-[700px]:pb-[88px]">
      <Frost variant="launch" />

      <h1
        className={`relative z-[1] m-0 max-w-[8.2em] text-left text-[clamp(40px,5.5vw,90px)] font-semibold leading-[1.025] tracking-[-0.02em] text-black ${REVEAL}`}
      >
        <span className="block">Fan Control.</span>
        <span className="block">
          For your {" "}
          <span className="inline-block h-[0.7875em] w-[0.6625em] overflow-clip align-[-0.1em] mb-[0.08em] mr-[0.05em] [&_img]:block [&_img]:size-full [&_img]:object-contain pointer-events-none">
            {appleGlyph}
          </span>
          Mac.
        </span>
      </h1>

      <h2>
        Take control of your Mac's fans without giving up macOS's automatic control.
      </h2>

      <div
        className={`relative z-[1] mt-[10px] flex flex-wrap items-center justify-start gap-4 max-[700px]:mt-[14px] max-[700px]:w-full ${REVEAL} delay-[70ms]`}
      >
        <Button hero className="max-[700px]:hidden">
          Download for Mac
        </Button>

        <div className="flex flex-nowrap items-center gap-4 max-[700px]:flex-wrap max-[700px]:gap-2">
          <Button hero hug variant="secondary" href="https://github.com/nikunjmathur08/Silicool">
            GitHub
          </Button>
        </div>
      </div>

      <p
        className={`relative z-[1] mt-5 text-[15px] font-medium leading-[1.025] tracking-[-0.02em] text-muted max-[700px]:mt-4 max-[700px]:text-[14px] ${REVEAL} delay-[120ms]`}
      >
        macOS 14 + · Apple silicon · Free ·  MIT licensed
      </p>

      <div
        className={`relative z-[1] mt-20 max-[700px]:mt-12 ${FRAME} ${REVEAL} delay-[140ms]`}
      >
        <div className={FRAME_MEDIA}>
          <video
            className="size-full object-cover"
            src="/assets/promo.mp4"
            poster="/assets/poster.jpg"
            autoPlay
            muted
            loop
            playsInline
            preload="metadata"
          />
        </div>
      </div>
    </section>
  );
}
