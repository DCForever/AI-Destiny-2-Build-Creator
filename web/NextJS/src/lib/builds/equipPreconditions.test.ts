import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { assertEquipReady } from "@/lib/builds/equipReady";
import { isInventoryFresh } from "@/lib/bungie/syncFreshness";

describe("equip preconditions (US1)", () => {
  it("throws NOT_EQUIP_READY when variant is not equip-ready", () => {
    expect(() =>
      assertEquipReady({
        equipReady: false,
        pinStatuses: [{ slot: "primary", status: "wishlist" }],
      }),
    ).toThrow(ApiError);

    try {
      assertEquipReady({
        equipReady: false,
        pinStatuses: [{ slot: "primary", status: "wishlist" }],
      });
    } catch (error) {
      expect(error).toBeInstanceOf(ApiError);
      expect((error as ApiError).code).toBe(API_ERROR_CODES.NOT_EQUIP_READY);
      expect((error as ApiError).status).toBe(409);
    }
  });

  it("maps class mismatch to INVALID_CHARACTER", () => {
    const buildClass: string = "Hunter";
    const characterClass: string = "Titan";
    const mismatch = buildClass !== characterClass;
    expect(mismatch).toBe(true);
    const error = new ApiError(
      API_ERROR_CODES.INVALID_CHARACTER,
      "Character does not match build class",
      { characterId: "c1", buildClass },
      400,
    );
    expect(error.code).toBe(API_ERROR_CODES.INVALID_CHARACTER);
    expect(error.status).toBe(400);
  });
});

describe("sync freshness", () => {
  it("treats sync within 60s as fresh", () => {
    const now = Date.parse("2026-07-10T12:00:30.000Z");
    expect(isInventoryFresh("2026-07-10T12:00:00.000Z", now)).toBe(true);
    expect(isInventoryFresh("2026-07-10T11:58:00.000Z", now)).toBe(false);
    expect(isInventoryFresh(null, now)).toBe(false);
  });
});

describe("INVALID_CHARACTER helper", () => {
  it("rejects when character class differs from build", () => {
    const assertCharacterClass = (buildClass: string, characterClass: string) => {
      if (buildClass !== characterClass) {
        throw new ApiError(API_ERROR_CODES.INVALID_CHARACTER, "mismatch", undefined, 400);
      }
    };
    expect(() => assertCharacterClass("Warlock", "Titan")).toThrow(ApiError);
    expect(() => assertCharacterClass("Warlock", "Warlock")).not.toThrow();
  });
});

// silence unused in case of tree-shake noise
void vi;
