import { describe, expect, it } from "vitest";

import {
  computeTotalArmorStats,
  isCompleteArmorStats,
  parseArmorStatValues,
} from "./parseArmorStats";

describe("parseArmorStatValues", () => {
  it("maps Bungie stat hashes to Armor 3.0 names", () => {
    const values = parseArmorStatValues([
      { statHash: 392767087, value: 10 },
      { statHash: 4244567218, value: 60 },
      { statHash: 1735777505, value: 15 },
      { statHash: 144602215, value: 5 },
      { statHash: 1943323491, value: 20 },
      { statHash: 2996146975, value: 30 },
    ]);
    expect(values).toEqual({
      Health: 10,
      Melee: 60,
      Grenade: 15,
      Super: 5,
      Class: 20,
      Weapons: 30,
    });
  });

  it("returns null for empty stats", () => {
    expect(parseArmorStatValues([])).toBeNull();
    expect(parseArmorStatValues(undefined)).toBeNull();
  });

  it("supports partial stat payloads", () => {
    const values = parseArmorStatValues([{ statHash: 4244567218, value: 42 }]);
    expect(values).toEqual({ Melee: 42 });
    expect(isCompleteArmorStats(values)).toBe(false);
  });
});

describe("computeTotalArmorStats", () => {
  it("sums known stat values", () => {
    expect(computeTotalArmorStats({ Melee: 10, Health: 5 })).toBe(15);
  });
});
