import { Routes, Route } from "react-router-dom";
import Nav from "./components/Nav";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import Privacy from "./pages/Privacy";
import Terms from "./pages/Terms";
import NotFound from "./pages/NotFound";

export default function App() {
  return (
    <div className="bg-bg text-fg font-sans text-[17px] leading-[1.6] max-[640px]:text-[16px] antialiased overflow-x-clip">
      <Nav />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/design" element={<Home />} />
        <Route path="/specs" element={<Home />} />
        <Route path="/faq" element={<Home />} />
        <Route path="/reads" element={<Home />} />
        <Route path="/install" element={<Home />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
      <Footer />
    </div>
  );
}
