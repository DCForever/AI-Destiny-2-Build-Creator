import { describe, expect, it } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { assertEquipReady } from "@/lib/builds/equipReady";

describe("dim-export gate (US1)", () => {
  it("blocks export when not equip-ready", () => {
    expect(() =>
      assertEquipReady({
        equipReady: false,
        pinStatuses: [{ slot: "primary", status: "wishlist" }],
      }),
    ).toThrow(ApiError);

    try {
      assertEquipReady({
        equipReady: false,
        pinStatuses: [{ slot: "helmet", status: "stale", reason: "instance_missing" }],
      });
    } catch (error) {
      expect((error as ApiError).code).toBe(API_ERROR_CODES.NOT_EQUIP_READY);
      expect((error as ApiError).status).toBe(409);
    }
  });
});
