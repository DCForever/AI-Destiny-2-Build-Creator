import { beforeEach, describe, expect, it, vi } from "vitest";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { SlotClaim } from "@/lib/builds/resolveVariant";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

import { assertExoticLimits } from "@/lib/builds/assertExoticLimits";

const W1 = 1001;
const W2 = 1002;
const A1 = 2001;
const A2 = 2002;

function claim(
  partial: Pick<SlotClaim, "slot" | "itemHash"> &
    Partial<Omit<SlotClaim, "slot" | "itemHash">>,
): SlotClaim {
  return {
    itemName: partial.itemName ?? `item-${partial.itemHash}`,
    source: partial.source ?? "set",
    ...partial,
  };
}

describe("assertExoticLimits", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "exotic-weapons") {
        return [{ hash: W1 }, { hash: W2 }];
      }
      if (store === "exotic-armor") {
        return [{ hash: A1 }, { hash: A2 }];
      }
      return [];
    });
  });

  it("allows empty claims (progressive create)", async () => {
    await expect(assertExoticLimits([])).resolves.toBeUndefined();
  });

  it("allows one exotic weapon and one exotic armor", async () => {
    const claims = [
      claim({ slot: "primary", itemHash: W1 }),
      claim({ slot: "helmet", itemHash: A1 }),
    ];
    await expect(assertExoticLimits(claims)).resolves.toBeUndefined();
  });

  it("allows exotics identified only by dedicated slot/source", async () => {
    getStore.mockImplementation(async () => []);
    const claims = [
      claim({
        slot: "exotic_weapon",
        itemHash: 9001,
        source: "variant_exotic_weapon",
      }),
      claim({
        slot: "exotic_armor",
        itemHash: 9002,
        source: "build_exotic_armor",
      }),
    ];
    await expect(assertExoticLimits(claims)).resolves.toBeUndefined();
  });

  it("blocks two distinct exotic weapons with TOO_MANY_EXOTICS", async () => {
    const claims = [
      claim({ slot: "primary", itemHash: W1 }),
      claim({ slot: "special", itemHash: W2 }),
    ];
    await expect(assertExoticLimits(claims)).rejects.toMatchObject({
      name: "ApiError",
      code: API_ERROR_CODES.TOO_MANY_EXOTICS,
      status: 400,
    });
    try {
      await assertExoticLimits(claims);
    } catch (e) {
      expect(e).toBeInstanceOf(ApiError);
      expect((e as ApiError).details).toMatchObject({
        exoticWeaponHashes: expect.arrayContaining([W1, W2]),
      });
    }
  });

  it("blocks two distinct exotic armors with TOO_MANY_EXOTICS", async () => {
    const claims = [
      claim({ slot: "helmet", itemHash: A1 }),
      claim({ slot: "arms", itemHash: A2 }),
    ];
    await expect(assertExoticLimits(claims)).rejects.toMatchObject({
      code: API_ERROR_CODES.TOO_MANY_EXOTICS,
      status: 400,
    });
  });
});
