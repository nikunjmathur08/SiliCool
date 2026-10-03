import { useEffect } from "react";
import { useLocation } from "react-router-dom";
import Hero from "../components/Hero";
import BentoGrid from "../components/BentoGrid";
import { Reads, Specs, Statement, Safety, Install } from "../components/Sections";
import FAQ from "../components/FAQ";

export default function Home() {
  const location = useLocation();

  useEffect(() => {
    // Handle intersection observer
    const targets = document.querySelectorAll(".js-reveal, [data-flip]");
    const flips = document.querySelectorAll("[data-flip]");

    if (
      matchMedia("(prefers-reduced-motion: reduce)").matches ||
      !("IntersectionObserver" in window)
    ) {
      targets.forEach((el) => el.classList.add("is-in"));
      flips.forEach((el) => el.classList.add("is-settled"));
    } else {
      const timers = [];
      const io = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            const el = entry.target;
            el.classList.add("is-in");
            if (el.hasAttribute("data-flip")) {
              const stagger = parseInt(el.style.getPropertyValue("--flip-delay"), 10) || 0;
              timers.push(window.setTimeout(() => el.classList.add("is-settled"), stagger + 800));
            }
            io.unobserve(el);
          });
        },
        { rootMargin: "0px 0px -8% 0px", threshold: 0.05 }
      );
      targets.forEach((el) => io.observe(el));
      
      // Cleanup
      return () => {
        io.disconnect();
        timers.forEach((t) => window.clearTimeout(t));
      };
    }
  }, []);

  useEffect(() => {
    // Scroll to section based on pathname
    const path = location.pathname;
    if (path === "/design" || path === "/specs" || path === "/faq" || path === "/reads" || path === "/install") {
      const id = path.substring(1);
      const element = document.getElementById(id);
      if (element) {
        element.scrollIntoView({ behavior: "smooth" });
      }
    } else if (path === "/") {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }, [location.pathname]);

  return (
    <main>
      <Hero />
      <BentoGrid />
      <Reads />
      <Specs />
      <Statement />
      <Statement force />
      <Safety />
      <Install />
      <FAQ />
    </main>
  );
}
