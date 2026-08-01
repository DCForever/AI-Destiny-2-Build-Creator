import type { ReactNode } from "react";

import {
  WORKSPACE_BACK_TO_LIBRARY_CLASSES,
  WORKSPACE_ROOT_CLASSES,
  workspaceMainBoxClasses,
  workspaceRailBoxClasses,
} from "@/lib/ui/viewportLayout";

import { Button } from "./Button";
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
 * Narrow + no selection: library rail owns the column (main hidden).
 * Narrow + detail focused (`focusMain`): library collapses; main is full height
 * with an optional back-to-library control (same contract as Catalog).
 */
export function Workspace({
  rail,
  main,
  railWidth = 280,
  railPosition = "start",
  focusMain = false,
  onBackToLibrary,
  backLabel = "Back to library",
  className = "",
}: {
  rail: ReactNode;
  main: ReactNode;
  railWidth?: RailWidth;
  railPosition?: "start" | "end";
  /**
   * When true, narrow viewports hide the library and show main only.
   * When false, narrow viewports hide main empty chrome and show library only.
   */
  focusMain?: boolean;
  /** Called from the narrow-only back control when `focusMain` is true. */
  onBackToLibrary?: () => void;
  backLabel?: string;
  className?: string;
}) {
  const cols = RAIL_COLS[railWidth][railPosition];
  const railBox = workspaceRailBoxClasses(focusMain);
  const mainBox = workspaceMainBoxClasses(focusMain);

  const mainContent =
    focusMain && onBackToLibrary ? (
      <div className="h-full min-h-0 flex flex-col overflow-hidden">
        <div className={WORKSPACE_BACK_TO_LIBRARY_CLASSES}>
          <Button size="sm" variant="ghost" onClick={onBackToLibrary}>
            ← {backLabel}
          </Button>
        </div>
        <div className="flex-1 min-h-0 overflow-hidden">{main}</div>
      </div>
    ) : (
      main
    );

  return (
    <div
      className={`${WORKSPACE_ROOT_CLASSES} ${cols} ${className}`.trim()}
    >
      {railPosition === "start" ? (
        <>
          <div className={railBox}>{rail}</div>
          <div className={mainBox}>{mainContent}</div>
        </>
      ) : (
        <>
          <div className={mainBox}>{mainContent}</div>
          <div className={railBox}>{rail}</div>
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
  gap = 12,
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
      className={`grid gap-2 md:grid-cols-2 xl:grid-cols-3 ${className}`.trim()}
    >
      {children}
    </div>
  );
}

