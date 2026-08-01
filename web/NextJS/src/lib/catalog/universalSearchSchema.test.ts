import { describe, expect, it } from "vitest";

import {
  parseUniversalSearchQuery,
  universalSearchQuerySchema,
} from "./universalSearchSchema";

describe("universalSearchQuerySchema", () => {
  it("defaults q empty and limit 48", () => {
    const parsed = universalSearchQuerySchema.parse({});
    expect(parsed.q).toBe("");
    expect(parsed.limit).toBe(48);
    expect(parsed.kinds).toBeUndefined();
    expect(parsed.includeOwned).toBeUndefined();
  });

  it("coerces limit and accepts includeOwned 0|1", () => {
    const parsed = universalSearchQuerySchema.parse({
      q: "melee",
      limit: "12",
      includeOwned: "1",
      kinds: "weapon_perk,origin_trait",
    });
    expect(parsed.limit).toBe(12);
    expect(parsed.includeOwned).toBe("1");
  });

  it("rejects limit out of range", () => {
    expect(universalSearchQuerySchema.safeParse({ limit: 0 }).success).toBe(false);
    expect(universalSearchQuerySchema.safeParse({ limit: 101 }).success).toBe(false);
  });

  it("parseUniversalSearchQuery validates kinds", () => {
    const bad = parseUniversalSearchQuery({ kinds: "weapon,not_a_kind" });
    expect(bad.ok).toBe(false);
    if (!bad.ok) expect(bad.error).toMatch(/Invalid kind/);

    const good = parseUniversalSearchQuery({
      q: "x",
      kinds: "weapon_perk,origin_trait",
      limit: "20",
      includeOwned: "0",
    });
    expect(good.ok).toBe(true);
    if (good.ok) {
      expect(good.data.kinds).toEqual(["weapon_perk", "origin_trait"]);
      expect(good.data.limit).toBe(20);
      expect(good.data.includeOwned).toBe("0");
    }
  });
});
