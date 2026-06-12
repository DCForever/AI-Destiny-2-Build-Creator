import { describe, expect, it } from "vitest";

import { equipmentToLoadoutText } from "./loadoutText";
import type { CharacterEquipment } from "./types";
import type { EntityCache } from "@/lib/manifest/types/services";
import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";

function makeRecord(hash: number, name: string) {
  return { hash, name, searchName: name.toLowerCase(), icon: null };
}

const STORE_DATA: Partial<EntityStores> = {
  weapons: [
    {
      ...makeRecord(1001, "Fatebringer"),
      slot: "Energy",
      element: "Solar",
      ammo: "Primary",
      frame: "Scout Rifle",
      itemTypeName: "Scout Rifle",
      originTraitHashes: [],
      perkColumns: [],
    },
  ],
  "exotic-weapons": [],
  "exotic-armor": [],
  aspects: [{ ...makeRecord(5001, "Consecration"), description: "", classType: "Titan", element: "Solar", fragmentCapacity: 2 }],
  fragments: [{ ...makeRecord(5002, "Ember of Empyrean"), description: "", element: "Solar", statModifiers: {} }],
  abilities: [],
  mods: [{ ...makeRecord(6001, "Radiant Light"), description: "", slotCategory: "general", energyCost: 1 }],
  "weapon-perks": [
    { ...makeRecord(7001, "Kill Clip"), description: "" },
    { ...makeRecord(7002, "Outlaw"), description: "" },
  ],
  "origin-traits": [{ ...makeRecord(8001, "Tex Balanced Stock"), description: "" }],
};

function createFakeCache(stores: Partial<EntityStores>): EntityCache {
  return {
    getMeta: async () => null,
    rebuild: async () => { throw new Error("not implemented"); },
    getStore: async <TName extends StoreName>(name: TName) => {
      const store = stores[name];
      if (store === undefined) throw new Error(`missing fixture: ${name}`);
      return store as EntityStores[TName];
    },
  };
}

const BASE_CHARACTER = {
  characterId: "c1",
  classType: "Hunter" as const,
  light: 1810,
  emblemPath: null,
  dateLastPlayed: "2024-01-01T00:00:00Z",
};

describe("equipmentToLoadoutText", () => {
  it("produces a weapon line with resolved name and plugs", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 1001, bucket: "Kinetic Weapons", plugHashes: [7001, 7002] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));

    expect(text).toContain("Kinetic Weapons: Fatebringer");
    expect(text).toContain("plugs: Kill Clip, Outlaw");
  });

  it("outputs 'Legendary armor piece' for armor with unresolved hash", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 99999, bucket: "Helmet", plugHashes: [] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));

    expect(text).toContain("Helmet: Legendary armor piece (not in entity cache)");
  });

  it("outputs 'Unknown item (hash)' for weapons with unresolved hash", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 88888, bucket: "Energy Weapons", plugHashes: [] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));

    expect(text).toContain("Energy Weapons: Unknown item (88888)");
  });

  it("deduplicates plug names", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 1001, bucket: "Kinetic Weapons", plugHashes: [7001, 7001, 7002] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));
    const plugLine = text.split("\n").find((l) => l.includes("plugs:"));

    expect(plugLine?.split("Kill Clip").length).toBe(2); // appears exactly once
  });

  it("caps plugs at 12 names", async () => {
    const manyHashes = Array.from({ length: 15 }, (_, i) => 7000 + i);
    const manyPerks = manyHashes.map((h) => ({ ...makeRecord(h, `Perk ${h}`), description: "" }));
    const stores = { ...STORE_DATA, "weapon-perks": manyPerks };

    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [{ itemHash: 1001, bucket: "Kinetic Weapons", plugHashes: manyHashes }],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(stores));
    const plugLine = text.split("\n").find((l) => l.includes("plugs:")) ?? "";
    const names = plugLine.replace("  plugs: ", "").split(", ");

    expect(names.length).toBe(12);
  });

  it("respects bucket order: Subclass before Kinetic before Helmet", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 99999, bucket: "Helmet", plugHashes: [] },
        { itemHash: 88888, bucket: "Kinetic Weapons", plugHashes: [] },
        { itemHash: 77777, bucket: "Subclass", plugHashes: [] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));
    const lines = text.split("\n").filter((l) => !l.startsWith("  "));
    const buckets = lines.map((l) => l.split(":")[0]);

    expect(buckets.indexOf("Subclass")).toBeLessThan(buckets.indexOf("Kinetic Weapons"));
    expect(buckets.indexOf("Kinetic Weapons")).toBeLessThan(buckets.indexOf("Helmet"));
  });

  it("omits a plug line when no plugs resolve to names", async () => {
    const equipment: CharacterEquipment = {
      character: BASE_CHARACTER,
      items: [
        { itemHash: 1001, bucket: "Energy Weapons", plugHashes: [99999] },
      ],
    };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));

    expect(text).not.toContain("plugs:");
  });

  it("returns empty string when there are no items", async () => {
    const equipment: CharacterEquipment = { character: BASE_CHARACTER, items: [] };

    const text = await equipmentToLoadoutText(equipment, createFakeCache(STORE_DATA));

    expect(text).toBe("");
  });
});
