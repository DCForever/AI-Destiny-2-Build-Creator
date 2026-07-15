import { describe, expect, it } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { createVariantRecord, listAttachments } from "@/lib/db/repositories/variantRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { prepareAttachments } from "@/lib/builds/attachmentService";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { parseOptimizerConstraints } from "@/lib/optimizer/types";
import {
  materializeCombination,
  type MaterializeCombinationBody,
  type MaterializeOwnership,
} from "@/lib/sets/materializeCombination";
import { listActiveSetItems } from "@/lib/sets/setItemService";

const SLOTS = ["helmet", "arms", "chest", "legs", "class_item"] as const;

function pieces(): MaterializeCombinationBody["pieces"] {
  return SLOTS.map((slot, i) => ({ slot, itemHash: 100 + i, instanceId: `inst-${slot}` }));
}

function body(overrides: Partial<MaterializeCombinationBody> = {}): MaterializeCombinationBody {
  return {
    pieces: pieces(),
    constraints: {
      lockedExoticItemHash: 100,
      setBonusGoals: [],
      statPriorities: ["Melee"],
      statThresholds: { Melee: 60 },
      preferReuse: false,
      includeModEstimates: true,
    },
    armorSetName: "Optimized Kit",
    ...overrides,
  };
}

function ownership(): MaterializeOwnership {
  const map = new Map<string, { itemHash: number; isExotic: boolean }>();
  for (const [i, slot] of SLOTS.entries()) {
    map.set(`inst-${slot}`, { itemHash: 100 + i, isExotic: false });
  }
  return { byInstanceId: map };
}

describe("materializeCombination", () => {
  it("creates a new armor set, persists constraints, and upserts five items", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m1", 3, "Player");

    const result = await materializeCombination(db, user.id, body());

    const set = getSet(db, user.id, result.armorSet.id)!;
    expect(set.type).toBe("armor");
    expect(set.name).toBe("Optimized Kit");
    const constraints = parseOptimizerConstraints(set.optimizerConstraints);
    expect(constraints?.lockedExoticItemHash).toBe(100);
    expect(constraints?.statThresholds?.Melee).toBe(60);
    const items = await listActiveSetItems(db, set.id);
    expect(items).toHaveLength(5);
  });

  it("auto-uniquifies the set name on collision", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m2", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, { id: "x", name: "Optimized Kit", type: "armor", tagIds: [], now });

    const result = await materializeCombination(db, user.id, body());
    expect(result.armorSet.name).toBe("Optimized Kit (2)");
  });

  it("creates a linked mod set when assumed mods are present", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m3", 3, "Player");

    const result = await materializeCombination(
      db,
      user.id,
      body({ assumedMods: [{ armorSlot: "helmet", itemHash: 900_000_001 }] }),
    );

    expect(result.modSet).toBeDefined();
    const armor = getSet(db, user.id, result.armorSet.id)!;
    expect(armor.linkedModSetId).toBe(result.modSet!.id);
    const modItems = await listActiveSetItems(db, result.modSet!.id);
    expect(modItems.length).toBeGreaterThan(0);
  });

  it("attaches armor set replace-by-type when attachNow", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m4", 3, "Player");
    const now = new Date().toISOString();
    createBuildRecord(db, user.id, {
      id: "b1",
      name: "Build",
      className: "Titan",
      subclass: { name: "Striker" },
      exoticArmorHash: null,
      exoticArmorName: null,
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      tagIds: [],
      synergyTypes: [],
      now,
    });
    createVariantRecord(db, { id: "v1", buildId: "b1", name: "Default", isDefault: true, now });
    createSetRecord(db, user.id, { id: "old", name: "Old Armor", type: "armor", tagIds: [], now });
    await prepareAttachments(db, user.id, "v1", [{ setId: "old", mode: "live" }], now);

    const result = await materializeCombination(
      db,
      user.id,
      body({ attachNow: true, buildId: "b1", variantId: "v1" }),
    );

    expect(result.attachments).toHaveLength(1);
    expect(result.attachments[0]?.replacedSetIds).toContain("old");
    const attached = listAttachments(db, "v1").map((a) => a.setId);
    expect(attached).toEqual([result.armorSet.id]);
  });

  it("rejects incomplete kits", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m5", 3, "Player");
    await expect(
      materializeCombination(db, user.id, body({ pieces: pieces().slice(0, 4) })),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_ITEM });
  });

  it("rejects more than one exotic via ownership", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m6", 3, "Player");
    const own = ownership();
    own.byInstanceId.set("inst-helmet", { itemHash: 100, isExotic: true });
    own.byInstanceId.set("inst-arms", { itemHash: 101, isExotic: true });
    await expect(materializeCombination(db, user.id, body(), own)).rejects.toMatchObject({
      code: API_ERROR_CODES.EXOTIC_LIMIT,
    });
  });

  it("rejects unowned instances via ownership", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m7", 3, "Player");
    const own = ownership();
    own.byInstanceId.delete("inst-legs");
    await expect(materializeCombination(db, user.id, body(), own)).rejects.toMatchObject({
      code: API_ERROR_CODES.INSTANCE_NOT_OWNED,
    });
  });

  it("requires build/variant when attachNow", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "m8", 3, "Player");
    await expect(
      materializeCombination(db, user.id, body({ attachNow: true })),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.ATTACH_REQUIRES_BUILD });
  });
});
