import { describe, expect, it } from "vitest";

import {
  getAffinityOverride,
  getVerbOverride,
} from "./abilityEnrichmentOverrides";

describe("abilityEnrichmentOverrides", () => {
  it("Phoenix Dive (1026): Dawnblade + Prismatic Warlock + Cure", () => {
    expect(getAffinityOverride(1026)).toEqual(["Dawnblade", "Prismatic Warlock"]);
    expect(getVerbOverride(1026)).toEqual(["Cure"]);
  });

  it("Chaos Reach (1018): Jolt verb override", () => {
    expect(getVerbOverride(1018)).toEqual(["Jolt"]);
  });

  it("unknown hash returns empty arrays", () => {
    expect(getAffinityOverride(999999)).toEqual([]);
    expect(getVerbOverride(999999)).toEqual([]);
  });
});
