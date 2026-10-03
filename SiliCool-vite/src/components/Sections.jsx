import { useState } from "react";
import { plusCircle } from "./glyphs";
import { SITE, REVEAL, EYEBROW, HEADLINE, BODY, FRAME, FRAME_MEDIA } from "../variants";

const specCards = [
  {
    icon: "wind-white.svg",
    label: "Fans found",
    value: "2 fans",
    body: "Reads SMC keys F0Ac, F0Mn and F0Mx on every sample.",
  },
  {
    icon: "cpu-white.svg",
    label: "CPU cores",
    value: "15 cores",
    body: "5 Super and 10 Performance, discovered through hw.perflevelN.",
  },
  {
    icon: "layers-white.svg",
    label: "GPU cores",
    value: "16 cores",
    body: "Reads the GPU core count from IORegistry alognside 42 available GPU probes.",
  },
  {
    icon: "gauge-white.svg",
    label: "Sample time",
    value: "15 ms",
    body: "84 keys per sweep, processed on a background task.",
  },
  {
    icon: "antenna-white.svg",
    label: "Initial scan",
    value: "2.8 s",
    body: "Hardware is enumerated, then scanned three times to identify duplicates.",
  },
  {
    icon: "bolt-white.svg",
    label: "Idle footprint",
    value: "15 MB",
    body: "Monitoring pauses when the panel is closed and no readings are visible.",
  },
  {
    icon: "clock-white.svg",
    label: "History window",
    value: "10 minutes",
    body: "14,400 bytes at 1 Hz, held in a fixed-size ring buffer.",
  },
];

const safetyRules = [
  ["Your Mac goes to sleep", "Returned to automatic, then resumed on wake"],
  ["You quit it, or log out", "Returned to automatic"],
  ["Ctrl-C in a terminal", "Returned to automatic"],
  ["kill, or a system shutdown", "Returned to automatic control when cleanup can"],
  ["Force Quit, kill -9", "Cannot be intercepted, see below"],
];

const CARD_ACCENT =
  "text-[clamp(29.44px,3.06vw,36.8px)] font-bold leading-[1.025] tracking-[-0.02em]";

const FLIP_FACE =
  "absolute inset-0 flex flex-col overflow-hidden bg-card rounded-[calc(52px*var(--card-scale))] px-[calc(48px*var(--card-scale))] pt-[calc(54px*var(--card-scale))] [backface-visibility:hidden] " +
  "max-[900px]:rounded-[clamp(calc(28px*var(--card-scale)),8vw,calc(52px*var(--card-scale)))] " +
  "max-[900px]:px-[calc(28px*var(--card-scale))] max-[900px]:pt-[calc(36px*var(--card-scale))]";

const FLIP_BTN =
  "absolute bottom-[calc(29px*var(--card-scale))] right-[calc(27px*var(--card-scale))] " +
  "h-[calc(40px*var(--card-scale))] w-[calc(40px*var(--card-scale))] " +
  "cursor-pointer border-0 bg-transparent p-0 " +
  "focus-visible:rounded-full focus-visible:outline-2 focus-visible:outline-offset-[3px] focus-visible:outline-[#3499ff] " +
  "max-[700px]:bottom-[calc(20px*var(--card-scale))] max-[700px]:right-[calc(20px*var(--card-scale))] " +
  "[&_svg]:block [&_svg]:size-full";

function FlipCard({ icon, label, value, body, index }) {
  const [flipped, setFlipped] = useState(false);
  const toggle = () => setFlipped((open) => !open);

  return (
    <article
      className="group relative h-[var(--card-height)] w-[var(--card-width)] flex-none [perspective:1600px] snap-start scroll-snap-stop-always max-[700px]:snap-center max-[700px]:first:snap-start max-[700px]:last:snap-end"
      data-flip=""
      data-flipped={flipped ? "" : undefined}
      style={{ "--flip-delay": `${index * 90}ms` }}
    >
      <div className="absolute inset-0 [transform:rotateY(-90deg)] transition-transform duration-700 [transition-timing-function:cubic-bezier(.2,.7,.2,1)] [transition-delay:var(--flip-delay,0s)] [transform-style:preserve-3d] group-[.is-in]:[transform:rotateY(0deg)] group-[.is-in]:group-data-[flipped]:[transform:rotateY(-180deg)] group-[.is-settled]:[transition-delay:0s] motion-reduce:transition-none">
        <div className={`${FLIP_FACE}`}>
          <div className="flex h-[60px] shrink-0 items-start justify-start overflow-clip max-[700px]:h-[calc(80px*var(--card-scale))]">
            <img
              className="h-full w-auto object-contain"
              src={`/assets/glyphs/${icon}`}
              alt={`${label} icon`}
            />
          </div>
          <div className="mt-[calc(26px*var(--card-scale))] max-[900px]:mt-[calc(24px*var(--card-scale))]">
            <p className={`m-0 text-accent ${CARD_ACCENT}`}>{label}</p>
            <p className={`m-0 mt-[calc(6px*var(--card-scale))] text-[#edeff1] ${CARD_ACCENT}`}>
              {value}
            </p>
          </div>
          <button
            type="button"
            className={FLIP_BTN}
            onClick={toggle}
            aria-label={`Flip to see how ${label} is measured`}
          >
            {plusCircle}
          </button>
        </div>

        <div className={`${FLIP_FACE} [transform:rotateY(180deg)]`}>
          <div className="flex h-[60px] shrink-0 items-start justify-start overflow-clip max-[700px]:h-[calc(80px*var(--card-scale))]">
            <img
              className="h-full w-auto object-contain"
              src={`/assets/glyphs/${icon}`}
              alt={`${label} icon back`}
            />
          </div>
          <div className="mt-[calc(26px*var(--card-scale))] max-[900px]:mt-[calc(24px*var(--card-scale))]">
            <p className={`m-0 text-accent ${CARD_ACCENT}`}>How</p>
            <p className="m-0 mt-[calc(28px*var(--card-scale))] max-w-[calc(280px*var(--card-scale))] text-[calc(20px*var(--card-scale))] font-medium leading-[1.1] tracking-[-0.01em] text-[#ffffff78] max-[900px]:text-[calc(16px*var(--card-scale))]">
              {body}
            </p>
          </div>
          <button
            type="button"
            className={FLIP_BTN}
            onClick={toggle}
            aria-label={`Flip back to ${label}`}
          >
            {plusCircle}
          </button>
        </div>
      </div>
    </article>
  );
}

export function Reads() {
  return (
    <section id="reads" className="pb-[clamp(80px,12vw,170px)]">
      <div className={SITE}>
        <h2 className={`${HEADLINE} ${REVEAL} delay-[70ms]`}>
          One panel. No window to manage.
        </h2>

        <p className={`${BODY} ${REVEAL} delay-[120ms]`}>
          Click the menu bar and the whole app is there. Sensors stay grouped
          in a fixed order, with 10 minutes of history and fan controls above.
        </p>
      </div>
    </section>
  );
}

export function Specs() {
  return (
    <section
      id="specs"
      className="overflow-x-clip bg-security py-[clamp(84px,15vw,240px)]"
    >
      <div className={`${SITE} ${REVEAL}`}>
        <p className={EYEBROW}>Measured, not claimed</p>
        <h2 className="m-0 text-left text-[clamp(32px,4.16vw,60px)] font-bold leading-[1.025] tracking-[-0.02em] text-[#515151]">
          Every number here came off{" "}
          <span className="text-white">a real machine.</span>
        </h2>
      </div>

      <div className="relative mx-auto mt-[clamp(40px,5vw,66px)] flex snap-x snap-mandatory gap-[calc(32px*var(--card-scale))] overflow-x-auto overflow-y-hidden scroll-smooth [touch-action:pan-x_pan-y] overscroll-x-contain ps-[var(--gutter)] pe-[calc(100%_-_var(--gutter)_-_var(--card-width))] scroll-ps-[var(--gutter)] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden max-[700px]:gap-4 max-[700px]:pe-[var(--gutter)] max-[700px]:scroll-pe-[var(--gutter)]">
        {specCards.map((card, index) => (
          <FlipCard key={card.label} index={index} {...card} />
        ))}
      </div>

      <p className="mx-auto mt-[84px] w-[var(--site-width)] text-[15px] font-medium leading-[1.4] tracking-[-0.02em] text-secmuted max-[700px]:mt-16">
        Taken on a M5 Pro MacBook Pro. Yours will report its own.
      </p>

    </section>
  );
}

export function Safety() {
  return (
    <section className="mx-auto mt-[clamp(80px,10vw,150px)] w-[var(--site-width)]">
      <p className={`${EYEBROW} ${REVEAL}`}>Safety</p>

      <h2
        className={`m-0 text-left text-[clamp(32px,4.16vw,60px)] font-bold leading-[1.025] tracking-[-0.02em] text-black ${REVEAL} delay-[70ms]`}
      >
        A pinned fan stays pinned.
        <span className="block text-[#1f1f1f]">So every exit hands it back.</span>
      </h2>

      <p
        className={`mt-6 max-w-[560px] text-[clamp(18px,1.6vw,20px)] font-medium leading-[1.35] tracking-[-0.01em] text-[#4b4b4b] ${REVEAL} delay-[120ms]`}
      >
        Fan settings outlive the process that made them. SiliCool treats that
        as its problem, not yours.
      </p>

      <div
        className={`mt-11 max-w-[840px] border-t border-b border-[#1111111a] ${REVEAL} delay-[140ms]`}
      >
        {safetyRules.map(([action, result]) => (
          <div
            className="grid grid-cols-2 gap-8 border-b border-[#1111111a] py-5 last:border-b-0 max-[900px]:grid-cols-1 max-[900px]:gap-1"
            key={action}
          >
            <div className="font-semibold tracking-[-0.01em] text-black">
              {action}
            </div>
            <div className="text-[#4b4b4b]">{result}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

export function Statement({ force = false }) {
  return (
    <section className="mx-auto w-[var(--site-width)] py-[clamp(70px,9vw,140px)]">
      <h2 className={`${HEADLINE} ${REVEAL}`}>
        {force ? (
          <>
            Force Quit cuts the line.
            <span className="text-body">
              {" "}
              Supported exits hand the fans back.
            </span>
          </>
        ) : (
          "Probes are not parts."
        )}
      </h2>

      <p
        className={`mt-[26px] max-w-[640px] text-[clamp(18px,1.6vw,20px)] font-medium leading-[1.35] tracking-[-0.01em] text-muted ${REVEAL} delay-[70ms]`}
      >
        {force ? (
          <>
            <code className="rounded-md bg-[#dde7f1] px-[7px] py-[2px] font-mono text-[0.86em]">
              SIGKILL
            </code>{" "}
            is the one signal no process can catch the OS terminates it
            before it can react. If you force quit SiliCool while a fan is
            held, the hold persists because nothing remains to release it. <br/>
            To recover: reopen SiliCool and press{" "}
            <strong>Release</strong>, or restart your Mac. Every other exit
            path returns the fans to automatic first.
          </>
        ) : (
          <>
            Your Mac exposes 42 GPU-related sensors but reports 16 GPU cores. There is
            no published mapping showing which sensors corresponds to which core. SiliCool
            labels these readings as probes, not individual cores, unless the reported count
            provides a reliable match.
          </>
        )}
      </p>
    </section>
  );
}

export function Install() {
  const steps = [
    {
      number: "1",
      title: "Drag it to Applications",
      description:
        "It has to run from there: macOS ties the approval to where the app lives.",
    },
    {
      number: "2",
      title: "Allow it once",
      description: (
        <>
          Open{" "}
          <strong>System Settings › Privacy &amp; Security</strong>, then click{" "}
          <strong>Open Anyway</strong>.
        </>
      ),
    },
    {
      number: "3",
      title: "Enable fan control",
      description: (
        <>
          Press Enable Fan Control, then switch SiliCool on under{" "}
          <strong>
            System Settings › General › Login Items &amp; Extensions
          </strong>
          .
        </>
      ),
    },
  ];

  return (
    <section
      id="install"
      className="pt-[clamp(30px,5vw,60px)] pb-[clamp(60px,9vw,130px)]"
    >
      <div className={SITE}>
        <p className={`${EYEBROW} ${REVEAL}`}>Install</p>

        <h2 className={`${HEADLINE} ${REVEAL} delay-[70ms]`}>
          Drag, open, approve.
        </h2>

        <p className={`${BODY} ${REVEAL} delay-[120ms]`}>
          Sensors work as soon as you open SiliCool. Fan control requires an additional approval
          controlling the SMC requires elevated privileges.
        </p>

        <div
          className={`mt-[clamp(36px,4.5vw,56px)] grid grid-cols-3 gap-[clamp(26px,3vw,44px)] max-[860px]:grid-cols-1 max-[860px]:max-w-[560px] ${REVEAL} delay-[140ms]`}
        >
          {steps.map(({ number, title, description }) => (
            <div key={number}>
              <div className="mb-[18px] grid size-[34px] place-items-center rounded-full bg-black text-[15px] font-semibold text-white">
                {number}
              </div>
              <h3 className="m-0 text-[20px] font-bold leading-[1.12] tracking-[-0.02em] text-black">
                {title}
              </h3>
              <p className="mt-2 text-[15.5px] leading-[1.5] text-muted">
                {description}
              </p>
            </div>
          ))}
        </div>
        <div
          className={`mt-[clamp(56px,7vw,86px)] flex min-h-[291px] w-full items-center gap-8 rounded-[52px] bg-accent px-[62px] py-12 max-[700px]:mt-12 max-[700px]:min-h-0 max-[700px]:flex-col max-[700px]:items-start max-[700px]:gap-5 max-[700px]:rounded-[clamp(28px,8vw,52px)] max-[700px]:px-7 max-[700px]:py-9 ${REVEAL}`}
        >
          <div className="flex h-[111px] w-[113px] shrink-0 overflow-clip max-[700px]:size-[70px] max-[700px]:h-[70px] max-[700px]:w-[70px]">
            <img
              className="size-full object-contain"
              src="/assets/glyphs/finder.svg"
              alt="Finder icon"
            />
          </div>
          <p className="m-0 max-w-[328px] text-[clamp(24px,3.33vw,40px)] font-bold leading-[1.025] tracking-[-0.02em] text-[#091c2f]">
            Why does macOS warn about it?
          </p>
          <p className="m-0 ml-auto max-w-[448px] text-[clamp(24px,3.33vw,40px)] font-bold leading-[1.025] tracking-[-0.02em] text-[#215080] max-[700px]:ml-0">
            SiliCool isn't notarized yet. The app is signed and the source is
            public under the MIT license, so you can inspect exactly what it does.
          </p>
        </div>
      </div>
    </section>
  );
}
