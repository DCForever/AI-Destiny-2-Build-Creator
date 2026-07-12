import { describe, expect, it, vi } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { createUserBuild, updateUserVariant } from "@/lib/builds/buildService";
import { seedFullCombatAttachments } from "@/lib/builds/testFixtures";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async () => []),
      getMeta: vi.fn(async () => null),
    },
  })),
}));

describe("buildFlow integration", () => {
  it("creates set, attaches to build variant, and resolves equipment", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "flow1", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const attachments = await seedFullCombatAttachments(db, user.id, "flow");

    const build = await createUserBuild(db, user.id, {
      name: "Solar Flow",
      className: "Hunter",
      subclass: { name: "Gunslinger", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 700,
      exoticArmorName: "Celestial Nighthawk",
      synergyTypes: [{ type: "melee", subType: "Base" }],
      tagIds: ["solar", "pve"],
    });

    const variantId = build!.variants[0]!.id;
    const attached = await updateUserVariant(db, user.id, build!.id, variantId, {
      attachments: attachments.map((a) => ({ ...a, mode: "snapshot" as const })),
    });

    const variant = attached!.variants.find((v) => v.id === variantId);
    expect(variant?.attachments).toHaveLength(3);
    expect(variant?.attachments.some((a) => a.setId === "flow-weapons")).toBe(true);
    expect(variant?.resolved?.equipment?.primary?.itemHash).toBe(1000);
  });
});
