import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { createUserBuild, updateUserVariant } from "@/lib/builds/buildService";
import { compareBuildVariants } from "@/lib/builds/compareVariants";
import { seedFullCombatAttachments } from "@/lib/builds/testFixtures";
import { createUserVariant, deleteUserVariant } from "@/lib/builds/variantService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async () => []),
    },
  })),
}));

describe("variantService", () => {
  it("duplicates variant with snapshot attachments and notes", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "v1", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const attachments = await seedFullCombatAttachments(db, user.id, "v1");

    const build = await createUserBuild(db, user.id, {
      name: "Test",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      synergyIds: [synergies[0]!.id],
      defaultVariant: { name: "Default", notes: "Survivability" },
    });

    const sourceId = build!.variants[0]!.id;
    await updateUserVariant(db, user.id, build!.id, sourceId, { attachments });

    const updated = await createUserVariant(db, user.id, build!.id, {
      duplicateFromVariantId: sourceId,
      name: "DPS",
      notes: "DPS",
    });

    expect(updated?.variants).toHaveLength(2);
    const copy = updated!.variants.find((v) => v.name === "DPS");
    expect(copy?.notes).toBe("DPS");
    expect(copy?.attachments[0]?.mode).toBe("snapshot");
    expect(copy?.attachments[0]?.snapshotConfigs?.length).toBeGreaterThan(0);
  });

  it("compare highlights notes and slot diffs", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "v2", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Compare",
      className: "Warlock",
      subclass: { name: "Voidwalker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 200,
      synergyIds: [synergies[0]!.id],
      defaultVariant: { name: "Default", notes: "Base" },
    });

    const dup = await createUserVariant(db, user.id, build!.id, {
      duplicateFromVariantId: build!.variants[0]!.id,
      name: "Alt",
      notes: "Alt notes",
    });

    const compare = await compareBuildVariants(db, user.id, build!.id);
    expect(compare?.shared.exoticArmor.hash).toBe(200);
    expect(compare?.variants).toHaveLength(2);
    expect(compare?.variants.some((v) => v.diffNotes)).toBe(true);
    expect(dup?.variants).toHaveLength(2);
  });

  it("blocks deleting sole variant", () => {
    const db = createTestDb();
    const user = ensureUser(db, "v3", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);

    return createUserBuild(db, user.id, {
      name: "Solo",
      className: "Hunter",
      subclass: { name: "Arcstrider", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 300,
      synergyIds: [synergies[0]!.id],
    }).then((build) => {
      expect(() =>
        deleteUserVariant(db, user.id, build!.id, build!.variants[0]!.id),
      ).toThrowError(expect.objectContaining({ code: API_ERROR_CODES.VARIANT_EMPTY }));
    });
  });
});
