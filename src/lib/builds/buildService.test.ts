import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import {
  createUserBuild,
  listUserBuilds,
  updateUserVariant,
} from "@/lib/builds/buildService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async () => []),
    },
  })),
}));

describe("buildService", () => {
  it("requires explicit synergies and does not auto-designate one", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b0", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const baseInput = {
      name: "No Designation",
      className: "Titan" as const,
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
    };
    const missingSynergyInput = baseInput as unknown as Parameters<typeof createUserBuild>[2];

    await expect(createUserBuild(db, user.id, missingSynergyInput)).rejects.toMatchObject({
      code: API_ERROR_CODES.NO_SYNERGY,
    });
    await expect(
      createUserBuild(db, user.id, { ...baseInput, synergyTypes: [] }),
    ).rejects.toMatchObject({
      code: API_ERROR_CODES.NO_SYNERGY,
    });

    expect(synergies.length).toBeGreaterThan(0);
    expect(listUserBuilds(db, user.id)).toHaveLength(0);
  });

  it("creates build with default variant and synergy", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b1", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Solar Titan",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      exoticArmorName: "Hallowfire Heart",
      synergyTypes: [{ type: "melee", subType: "Base" }],
      tagIds: ["solar", "pve"],
      defaultVariant: { attachments: [] },
    });

    expect(build?.variants).toHaveLength(1);
    expect(build?.synergies).toHaveLength(1);
  });

  it("rejects incomplete default loadout when attachments saved", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b2", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createSetRecord(db, user.id, { id: "set-w", name: "Weapons", type: "weapon", tagIds: [], now });
    await upsertSetItem(db, "set-w", "weapon", {
      slot: "primary",
      itemHash: 500,
      itemName: "Gun",
    });

    const build = await createUserBuild(db, user.id, {
      name: "Empty",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      synergyTypes: [{ type: "melee", subType: "Base" }],
    });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: "set-w", mode: "live" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.DEFAULT_VARIANT_INCOMPLETE });

    const emptySet = crypto.randomUUID();
    createSetRecord(db, user.id, { id: emptySet, name: "Empty Set", type: "mod", tagIds: [], now });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: emptySet, mode: "live" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.DEFAULT_VARIANT_INCOMPLETE });
  });

  it("allows create without exotic armor and with pinned super / shared weapon", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b-id", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      className: "Warlock",
      subclass: {
        name: "Stormcaller",
        super: "Chaos Reach",
        classAbility: "",
        movement: "",
        melee: "",
        grenade: "",
        aspects: [],
        fragments: [],
        rationale: "",
      },
      exoticArmorHash: null,
      exoticWeaponHash: 555,
      exoticWeaponName: "Riskrunner",
      pinnedSuper: "Chaos Reach",
      synergyTypes: [{ type: "melee", subType: "Base" }],
    });

    expect(build?.exoticArmorHash).toBeNull();
    expect(build?.exoticWeaponHash).toBe(555);
    expect(build?.pinnedSuper).toBe("Chaos Reach");
    expect(build?.name).toContain("Warlock");
  });

  it("requires identityAction when changing synergy types", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b-fork", 3, "Player");
    seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Original",
      className: "Titan",
      subclass: {
        name: "Sunbreaker",
        super: "",
        classAbility: "",
        movement: "",
        melee: "",
        grenade: "",
        aspects: [],
        fragments: [],
        rationale: "",
      },
      exoticArmorHash: 100,
      synergyTypes: [{ type: "melee", subType: "Base" }],
    });

    const { updateUserBuild } = await import("@/lib/builds/buildService");
    await expect(
      updateUserBuild(db, user.id, build!.id, {
        synergyTypes: [{ type: "grenade", subType: "Base" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.IDENTITY_CONFIRM_REQUIRED });

    const confirmed = await updateUserBuild(db, user.id, build!.id, {
      synergyTypes: [{ type: "grenade", subType: "Base" }],
      identityAction: "confirm",
    });
    expect(confirmed?.id).toBe(build!.id);
    expect(confirmed?.synergyTypes?.[0]?.type).toBe("grenade");

    const forked = await updateUserBuild(db, user.id, build!.id, {
      synergyTypes: [{ type: "melee", subType: "Base" }],
      identityAction: "fork",
    });
    expect(forked?.id).not.toBe(build!.id);
    expect((forked as { forkedFromId?: string })?.forkedFromId).toBe(build!.id);
  });

  it("creates build with unmatched synergy type (no library record)", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b-unmatched", 3, "Player");

    const build = await createUserBuild(db, user.id, {
      name: "Devour Intent",
      className: "Warlock",
      subclass: {
        name: "Voidwalker",
        super: "",
        classAbility: "",
        movement: "",
        melee: "",
        grenade: "",
        aspects: [],
        fragments: [],
        rationale: "",
      },
      synergyTypes: [{ type: "verb", subType: "Devour" }],
    });

    expect(build?.synergyTypes).toHaveLength(1);
    expect(build?.synergyTypes?.[0]?.label).toBe("Verb: Devour");
    expect(build?.synergies).toHaveLength(0);
  });

  it("rejects duplicate build names within the same class", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b-name", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const base = {
      className: "Warlock" as const,
      subclass: {
        name: "Stormcaller",
        super: "Chaos Reach",
        classAbility: "",
        movement: "",
        melee: "",
        grenade: "",
        aspects: [],
        fragments: [],
        rationale: "",
      },
      synergyTypes: [{ type: "melee" as const, subType: "Base" }],
    };

    await createUserBuild(db, user.id, { ...base, name: "Ionic Trace Kit" });
    await expect(createUserBuild(db, user.id, { ...base, name: "Ionic Trace Kit" })).rejects.toMatchObject({
      code: API_ERROR_CODES.DUPLICATE_BUILD_NAME,
    });
    await expect(
      createUserBuild(db, user.id, { ...base, className: "Titan", name: "Ionic Trace Kit" }),
    ).resolves.toBeTruthy();
  });

  it("blocks pair armor mismatch", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b3", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createSetRecord(db, user.id, { id: "pair-bad", name: "Pair", type: "pair", tagIds: [], now });
    await upsertSetItem(db, "pair-bad", "pair", {
      slot: "exotic_armor",
      itemHash: 999,
      itemName: "Wrong Armor",
    });

    const build = await createUserBuild(db, user.id, {
      name: "Pair Test",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      synergyTypes: [{ type: "melee", subType: "Base" }],
    });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: "pair-bad", mode: "live" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.PAIR_ARMOR_MISMATCH });
  });
});
