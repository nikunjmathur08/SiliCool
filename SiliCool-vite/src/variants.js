export const SITE = "mx-auto w-[var(--site-width)]";

export const REVEAL =
  "js-reveal opacity-0 blur-[14px] translate-y-10 " +
  "[transition-property:opacity,transform,filter] " +
  "[transition-duration:.7s,.7s,.45s] " +
  "[&.is-in]:opacity-100 [&.is-in]:blur-none [&.is-in]:translate-y-0 " +
  "motion-reduce:transition-none motion-reduce:opacity-100 " +
  "motion-reduce:blur-none motion-reduce:translate-y-0";

export const EYEBROW =
  "m-0 mb-1 text-[20px] font-semibold leading-[1.025] tracking-[-0.02em] text-accent";

export const HEADLINE =
  "m-0 max-w-[15.2em] text-[clamp(36px,4.16vw,60px)] font-bold " +
  "leading-[1.05] tracking-[-0.02em] text-black";

export const BODY =
  "mt-6 max-w-[640px] text-[clamp(18px,1.6vw,20px)] font-medium " +
  "leading-[1.35] tracking-[-0.01em] text-muted";

export const FRAME =
  "w-full rounded-[clamp(20px,2.9vw,44px)] bg-frame p-2.5 max-[700px]:p-2";

export const FRAME_MEDIA =
  "relative aspect-video w-full overflow-clip rounded-[clamp(16px,2.2vw,34px)] " +
  "bg-[#d8e3ee]";

export const frameMediaChild = "size-full object-cover";
