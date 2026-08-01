import { describe, expect, it } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  assertArmorSetBonusConstraint,
  buildSetBonusMembershipIndex,
  evaluateArmorSetBonusConstraint,
  parseArmorSetBonusConstraint,
  serializeArmorSetBonusConstraint,
} from "@/lib/sets/armorSetBonusConstraint";
import type { SetBonusRecord } from "@/lib/manifest/types/records";

const FAMILY_A = 9001;
const FAMILY_B = 9002;

const membership = buildSetBonusMembershipIndex([
  {
    hash: FAMILY_A,
    name: "Family A",
    itemHashes: [101, 102, 103, 104, 105],
    perks: [
      { requiredCount: 2, name: "2pc", description: "" },
      { requiredCount: 4, name: "4pc", description: "" },
    ],
  } as SetBonusRecord,
  {
    hash: FAMILY_B,
    name: "Family B",
    itemHashes: [201, 202],
    perks: [{ requiredCount: 2, name: "2pc", description: "" }],
  } as SetBonusRecord,
]);

const constraint2 = {
  armorSetHash: FAMILY_A,
  armorSetName: "Family A",
  targetTier: 2 as const,
};

const constraint4 = {
  armorSetHash: FAMILY_A,
  armorSetName: "Family A",
  targetTier: 4 as const,
};

describe("parse/serialize ArmorSetBonusConstraint", () => {
  it("round-trips valid constraint", () => {
    const raw = serializeArmorSetBonusConstraint(constraint2);
    expect(parseArmorSetBonusConstraint(raw)).toEqual(constraint2);
  });

  it("returns null for empty or invalid", () => {
    expect(parseArmorSetBonusConstraint(null)).toBeNull();
    expect(parseArmorSetBonusConstraint("")).toBeNull();
    expect(parseArmorSetBonusConstraint("{not json")).toBeNull();
    expect(parseArmorSetBonusConstraint(JSON.stringify({ armorSetHash: 1, targetTier: 3 }))).toBeNull();
  });
});

describe("evaluateArmorSetBonusConstraint", () => {
  it("passes with no constraint", () => {
    const r = evaluateArmorSetBonusConstraint(null, [{ itemHash: 999 }], membership);
    expect(r.ok).toBe(true);
  });

  it("allows empty fill scaffold", () => {
    const r = evaluateArmorSetBonusConstraint(constraint2, [], membership);
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.memberCount).toBe(0);
  });

  it("rejects non-exotic outside family", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [
        { itemHash: 101 },
        { itemHash: 201 },
      ],
      membership,
    );
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.code).toBe(API_ERROR_CODES.ARMOR_SET_BONUS_MISMATCH);
      expect(r.mismatchHashes).toEqual([201]);
    }
  });

  it("rejects incomplete tier when requireTier (default)", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [{ itemHash: 101 }],
      membership,
    );
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe(API_ERROR_CODES.ARMOR_SET_BONUS_INCOMPLETE);
  });

  it("allows incomplete tier when requireTier false (fill path)", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [{ itemHash: 101 }],
      membership,
      { requireTier: false },
    );
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.memberCount).toBe(1);
  });

  it("still rejects mismatch when requireTier false", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [{ itemHash: 201 }],
      membership,
      { requireTier: false },
    );
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe(API_ERROR_CODES.ARMOR_SET_BONUS_MISMATCH);
  });

  it("exotics do not count toward tier", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [
        { itemHash: 101 },
        { itemHash: 9999, isExotic: true },
      ],
      membership,
    );
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.code).toBe(API_ERROR_CODES.ARMOR_SET_BONUS_INCOMPLETE);
      expect(r.memberCount).toBe(1);
      expect(r.softWarnings.some((w) => w.code === "EXOTIC_BLOCKS_SET_BONUS")).toBe(true);
    }
  });

  it("accepts 2 members + exotic for 2pc", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [
        { itemHash: 101 },
        { itemHash: 102 },
        { itemHash: 9999, isExotic: true },
      ],
      membership,
    );
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.memberCount).toBe(2);
  });

  it("accepts four members for 4pc", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint4,
      [
        { itemHash: 101 },
        { itemHash: 102 },
        { itemHash: 103 },
        { itemHash: 104 },
      ],
      membership,
    );
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.memberCount).toBe(4);
  });

  it("unknown hash (not in membership) is mismatch for non-exotic", () => {
    const r = evaluateArmorSetBonusConstraint(
      constraint2,
      [{ itemHash: 555 }],
      membership,
    );
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe(API_ERROR_CODES.ARMOR_SET_BONUS_MISMATCH);
  });
});

describe("assertArmorSetBonusConstraint", () => {
  it("throws INVALID_ITEM when constraint on non-armor type", () => {
    expect(() =>
      assertArmorSetBonusConstraint(constraint2, [], membership, { setType: "weapon" }),
    ).toThrow(ApiError);
    try {
      assertArmorSetBonusConstraint(constraint2, [], membership, { setType: "weapon" });
    } catch (e) {
      expect(e).toMatchObject({ code: API_ERROR_CODES.INVALID_ITEM });
    }
  });

  it("throws ARMOR_SET_BONUS_INCOMPLETE", () => {
    expect(() =>
      assertArmorSetBonusConstraint(constraint2, [{ itemHash: 101 }], membership),
    ).toThrow(ApiError);
    try {
      assertArmorSetBonusConstraint(constraint2, [{ itemHash: 101 }], membership);
    } catch (e) {
      expect(e).toMatchObject({ code: API_ERROR_CODES.ARMOR_SET_BONUS_INCOMPLETE });
    }
  });
});
