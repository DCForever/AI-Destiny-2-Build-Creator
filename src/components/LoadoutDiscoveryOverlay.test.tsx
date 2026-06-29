import { describe, expect, it } from "vitest";

import { discoveryOverlayTitle } from "./LoadoutDiscoveryOverlay";

describe("LoadoutDiscoveryOverlay", () => {
  it("formats title with match count", () => {
    expect(discoveryOverlayTitle("Loadouts with Crown of Tempests", 2)).toBe(
      "Loadouts with Crown of Tempests (2)",
    );
  });

  it("formats empty overlay title", () => {
    expect(discoveryOverlayTitle("Loadouts with Crown of Tempests", 0)).toBe(
      "Loadouts with Crown of Tempests — no other matches",
    );
  });
});
