import { describe, expect, it } from "vitest";

import type { CompositionSearchHit } from "./universalSearch";
import { synergyLinkFromHit } from "./synergyLinkFromHit";
import type { CompositionKind } from "./compositionKinds";
import { hitActions } from "./compositionKinds";

function hit(
  partial: Partial<CompositionSearchHit> &
    Pick<CompositionSearchHit, "kind" | "id" | "name">,
): CompositionSearchHit {
  const kind = partial.kind;
  return {
    description: "",
    icon: null,
    matchField: "name",
    owned: null,
    actions: hitActions(kind),
    ...partial,
  };
}

describe("synergyLinkFromHit", () => {
  it("maps weapon and exotic_weapon to weapon links with itemHash", () => {
    expect(
      synergyLinkFromHit(
        hit({ kind: "weapon", id: "weapon:1", name: "Funnelweb", hash: 1 }),
      ),
    ).toEqual({
      kind: "weapon",
      displayName: "Funnelweb",
      itemHash: 1,
    });

    expect(
      synergyLinkFromHit(
        hit({
          kind: "exotic_weapon",
          id: "exotic_weapon:99",
          name: "Whisper",
          hash: 99,
        }),
      ),
    ).toEqual({
      kind: "weapon",
      displayName: "Whisper",
      itemHash: 99,
    });
  });

  it("maps weapon_perk to perkHash", () => {
    expect(
      synergyLinkFromHit(
        hit({ kind: "weapon_perk", id: "weapon_perk:2", name: "Frenzy", hash: 2 }),
      ),
    ).toEqual({
      kind: "weapon_perk",
      displayName: "Frenzy",
      perkHash: 2,
    });
  });

  it("maps origin_trait with name + hash", () => {
    expect(
      synergyLinkFromHit(
        hit({
          kind: "origin_trait",
          id: "origin_trait:3",
          name: "Veist Stinger",
          hash: 3,
        }),
      ),
    ).toEqual({
      kind: "origin_trait",
      displayName: "Veist Stinger",
      originTraitName: "Veist Stinger",
      originTraitHash: 3,
    });
  });

  it("maps armor_set_bonus from meta fields", () => {
    expect(
      synergyLinkFromHit(
        hit({
          kind: "armor_set_bonus",
          id: "armor_set_bonus:8001:2",
          name: "Eutechnology 2pc — Gift of the Ley Lines",
          hash: 8001,
          meta: {
            armorSetName: "Eutechnology",
            armorSetHash: 8001,
            bonusPieces: 2,
            bonusName: "Gift of the Ley Lines",
          },
        }),
      ),
    ).toEqual({
      kind: "armor_set_bonus",
      displayName: "Eutechnology 2pc — Gift of the Ley Lines",
      armorSetName: "Eutechnology",
      bonusPieces: 2,
      bonusName: "Gift of the Ley Lines",
      armorSetHash: 8001,
    });
  });

  it("maps exotic_armor to itemHash", () => {
    expect(
      synergyLinkFromHit(
        hit({
          kind: "exotic_armor",
          id: "exotic_armor:50",
          name: "Starfire Protocol",
          hash: 50,
        }),
      ),
    ).toEqual({
      kind: "exotic_armor",
      displayName: "Starfire Protocol",
      itemHash: 50,
    });
  });

  it("maps artifact_perk with parentItemHash from meta", () => {
    expect(
      synergyLinkFromHit(
        hit({
          kind: "artifact_perk",
          id: "artifact_perk:77",
          name: "Anti-Barrier Scout",
          hash: 77,
          meta: { parentItemHash: 900, artifactName: "Tablet" },
        }),
      ),
    ).toEqual({
      kind: "artifact_perk",
      displayName: "Anti-Barrier Scout",
      perkHash: 77,
      parentItemHash: 900,
    });
  });

  it("returns null when actions.synergy is false or identity missing", () => {
    const nonSynergy: CompositionKind[] = [
      "armor",
      "mod",
      "aspect",
      "fragment",
      "ability",
    ];
    for (const kind of nonSynergy) {
      expect(
        synergyLinkFromHit(hit({ kind, id: `${kind}:1`, name: "X", hash: 1 })),
      ).toBeNull();
    }

    expect(
      synergyLinkFromHit(
        hit({ kind: "weapon", id: "weapon:x", name: "No Hash" }),
      ),
    ).toBeNull();

    expect(
      synergyLinkFromHit(
        hit({
          kind: "armor_set_bonus",
          id: "armor_set_bonus:bad",
          name: "Incomplete",
          meta: { armorSetName: "Only Name" },
        }),
      ),
    ).toBeNull();
  });
});
