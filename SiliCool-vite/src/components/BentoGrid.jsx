import { REVEAL, SITE } from "../variants";

const features = [
  { icon: "gauge.svg", label: "Fan curves" },
  { icon: "clock.svg", label: "10 min history" },
  { icon: "eye-slash.svg", label: "No telemetry" },
];

const identityViews = [
  { src: "/assets/panel-curve.jpg", position: "50% 22%" },
  { src: "/assets/panel-monitor.png", position: "50% 46%" },
  { src: "/assets/panel-settings.jpg", position: "50% 70%" },
];

export default function BentoGrid() {
  return (
    <section
      id="design"
      className="pt-[clamp(60px,7vw,100px)] pb-[clamp(90px,15vw,220px)] max-[700px]:pt-9 max-[700px]:pb-20"
    >
      <div className={SITE}>
        <h2
          className={`mx-2.5 mb-[clamp(28px,3.4vw,48px)] max-w-[15.2em] text-[clamp(36px,4.16vw,60px)] font-bold leading-[1.05] tracking-[-0.02em] text-black max-[700px]:mb-4 ${REVEAL}`}
        >
          <span className="block">Auto by default.</span>
          <span className="block text-soft">Manual the moment you want it.</span>
        </h2>

        <div className="grid grid-cols-[minmax(0,492fr)_minmax(0,141fr)_minmax(0,492fr)] items-stretch gap-[38px] max-[900px]:grid-cols-1 max-[900px]:gap-6">
          <div
            className={`col-start-1 row-start-1 col-end-3 flex min-h-0 flex-col gap-9 max-[900px]:col-auto max-[900px]:row-auto max-[900px]:gap-5 ${REVEAL} delay-[70ms]`}
          >
            <div className="flex min-h-0 flex-[323_1_0] items-center justify-evenly rounded-[clamp(24px,3.66vw,44px)] bg-frame px-4 pt-6 pb-5 max-[900px]:flex-none max-[900px]:min-h-[240px] max-[700px]:pt-7 max-[700px]:pb-6">
              <div className="flex flex-col items-center justify-end gap-[21px]">
                <div className="grid aspect-square w-[clamp(110px,13.82vw,166px)] place-items-center rounded-[25.8%] bg-black p-6 max-[900px]:p-[18px]">
                  <img
                    className="size-full object-contain"
                    src="/assets/icon.png"
                    alt=""
                  />
                </div>
                <p className="m-0 text-[clamp(15px,1.66vw,20px)] leading-[1.025] tracking-[-0.05em] text-[#353535]">
                  Auto
                </p>
              </div>

              <div className="flex flex-col items-center justify-end gap-[21px]">
                <div className="flex flex-col gap-[clamp(28px,3.83vw,46px)]">
                  <div className="relative flex h-[clamp(38px,4.41vw,53px)] w-[clamp(130px,17.57vw,200px)] items-center gap-2 overflow-clip rounded-[64px] bg-black px-3.5">
                    <span className="whitespace-nowrap text-[clamp(12px,1.1vw,14px)] font-semibold tracking-[-0.02em] text-white">
                      2317{" "}
                      <small className="text-[0.75em] font-medium opacity-70">
                        rpm
                      </small>
                    </span>
                    <span className="absolute bottom-[9px] left-3.5 right-3.5 h-[3px] rounded-[99px] bg-white/20">
                      <span
                        className="block h-full rounded-[99px] bg-accent"
                        style={{ width: "31%" }}
                      />
                    </span>
                  </div>

                  <div className="relative flex h-[clamp(38px,4.41vw,53px)] w-[clamp(130px,17.57vw,200px)] items-center gap-2 overflow-clip rounded-[64px] bg-black px-3.5">
                    <span className="whitespace-nowrap text-[clamp(12px,1.1vw,14px)] font-semibold tracking-[-0.02em] text-white">
                      3956{" "}
                      <small className="text-[0.75em] font-medium opacity-70">
                        rpm
                      </small>
                    </span>
                    <span className="absolute bottom-[9px] left-3.5 right-3.5 h-[3px] rounded-[99px] bg-white/20">
                      <span
                        className="block h-full rounded-[99px] bg-accent"
                        style={{ width: "50%" }}
                      />
                    </span>
                  </div>
                </div>
                <p className="m-0 text-[clamp(15px,1.66vw,20px)] leading-[1.025] tracking-[-0.05em] text-[#353535]">
                  Manual
                </p>
              </div>
            </div>

            <div className="flex min-h-0 flex-[249_1_0] items-center justify-evenly rounded-[clamp(28px,4.33vw,52px)] bg-frame px-3 pt-7 pb-6 max-[900px]:flex-none max-[900px]:min-h-[170px] max-[700px]:px-2 max-[700px]:pt-6 max-[700px]:pb-5">
              {features.map(({ icon, label }) => (
                <div
                  className="flex w-[min(172px,30%)] flex-col items-center gap-[18px] text-center max-[700px]:w-[min(110px,32%)] max-[700px]:gap-3"
                  key={label}
                >
                  <div className="flex h-[clamp(40px,4.66vw,56px)] items-center justify-center overflow-clip">
                    <img
                      className="h-full w-auto object-contain"
                      src={`/assets/glyphs/${icon}`}
                      alt=""
                    />
                  </div>
                  <p className="m-0 text-[clamp(16px,2.16vw,26px)] font-bold leading-[1.025] tracking-[-0.02em] text-black">
                    {label}
                  </p>
                </div>
              ))}
            </div>
          </div>

          <div
            className={`relative col-start-3 row-start-1 aspect-[492/608] w-full overflow-clip rounded-[clamp(24px,3.66vw,44px)] max-[900px]:col-auto max-[900px]:row-auto max-[900px]:mx-auto max-[900px]:w-[min(100%,492px)] ${REVEAL} delay-[120ms]`}
          >
            <img
              className="absolute inset-0 size-full object-cover object-top"
              src="/assets/panel-monitor.png"
              alt="The SiliCool panel open from the menu bar"
            />
            <div className="pointer-events-none absolute inset-x-0 bottom-0 h-[43.5%] bg-[linear-gradient(#0000,#000000ab_62%)] backdrop-blur-[2px] [-webkit-backdrop-filter:blur(2px)]" />
            <div className="absolute bottom-[5.26%] left-[7.52%] right-[7.52%] z-[1]">
              <h3 className="m-0 text-[clamp(18px,2.16vw,26px)] font-bold leading-[1.025] tracking-[-0.02em] text-white">
                Menu bar ready
              </h3>
              <p className="mt-2 max-w-[293px] text-[clamp(13px,1.33vw,16px)] font-medium leading-[1.025] tracking-[-0.02em] text-[silver]">
                Every reading, grouped in a fixed order — and the two fans
                macOS never lets you touch.
              </p>
            </div>
          </div>

          <div
            className={`relative col-start-1 row-start-2 aspect-[492/329] w-full overflow-clip rounded-[clamp(28px,4.33vw,52px)] bg-panel max-[900px]:col-auto max-[900px]:row-auto max-[900px]:mx-auto max-[900px]:w-[min(100%,492px)] ${REVEAL} delay-[140ms]`}
          >
            <img
              className="absolute inset-0 size-full object-cover"
              src="/assets/native-app.png"
              alt=""
            />
            <h3 className="sr-only">Native App</h3>
          </div>

          <div
            className={`relative col-start-2 row-start-2 col-end-4 min-h-0 overflow-clip rounded-[clamp(28px,4.33vw,52px)] bg-frame max-[900px]:col-auto max-[900px]:row-auto max-[900px]:overflow-visible ${REVEAL} delay-[210ms]`}
          >
            <div className="relative z-[2] max-w-[346px] p-[50px_0_0_50px] max-[900px]:max-w-none max-[900px]:p-[40px_32px_0] max-[700px]:p-[28px_20px_0]">
              <h3 className="m-0 text-[clamp(26px,2.91vw,35px)] font-bold leading-[1.025] tracking-[-0.02em] text-black">
                256 live sensors
              </h3>
              <p className="mt-5 max-w-[280px] text-[clamp(13px,1.2vw,18px)] leading-[1.1] tracking-[-0.02em] text-[#787878] max-[900px]:max-w-none max-[700px]:mt-4">
                CPU cores, GPU probes, SoC, battery, enclosure and power — in
                real time.
              </p>
            </div>

            <div className="absolute top-[13.81%] left-[58.12%] flex w-[60.8%] flex-col gap-3 max-[900px]:static max-[900px]:w-full max-[900px]:px-8 max-[900px]:pt-7 max-[900px]:pb-9 max-[700px]:px-5 max-[700px]:pt-5 max-[700px]:pb-6">
              {identityViews.map(({ src, position }) => (
                <img
                  key={src}
                  className="aspect-[492/100] h-auto w-full rounded-[21px] object-cover max-[700px]:rounded-[15px]"
                  src={src}
                  alt=""
                  style={{ objectPosition: position }}
                />
              ))}
            </div>

            <div className="pointer-events-none absolute bottom-0 right-0 z-[1] h-[75%] w-[95%] rounded-br-[clamp(28px,5.33vw,52px)] bg-[radial-gradient(120%_90%_at_100%_100%,#eaf0f6d1,#eaf0f666,#0000_70%)] max-[900px]:hidden" />
          </div>
        </div>
      </div>
    </section>
  );
}
