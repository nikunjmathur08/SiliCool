import { plusCircle } from "./glyphs";
import { SITE, REVEAL, EYEBROW, HEADLINE } from "../variants";

const faqs = [
  {
    question: "Can this damage my Mac?",
    answer:
      "SiliCool can only ask for speeds between the minimum and maximum the fan itself reports. Thermal throttling is handled by your Mac’s firmware.",
  },
  {
    question: "macOS says it can’t verify the developer. Is that a problem?",
    answer:
      "It means SiliCool hasn’t been through Apple’s notarization service. To open it: System Settings › Privacy & Security › Open Anyway.",
  },
  {
    question: "Does it collect any data?",
    answer: (
      <>
        No. No analytics, no telemetry, no accounts, and no networking code at
        all — readings have no way to leave your Mac. See the{" "}
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
      "Writing fan keys to the SMC requires root. SiliCool uses a small privileged helper rather than running the whole app as root.",
  },
  {
    question: "Does it work on Intel Macs?",
    answer:
      "Not yet. The sensor naming and manual-mode key target Apple silicon.",
  },
  {
    question: "What happens if I delete the app?",
    answer:
      "Use Remove helper in Settings first — it returns the fans to automatic and unregisters the daemon.",
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
          Worth asking before installing a fan controller.
        </h2>

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
