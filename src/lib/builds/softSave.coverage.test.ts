import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  assertNoSlotConflicts,
  buildEquipmentMap,
  detectSlotConflicts,
  type SlotClaim,
} from "@/lib/builds/resolveVariant";

const ROOT = join(process.cwd(), "src/lib/builds");

describe("soft coverage does not hard-block save (US4)", () => {
  it("build/variant save modules do not import coverage", () => {
    for (const file of ["buildService.ts", "variantService.ts", "resolveVariant.ts"]) {
      const src = readFileSync(join(ROOT, file), "utf8");
      expect(src).not.toMatch(/coverage/i);
    }
  });

  it("slot conflicts still hard-fail independently of coverage", () => {
    const claims: SlotClaim[] = [
      {
        slot: "primary",
        itemHash: 1,
        itemName: "A",
        source: "variant_exotic_weapon",
      },
      {
        slot: "primary",
        itemHash: 2,
        itemName: "B",
        source: "set",
      },
    ];
    const conflicts = detectSlotConflicts(claims);
    expect(() =>
      assertNoSlotConflicts({ equipment: buildEquipmentMap(claims), conflicts }),
    ).toThrow(ApiError);
    try {
      assertNoSlotConflicts({ equipment: buildEquipmentMap(claims), conflicts });
    } catch (err) {
      expect(err).toMatchObject({ code: API_ERROR_CODES.SLOT_CONFLICT });
    }
  });
});
