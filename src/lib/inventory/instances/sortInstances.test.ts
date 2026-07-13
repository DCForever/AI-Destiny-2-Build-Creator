import { describe, expect, it } from "vitest";

import { sortInstancesByPower, sortInstancesByStat } from "./sortInstances";
import type { OwnedInstanceDetail } from "./types";

function armorInstance(
  id: string,
  power: number,
  statValues?: OwnedInstanceDetail["statValues"],
): OwnedInstanceDetail {
  return {
    instanceId: id,
    itemHash: 1,
    kind: "armor",
    bucket: "Helmet",
    location: "vault",
    power,
    isMasterwork: false,
    isCrafted: false,
    rollTags: [],
    plugs: [],
    syncedAt: "2026-01-01T00:00:00.000Z",
    statValues,
    totalStats: statValues
      ? Object.values(statValues).reduce<number>(
          (sum, value) => sum + (value ?? 0),
          0,
        )
      : undefined,
    statsIncomplete: !statValues,
  };
}

describe("sortInstancesByPower", () => {
  it("orders by power descending", () => {
    const a = armorInstance("a", 1800);
    const b = armorInstance("b", 1810);
    expect(sortInstancesByPower([a, b]).map((row) => row.instanceId)).toEqual(["b", "a"]);
  });
});

describe("sortInstancesByStat", () => {
  it("orders by selected stat descending", () => {
    const low = armorInstance("low", 1800, {
      Health: 5,
      Melee: 10,
      Grenade: 5,
      Super: 5,
      Class: 5,
      Weapons: 5,
    });
    const high = armorInstance("high", 1790, {
      Health: 5,
      Melee: 60,
      Grenade: 5,
      Super: 5,
      Class: 5,
      Weapons: 5,
    });
    const sorted = sortInstancesByStat([low, high], "Melee");
    expect(sorted[0]?.instanceId).toBe("high");
  });

  it("orders by total stats when sortBy is total", () => {
    const low = armorInstance("low", 1810, {
      Health: 1,
      Melee: 1,
      Grenade: 1,
      Super: 1,
      Class: 1,
      Weapons: 1,
    });
    const high = armorInstance("high", 1800, {
      Health: 20,
      Melee: 20,
      Grenade: 20,
      Super: 20,
      Class: 20,
      Weapons: 20,
    });
    const sorted = sortInstancesByStat([low, high], "total");
    expect(sorted[0]?.instanceId).toBe("high");
  });

  it("places incomplete stat rows last", () => {
    const incomplete = armorInstance("incomplete", 1900);
    const complete = armorInstance("complete", 1800, {
      Health: 10,
      Melee: 10,
      Grenade: 10,
      Super: 10,
      Class: 10,
      Weapons: 10,
    });
    const sorted = sortInstancesByStat([incomplete, complete], "total");
    expect(sorted.map((row) => row.instanceId)).toEqual(["complete", "incomplete"]);
  });
});
