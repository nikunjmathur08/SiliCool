import { useEffect } from "react";
import Nav from "./components/Nav";
import Hero from "./components/Hero";
import BentoGrid from "./components/BentoGrid";
import { Reads, Specs, Statement, Install } from "./components/Sections";
import FAQ from "./components/FAQ";
import Footer from "./components/Footer";

export default function App() {
  useEffect(() => {
    const targets = document.querySelectorAll(".js-reveal, [data-flip]");
    const flips = document.querySelectorAll("[data-flip]");

    if (
      matchMedia("(prefers-reduced-motion: reduce)").matches ||
      !("IntersectionObserver" in window)
    ) {
      targets.forEach((el) => el.classList.add("is-in"));
      flips.forEach((el) => el.classList.add("is-settled"));
      return;
    }

    const timers = [];

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;

          const el = entry.target;
          el.classList.add("is-in");

          if (el.hasAttribute("data-flip")) {
            const stagger =
              parseInt(el.style.getPropertyValue("--flip-delay"), 10) || 0;
            timers.push(
              window.setTimeout(() => el.classList.add("is-settled"), stagger + 800)
            );
          }

          io.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.05 }
    );

    targets.forEach((el) => io.observe(el));

    return () => {
      io.disconnect();
      timers.forEach((t) => window.clearTimeout(t));
    };
  }, []);

  return (
    <div className="bg-bg text-fg font-sans text-[17px] leading-[1.6] max-[640px]:text-[16px] antialiased overflow-x-clip">
      <Nav />
      <main>
        <Hero />
        <BentoGrid />
        <Reads />
        <Specs />
        <Statement />
        <Install />
        <Statement force />
        <FAQ />
      </main>
      <Footer />
    </div>
  );
}
