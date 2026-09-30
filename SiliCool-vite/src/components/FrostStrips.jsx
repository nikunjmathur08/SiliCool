import { frostStrips } from "./frostStrips";

const FROST_CORE =
  "pointer-events-none left-1/2 z-0 -ml-[50vw] h-[var(--fh)] w-screen " +
  "overflow-hidden isolate [contain:layout_paint] " +
  "[-webkit-mask-image:linear-gradient(#000_0%,#000_55%,transparent_100%)] " +
  "[mask-image:linear-gradient(#000_0%,#000_55%,transparent_100%)]";

const FIELD =
  "flex h-[calc(100%_+_var(--fb))] w-[calc(100%_+_2_*_var(--fb))] " +
  "-mt-[var(--fb)] -ml-[var(--fb)] items-start justify-center gap-[var(--sg)] " +
  "px-[var(--fb)] pt-[var(--fb)] blur-[var(--fb)] [transform:translateZ(0)] " +
  "max-[700px]:-translate-x-[100px]";

const STRIP_BASE =
  "block h-[calc(var(--smh)*var(--h)/100)] w-[var(--sw)] flex-none rounded-b-full " +
  "bg-[var(--sc)] opacity-[calc(var(--o)*var(--so)*var(--sr))] " +
  "motion-reduce:animate-none " +
  "motion-reduce:opacity-[calc(var(--o)*var(--so))] " +
  "max-[700px]:animate-none max-[700px]:opacity-[calc(var(--o)*var(--so))]";

const STRIP_GLOW =
  "animate-strip-glow [animation-delay:calc(var(--i)*var(--ss))]";

const STRIP_LAUNCH =
  "animate-strip-launch " +
  "[animation-delay:calc(var(--i)*var(--gs)),calc(var(--i)*var(--ss))]";

export default function Frost({ variant = "launch", className = "" }) {
  const launch = variant === "launch";

  return (
    <div
      aria-hidden="true"
      className={[
        FROST_CORE,
        launch
          ? "absolute top-[calc(-1_*_var(--fl))]"
          : "relative -scale-y-100",
        className,
      ].join(" ")}
    >
      <div className={FIELD}>
        {frostStrips.map(({ i, h, o, mods }) => (
          <span
            key={i}
            className={[STRIP_BASE, launch ? STRIP_LAUNCH : STRIP_GLOW, mods]
              .join(" ")
              .trim()}
            style={{ "--h": h, "--o": o, "--i": i }}
          />
        ))}
      </div>
    </div>
  );
}
