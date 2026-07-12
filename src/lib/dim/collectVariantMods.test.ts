import { describe, expect, it, vi } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import {
  createVariantRecord,
  replaceAttachments,
} from "@/lib/db/repositories/variantRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { collectVariantMods } from "@/lib/dim/collectVariantMods";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore: vi.fn(async () => []) },
  })),
}));

describe("collectVariantMods", () => {
  it("collects armor modHashes and snapshot mod-set item hashes", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "dim-mods", 3, "G");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createSetRecord(db, user.id, { id: "set-armor", name: "Armor", type: "armor", tagIds: [], now });
    await upsertSetItem(db, "set-armor", "armor", {
      slot: "helmet",
      itemHash: 10,
      itemName: "Helm",
      modHashes: [101, 102],
    });

    createSetRecord(db, user.id, { id: "set-mods", name: "Mods", type: "mod", tagIds: [], now });

    createBuildRecord(db, user.id, {
      id: "build-1",
      name: "B",
      className: "Titan",
      subclass: { name: "Sunbreaker" },
      exoticArmorHash: null,
      exoticArmorName: null,
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      tagIds: [],
      synergyTypes: [{ type: "melee", subType: "Base" }],
      now,
    });
    createVariantRecord(db, {
      id: "var-1",
      buildId: "build-1",
      name: "Default",
      isDefault: true,
      now,
    });
    replaceAttachments(
      db,
      "var-1",
      [
        { setId: "set-armor", mode: "live", snapshotConfigs: null },
        {
          setId: "set-mods",
          mode: "snapshot",
          snapshotConfigs: [{ slot: "mod", itemHash: 201, itemName: "Mod A", modHashes: null }],
        },
      ],
      now,
    );

    const hashes = await collectVariantMods(db, user.id, "var-1");
    expect(hashes.sort((a, b) => a - b)).toEqual([101, 102, 201]);
  });
});
