import { describe, expect, it, vi } from "vitest";

import { RAW_TABLES } from "@/lib/manifest/__fixtures__/rawTables";
import { listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async (store: string) => {
        if (store === "abilities") {
          return [
            {
              hash: 1018,
              name: "Chaos Reach",
              description: "Arc beam super.",
              kind: "super",
              classType: "Warlock",
              element: "Arc",
              searchName: "chaos reach",
              icon: null,
            },
            {
              hash: 1099,
              name: "Chaos Reach",
              description: "Longer arc beam super description.",
              kind: "super",
              classType: "Warlock",
              element: "Arc",
              searchName: "chaos reach",
              icon: null,
            },
            {
              hash: 1020,
              name: "Storm Fist",
              description: "Arc melee.",
              kind: "melee",
              classType: "Titan",
              element: "Arc",
              searchName: "storm fist",
              icon: null,
            },
            {
              hash: 1021,
              name: "Storm Fist",
              description: "Short.",
              kind: "melee",
              classType: "Titan",
              element: "Arc",
              searchName: "storm fist",
              icon: null,
            },
            {
              hash: 1019,
              name: "Pulse Grenade",
              description: "Arc grenade.",
              kind: "grenade",
              classType: null,
              element: "Arc",
              searchName: "pulse grenade",
              icon: null,
            },
            {
              hash: 1022,
              name: "Pulse Grenade",
              description: "Arc grenade.",
              kind: "grenade",
              classType: null,
              element: "Arc",
              searchName: "pulse grenade",
              icon: null,
            },
          ];
        }
        if (store === "weapons") {
          return [
            {
              hash: 100,
              name: "Outbreak Perfected",
              searchName: "outbreak perfected",
              description: "",
              icon: null,
              slot: "Kinetic",
              element: "Kinetic",
              ammo: "Primary",
              frame: "Micro-Missile Frame",
              itemTypeName: "Pulse Rifle",
              originTraitHashes: [],
              perkColumns: [],
            },
            {
              hash: 101,
              name: "Fatebringer",
              searchName: "fatebringer",
              description: "",
              icon: null,
              slot: "Kinetic",
              element: "Kinetic",
              ammo: "Primary",
              frame: "Adaptive Frame",
              itemTypeName: "Hand Cannon",
              originTraitHashes: [],
              perkColumns: [],
            },
          ];
        }
        if (store === "exotic-weapons") {
          return [
            {
              hash: 200,
              name: "Witherhoard",
              searchName: "witherhoard",
              description: "",
              icon: null,
              slot: "Kinetic",
              element: "Kinetic",
              ammo: "Special",
              frame: "Breech Grenade Launcher",
              intrinsic: { name: "Blight", description: "" },
              catalyst: null,
              flavorText: "",
            },
          ];
        }
        return [];
      }),
    },
    manifest: {
      getStatus: vi.fn(async () => ({ cachedVersion: "fixture-v" })),
      loadRawTable: vi.fn(async () => RAW_TABLES.DestinyInventoryItemDefinition),
    },
  })),
}));

describe("subTypeVocabularies", () => {
  it("lists curated verb glossary without Base", async () => {
    const verbs = await listSubTypeOptions("verb");
    const scorch = verbs.filter((v) => v.name === "Scorch");
    expect(scorch).toHaveLength(1);
    expect(verbs.some((v) => v.name === "Base")).toBe(false);
    expect(verbs.length).toBeGreaterThanOrEqual(32);
  });

  it("includes Destinypedia verb staples", async () => {
    const names = (await listSubTypeOptions("verb")).map((v) => v.name);
    for (const name of [
      "Sever",
      "Void Breach",
      "Radiant",
      "Weaken",
      "Cure",
      "Exhaust",
      "Devour",
      "Amplified",
      "Ionic Trace",
      "Stasis Shard",
      "Void Overshield",
      "Suppression",
    ]) {
      expect(names).toContain(name);
    }
    expect(names).not.toContain("Solar");
    expect(names).not.toContain("Volatile Rounds");
  });

  it("prepends Base for melee grenade super", async () => {
    const melee = await listSubTypeOptions("melee");
    expect(melee[0]?.name).toBe("Base");
    expect(melee.some((m) => m.name === "Storm Fist")).toBe(true);

    const grenade = await listSubTypeOptions("grenade");
    expect(grenade[0]?.name).toBe("Base");

    const superOptions = await listSubTypeOptions("super");
    expect(superOptions[0]?.name).toBe("Base");
  });

  it("deduplicates ability options by display name", async () => {
    const supers = await listSubTypeOptions("super");
    expect(supers.filter((o) => o.name === "Chaos Reach")).toHaveLength(1);
    expect(supers.find((o) => o.name === "Chaos Reach")?.description).toBe(
      "Longer arc beam super description.",
    );
    expect(supers.find((o) => o.name === "Chaos Reach")?.id).toBe("1099");

    const melee = await listSubTypeOptions("melee");
    expect(melee.filter((o) => o.name === "Storm Fist")).toHaveLength(1);
    expect(melee.find((o) => o.name === "Storm Fist")?.id).toBe("1020");

    const grenade = await listSubTypeOptions("grenade");
    expect(grenade.filter((o) => o.name === "Pulse Grenade")).toHaveLength(1);
    expect(grenade.find((o) => o.name === "Pulse Grenade")?.id).toBe("1019");
  });

  it("includes Kinetic in element options", async () => {
    const elements = await listSubTypeOptions("element");
    expect(elements.map((e) => e.name)).toContain("Kinetic");
    expect(elements.some((e) => e.name === "Base")).toBe(false);
  });

  it("builds weapon type and frame options from manifest", async () => {
    const options = await listSubTypeOptions("weapon_archetype");
    expect(options.map((o) => o.name)).toEqual(["Precision Frame", "Pulse Rifle"]);
    expect(options.some((o) => o.name === "Kill Clip")).toBe(false);
    expect(options.some((o) => o.name === "Base")).toBe(false);
  });
});
