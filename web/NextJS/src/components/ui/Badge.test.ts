import { describe, expect, it } from "vitest";

import { badgeToneClass } from "./Badge";

describe("badgeToneClass", () => {
  it("maps design tones to globals.css modifiers", () => {
    expect(badgeToneClass("verified")).toBe("badge-verified");
    expect(badgeToneClass("accent")).toBe("badge-accent");
    expect(badgeToneClass("fuzzy")).toBe("badge-fuzzy");
    expect(badgeToneClass("unresolved")).toBe("badge-unresolved");
    expect(badgeToneClass("illegal")).toBe("badge-illegal");
  });

  it("aliases warning→fuzzy and danger→illegal wash tokens", () => {
    expect(badgeToneClass("warning")).toBe("badge-fuzzy");
    expect(badgeToneClass("danger")).toBe("badge-illegal");
  });
});
