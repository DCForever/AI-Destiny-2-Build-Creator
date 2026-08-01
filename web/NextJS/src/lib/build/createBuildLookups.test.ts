import { describe, expect, it } from "vitest";

import {
  defaultSubclassForClass,
  isValidSubclassForClass,
  pinnedSuperAfterSubclassChange,
  subclassAfterClassChange,
  subclassesForClass,
} from "./createBuildLookups";

describe("createBuildLookups", () => {
  it("lists subclasses per class", () => {
    expect(subclassesForClass("Titan")).toContain("Sunbreaker");
    expect(subclassesForClass("Hunter")).toContain("Gunslinger");
    expect(subclassesForClass("Warlock")).toContain("Dawnblade");
  });

  it("defaults to first subclass for class", () => {
    expect(defaultSubclassForClass("Titan")).toBe(subclassesForClass("Titan")[0]);
  });

  it("rejects free-form subclass names", () => {
    expect(isValidSubclassForClass("Titan", "Sunbreaker")).toBe(true);
    expect(isValidSubclassForClass("Titan", "Gunslinger")).toBe(false);
    expect(isValidSubclassForClass("Titan", "My Cool Subclass")).toBe(false);
  });

  it("resets subclass when class change makes it invalid", () => {
    expect(subclassAfterClassChange("Hunter", "Sunbreaker")).toBe(
      defaultSubclassForClass("Hunter"),
    );
    expect(subclassAfterClassChange("Titan", "Sunbreaker")).toBe("Sunbreaker");
  });

  it("clears pinned super when subclass changes", () => {
    expect(pinnedSuperAfterSubclassChange("Sunbreaker", "Striker", "Hammer of Sol")).toBeNull();
    expect(pinnedSuperAfterSubclassChange("Sunbreaker", "Sunbreaker", "Hammer of Sol")).toBe(
      "Hammer of Sol",
    );
  });
});
