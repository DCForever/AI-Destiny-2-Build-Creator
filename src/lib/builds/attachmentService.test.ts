import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { createVariantRecord, listAttachments } from "@/lib/db/repositories/variantRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { prepareAttachments } from "./attachmentService";
import { loadExpandedAttachmentItems } from "./resolveVariant";

describe("attachmentService", () => {
  it("captures snapshot configs at attach time", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "a1", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "build-1",
      name: "Test",
      className: "Titan",
      subclass: { name: "Sunbreaker" },
      exoticArmorHash: 1,
      exoticArmorName: "X",
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      tagIds: [],
      synergyTypes: [{ type: "melee", subType: "Base" }],
      now,
    });

    createSetRecord(db, user.id, { id: "set-a", name: "Armor", type: "armor", tagIds: [], now });
    await upsertSetItem(db, "set-a", "armor", {
      slot: "helmet",
      itemHash: 100,
      itemName: "Helm",
    });

    createVariantRecord(db, {
      id: "var-1",
      buildId: "build-1",
      name: "Default",
      isDefault: true,
      now,
    });

    await prepareAttachments(db, user.id, "var-1", [{ setId: "set-a", mode: "snapshot" }], now);
    const attachments = listAttachments(db, "var-1");
    expect(attachments[0]?.mode).toBe("snapshot");
    expect(attachments[0]?.snapshotConfigs).toHaveLength(1);

    await upsertSetItem(db, "set-a", "armor", {
      slot: "helmet",
      itemHash: 200,
      itemName: "New Helm",
      confirmReplace: true,
    });

    const liveItems = await loadExpandedAttachmentItems(db, user.id, attachments[0]!);
    expect(liveItems[0]?.itemHash).toBe(100);
  });

  it("live attachment reflects set changes", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "a2", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "build-2",
      name: "Test",
      className: "Titan",
      subclass: { name: "Sunbreaker" },
      exoticArmorHash: 1,
      exoticArmorName: "X",
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      tagIds: [],
      synergyTypes: [{ type: "melee", subType: "Base" }],
      now,
    });

    createSetRecord(db, user.id, { id: "set-l", name: "Live", type: "weapon", tagIds: [], now });
    await upsertSetItem(db, "set-l", "weapon", { slot: "primary", itemHash: 300, itemName: "Old" });

    createVariantRecord(db, { id: "var-2", buildId: "build-2", name: "Default", now });
    await prepareAttachments(db, user.id, "var-2", [{ setId: "set-l", mode: "live" }], now);

    await upsertSetItem(db, "set-l", "weapon", {
      slot: "primary",
      itemHash: 400,
      itemName: "New",
      confirmReplace: true,
    });

    const attachments = listAttachments(db, "var-2");
    const items = await loadExpandedAttachmentItems(db, user.id, attachments[0]!);
    expect(items[0]?.itemHash).toBe(400);
  });
});
