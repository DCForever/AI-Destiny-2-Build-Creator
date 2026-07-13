import { describe, expect, it } from "vitest";

import {
  funnelCopyVault,
  helmetCopy,
  subclassItem,
} from "./__fixtures__/inventoryFixtures";
import { ringingNailAllPlugHashes } from "./__fixtures__/plugFixtures";
import { collectEquipmentPlugHashes } from "./collectPlugHashes";

describe("collectEquipmentPlugHashes", () => {
  it("unions unique plug hashes from weapon and armor equipment rows", () => {
    const hashes = collectEquipmentPlugHashes([funnelCopyVault, helmetCopy, subclassItem]);
    expect(hashes.sort((a, b) => a - b)).toEqual([1001, 2001, 3001, 5001, 6001, 6002, 882794621]);
  });

  it("excludes subclass and other non-equipment buckets", () => {
    const hashes = collectEquipmentPlugHashes([subclassItem]);
    expect(hashes).toEqual([]);
  });

  it("deduplicates shared plug hashes across copies", () => {
    const hashes = collectEquipmentPlugHashes([funnelCopyVault, funnelCopyVault]);
    expect(hashes.sort((a, b) => a - b)).toEqual([1001, 2001, 3001]);
  });

  it("includes manifest-only plug hashes when present on equipment rows", () => {
    const ringingNailRow = {
      ...funnelCopyVault,
      instanceId: "inst-rn",
      itemHash: 4206550094,
      plugHashes: ringingNailAllPlugHashes,
    };
    const hashes = collectEquipmentPlugHashes([ringingNailRow]);
    expect(hashes).toContain(1636108362);
    expect(hashes).toContain(3634656993);
    expect(new Set(hashes).size).toBe(ringingNailAllPlugHashes.length);
  });

  it("includes socket_plugs reusable alternates for multi-option columns", () => {
    const withSockets = {
      ...funnelCopyVault,
      socketPlugs: [
        {
          socketIndex: 1,
          equippedPlugHash: 1001,
          reusablePlugHashes: [1001, 9001, 9002],
          columnKind: "barrel" as const,
          columnLabel: "Barrel",
        },
      ],
    };
    const hashes = collectEquipmentPlugHashes([withSockets]);
    expect(hashes).toContain(9001);
    expect(hashes).toContain(9002);
  });
});
