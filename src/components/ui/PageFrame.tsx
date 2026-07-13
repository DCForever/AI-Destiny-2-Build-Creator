import type { ReactNode } from "react";

/**
 * Viewport-stable page shell under AppShell main.
 * Fills remaining height; chrome (header/filters) should be shrink-0,
 * body flex-1 min-h-0 so content scrolls without resizing the frame.
 */
export function PageFrame({
  children,
  className = "",
  /** max-w-[1600px] product default; Settings uses narrow. */
  width = "wide",
}: {
  children: ReactNode;
  className?: string;
  width?: "wide" | "narrow";
}) {
  const max =
    width === "narrow" ? "max-w-3xl" : "max-w-[1600px]";
  return (
    <div
      className={`h-full min-h-0 flex flex-col w-full ${max} mx-auto px-3 sm:px-6 py-3 sm:py-4 ${className}`.trim()}
    >
      {children}
    </div>
  );
}

/** Non-scrolling chrome at top of PageFrame (title, filters). */
export function PageFrameChrome({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`shrink-0 ${className}`.trim()}>{children}</div>
  );
}

/**
 * Fills remaining PageFrame height. Prefer overflow-hidden + inner scroll
 * for dual-pane; overflow-y-auto for single-column pages.
 */
export function PageFrameBody({
  children,
  className = "",
  scroll = false,
}: {
  children: ReactNode;
  className?: string;
  /** When true, this region scrolls (settings / loadouts). */
  scroll?: boolean;
}) {
  return (
    <div
      className={`flex-1 min-h-0 ${scroll ? "overflow-y-auto" : "overflow-hidden"} ${className}`.trim()}
    >
      {children}
    </div>
  );
}
