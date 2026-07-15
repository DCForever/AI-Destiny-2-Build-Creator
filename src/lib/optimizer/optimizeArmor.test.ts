import { describe, expect, it } from "vitest";

import { optimizeArmor } from "./optimizeArmor";
import { ARMOR_OPTIMIZER_SLOTS, type ArmorSlot, type CandidatePiece } from "./types";
import type { AppDatabase } from "@/lib/db/client";

const db = {} as AppDatabase;

function piece(slot: ArmorSlot, itemHash: number, extra: Partial<CandidatePiece> = {}): CandidatePiece {
  return {
    slot,
    itemHash,
    instanceId: `${slot}-${itemHash}`,
    isExotic: false,
    statValues: {},
    energyCapacity: 10,
    usedInSets: [],
    ...extra,
  };
}

/** Two options per slot so ranking has something to sort. */
function candidatePool(): CandidatePiece[] {
  const pool: CandidatePiece[] = [];
  ARMOR_OPTIMIZER_SLOTS.forEach((slot, i) => {
    pool.push(piece(slot, 100 + i, { statValues: { Melee: 10 } }));
    pool.push(piece(slot, 200 + i, { statValues: { Melee: 5, Health: 20 } }));
  });
  return pool;
}

describe("optimizeArmor (injected candidates)", () => {
  it("returns complete five-slot kits ranked by priority", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      statPriorities: ["Melee"],
    });
    expect(result.combinations.length).toBeGreaterThan(0);
    for (const combo of result.combinations) {
      expect(combo.pieces).toHaveLength(5);
      expect(combo.pieces.filter((p) => p.isExotic).length).toBeLessThanOrEqual(1);
    }
    const first = result.combinations[0].estimatedStats.Melee ?? 0;
    const last = result.combinations.at(-1)?.estimatedStats.Melee ?? 0;
    expect(first).toBeGreaterThanOrEqual(last);
  });

  it("respects maxResults and reports evaluatedCount", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      maxResults: 3,
    });
    expect(result.combinations.length).toBeLessThanOrEqual(3);
    expect(result.evaluatedCount).toBeGreaterThan(0);
  });

  it("flags truncated when more valid kits exist than maxResults (SC-007)", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      maxResults: 3,
    });
    // 2^5 = 32 complete kits from candidatePool(); only the top 3 are returned.
    expect(result.combinations).toHaveLength(3);
    expect(result.truncated).toBe(true);
    expect(result.evaluatedCount).toBeGreaterThanOrEqual(32);
  });

  it("does not flag truncated when every valid kit fits within maxResults", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      maxResults: 50,
    });
    expect(result.combinations.length).toBeLessThanOrEqual(50);
    expect(result.truncated).toBe(false);
  });

  it("requires the locked exotic in every kit", async () => {
    const pool = candidatePool();
    pool.push(piece("helmet", 555, { isExotic: true, statValues: { Melee: 99 } }));
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: pool,
      lockedExoticItemHash: 555,
    });
    for (const combo of result.combinations) {
      expect(combo.pieces.some((p) => p.itemHash === 555)).toBe(true);
    }
  });

  it("returns EXOTIC_UNAVAILABLE when the locked exotic is not owned", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      lockedExoticItemHash: 999999,
    });
    expect(result.combinations).toHaveLength(0);
    expect(result.emptyReason?.code).toBe("EXOTIC_UNAVAILABLE");
  });

  it("returns NO_CLASS_ARMOR when no candidates are available", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: [],
    });
    expect(result.emptyReason?.code).toBe("NO_CLASS_ARMOR");
  });

  it("hard-filters when thresholds are required and unmet", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      statThresholds: { Melee: 999 },
      requireThresholds: true,
    });
    expect(result.combinations).toHaveLength(0);
    expect(result.emptyReason?.code).toBe("THRESHOLDS_UNMET");
  });

  it("annotates soft thresholds without filtering when not required", async () => {
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: candidatePool(),
      statThresholds: { Melee: 999 },
    });
    expect(result.combinations.length).toBeGreaterThan(0);
    expect(result.combinations.every((c) => c.meetsSoftThresholds === false)).toBe(true);
  });

  it("meets a soft Melee threshold only with mod estimates enabled (SC-004)", async () => {
    const base = { db, userId: 1, classType: "Titan" as const, statThresholds: { Melee: 60 } };

    const withoutMods = await optimizeArmor({
      ...base,
      candidates: candidatePool(),
      includeModEstimates: false,
    });
    expect(withoutMods.combinations.every((c) => c.meetsSoftThresholds === false)).toBe(true);
    expect(withoutMods.combinations.every((c) => c.assumedMods.length === 0)).toBe(true);

    const withMods = await optimizeArmor({
      ...base,
      candidates: candidatePool(),
      includeModEstimates: true,
    });
    const top = withMods.combinations[0];
    expect(top.assumedMods.length).toBeGreaterThan(0);
    expect(top.estimatedStats.Melee ?? 0).toBeGreaterThanOrEqual(60);
    expect(top.meetsSoftThresholds).toBe(true);
  });

  it("enforces set-bonus coverage goals", async () => {
    const pool = candidatePool().map((p) =>
      p.slot === "helmet" || p.slot === "arms" ? { ...p, setBonusKey: "TechSec" } : p,
    );
    const result = await optimizeArmor({
      db,
      userId: 1,
      classType: "Titan",
      candidates: pool,
      setBonusGoals: [{ setBonusKey: "TechSec", minPieces: 2 }],
    });
    expect(result.combinations.length).toBeGreaterThan(0);
    for (const combo of result.combinations) {
      const tech = combo.setBonusSummary.find((s) => s.setBonusKey === "TechSec");
      expect(tech?.pieceCount).toBeGreaterThanOrEqual(2);
    }
  });
});
