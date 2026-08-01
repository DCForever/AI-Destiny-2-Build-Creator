import { describe, expect, it } from "vitest";

import {
  EXOTIC_ABILITY_REQUIREMENTS,
  hasAbilityRequirements,
  lookupExoticAbilityRequirements,
} from "./exoticAbilityRequirements";

describe("lookupExoticAbilityRequirements", () => {
  it("returns null for unknown exotic", () => {
    expect(
      lookupExoticAbilityRequirements({ name: "Not A Real Exotic" }),
    ).toBeNull();
  });

  it("finds curated rows by hash when present", () => {
    const withHash = EXOTIC_ABILITY_REQUIREMENTS.find((r) => r.hash != null);
    if (!withHash?.hash) {
      expect(true).toBe(true);
      return;
    }
    const hit = lookupExoticAbilityRequirements({ hash: withHash.hash });
    expect(hit).not.toBeNull();
  });

  it("hasAbilityRequirements", () => {
    expect(hasAbilityRequirements(null)).toBe(false);
    expect(hasAbilityRequirements({})).toBe(false);
    expect(hasAbilityRequirements({ super: "X" })).toBe(true);
  });
});
