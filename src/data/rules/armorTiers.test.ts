import { describe, expect, it } from "vitest";

import { resolveArmorTier } from "./armorTiers";

describe("resolveArmorTier", () => {
  it("uses the API gearTier as the exact, non-approximate source", () => {
    const result = resolveArmorTier({
      gearTier: 5,
      totalStats: 60,
      isExotic: false,
      statsComplete: true,
    });
    expect(result).toEqual({
      tier: 5,
      label: "Tier 5",
      source: "api",
      approximate: false,
      available: true,
    });
  });

  it("labels an exotic that still carries an API gearTier", () => {
    const result = resolveArmorTier({ gearTier: 3, isExotic: true, statsComplete: true });
    expect(result.tier).toBe(3);
    expect(result.label).toBe("Exotic · Tier 3");
    expect(result.source).toBe("api");
  });

  it("labels exotics without a numeric tier as Exotic", () => {
    const result = resolveArmorTier({ gearTier: null, isExotic: true, statsComplete: false });
    expect(result).toEqual({
      tier: null,
      label: "Exotic",
      source: "api",
      approximate: false,
      available: true,
    });
  });

  it("falls back to a stat-band estimate for legacy legendary copies", () => {
    const result = resolveArmorTier({
      gearTier: null,
      totalStats: 72,
      isExotic: false,
      statsComplete: true,
    });
    expect(result).toEqual({
      tier: 4,
      label: "~Tier 4",
      source: "estimated",
      approximate: true,
      available: true,
    });
  });

  it.each([
    [50, 1],
    [60, 2],
    [66, 3],
    [73, 4],
    [80, 5],
  ])("maps total %i to estimated tier %i", (totalStats, tier) => {
    const result = resolveArmorTier({
      gearTier: null,
      totalStats,
      isExotic: false,
      statsComplete: true,
    });
    expect(result.tier).toBe(tier);
    expect(result.source).toBe("estimated");
  });

  it("reports unavailable when no gearTier and stats are incomplete", () => {
    const result = resolveArmorTier({
      gearTier: null,
      totalStats: undefined,
      isExotic: false,
      statsComplete: false,
    });
    expect(result).toEqual({
      tier: null,
      label: "Tier unavailable",
      source: "none",
      approximate: false,
      available: false,
    });
  });
});
