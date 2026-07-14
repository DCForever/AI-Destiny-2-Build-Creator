import type { ReactNode } from "react";

import {
  WORKSPACE_MAIN_BOX_CLASSES,
  WORKSPACE_RAIL_BOX_CLASSES,
  WORKSPACE_ROOT_CLASSES,
} from "@/lib/ui/viewportLayout";

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
 * Two-pane feature layout sized by the parent (viewport frame), not content.
 *
 * Desktop (lg+): grid fills height; rail and main scroll independently.
 * Narrow: stacked column; rail height-capped; main flex-1 min-h-0 for usable scroll.
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
      className={`${WORKSPACE_ROOT_CLASSES} ${cols} ${className}`.trim()}
    >
      {railPosition === "start" ? (
        <>
          <div className={WORKSPACE_RAIL_BOX_CLASSES}>{rail}</div>
          <div className={WORKSPACE_MAIN_BOX_CLASSES}>{main}</div>
        </>
      ) : (
        <>
          <div className={WORKSPACE_MAIN_BOX_CLASSES}>{main}</div>
          <div className={WORKSPACE_RAIL_BOX_CLASSES}>{rail}</div>
        </>
      )}
    </div>
  );
}

/**
 * Vertical stack for the main pane. Use inside a height-locked parent with
 * overflow-y-auto on this element (or a child scroll region).
 */
export function WorkspaceMain({
  children,
  gap = 16,
  className = "",
  scroll = true,
}: {
  children: ReactNode;
  gap?: 8 | 12 | 16 | 24;
  className?: string;
  /** When true (default), this pane scrolls within the workspace. */
  scroll?: boolean;
}) {
  return (
    <div
      className={`h-full min-h-0 ${scroll ? "overflow-y-auto overscroll-contain" : "overflow-hidden"} ${className}`.trim()}
    >
      <Stack gap={gap}>{children}</Stack>
    </div>
  );
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
