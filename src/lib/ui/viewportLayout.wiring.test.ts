import { readFileSync } from "node:fs";
import path from "node:path";

import { describe, expect, it } from "vitest";

/**
 * Structural check: shared layout primitives consume the viewport contract
 * (not ad-hoc max-heights that drift from the testable module).
 */
function readSrc(rel: string): string {
  return readFileSync(path.join(process.cwd(), rel), "utf8");
}

describe("viewport layout wiring", () => {
  it("Workspace uses shared rail/main/root class contract + master–detail focus", () => {
    const src = readSrc("src/components/ui/Workspace.tsx");
    expect(src).toContain("@/lib/ui/viewportLayout");
    expect(src).toContain("WORKSPACE_ROOT_CLASSES");
    expect(src).toContain("workspaceRailBoxClasses");
    expect(src).toContain("workspaceMainBoxClasses");
    expect(src).toContain("focusMain");
    expect(src).toContain("WORKSPACE_BACK_TO_LIBRARY_CLASSES");
  });

  it("Sets/Build/Synergy pass focusMain so library collapses on narrow detail", () => {
    for (const rel of [
      "src/components/sets/SetsPage.tsx",
      "src/components/build/BuildPage.tsx",
      "src/components/synergy/SynergyPage.tsx",
    ]) {
      const src = readSrc(rel);
      expect(src).toContain("focusMain=");
      expect(src).toContain("onBackToLibrary");
    }
  });

  it("PageFrame chrome uses height-capped scroll contract", () => {
    const src = readSrc("src/components/ui/PageFrame.tsx");
    expect(src).toContain("@/lib/ui/viewportLayout");
    expect(src).toContain("PAGE_FRAME_CHROME_CLASSES");
    expect(src).toContain("PAGE_FRAME_ROOT_CLASSES");
  });

  it("AppShell locks document height via shared shell classes", () => {
    const src = readSrc("src/components/AppShell.tsx");
    expect(src).toContain("APP_SHELL_ROOT_CLASSES");
    expect(src).toContain("APP_SHELL_MAIN_CLASSES");
  });

  it("Catalog embed chrome uses shared embedded chrome classes", () => {
    const src = readSrc("src/components/catalog/CatalogScreen.tsx");
    expect(src).toContain("EMBEDDED_CATALOG_CHROME_CLASSES");
    expect(src).toContain("basis-0");
  });

  it("CatalogScreen uses master-detail helpers + collapsible secondary filters", () => {
    const src = readSrc("src/components/catalog/CatalogScreen.tsx");
    expect(src).toContain("catalogBodyRootClasses");
    expect(src).toContain("catalogResultsPaneClasses");
    expect(src).toContain("catalogDetailPaneClasses");
    expect(src).toContain("CATALOG_BACK_TO_RESULTS_CLASSES");
    expect(src).toContain("filtersOpen");
    expect(src).toContain("useState(false)");
    expect(src).toContain("filtersOpen");
    expect(src).toContain("Results");
    // Body uses master-detail helpers, not dual-pane <Workspace .../>
    expect(src).not.toContain("<Workspace ");
    expect(src).not.toContain("<Workspace\n");
    expect(src).toContain("WorkspaceMain");
  });

  it("Set-fill omits Sets chrome + library rail (single Catalog pane)", () => {
    const sets = readSrc("src/components/sets/SetsPage.tsx");
    expect(sets).toContain("Set-fill: single full-pane Catalog");
    const start = sets.indexOf("if (fillSlot && detail)");
    expect(start).toBeGreaterThanOrEqual(0);
    const afterFill = sets.slice(start).replace(/\r\n/g, "\n");
    const endRel = afterFill.indexOf("\n  return (\n    <PageFrame>");
    const fillBlock =
      endRel >= 0 ? afterFill.slice(0, endRel) : afterFill.slice(0, 800);
    expect(fillBlock).toContain("SlotFillPanel");
    expect(fillBlock).not.toContain("SetsLibrary");
    expect(fillBlock).not.toContain("PageFrameChrome");
    expect(fillBlock).not.toContain("<Workspace");
  });

  it("Sets fill pane + SlotFillPanel preserve min-h-0 overflow chain", () => {
    const sets = readSrc("src/components/sets/SetsPage.tsx");
    const fill = readSrc("src/components/sets/SlotFillPanel.tsx");
    expect(sets).toContain("flex-1 min-h-0 overflow-hidden");
    expect(fill).toContain("h-full min-h-0 flex flex-col");
    expect(fill).toContain("flex-1 min-h-0 overflow-hidden");
  });

  it("BuildLibrary keeps shrink-0 filters + flex-1 scroll list under rail height", () => {
    const lib = readSrc("src/components/build/BuildLibrary.tsx");
    expect(lib).toContain("h-full min-h-0 flex flex-col overflow-hidden");
    expect(lib).toContain("shrink-0");
    expect(lib).toContain("flex-1 min-h-0 overflow-y-auto");
  });
});
