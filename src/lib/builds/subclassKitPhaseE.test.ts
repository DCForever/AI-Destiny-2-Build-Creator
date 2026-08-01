import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { listVariants } from "@/lib/db/repositories/variantRepository";
import {
  createUserBuild,
  updateUserBuild,
  updateUserVariant,
} from "@/lib/builds/buildService";
import { createUserVariant } from "@/lib/builds/variantService";
import {
  COMPLETE_DEFAULT_ARTIFACT,
  COMPLETE_DEFAULT_SUBCLASS_KIT,
} from "@/lib/builds/testFixtures";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async (name: string) => {
        if (name === "artifacts") {
          return [
            {
              hash: COMPLETE_DEFAULT_ARTIFACT.artifactHash,
              name: COMPLETE_DEFAULT_ARTIFACT.artifactName,
              perks: COMPLETE_DEFAULT_ARTIFACT.artifactConfig.map((hash) => ({
                hash,
                name: `Perk ${hash}`,
              })),
            },
          ];
        }
        return [];
      }),
    },
  })),
}));

describe("Phase E per-variant kit + tree wipe", () => {
  it("stores kit on default variant at create", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "e1", 3, "Player");
    seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Solar Titan",
      className: "Titan",
      subclass: { ...COMPLETE_DEFAULT_SUBCLASS_KIT },
      synergyTypes: [{ type: "melee", subType: "Base" }],
      defaultVariant: { ...COMPLETE_DEFAULT_ARTIFACT },
    });

    const def = build!.variants.find((v) => v.isDefault);
    expect(def?.subclassKit?.super).toBe(COMPLETE_DEFAULT_SUBCLASS_KIT.super);
    expect(def?.subclass?.name).toBe("Sunbreaker");
    expect(def?.subclass?.aspects).toEqual(COMPLETE_DEFAULT_SUBCLASS_KIT.aspects);
  });

  it("allows different kits on variants without identity confirm", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "e2", 3, "Player");
    seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Kit Split",
      className: "Titan",
      subclass: { ...COMPLETE_DEFAULT_SUBCLASS_KIT },
      synergyTypes: [{ type: "melee", subType: "Base" }],
      defaultVariant: { ...COMPLETE_DEFAULT_ARTIFACT },
    });
    const defaultId = build!.variants[0]!.id;

    const withCopy = await createUserVariant(db, user.id, build!.id, {
      name: "Alt",
      duplicateFromVariantId: defaultId,
    });
    const alt = withCopy!.variants.find((v) => v.name === "Alt")!;

    const updated = await updateUserVariant(db, user.id, build!.id, alt.id, {
      subclassKit: {
        ...COMPLETE_DEFAULT_SUBCLASS_KIT,
        super: "Burning Maul",
        aspects: ["Roaring Flames", "Sol Invictus"],
      },
    });

    const def = updated!.variants.find((v) => v.isDefault)!;
    const altNext = updated!.variants.find((v) => v.id === alt.id)!;
    expect(def.subclass?.super).toBe(COMPLETE_DEFAULT_SUBCLASS_KIT.super);
    expect(altNext.subclass?.super).toBe("Burning Maul");
    expect(altNext.subclass?.aspects).toContain("Sol Invictus");
  });

  it("tree change requires identity action and wipes all variant kits", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "e3", 3, "Player");
    seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Tree Swap",
      className: "Titan",
      subclass: { ...COMPLETE_DEFAULT_SUBCLASS_KIT },
      synergyTypes: [{ type: "melee", subType: "Base" }],
      defaultVariant: { ...COMPLETE_DEFAULT_ARTIFACT },
    });

    await expect(
      updateUserBuild(db, user.id, build!.id, {
        subclass: { ...COMPLETE_DEFAULT_SUBCLASS_KIT, name: "Striker" },
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.IDENTITY_CONFIRM_REQUIRED });

    const confirmed = await updateUserBuild(db, user.id, build!.id, {
      subclass: { ...COMPLETE_DEFAULT_SUBCLASS_KIT, name: "Striker" },
      identityAction: "confirm",
    });

    expect(
      (confirmed!.subclass as { name?: string }).name ??
        confirmed!.variants[0]?.subclass?.name,
    ).toBe("Striker");

    for (const v of listVariants(db, build!.id)) {
      expect(v.subclassKit?.aspects ?? []).toEqual([]);
      expect(v.subclassKit?.super ?? "").toBe("");
    }
    const detail = confirmed!.variants[0];
    expect(detail?.subclass?.aspects ?? []).toEqual([]);
  });
});
