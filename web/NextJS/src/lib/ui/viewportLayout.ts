/**
 * Shared narrow/wide viewport layout contract for product dual-pane screens.
 *
 * Breakpoint: Tailwind `lg` (1024px). Below: stacked rail + main.
 * Above: CSS grid dual-pane with independent full-height scroll regions.
 *
 * These class strings are the single source of truth — Workspace/PageFrame
 * import them so unit tests can assert the responsive contract without a browser.
 */

/** Tailwind prefix for dual-pane (matches Workspace grid). */
export const VIEWPORT_DUAL_PANE_BREAKPOINT = "lg" as const;

/**
 * Stacked mobile: **definite** rail height (not only max-h) so inner library
 * panels (shrink-0 filters + flex-1 list) get a real flex container height.
 * 40dvh leaves ~60% for main; no tight rem floor that clips dense filters.
 * Desktop: fill grid cell; overflow hidden so list scrolls inside the rail.
 *
 * Prefer {@link workspaceRailBoxClasses} when the page has master–detail focus
 * (library collapses below lg while a detail is open).
 */
export const WORKSPACE_RAIL_BOX_CLASSES =
  "min-h-0 min-w-0 shrink-0 h-[40dvh] max-h-[40dvh] overflow-hidden lg:h-full lg:max-h-none lg:flex lg:flex-col";

/**
 * Main pane takes remaining height on stack; full height in dual-pane grid.
 */
export const WORKSPACE_MAIN_BOX_CLASSES =
  "min-h-0 min-w-0 overflow-hidden flex-1 basis-0 lg:h-full lg:flex lg:flex-col";

/** Root workspace: column stack below lg, grid at lg+. */
export const WORKSPACE_ROOT_CLASSES =
  "h-full min-h-0 flex flex-col gap-2 lg:gap-4 lg:grid lg:items-stretch";

/**
 * Library rail allocation for Workspace master–detail.
 * - No detail focused: rail uses full stack height below lg (list is primary).
 * - Detail focused: rail **hidden** below lg; dual-pane rail at lg+.
 */
export function workspaceRailBoxClasses(focusMain: boolean): string {
  if (!focusMain) {
    return "min-h-0 min-w-0 flex-1 basis-0 overflow-hidden flex flex-col h-full lg:h-full lg:max-h-none lg:flex-none lg:shrink-0";
  }
  return "min-h-0 min-w-0 overflow-hidden hidden lg:flex lg:flex-col lg:h-full";
}

/**
 * Main pane allocation for Workspace master–detail.
 * - No detail focused: hide empty/main chrome below lg so library owns the column.
 * - Detail focused: main fills the stack below lg.
 */
export function workspaceMainBoxClasses(focusMain: boolean): string {
  if (!focusMain) {
    return "min-h-0 min-w-0 overflow-hidden hidden lg:flex lg:flex-col lg:h-full lg:flex-1 lg:basis-0";
  }
  return "min-h-0 min-w-0 overflow-hidden flex-1 basis-0 flex flex-col h-full lg:h-full";
}

/** Back control for library master–detail (visible only below lg). */
export const WORKSPACE_BACK_TO_LIBRARY_CLASSES = "shrink-0 lg:hidden mb-2";

/**
 * Page filter/title chrome: scrollable + height-capped on narrow viewports so
 * lists/detail stay usable; unconstrained on desktop.
 * (Not used during set-fill — that mode omits page chrome entirely.)
 */
export const PAGE_FRAME_CHROME_CLASSES =
  "shrink-0 max-h-[min(28dvh,12rem)] overflow-y-auto overscroll-contain lg:max-h-none lg:overflow-visible";

/**
 * Catalog / set-fill embedded chrome only (single chrome layer in fill mode).
 * Kept modest so catalog results+detail remain the primary scroll surfaces.
 */
export const EMBEDDED_CATALOG_CHROME_CLASSES =
  "shrink-0 max-h-[min(28dvh,11rem)] overflow-y-auto overscroll-contain pb-2";

/**
 * Minimum fraction of stacked rail height reserved for the scrollable list
 * after shrink-0 filter chrome (used by dense-rail tests / documentation).
 * 40dvh rail × 0.25 ≈ list still visible with tall filter chrome.
 */
export const WORKSPACE_RAIL_LIST_MIN_FRACTION = 0.25;

/** Document must not grow; shell owns height. */
export const APP_SHELL_ROOT_CLASSES =
  "flex flex-col h-dvh max-h-dvh overflow-hidden";

export const APP_SHELL_MAIN_CLASSES =
  "flex-1 min-h-0 overflow-hidden flex flex-col";

export const PAGE_FRAME_ROOT_CLASSES =
  "h-full min-h-0 flex flex-col w-full mx-auto px-2 sm:px-6 py-2 sm:py-4";

/**
 * Catalog body: master–detail below lg / when no selection (list uses full body).
 * Dual-pane only at lg+ **and** an item is selected.
 */
export function catalogBodyRootClasses(hasSelection: boolean): string {
  if (!hasSelection) {
    return "h-full min-h-0 flex flex-col";
  }
  return "h-full min-h-0 flex flex-col gap-2 lg:gap-4 lg:grid lg:grid-cols-[minmax(14rem,20rem)_minmax(0,1fr)] lg:items-stretch";
}

/** Results list pane allocation for Catalog body. */
export function catalogResultsPaneClasses(hasSelection: boolean): string {
  if (!hasSelection) {
    // Full body — no empty detail pane stealing width/height
    return "min-h-0 min-w-0 flex-1 basis-0 overflow-hidden flex flex-col h-full";
  }
  // Selected: hide list below lg (detail-only); rail on lg+
  return "min-h-0 min-w-0 overflow-hidden hidden lg:flex lg:flex-col lg:h-full";
}

/** Detail pane — only mounted/shown when an item is selected. */
export function catalogDetailPaneClasses(): string {
  return "min-h-0 min-w-0 flex-1 basis-0 overflow-hidden flex flex-col h-full";
}

/** Back control for master–detail (visible only below lg). */
export const CATALOG_BACK_TO_RESULTS_CLASSES = WORKSPACE_BACK_TO_LIBRARY_CLASSES;
