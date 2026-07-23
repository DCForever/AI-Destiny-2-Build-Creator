import { beforeEach, describe, expect, it, vi } from "vitest";
import { API_ERROR_CODES } from "@/lib/api/errors";
import { MAX_SUBCLASS_ASPECTS } from "@/lib/builds/destinyBuildConstraints";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

import { assertSubclassKitLegal } from "@/lib/builds/assertSubclassKit";

describe("assertSubclassKitLegal", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "aspects") {
        return [
          { name: "Aspect Alpha", fragmentCapacity: 2 },
          { name: "Aspect Beta", fragmentCapacity: 3 },
          { name: "Aspect Gamma", fragmentCapacity: 1 },
        ];
      }
      return [];
    });
  });

  it("allows empty kit (progressive create)", async () => {
    await expect(assertSubclassKitLegal({})).resolves.toBeUndefined();
  });

  it("allows a legal aspect/fragment kit within capacity", async () => {
    await expect(
      assertSubclassKitLegal({
        aspects: ["Aspect Alpha", "Aspect Beta"],
        fragments: ["F1", "F2", "F3", "F4", "F5"],
      }),
    ).resolves.toBeUndefined();
  });

  it("blocks more fragments than resolved aspect capacity", async () => {
    await expect(
      assertSubclassKitLegal({
        aspects: ["Aspect Alpha", "Aspect Beta"],
        fragments: ["F1", "F2", "F3", "F4", "F5", "F6"],
      }),
    ).rejects.toMatchObject({
      code: API_ERROR_CODES.ILLEGAL_SUBCLASS_KIT,
      status: 400,
    });
  });

  it("blocks more aspects than MAX_SUBCLASS_ASPECTS", async () => {
    expect(MAX_SUBCLASS_ASPECTS).toBe(2);
    await expect(
      assertSubclassKitLegal({
        aspects: ["Aspect Alpha", "Aspect Beta", "Aspect Gamma"],
        fragments: [],
      }),
    ).rejects.toMatchObject({
      code: API_ERROR_CODES.ILLEGAL_SUBCLASS_KIT,
      status: 400,
    });
  });

  it("skips fragment over-cap when an aspect name does not resolve", async () => {
    // capacityResolved=false → evaluateSubclassKit does not emit fragment hard block
    await expect(
      assertSubclassKitLegal({
        aspects: ["Aspect Alpha", "Unknown Aspect"],
        fragments: ["F1", "F2", "F3", "F4", "F5", "F6", "F7"],
      }),
    ).resolves.toBeUndefined();
  });
});
