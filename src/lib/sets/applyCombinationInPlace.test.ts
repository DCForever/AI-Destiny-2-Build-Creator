import { describe, expect, it } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { getSet } from "@/lib/db/repositories/setRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { serializeOptimizerConstraints } from "@/lib/optimizer/types";
import {
  applyCombinationInPlace,
  type ApplyCombinationBody,
} from "@/lib/sets/applyCombinationInPlace";
import { listActiveSetItems, upsertSetItem } from "@/lib/sets/setItemService";

const SLOTS = ["helmet", "arms", "chest", "legs", "class_item"] as const;

function newPieces(prefix: string): ApplyCombinationBody["pieces"] {
  return SLOTS.map((slot, i) => ({ slot, itemHash: 500 + i, instanceId: `${prefix}-${slot}` }));
}

async function seedArmorSet(db: ReturnType<typeof createTestDb>, userId: number, id: string) {
  const now = new Date().toISOString();
  createSetRecord(db, userId, {
    id,
    name: "Living Kit",
    type: "armor",
    tagIds: [],
    now,
    optimizerConstraints: serializeOptimizerConstraints({ setBonusGoals: [], statPriorities: ["Melee"] }),
  });
  for (const slot of SLOTS) {
    await upsertSetItem(db, id, "armor", {
      slot,
      itemHash: 10,
      itemName: "Old",
      instanceId: `old-${slot}`,
      confirmReplace: true,
    });
  }
}

describe("applyCombinationInPlace", () => {
  it("replaces items on the same set id and keeps constraints", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "ap1", 3, "Player");
    await seedArmorSet(db, user.id, "set-1");

    const result = await applyCombinationInPlace(db, user.id, "set-1", { pieces: newPieces("new") });

    expect(result.itemsUpdated).toBe(true);
    expect(result.armorSet.id).toBe("set-1");
    expect(result.armorSet.optimizerConstraints?.statPriorities).toEqual(["Melee"]);
    const items = await listActiveSetItems(db, "set-1");
    expect(items).toHaveLength(5);
    expect(items.map((i) => i.instanceId).sort()).toEqual(newPieces("new").map((p) => p.instanceId).sort());
  });

  it("is a no-op when the kit equals the current pieces", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "ap2", 3, "Player");
    await seedArmorSet(db, user.id, "set-2");
    const same = SLOTS.map((slot) => ({ slot, itemHash: 10, instanceId: `old-${slot}` }));

    const result = await applyCombinationInPlace(db, user.id, "set-2", { pieces: same });
    expect(result.itemsUpdated).toBe(false);
  });

  it("rejects unknown or non-armor sets", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "ap3", 3, "Player");
    await expect(
      applyCombinationInPlace(db, user.id, "missing", { pieces: newPieces("x") }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SET_NOT_FOUND });
  });

  it("creates and links a mod set when assumed mods are present", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "ap4", 3, "Player");
    await seedArmorSet(db, user.id, "set-4");

    const result = await applyCombinationInPlace(db, user.id, "set-4", {
      pieces: newPieces("new"),
      assumedMods: [{ armorSlot: "helmet", itemHash: 900_000_001 }],
    });

    expect(result.modSet).toBeDefined();
    expect(result.modSet?.updated).toBe(false);
    const armor = getSet(db, user.id, "set-4")!;
    expect(armor.linkedModSetId).toBe(result.modSet!.id);
  });

  it("updates an existing linked mod set in place", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "ap5", 3, "Player");
    await seedArmorSet(db, user.id, "set-5");
    const first = await applyCombinationInPlace(db, user.id, "set-5", {
      pieces: newPieces("new"),
      assumedMods: [{ armorSlot: "helmet", itemHash: 900_000_001 }],
    });

    const second = await applyCombinationInPlace(db, user.id, "set-5", {
      pieces: newPieces("new"),
      assumedMods: [{ armorSlot: "arms", itemHash: 900_000_002 }],
    });

    expect(second.modSet?.id).toBe(first.modSet?.id);
    expect(second.modSet?.updated).toBe(true);
  });
});
