import { describe, expect, it } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  assertSetMinimumOccupancy,
  countModPieces,
  countWeaponOrArmorItems,
  evaluateSetMinimumOccupancy,
} from "@/lib/sets/setMinimumOccupancy";

describe("countWeaponOrArmorItems", () => {
  it("counts unique weapon domain slots", () => {
    expect(
      countWeaponOrArmorItems("weapon", [
        { slot: "primary" },
        { slot: "heavy" },
        { slot: "primary" },
      ]),
    ).toBe(2);
  });

  it("ignores soft-removed", () => {
    expect(
      countWeaponOrArmorItems("armor", [
        { slot: "helmet" },
        { slot: "arms", removedAt: "2026-01-01" },
      ]),
    ).toBe(1);
  });
});

describe("countModPieces", () => {
  it("counts distinct armor pieces from mod keys", () => {
    expect(
      countModPieces([
        { slot: "helmet:1" },
        { slot: "helmet:2" },
        { slot: "arms:3" },
      ]),
    ).toBe(2);
  });

  it("treats legacy free-list as one piece", () => {
    expect(
      countModPieces([{ slot: "mod:10" }, { slot: "mod:11" }]),
    ).toBe(1);
  });
});

describe("evaluateSetMinimumOccupancy", () => {
  it("allows empty weapon scaffold", () => {
    const r = evaluateSetMinimumOccupancy("weapon", []);
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.empty).toBe(true);
  });

  it("rejects single-item weapon set", () => {
    const r = evaluateSetMinimumOccupancy("weapon", [{ slot: "primary" }]);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.code).toBe(API_ERROR_CODES.SET_MIN_ITEMS);
      expect(r.count).toBe(1);
      expect(r.required).toBe(2);
    }
  });

  it("accepts weapon set with two items", () => {
    const r = evaluateSetMinimumOccupancy("weapon", [
      { slot: "primary" },
      { slot: "special" },
    ]);
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.empty).toBe(false);
  });

  it("rejects armor set with one piece", () => {
    const r = evaluateSetMinimumOccupancy("armor", [{ slot: "helmet" }]);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe(API_ERROR_CODES.SET_MIN_ITEMS);
  });

  it("rejects mod set with one piece only", () => {
    const r = evaluateSetMinimumOccupancy("mod", [
      { slot: "helmet:1" },
      { slot: "helmet:2" },
    ]);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.code).toBe(API_ERROR_CODES.MOD_SET_MIN_SLOTS);
      expect(r.count).toBe(1);
    }
  });

  it("accepts mod set with two pieces", () => {
    const r = evaluateSetMinimumOccupancy("mod", [
      { slot: "helmet:1" },
      { slot: "legs:2" },
    ]);
    expect(r.ok).toBe(true);
  });

  it("rejects incomplete pair", () => {
    const r = evaluateSetMinimumOccupancy("pair", [
      { slot: "exotic_weapon" },
    ]);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe(API_ERROR_CODES.PAIR_INCOMPLETE);
  });

  it("accepts complete pair", () => {
    const r = evaluateSetMinimumOccupancy("pair", [
      { slot: "exotic_weapon" },
      { slot: "exotic_armor" },
    ]);
    expect(r.ok).toBe(true);
  });

  it("always ok for fashion", () => {
    expect(evaluateSetMinimumOccupancy("fashion", []).ok).toBe(true);
    expect(
      evaluateSetMinimumOccupancy("fashion", [{ slot: "ghost" }]).ok,
    ).toBe(true);
  });
});

describe("assertSetMinimumOccupancy", () => {
  it("throws ApiError with SET_MIN_ITEMS", () => {
    try {
      assertSetMinimumOccupancy("weapon", [{ slot: "heavy" }]);
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(ApiError);
      expect((e as ApiError).code).toBe(API_ERROR_CODES.SET_MIN_ITEMS);
    }
  });

  it("does not throw for empty scaffold", () => {
    expect(() => assertSetMinimumOccupancy("mod", [])).not.toThrow();
  });
});
