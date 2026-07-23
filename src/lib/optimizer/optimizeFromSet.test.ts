import { describe, expect, it } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { serializeOptimizerConstraints } from "@/lib/optimizer/types";
import { upsertSetItem } from "@/lib/sets/setItemService";

import { optimizeFromSet } from "./optimizeFromSet";
import { ARMOR_OPTIMIZER_SLOTS, type ArmorSlot, type CandidatePiece } from "./types";

function piece(slot: ArmorSlot, instanceId: string, melee: number): CandidatePiece {
  return {
    slot,
    itemHash: 10,
    instanceId,
    isExotic: false,
    statValues: { Melee: melee },
    energyCapacity: 10,
    usedInSets: [],
  };
}

/** Current (weak) piece + a stronger alternative per slot. */
function candidatePool(): CandidatePiece[] {
  const pool: CandidatePiece[] = [];
  for (const slot of ARMOR_OPTIMIZER_SLOTS) {
    pool.push(piece(slot, `cur-${slot}`, 2));
    pool.push(piece(slot, `better-${slot}`, 10));
  }
  return pool;
}

async function seedConstrainedSet(db: ReturnType<typeof createTestDb>, userId: number, id: string) {
  const now = new Date().toISOString();
  createSetRecord(db, userId, {
    id,
    name: "Kit",
    type: "armor",
    tagIds: [],
    now,
    optimizerConstraints: serializeOptimizerConstraints({
      setBonusGoals: [],
      statPriorities: ["Melee"],
      includeModEstimates: false,
    }),
  });
  for (const slot of ARMOR_OPTIMIZER_SLOTS) {
    await upsertSetItem(db, id, "armor", {
      slot,
      itemHash: 10,
      itemName: "Cur",
      instanceId: `cur-${slot}`,
      confirmReplace: true,
    });
  }
}

describe("optimizeFromSet", () => {
  it("optimizes with stored constraints and flags improvement over current pieces", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of1", 3, "Player");
    await seedConstrainedSet(db, user.id, "set-1");

    const result = await optimizeFromSet({
      db,
      userId: user.id,
      setId: "set-1",
      classType: "Titan",
      candidates: candidatePool(),
    });

    expect(result.armorSetId).toBe("set-1");
    expect(result.constraintsUsed.statPriorities).toEqual(["Melee"]);
    expect(result.hasImprovement).toBe(true);
    expect(result.combinations.length).toBeGreaterThan(0);
  });

  it("reports no improvement when current pieces are already optimal", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of2", 3, "Player");
    await seedConstrainedSet(db, user.id, "set-2");
    const strongCurrent = ARMOR_OPTIMIZER_SLOTS.map((slot) => piece(slot, `cur-${slot}`, 10));

    const result = await optimizeFromSet({
      db,
      userId: user.id,
      setId: "set-2",
      classType: "Titan",
      candidates: strongCurrent,
    });
    expect(result.hasImprovement).toBe(false);
  });

  it("throws NO_CONSTRAINTS when the set has no stored constraints", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of3", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, { id: "bare", name: "Bare", type: "armor", tagIds: [], now });

    await expect(
      optimizeFromSet({ db, userId: user.id, setId: "bare", classType: "Titan", candidates: candidatePool() }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.NO_CONSTRAINTS });
  });

  it("throws SET_NOT_FOUND for unknown sets", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of4", 3, "Player");
    await expect(
      optimizeFromSet({ db, userId: user.id, setId: "missing", classType: "Titan", candidates: [] }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SET_NOT_FOUND });
  });

  it("optimizes empty armor set when classType is provided", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of5", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "empty-armor",
      name: "Empty",
      type: "armor",
      tagIds: [],
      now,
      optimizerConstraints: serializeOptimizerConstraints({
        setBonusGoals: [],
        statPriorities: ["Melee"],
        includeModEstimates: false,
      }),
    });

    const result = await optimizeFromSet({
      db,
      userId: user.id,
      setId: "empty-armor",
      classType: "Warlock",
      candidates: candidatePool(),
    });

    expect(result.armorSetId).toBe("empty-armor");
    expect(result.combinations.length).toBeGreaterThan(0);
  });

  it("fails class resolution on empty set without classType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "of6", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "empty-no-class",
      name: "Empty2",
      type: "armor",
      tagIds: [],
      now,
      optimizerConstraints: serializeOptimizerConstraints({
        setBonusGoals: [],
        includeModEstimates: false,
      }),
    });

    await expect(
      optimizeFromSet({
        db,
        userId: user.id,
        setId: "empty-no-class",
        candidates: candidatePool(),
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_ITEM });
  });
});
