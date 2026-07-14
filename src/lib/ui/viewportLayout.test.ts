import { describe, expect, it } from "vitest";

import {
  APP_SHELL_MAIN_CLASSES,
  APP_SHELL_ROOT_CLASSES,
  EMBEDDED_CATALOG_CHROME_CLASSES,
  PAGE_FRAME_CHROME_CLASSES,
  PAGE_FRAME_ROOT_CLASSES,
  VIEWPORT_DUAL_PANE_BREAKPOINT,
  WORKSPACE_BACK_TO_LIBRARY_CLASSES,
  WORKSPACE_MAIN_BOX_CLASSES,
  WORKSPACE_RAIL_BOX_CLASSES,
  WORKSPACE_RAIL_LIST_MIN_FRACTION,
  WORKSPACE_ROOT_CLASSES,
  catalogBodyRootClasses,
  catalogDetailPaneClasses,
  catalogResultsPaneClasses,
  workspaceMainBoxClasses,
  workspaceRailBoxClasses,
} from "@/lib/ui/viewportLayout";

/**
 * Model a dense library rail: shrink-0 filter chrome + flex-1 list.
 * Mirrors BuildLibrary structure under WORKSPACE_RAIL_BOX_CLASSES height.
 */
function listHeightFraction(railHeightPx: number, filterChromePx: number): number {
  const list = Math.max(0, railHeightPx - filterChromePx);
  return list / railHeightPx;
}

describe("viewportLayout contract", () => {
  it("uses lg as the dual-pane breakpoint", () => {
    expect(VIEWPORT_DUAL_PANE_BREAKPOINT).toBe("lg");
    expect(WORKSPACE_ROOT_CLASSES).toContain("lg:grid");
    expect(WORKSPACE_RAIL_BOX_CLASSES).toContain("lg:h-full");
    expect(WORKSPACE_MAIN_BOX_CLASSES).toContain("lg:h-full");
    expect(PAGE_FRAME_CHROME_CLASSES).toContain("lg:max-h-none");
  });

  it("gives stacked rail a definite height so flex lists work", () => {
    expect(WORKSPACE_ROOT_CLASSES).toMatch(/flex flex-col/);
    expect(WORKSPACE_RAIL_BOX_CLASSES).toMatch(/\bh-\[40dvh\]/);
    expect(WORKSPACE_RAIL_BOX_CLASSES).toMatch(/max-h-\[40dvh\]/);
    expect(WORKSPACE_RAIL_BOX_CLASSES).toMatch(/overflow-hidden/);
    expect(WORKSPACE_RAIL_BOX_CLASSES).not.toMatch(/12rem/);
  });

  it("keeps list usable under dense filter chrome at 40dvh rail height", () => {
    const railPx = 267;
    const denseFiltersPx = 160;
    const fraction = listHeightFraction(railPx, denseFiltersPx);
    expect(fraction).toBeGreaterThanOrEqual(WORKSPACE_RAIL_LIST_MIN_FRACTION);
    const brokenRailPx = 156;
    expect(listHeightFraction(brokenRailPx, denseFiltersPx)).toBe(0);
  });

  it("gives main pane flex-1 min-h-0 so it can scroll on narrow stacks", () => {
    expect(WORKSPACE_MAIN_BOX_CLASSES).toMatch(/flex-1/);
    expect(WORKSPACE_MAIN_BOX_CLASSES).toMatch(/min-h-0/);
    expect(WORKSPACE_MAIN_BOX_CLASSES).toMatch(/overflow-hidden/);
    expect(WORKSPACE_MAIN_BOX_CLASSES).toMatch(/basis-0/);
  });

  it("caps page and embedded chrome height on small screens", () => {
    expect(PAGE_FRAME_CHROME_CLASSES).toMatch(/max-h-\[/);
    expect(PAGE_FRAME_CHROME_CLASSES).toMatch(/overflow-y-auto/);
    expect(EMBEDDED_CATALOG_CHROME_CLASSES).toMatch(/max-h-\[/);
    expect(EMBEDDED_CATALOG_CHROME_CLASSES).toMatch(/overflow-y-auto/);
  });

  it("locks app shell and page frame to viewport height without document growth", () => {
    expect(APP_SHELL_ROOT_CLASSES).toMatch(/h-dvh|max-h-dvh/);
    expect(APP_SHELL_ROOT_CLASSES).toMatch(/overflow-hidden/);
    expect(APP_SHELL_MAIN_CLASSES).toMatch(/min-h-0/);
    expect(APP_SHELL_MAIN_CLASSES).toMatch(/overflow-hidden/);
    expect(PAGE_FRAME_ROOT_CLASSES).toMatch(/h-full/);
    expect(PAGE_FRAME_ROOT_CLASSES).toMatch(/min-h-0/);
    expect(PAGE_FRAME_ROOT_CLASSES).toMatch(/flex flex-col/);
  });

  it("Catalog master–detail: no selection expands results; dual-pane only when selected at lg+", () => {
    const emptyRoot = catalogBodyRootClasses(false);
    const selectedRoot = catalogBodyRootClasses(true);
    expect(emptyRoot).toMatch(/flex flex-col/);
    expect(emptyRoot).not.toMatch(/lg:grid/);
    expect(selectedRoot).toMatch(/lg:grid/);
    expect(selectedRoot).toMatch(/lg:grid-cols-/);

    const resultsEmpty = catalogResultsPaneClasses(false);
    const resultsSelected = catalogResultsPaneClasses(true);
    expect(resultsEmpty).toMatch(/flex-1/);
    // Must not use display:none class when empty (overflow-hidden is OK)
    expect(resultsEmpty.split(/\s+/)).not.toContain("hidden");
    // Selected: list hidden below lg so detail gets the body
    expect(resultsSelected.split(/\s+/)).toContain("hidden");
    expect(resultsSelected).toMatch(/lg:flex/);

    const detail = catalogDetailPaneClasses();
    expect(detail).toMatch(/flex-1/);
    expect(detail).toMatch(/min-h-0/);
  });

  it("fails if results pane always forces dual split with empty detail", () => {
    // Regression: always dual-pane Workspace left empty detail stealing half body
    const resultsWhenEmpty = catalogResultsPaneClasses(false);
    expect(resultsWhenEmpty).toMatch(/flex-1/);
    expect(resultsWhenEmpty.split(/\s+/)).not.toContain("hidden");
    expect(catalogBodyRootClasses(false)).not.toContain("lg:grid");
  });

  it("Workspace master–detail: library collapses below lg when focusMain", () => {
    const railBrowse = workspaceRailBoxClasses(false);
    const railDetail = workspaceRailBoxClasses(true);
    const mainBrowse = workspaceMainBoxClasses(false);
    const mainDetail = workspaceMainBoxClasses(true);

    // Browse: rail fills column; main hidden on narrow
    expect(railBrowse.split(/\s+/)).not.toContain("hidden");
    expect(railBrowse).toMatch(/flex-1/);
    expect(mainBrowse.split(/\s+/)).toContain("hidden");
    expect(mainBrowse).toMatch(/lg:flex/);

    // Detail: rail hidden on narrow; main fills column
    expect(railDetail.split(/\s+/)).toContain("hidden");
    expect(railDetail).toMatch(/lg:flex/);
    expect(mainDetail.split(/\s+/)).not.toContain("hidden");
    expect(mainDetail).toMatch(/flex-1/);

    expect(WORKSPACE_BACK_TO_LIBRARY_CLASSES).toMatch(/lg:hidden/);
  });
});

