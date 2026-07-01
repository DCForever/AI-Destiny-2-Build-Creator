import { describe, expect, it } from "vitest";

import { emptyFilterMessage } from "@/lib/catalog/emptyFilterResult";
import { resolveSetBonusFilter } from "@/lib/catalog/setBonusFilter";
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
});
