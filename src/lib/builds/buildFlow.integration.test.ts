import { describe, expect, it, vi } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { createUserBuild, updateUserVariant } from "@/lib/builds/buildService";

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
    const now = new Date().toISOString();

    createSetRecord(db, user.id, {
      id: "weapon-set",
      name: "Solar PVE",
      type: "weapon",
      tagIds: ["solar", "pve"],
      now,
    });
    await upsertSetItem(db, "weapon-set", "weapon", {
      slot: "primary",
      itemHash: 900,
      itemName: "Sunshot",
      selectedPerks: [111, 222],
    });

    const build = await createUserBuild(db, user.id, {
      name: "Solar Flow",
      className: "Hunter",
      subclass: { name: "Gunslinger", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 700,
      exoticArmorName: "Celestial Nighthawk",
      synergyIds: [synergies[0]!.id],
      tagIds: ["solar", "pve"],
    });

    const variantId = build!.variants[0]!.id;
    const attached = await updateUserVariant(db, user.id, build!.id, variantId, {
      attachments: [{ setId: "weapon-set", mode: "snapshot" }],
    });

    const variant = attached!.variants.find((v) => v.id === variantId);
    expect(variant?.attachments).toHaveLength(1);
    expect(variant?.attachments[0]?.setId).toBe("weapon-set");
    expect(variant?.resolved?.equipment?.primary?.itemHash).toBe(900);
  });
});
