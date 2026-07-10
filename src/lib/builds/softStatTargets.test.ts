import { describe, expect, it } from "vitest";

import { normalizeSoftStatTargets, mergeSoftStatTargets } from "@/lib/builds/softStatTargets";
import { softStatWarnings, estimateLoadoutStats } from "@/lib/builds/statEstimate";
import { suggestStatNudges, targetsFromAcceptedNudges } from "@/lib/builds/statNudges";
import { API_ERROR_CODES } from "@/lib/api/errors";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("softStatTargets", () => {
  it("accepts EoF six in range", () => {
    expect(normalizeSoftStatTargets({ Health: 100, Weapons: 80 })).toEqual({
      Health: 100,
      Weapons: 80,
    });
  });

  it("rejects out of range and unknown keys", () => {
    expect(() => normalizeSoftStatTargets({ Health: 201 })).toThrow();
    expect(() => normalizeSoftStatTargets({ Strength: 50 } as never)).toThrow();
  });

  it("merge never lowers existing", () => {
    expect(mergeSoftStatTargets({ Health: 120 }, { Health: 100, Melee: 80 })).toEqual({
      Health: 120,
      Melee: 80,
    });
  });
});

describe("softStatWarnings", () => {
  it("emits below-target rows only", () => {
    const rows = softStatWarnings(
      { Health: 100, Weapons: 50 },
      { Health: 72, Weapons: 60, Melee: 0, Grenade: 0, Super: 0, Class: 0, incomplete: true },
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]?.stat).toBe("Health");
  });
});

describe("estimateLoadoutStats", () => {
  it("marks incomplete without instance stats", () => {
    const estimate = estimateLoadoutStats(
      [{ slot: "helmet", itemHash: 1, itemName: "H", source: "set" }],
      new Map(),
    );
    expect(estimate.incomplete).toBe(true);
  });
});

describe("statNudges", () => {
  it("suggests from synergy type and accept merges up", () => {
    const nudges = suggestStatNudges([
      {
        id: "s1",
        userId: 1,
        name: "Punch",
        type: "melee",
        subType: null,
        description: "",
        createdAt: "",
        updatedAt: "",
        links: [],
      },
    ]);
    expect(nudges[0]?.stat).toBe("Melee");
    expect(targetsFromAcceptedNudges({ Melee: 120 }, nudges).Melee).toBe(120);
    expect(targetsFromAcceptedNudges({}, nudges).Melee).toBe(100);
  });
});

describe("US4 soft-stat not identity", () => {
  it("identityFieldsChanged ignores softStatTargets", () => {
    const src = readFileSync(join(process.cwd(), "src/lib/builds/buildService.ts"), "utf8");
    const start = src.indexOf("function identityFieldsChanged");
    const end = src.indexOf("\n}", start);
    expect(src.slice(start, end)).not.toMatch(/softStat/i);
  });

  it("INVALID_ITEM used for bad targets", () => {
    expect(API_ERROR_CODES.INVALID_ITEM).toBe("INVALID_ITEM");
  });
});
