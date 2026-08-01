import { describe, expect, it } from "vitest";

import {
  elementFromSubclass,
  loadoutAccentColor,
  subclassNameFromBuildSubclass,
} from "./identityVisuals";

describe("elementFromSubclass", () => {
  it("maps known subclasses to elements", () => {
    expect(elementFromSubclass("Sunbreaker")).toBe("Solar");
    expect(elementFromSubclass("Nightstalker")).toBe("Void");
    expect(elementFromSubclass("Stormcaller")).toBe("Arc");
  });

  it("falls back for unknown", () => {
    expect(elementFromSubclass("Unknown Sub")).toBe("Kinetic");
  });
});

describe("subclassNameFromBuildSubclass", () => {
  it("reads name from object or string", () => {
    expect(subclassNameFromBuildSubclass({ name: "Sunbreaker" })).toBe(
      "Sunbreaker",
    );
    expect(subclassNameFromBuildSubclass("Striker")).toBe("Striker");
  });
});

describe("loadoutAccentColor", () => {
  it("is stable for the same seed", () => {
    expect(loadoutAccentColor("Pyre")).toBe(loadoutAccentColor("Pyre"));
  });
});
