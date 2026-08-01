import { describe, expect, it } from "vitest";

import { FIXTURE_SET_TIER_DESCRIPTION } from "@/lib/search/__fixtures__/descriptionSearchFixtures";
import { FIXTURE_SET_EUTECHNOLOGY } from "./__fixtures__/setLookupFixtures";
import { resolveSetBonusFilter } from "./setBonusFilter";

describe("resolveSetBonusFilter", () => {
  it("matches set bonus by name substring", () => {
    const result = resolveSetBonusFilter("eutech", [FIXTURE_SET_EUTECHNOLOGY]);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.sets).toHaveLength(1);
      expect([...result.armorHashes]).toEqual([9001, 9002]);
    }
  });

  it("matches set bonus by hash", () => {
    const result = resolveSetBonusFilter("8001", [FIXTURE_SET_EUTECHNOLOGY]);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.sets[0]?.hash).toBe(8001);
    }
  });

  it("returns unresolved when no set matches", () => {
    const result = resolveSetBonusFilter("Unknown Set", [FIXTURE_SET_EUTECHNOLOGY]);
    expect(result.ok).toBe(false);
  });

  it("matches set bonus by tier perk description", () => {
    const result = resolveSetBonusFilter("overshield", [FIXTURE_SET_TIER_DESCRIPTION]);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.sets[0]?.name).toBe("Osmium Council");
      expect([...result.armorHashes]).toEqual([9101]);
    }
  });
});
