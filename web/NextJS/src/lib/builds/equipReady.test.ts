import { describe, expect, it } from "vitest";

import type { ResolvedVariantEquipment } from "@/lib/builds/resolveVariant";
import {
  assertEquipReady,
  buildInventoryPinIndex,
  computeEquipReady,
} from "@/lib/builds/equipReady";
import { API_ERROR_CODES } from "@/lib/api/errors";

function resolved(
  equipment: ResolvedVariantEquipment["equipment"],
): ResolvedVariantEquipment {
  return { equipment, conflicts: [] };
}

describe("computeEquipReady", () => {
  it("marks slots without instanceId as wishlist and not equip-ready", () => {
    const result = computeEquipReady(
      resolved({
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
        },
      }),
      buildInventoryPinIndex([]),
    );
    expect(result.equipReady).toBe(false);
    expect(result.pinStatuses).toEqual([{ slot: "primary", status: "wishlist" }]);
  });

  it("is equip-ready when every applied combat slot is pinned", () => {
    const inventory = buildInventoryPinIndex([
      { instanceId: "a", itemHash: 1 },
      { instanceId: "b", itemHash: 2 },
    ]);
    const result = computeEquipReady(
      resolved({
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
          instanceId: "a",
        },
        helmet: {
          slot: "helmet",
          itemHash: 2,
          itemName: "Helm",
          source: "set",
          instanceId: "b",
        },
      }),
      inventory,
    );
    expect(result.equipReady).toBe(true);
    expect(result.pinStatuses.every((s) => s.status === "pinned")).toBe(true);
  });

  it("ignores empty non-default gaps (only applied slots)", () => {
    const inventory = buildInventoryPinIndex([{ instanceId: "a", itemHash: 1 }]);
    const result = computeEquipReady(
      resolved({
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
          instanceId: "a",
        },
      }),
      inventory,
    );
    expect(result.equipReady).toBe(true);
    expect(result.pinStatuses).toHaveLength(1);
  });

  it("marks missing inventory instance as stale", () => {
    const result = computeEquipReady(
      resolved({
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
          instanceId: "gone",
        },
      }),
      buildInventoryPinIndex([]),
    );
    expect(result.equipReady).toBe(false);
    expect(result.pinStatuses[0]).toMatchObject({
      status: "stale",
      reason: "instance_missing",
    });
  });

  it("assertEquipReady throws NOT_EQUIP_READY when not ready", () => {
    const result = computeEquipReady(
      resolved({
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
        },
      }),
      buildInventoryPinIndex([]),
    );
    expect(() => assertEquipReady(result)).toThrow(
      expect.objectContaining({ code: API_ERROR_CODES.NOT_EQUIP_READY }),
    );
  });

  it("post-sync: pre-ready pins become not equip-ready when instance missing after refresh", () => {
    const equipment = {
      primary: {
        slot: "primary" as const,
        itemHash: 1,
        itemName: "Gun",
        source: "set" as const,
        instanceId: "pin-a",
      },
      helmet: {
        slot: "helmet" as const,
        itemHash: 2,
        itemName: "Helm",
        source: "set" as const,
        instanceId: "pin-b",
      },
    };

    const preSync = computeEquipReady(
      resolved(equipment),
      buildInventoryPinIndex([
        { instanceId: "pin-a", itemHash: 1 },
        { instanceId: "pin-b", itemHash: 2 },
      ]),
    );
    expect(preSync.equipReady).toBe(true);

    // Post-sync inventory lost pin-b (sold/transferred out of account view).
    const postSync = computeEquipReady(
      resolved(equipment),
      buildInventoryPinIndex([{ instanceId: "pin-a", itemHash: 1 }]),
    );
    expect(postSync.equipReady).toBe(false);
    expect(postSync.pinStatuses).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          slot: "helmet",
          status: "stale",
          reason: "instance_missing",
          instanceId: "pin-b",
        }),
      ]),
    );
    expect(() => assertEquipReady(postSync)).toThrow(
      expect.objectContaining({
        code: API_ERROR_CODES.NOT_EQUIP_READY,
        status: 409,
      }),
    );
  });

  it("post-sync happy path: all claimed instances still present remain equip-ready", () => {
    const equipment = {
      primary: {
        slot: "primary" as const,
        itemHash: 1,
        itemName: "Gun",
        source: "set" as const,
        instanceId: "pin-a",
      },
      special: {
        slot: "special" as const,
        itemHash: 3,
        itemName: "Special",
        source: "set" as const,
        instanceId: "pin-c",
      },
      helmet: {
        slot: "helmet" as const,
        itemHash: 2,
        itemName: "Helm",
        source: "set" as const,
        instanceId: "pin-b",
      },
    };
    const postSync = computeEquipReady(
      resolved(equipment),
      buildInventoryPinIndex([
        { instanceId: "pin-a", itemHash: 1 },
        { instanceId: "pin-b", itemHash: 2 },
        { instanceId: "pin-c", itemHash: 3 },
      ]),
    );
    expect(postSync.equipReady).toBe(true);
    expect(() => assertEquipReady(postSync)).not.toThrow();
  });
});
