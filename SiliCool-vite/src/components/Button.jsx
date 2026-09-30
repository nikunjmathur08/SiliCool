const BASE =
  "inline-flex h-[54px] cursor-pointer items-center justify-center gap-2.5 " +
  "rounded-[49px] whitespace-nowrap no-underline font-medium " +
  "text-[20px] leading-[1.025] tracking-[-0.02em] transition-colors " +
  "focus-visible:outline-2 focus-visible:outline-offset-[3px] " +
  "focus-visible:outline-[#3499ff] max-[700px]:gap-[7px]";

const VARIANTS = {
  primary: "bg-black text-white hover:bg-accent",
  secondary: "bg-surface text-[#313131] hover:bg-[#e0e0e0]",
};

const SIZING = {
  fixed: "w-[206px] max-[700px]:w-auto max-[700px]:h-11 max-[700px]:px-[18px] max-[700px]:text-[15px]",
  hug: "w-auto px-7 max-[700px]:h-11 max-[700px]:px-4 max-[700px]:text-[15px]",
  heroFixed:
    "w-[206px] max-[700px]:w-auto max-[700px]:h-10 max-[700px]:px-3 max-[700px]:text-[14px]",
  heroHug:
    "w-auto px-7 max-[700px]:h-10 max-[700px]:px-3 max-[700px]:text-[14px]",
};

export default function Button({
  children,
  href = "/downloads/SiliCool.dmg",
  variant = "primary",
  hug = false,
  hero = false,
  glyph,
  className = "",
}) {
  const sizing = hero
    ? hug
      ? SIZING.heroHug
      : SIZING.heroFixed
    : hug
      ? SIZING.hug
      : SIZING.fixed;

  const classes = [BASE, VARIANTS[variant] ?? VARIANTS.primary, sizing, className]
    .join(" ")
    .trim();

  return (
    <a
      className={classes}
      href={href}
      {...(href.startsWith("http")
        ? { target: "_blank", rel: "noreferrer" }
        : {})}
    >
      {glyph ? (
        <span className="h-[17px] shrink-0 [&_img]:block [&_img]:h-full [&_img]:w-auto max-[700px]:h-[13px]">
          {glyph}
        </span>
      ) : null}
      {children}
    </a>
  );
}
