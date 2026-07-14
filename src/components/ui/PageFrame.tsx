import type { ReactNode } from "react";

import {
  PAGE_FRAME_CHROME_CLASSES,
  PAGE_FRAME_ROOT_CLASSES,
} from "@/lib/ui/viewportLayout";

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
  const max = width === "narrow" ? "max-w-3xl" : "max-w-[1600px]";
  return (
    <div
      className={`${PAGE_FRAME_ROOT_CLASSES} ${max} ${className}`.trim()}
    >
      {children}
    </div>
  );
}

/**
 * Page title/filters. Height-capped + scrollable below lg so list/detail
 * panes keep a usable share of the viewport on phones.
 */
export function PageFrameChrome({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`${PAGE_FRAME_CHROME_CLASSES} ${className}`.trim()}>
      {children}
    </div>
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
      className={`flex-1 min-h-0 ${scroll ? "overflow-y-auto overscroll-contain" : "overflow-hidden"} ${className}`.trim()}
    >
      {children}
    </div>
  );
}
