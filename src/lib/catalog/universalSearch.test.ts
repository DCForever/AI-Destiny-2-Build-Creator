import { describe, expect, it } from "vitest";

import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";

import { searchCompositionCatalog } from "./universalSearch";

function storesFixture(partial: Partial<EntityStores>): EntityStoreMap {
  return {
    "exotic-armor": [],
    "exotic-weapons": [],
    weapons: [],
    "weapon-perks": [],
    "origin-traits": [],
    artifacts: [],
    aspects: [],
    fragments: [],
    abilities: [],
    mods: [],
    "set-bonuses": [],
    stats: [],
    ...partial,
  };
}

type EntityStoreMap = EntityStores;

function makeGetStore(map: EntityStoreMap) {
  return async <TName extends StoreName>(name: TName): Promise<EntityStores[TName]> =>
    map[name];
}

describe("searchCompositionCatalog", () => {
  it("returns NEED_QUERY for whitespace-only q", async () => {
    const result = await searchCompositionCatalog(makeGetStore(storesFixture({})), {
      q: "   ",
      limit: 10,
    });
    expect(result.code).toBe("NEED_QUERY");
    expect(result.hits).toEqual([]);
    expect(result.truncated).toBe(false);
  });

  it("matches name and description across kinds", async () => {
    const result = await searchCompositionCatalog(
      makeGetStore(
        storesFixture({
          weapons: [
            {
              hash: 1,
              name: "Funnelweb",
              searchName: "funnelweb",
              icon: "/w.png",
              slot: "Energy",
              element: "Void",
              ammo: "Primary",
              frame: "Lightweight Frame",
              itemTypeName: "Submachine Gun",
              originTraitHashes: [],
              perkColumns: [],
            },
          ],
          "weapon-perks": [
            {
              hash: 2,
              name: "Frenzy",
              searchName: "frenzy",
              icon: "/p.png",
              description: "Being in combat for an extended time increases damage.",
              source: "legendary",
            },
          ],
          "origin-traits": [
            {
              hash: 3,
              name: "Veist Stinger",
              searchName: "veist stinger",
              icon: "/o.png",
              description: "Damaging an enemy with this weapon has a chance to reload.",
            },
          ],
        }),
      ),
      { q: "combat", limit: 20 },
    );

    expect(result.code).toBeUndefined();
    const kinds = result.hits.map((h) => h.kind);
    expect(kinds).toContain("weapon_perk");
    const frenzy = result.hits.find((h) => h.name === "Frenzy");
    expect(frenzy?.matchField).toBe("description");
    expect(frenzy?.actions).toEqual({ set: false, synergy: true });
  });

  it("ranks name matches before description-only", async () => {
    const result = await searchCompositionCatalog(
      makeGetStore(
        storesFixture({
          "weapon-perks": [
            {
              hash: 10,
              name: "Other Perk",
              searchName: "other perk",
              icon: null,
              description: "Grants melee energy on hit.",
            },
            {
              hash: 11,
              name: "Melee Wellmaker",
              searchName: "melee wellmaker",
              icon: null,
              description: "Something else entirely.",
            },
          ],
        }),
      ),
      { q: "melee", kinds: ["weapon_perk"], limit: 10 },
    );

    expect(result.hits.map((h) => h.name)).toEqual(["Melee Wellmaker", "Other Perk"]);
    expect(result.hits[0]?.matchField).toBe("name");
    expect(result.hits[1]?.matchField).toBe("description");
  });

  it("filters by kinds and may return FILTERED_EMPTY", async () => {
    const getStore = makeGetStore(
      storesFixture({
        weapons: [
          {
            hash: 1,
            name: "Funnelweb",
            searchName: "funnelweb",
            icon: null,
            slot: "Energy",
            element: "Void",
            ammo: "Primary",
            frame: "Lightweight",
            itemTypeName: "SMG",
            originTraitHashes: [],
            perkColumns: [],
          },
        ],
      }),
    );

    const filtered = await searchCompositionCatalog(getStore, {
      q: "Funnelweb",
      kinds: ["weapon_perk"],
      limit: 10,
    });
    expect(filtered.hits).toEqual([]);
    expect(filtered.code).toBe("FILTERED_EMPTY");

    const open = await searchCompositionCatalog(getStore, {
      q: "Funnelweb",
      kinds: ["weapon"],
      limit: 10,
    });
    expect(open.hits).toHaveLength(1);
    expect(open.hits[0]?.kind).toBe("weapon");
  });

  it("annotates ownership on equippable hits", async () => {
    const result = await searchCompositionCatalog(
      makeGetStore(
        storesFixture({
          "exotic-weapons": [
            {
              hash: 99,
              name: "Whisper",
              searchName: "whisper",
              icon: null,
              slot: "Power",
              element: "Solar",
              ammo: "Heavy",
              frame: "Aggressive",
              intrinsic: { name: "White Nail", description: "Precision hits return ammo." },
              catalyst: null,
              flavorText: "",
            },
          ],
        }),
      ),
      {
        q: "Whisper",
        kinds: ["exotic_weapon"],
        ownedHashes: new Map([[99, 2]]),
      },
    );
    expect(result.hits[0]?.owned).toEqual({ count: 2 });
    expect(result.hits[0]?.actions.set).toBe(true);
  });

  it("returns empty hits without NEED_QUERY when nothing matches (no kind filter)", async () => {
    const result = await searchCompositionCatalog(makeGetStore(storesFixture({})), {
      q: "zzzz-no-such-entity",
      limit: 10,
    });
    expect(result.code).toBeUndefined();
    expect(result.hits).toEqual([]);
    expect(result.truncated).toBe(false);
  });

  it("expands set-bonus tiers with armor_set_bonus:hash:count ids", async () => {
    const result = await searchCompositionCatalog(
      makeGetStore(
        storesFixture({
          "set-bonuses": [
            {
              hash: 8001,
              name: "Eutechnology",
              searchName: "eutechnology",
              icon: null,
              perks: [
                {
                  requiredCount: 2,
                  name: "Gift of the Ley Lines",
                  description: "Void buff.",
                },
              ],
              itemHashes: [],
            },
          ],
        }),
      ),
      { q: "gift", kinds: ["armor_set_bonus"] },
    );
    expect(result.hits).toHaveLength(1);
    expect(result.hits[0]?.id).toBe("armor_set_bonus:8001:2");
    expect(result.hits[0]?.actions).toEqual({ set: false, synergy: true });
  });

  it("searches artifact perks like synergy picker", async () => {
    const result = await searchCompositionCatalog(
      makeGetStore(
        storesFixture({
          artifacts: [
            {
              hash: 500,
              name: "Tablet of Ruin",
              searchName: "tablet of ruin",
              icon: "/a.png",
              description: "Seasonal artifact",
              perks: [
                {
                  hash: 501,
                  name: "Anti-Barrier Sidearm",
                  searchName: "anti-barrier sidearm",
                  icon: "/p.png",
                  description: "Sidearms you equip deal anti-barrier damage.",
                  column: 0,
                  row: 1,
                  artifactName: "Tablet of Ruin",
                },
              ],
            },
          ],
        }),
      ),
      { q: "anti-barrier", kinds: ["artifact_perk"] },
    );
    expect(result.hits).toHaveLength(1);
    expect(result.hits[0]?.meta).toMatchObject({
      artifactName: "Tablet of Ruin",
      parentItemHash: 500,
    });
  });
});
