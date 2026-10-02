import { plusCircle } from "./glyphs";
import { SITE, REVEAL, EYEBROW, HEADLINE } from "../variants";

const faqs = [
  {
    question: "Can this damage my Mac?",
    answer:
      "SiliCool only allows fan speeds within the minimum and maximum values reported by the fan controller. Your Mac's built-in thermal management continues to operate independently",
  },
  {
    question: "macOS says it can't verify the developer. Is that a problem?",
    answer:
      "SiliCool is signed but hasn't been notarized by Apple yet. macOS may therefore show a security warning the first time you open it. To continue, open System Settings → Privacy & Security and click Open Anyway.",
  },
  {
    question: "Does it collect any data?",
    answer: (
      <>
        No. No analytics, no telemetry, no accounts and no networking code.
        Sensor readings stay on your Mac and are never sent anywhere. See the{" "}
        <a className="text-accent underline underline-offset-4" href="/privacy.html">
          privacy page
        </a>
        .
      </>
    ),
  },
  {
    question: "Why does it need an admin approval?",
    answer:
      "Writing fan settings to the SMC requires elevated privileges. SiliCool uses a small privileged helper rather than running the whole app with elevated privileges.",
  },
  {
    question: "Does it work on Intel Macs?",
    answer:
      "Not yet. SiliCool currently targets Apple silicon, where the sensor layout and fan-control keys it relies on are available.",
  },
  {
    question: "What happens if I delete the app?",
    answer:
      "Remove the helper from SiliCool's Settings before deleting the app. This returns the fans to automatic control and unregisters the privileged helper.",
  },
  {
    question: "What happens if SiliCool quits unexpectedly?",
    answer:
      "On supported exit paths, SiliCool releases manual fan control before exiting. The one exception is SIGKILL, including Force Quit, which the app cannot intercept. If a fan remains held, reopen SiliCool and press Release, or restart your Mac.",
  },
];

export default function FAQ() {
  return (
    <section
      id="faq"
      className="pt-[clamp(40px,6vw,90px)] pb-[clamp(70px,11vw,150px)]"
    >
      <div className={SITE}>
        <p className={`${EYEBROW} ${REVEAL}`}>Questions</p>

        <h2 className={`${HEADLINE} ${REVEAL} delay-[70ms]`}>
          Questions worth asking.
        </h2>

        <h3>
          Before you give a fan controller access to your Mac.
        </h3>

        <div
          className={`mt-[clamp(32px,4vw,48px)] border-t border-b border-line ${REVEAL} delay-[120ms]`}
        >
          {faqs.map(({ question, answer }) => (
            <details className="group border-b border-line last:border-b-0" key={question}>
              <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-6 text-[clamp(18px,1.7vw,21px)] font-semibold leading-[1.3] tracking-[-0.02em] text-black [&::-webkit-details-marker]:hidden">
                <span>{question}</span>
                <span className="size-10 shrink-0 transition-transform duration-300 [transition-timing-function:cubic-bezier(.16,1,.3,1)] group-open:rotate-45">
                  {plusCircle}
                </span>
              </summary>

              <div className="max-w-[720px] pb-[26px] pr-16 text-[17px] leading-[1.6] text-muted">
                {answer}
              </div>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
