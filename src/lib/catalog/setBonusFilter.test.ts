import { describe, expect, it } from "vitest";

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
});
