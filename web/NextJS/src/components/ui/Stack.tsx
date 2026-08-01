import type { CSSProperties, ReactNode } from "react";

const GAP: Record<number, string> = {
  0: "gap-0",
  2: "gap-0.5",
  4: "gap-1",
  6: "gap-1.5",
  8: "gap-2",
  10: "gap-2.5",
  12: "gap-3",
  16: "gap-4",
  24: "gap-6",
};

type Gap = keyof typeof GAP;

export function Stack({
  children,
  gap = 12,
  className = "",
}: {
  children: ReactNode;
  gap?: Gap;
  className?: string;
}) {
  return (
    <div className={`flex flex-col ${GAP[gap]} ${className}`.trim()}>
      {children}
    </div>
  );
}

export function Row({
  children,
  gap = 8,
  align = "center",
  justify = "start",
  wrap = false,
  className = "",
}: {
  children: ReactNode;
  gap?: Gap;
  align?: "start" | "center" | "end" | "baseline" | "stretch";
  justify?: "start" | "center" | "end" | "between";
  wrap?: boolean;
  className?: string;
}) {
  const alignClass = {
    start: "items-start",
    center: "items-center",
    end: "items-end",
    baseline: "items-baseline",
    stretch: "items-stretch",
  }[align];
  const justifyClass = {
    start: "justify-start",
    center: "justify-center",
    end: "justify-end",
    between: "justify-between",
  }[justify];

  return (
    <div
      className={`flex ${alignClass} ${justifyClass} ${GAP[gap]} ${
        wrap ? "flex-wrap" : ""
      } ${className}`.trim()}
    >
      {children}
    </div>
  );
}

/** Wrapping chip/button cluster. */
export function Cluster({
  children,
  gap = 6,
  className = "",
  style,
}: {
  children: ReactNode;
  gap?: Gap;
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <div
      className={`flex flex-wrap ${GAP[gap]} ${className}`.trim()}
      style={style}
    >
      {children}
    </div>
  );
}
