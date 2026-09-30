export default function Container({
  children,
  className = "",
  size = "default",
}) {
  const sizes = {
    default: "max-w-6xl",
    narrow: "max-w-3xl",
    wide: "max-w-7xl",
  };

  return (
    <div
      className={`mx-auto w-full px-6 sm:px-8 ${sizes[size]} ${className}`}
    >
      {children}
    </div>
  );
}