const STRIP_COUNT = 42;

const stripMods = (i, total) => {
  const edge = Math.min(i, total - 1 - i);
  const mods = [];

  if (edge >= 15) mods.push("hidden min-[1080px]:block");
  if (edge >= 20) mods.push("hidden min-[1680px]:block");
  if (edge < 15 && i % 5 === 2) mods.push("max-[700px]:hidden");
  if (i % 7 === 3) mods.push("mr-[var(--sg)]");

  return mods.join(" ");
};

export const frostStrips = Array.from({ length: STRIP_COUNT }, (_, i) => {
  const bell = Math.sin((Math.PI * i) / (STRIP_COUNT - 1));
  const wobble = 0.5 + 0.5 * Math.abs(Math.sin(i * 2.7));
  const shimmer = 0.58 + 0.42 * Math.abs(Math.cos(i * 1.9));

  return {
    i,
    h: Math.round(18 + 80 * bell * wobble),
    o: Number((0.12 + 0.66 * bell * shimmer).toFixed(2)),
    mods: stripMods(i, STRIP_COUNT),
  };
});
