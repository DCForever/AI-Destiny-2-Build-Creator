import { describe, expect, it } from "vitest";

import { createSetsFromBuild } from "@/lib/builds/createSetsFromBuild";
import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { createVariantRecord, listAttachments } from "@/lib/db/repositories/variantRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { prepareAttachments } from "@/lib/builds/attachmentService";
import { parseOptimizerConstraints } from "@/lib/optimizer/types";

describe("createSetsFromBuild", () => {
  it("creates armor set with seeded constraints and attaches replace-by-type", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "cs1", 3, "Player");
    seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "b1",
      name: "Melee Lock",
      className: "Warlock",
      subclass: { name: "Dawnblade" },
      exoticArmorHash: 777,
      exoticArmorName: "Osmiomancy",
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      softStatTargets: { Melee: 100 },
      tagIds: [],
      synergyTypes: [{ type: "melee", subType: "Base" }],
      now,
    });
    createVariantRecord(db, {
      id: "v1",
      buildId: "b1",
      name: "Default",
      isDefault: true,
      now,
    });

    createSetRecord(db, user.id, { id: "armor-src", name: "Src", type: "armor", tagIds: [], now });
    await upsertSetItem(db, "armor-src", "armor", {
      slot: "helmet",
      itemHash: 777,
      itemName: "Osmiomancy",
      instanceId: "inst-helm",
      confirmReplace: true,
    });
    await upsertSetItem(db, "armor-src", "armor", {
      slot: "arms",
      itemHash: 10,
      itemName: "Arms",
      instanceId: "inst-arms",
      confirmReplace: true,
    });
    await prepareAttachments(db, user.id, "v1", [{ setId: "armor-src", mode: "live" }], now);

    const result = await createSetsFromBuild(db, user.id, "b1", {
      attachNow: true,
      categories: ["armor"],
    });

    expect(result.createdSets).toHaveLength(1);
    expect(result.createdSets[0]?.type).toBe("armor");
    expect(result.attachments).toHaveLength(1);

    const set = getSet(db, user.id, result.createdSets[0]!.id)!;
    const constraints = parseOptimizerConstraints(set.optimizerConstraints);
    expect(constraints?.lockedExoticItemHash).toBe(777);
    expect(constraints?.statThresholds?.Melee).toBe(100);
    expect(constraints?.setBonusGoals).toEqual([]);

    const attachments = listAttachments(db, "v1");
    expect(attachments.map((a) => a.setId)).toEqual([result.createdSets[0]!.id]);
  });

  it("skips attach when attachNow is false", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "cs2", 3, "Player");
    seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "b2",
      name: "Kit",
      className: "Hunter",
      subclass: { name: "Nightstalker" },
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
      id: "v2",
      buildId: "b2",
      name: "Default",
      isDefault: true,
      now,
    });
    createSetRecord(db, user.id, { id: "a2", name: "Src2", type: "armor", tagIds: [], now });
    await upsertSetItem(db, "a2", "armor", {
      slot: "chest",
      itemHash: 11,
      itemName: "Chest",
      confirmReplace: true,
    });
    await prepareAttachments(db, user.id, "v2", [{ setId: "a2", mode: "live" }], now);

    const result = await createSetsFromBuild(db, user.id, "b2", {
      attachNow: false,
      categories: ["armor"],
    });
    expect(result.attachments).toHaveLength(0);
    expect(listAttachments(db, "v2").map((a) => a.setId)).toEqual(["a2"]);
  });
});
