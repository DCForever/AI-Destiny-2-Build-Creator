import { describe, expect, it } from "vitest";

import type { ManifestService } from "@/lib/manifest/types/services";

import {
  buildEquipmentBucketLookup,
  resolveTransferContainerBuckets,
} from "./resolveEquipmentBuckets";
import type { RawInventoryItem } from "./types";

const VAULT_GENERAL = 138197802;
const KINETIC = 1498876634;
const HELMET = 3448274439;

function makeItem(overrides: Partial<RawInventoryItem>): RawInventoryItem {
  return {
    instanceId: "inst1",
    itemHash: 100,
    bucketHash: VAULT_GENERAL,
    location: "vault",
    power: 1800,
    plugHashes: [],
    isMasterwork: false,
    isCrafted: false,
    ...overrides,
  };
}

describe("resolveTransferContainerBuckets", () => {
  it("rewrites vault container items using manifest bucket lookup", () => {
    const lookup = new Map<number, number>([[100, KINETIC], [200, HELMET]]);
    const { items, resolvedFromTransfer, droppedNonEquipment } = resolveTransferContainerBuckets(
      [makeItem({ itemHash: 100 }), makeItem({ itemHash: 200, instanceId: "inst2" })],
      lookup,
    );

    expect(resolvedFromTransfer).toBe(2);
    expect(droppedNonEquipment).toBe(0);
    expect(items).toHaveLength(2);
    expect(items[0]?.bucketHash).toBe(KINETIC);
    expect(items[1]?.bucketHash).toBe(HELMET);
  });

  it("drops transfer-container items that do not resolve to equipment", () => {
    const { items, droppedNonEquipment } = resolveTransferContainerBuckets(
      [makeItem({ itemHash: 999 })],
      new Map(),
    );

    expect(items).toHaveLength(0);
    expect(droppedNonEquipment).toBe(1);
  });

  it("leaves character equipment bucket items unchanged", () => {
    const item = makeItem({ bucketHash: KINETIC, location: "character" });
    const { items } = resolveTransferContainerBuckets([item], new Map());

    expect(items).toEqual([item]);
  });
});

describe("buildEquipmentBucketLookup", () => {
  it("reads inventory.bucketTypeHash from DestinyInventoryItemDefinition", async () => {
    const manifest = {
      loadRawTable: async () => ({
        "100": {
          hash: 100,
          displayProperties: { name: "Test Weapon", description: "" },
          inventory: { bucketTypeHash: KINETIC },
        },
        "200": {
          hash: 200,
          displayProperties: { name: "Shader", description: "" },
          inventory: { bucketTypeHash: 18606351 },
        },
      }),
    };

    const lookup = await buildEquipmentBucketLookup(manifest as unknown as ManifestService, "v1", [100, 200]);

    expect(lookup.get(100)).toBe(KINETIC);
    expect(lookup.has(200)).toBe(false);
  });
});
