import { describe, expect, it } from "vitest";

import { createSetAndAttach } from "@/lib/builds/createSetAndAttach";
import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { createSetRecord, getSet } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import {
  createVariantRecord,
  listAttachments,
} from "@/lib/db/repositories/variantRepository";

describe("createSetAndAttach", () => {
  it("creates empty armor set and live-attaches replace-by-type", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "csa1", 3, "Player");
    seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "b1",
      name: "Voidlock",
      className: "Warlock",
      subclass: { name: "Voidwalker" },
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
      id: "v1",
      buildId: "b1",
      name: "Default",
      isDefault: true,
      now,
    });
    createSetRecord(db, user.id, {
      id: "old-armor",
      name: "Old",
      type: "armor",
      tagIds: [],
      now,
    });
    const { prepareAttachments } = await import("@/lib/builds/attachmentService");
    await prepareAttachments(
      db,
      user.id,
      "v1",
      [{ setId: "old-armor", mode: "live" }],
      now,
    );

    const result = await createSetAndAttach(db, user.id, "b1", {
      variantId: "v1",
      type: "armor",
      attachNow: true,
    });

    expect(result.set.type).toBe("armor");
    expect(result.set.name).toMatch(/Voidlock/);
    expect(result.attachment?.mode).toBe("live");
    expect(result.attachment?.replacedSetIds).toContain("old-armor");
    expect(listAttachments(db, "v1").map((a) => a.setId)).toEqual([
      result.set.id,
    ]);
    expect(getSet(db, user.id, result.set.id)?.type).toBe("armor");
  });

  it("auto-suffixes duplicate names", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "csa2", 3, "Player");
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
    createSetRecord(db, user.id, {
      id: "exist",
      name: "Kit Armor",
      type: "armor",
      tagIds: [],
      now,
    });

    const result = await createSetAndAttach(db, user.id, "b2", {
      variantId: "v2",
      type: "armor",
      name: "Kit Armor",
    });
    expect(result.set.name).toBe("Kit Armor (2)");
  });

  it("skips attach when attachNow false", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "csa3", 3, "Player");
    seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();
    createBuildRecord(db, user.id, {
      id: "b3",
      name: "X",
      className: "Titan",
      subclass: { name: "Striker" },
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
      id: "v3",
      buildId: "b3",
      name: "Default",
      isDefault: true,
      now,
    });

    const result = await createSetAndAttach(db, user.id, "b3", {
      variantId: "v3",
      type: "weapon",
      attachNow: false,
    });
    expect(result.attachment).toBeNull();
    expect(listAttachments(db, "v3")).toHaveLength(0);
  });
});
