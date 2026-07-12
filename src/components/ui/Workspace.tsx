import type { ReactNode } from "react";

import { Stack } from "./Stack";

type RailWidth = 240 | 280 | 320;

const RAIL_COLS: Record<RailWidth, { start: string; end: string }> = {
  240: {
    start: "lg:grid-cols-[240px_minmax(0,1fr)]",
    end: "lg:grid-cols-[minmax(0,1fr)_240px]",
  },
  280: {
    start: "lg:grid-cols-[280px_minmax(0,1fr)]",
    end: "lg:grid-cols-[minmax(0,1fr)_280px]",
  },
  320: {
    start: "lg:grid-cols-[320px_minmax(0,1fr)]",
    end: "lg:grid-cols-[minmax(0,1fr)_320px]",
  },
};

/**
 * Two-pane feature layout. Swap `railPosition` or reorder `WorkspaceMain`
 * children without restyling feature panels.
 */
export function Workspace({
  rail,
  main,
  railWidth = 280,
  railPosition = "start",
  className = "",
}: {
  rail: ReactNode;
  main: ReactNode;
  railWidth?: RailWidth;
  railPosition?: "start" | "end";
  className?: string;
}) {
  const cols = RAIL_COLS[railWidth][railPosition];

  return (
    <div
      className={`flex flex-col gap-4 lg:grid lg:items-start ${cols} ${className}`.trim()}
    >
      {railPosition === "start" ? (
        <>
          {rail}
          <div className="min-w-0">{main}</div>
        </>
      ) : (
        <>
          <div className="min-w-0">{main}</div>
          {rail}
        </>
      )}
    </div>
  );
}

/** Vertical stack for the main pane — reorder children freely. */
export function WorkspaceMain({
  children,
  gap = 16,
}: {
  children: ReactNode;
  gap?: 8 | 12 | 16 | 24;
}) {
  return <Stack gap={gap}>{children}</Stack>;
}

/** Responsive card grid for variants / comparable panels. */
export function CardGrid({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`grid gap-3 md:grid-cols-2 xl:grid-cols-3 ${className}`.trim()}
    >
      {children}
    </div>
  );
}
