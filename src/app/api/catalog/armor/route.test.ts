import { describe, expect, it } from "vitest";

import { emptyFilterMessage } from "@/lib/catalog/emptyFilterResult";
import { resolveSetBonusFilter } from "@/lib/catalog/setBonusFilter";
import { FIXTURE_SET_TIER_DESCRIPTION } from "@/lib/search/__fixtures__/descriptionSearchFixtures";
import { FIXTURE_SET_EUTECHNOLOGY } from "@/lib/catalog/__fixtures__/setLookupFixtures";

describe("armor catalog route helpers", () => {
  it("emptyFilterMessage covers set bonus filter", () => {
    expect(emptyFilterMessage({ setBonus: "Missing" })).toContain("Missing");
  });

  it("resolveSetBonusFilter returns armor hashes for known set", () => {
    const result = resolveSetBonusFilter("Eutechnology", [FIXTURE_SET_EUTECHNOLOGY]);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.armorHashes]).toEqual([9001, 9002]);
    }
  });

  it("resolveSetBonusFilter matches tier perk description", () => {
    const result = resolveSetBonusFilter("overshield", [FIXTURE_SET_TIER_DESCRIPTION]);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.sets[0]?.name).toBe("Osmium Council");
    }
  });
});
