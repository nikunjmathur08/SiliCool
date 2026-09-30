import { gridGlyph, gearGlyph, infoGlyph } from "./glyphs";

const FROST =
  "rounded-[34px] border-[1.5px] border-[#fffcfc40] bg-[#eaeaeabf] " +
  "backdrop-blur-[16px] [-webkit-backdrop-filter:blur(16px)]";

const ITEM =
  "inline-flex h-[47px] cursor-pointer items-center rounded-[36px] " +
  "bg-[#ffffffd6] text-[16px] font-medium leading-[1.025] " +
  "tracking-[-0.02em] whitespace-nowrap no-underline text-[#313131e3] " +
  "transition-colors hover:bg-[#e6e6e6f2] " +
  "focus-visible:outline-2 focus-visible:outline-offset-[3px] " +
  "focus-visible:outline-[#3499ff] " +
  "max-[760px]:h-10 max-[760px]:text-[13px] " +
  "max-[560px]:h-[37px] max-[560px]:text-[12px]";

const ICON =
  "[&_img]:block [&_img]:h-[13px] [&_img]:w-auto [&_img]:shrink-0";

const ICON_BIG = "[&_img]:block [&_img]:h-[15px] [&_img]:w-auto";

export default function Nav() {
  return (
    <header className="pointer-events-none fixed inset-x-0 bottom-[calc(20px+env(safe-area-inset-bottom,0px))] z-[100] flex items-center justify-center px-3.5">
      <div className="flex items-center gap-2.5">
        <a
          href="#"
          className={`pointer-events-auto flex h-[65px] items-center justify-center px-[26px] text-[31px] font-medium leading-[1.025] tracking-[-0.02em] whitespace-nowrap no-underline text-[#000000bf] transition-colors hover:text-accent focus-visible:outline-2 focus-visible:outline-offset-[3px] focus-visible:outline-[#3499ff] max-[760px]:h-[53px] max-[760px]:px-[19px] max-[760px]:text-[21px] max-[560px]:h-12 max-[560px]:px-3.5 max-[560px]:text-[18px] ${FROST}`}
        >
          SiliCool
        </a>

        <nav
          aria-label="Primary"
          className={`pointer-events-auto relative z-[1] flex h-[65px] items-center gap-[7px] p-[9px_10px_9px_11px] max-[760px]:h-[53px] max-[760px]:min-w-0 max-[760px]:px-[7px] max-[760px]:py-1.5 max-[560px]:h-12 max-[560px]:gap-[5px] max-[560px]:p-[5px] ${FROST}`}
        >
          <a
            href="#design"
            className={`${ITEM} ${ICON} justify-start gap-[7px] pl-[25px] pr-4 max-[760px]:gap-[5px] max-[760px]:pl-[14px] max-[760px]:pr-3 max-[560px]:w-[37px] max-[560px]:justify-center max-[560px]:p-0`}
          >
            {gridGlyph}
            <span className="max-[560px]:hidden">Design</span>
          </a>

          <a
            href="#specs"
            className={`${ITEM} ${ICON} justify-start gap-[7px] pl-[25px] pr-4 max-[760px]:gap-[5px] max-[760px]:pl-[14px] max-[760px]:pr-3 max-[560px]:w-[37px] max-[560px]:justify-center max-[560px]:p-0`}
          >
            {gearGlyph}
            <span className="max-[560px]:hidden">Specs</span>
          </a>

          <a
            href="#faq"
            aria-label="FAQ"
            className={`${ITEM} ${ICON_BIG} w-[55px] justify-center max-[760px]:w-10 max-[560px]:w-[37px] [&_img]:max-[560px]:h-[13px]`}
          >
            {infoGlyph}
          </a>

          <a
            href="/downloads/SiliCool.dmg"
            className="inline-flex h-[47px] w-[118px] cursor-pointer items-center justify-center rounded-[35px] border border-[#414141e6] bg-[#000000e6] text-[16px] font-medium leading-[1.025] tracking-[-0.02em] whitespace-nowrap no-underline text-[#ffffffe6] transition-colors hover:border-accent hover:bg-accent hover:text-white focus-visible:outline-2 focus-visible:outline-offset-[3px] focus-visible:outline-[#3499ff] max-[760px]:h-10 max-[760px]:w-auto max-[760px]:px-3.5 max-[760px]:text-[13px] max-[560px]:h-[37px] max-[560px]:px-3 max-[560px]:text-[12px]"
          >
            Download
          </a>
        </nav>
      </div>
    </header>
  );
}
