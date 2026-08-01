import { describe, expect, it } from "vitest";

import { CLASS_ICON_PATH, classIconPath } from "./classIcons";

describe("classIcons", () => {
  it("maps every guardian class to a public destiny-icons path", () => {
    for (const c of ["Titan", "Hunter", "Warlock"] as const) {
      expect(CLASS_ICON_PATH[c]).toMatch(
        /^\/destiny-icons\/general\/class_.+\.svg$/,
      );
      expect(classIconPath(c)).toBe(CLASS_ICON_PATH[c]);
    }
  });

  it("resolves case-insensitive labels and rejects unknown", () => {
    expect(classIconPath("hunter")).toBe(CLASS_ICON_PATH.Hunter);
    expect(classIconPath(null)).toBeNull();
    expect(classIconPath("unknown")).toBeNull();
  });
});
