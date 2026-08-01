import { describe, expect, it } from "vitest";

import {
  mapCompositionKindToDefaultSetType,
  resolveInstancePin,
  slotsForSetType,
  suggestSlotsForHit,
} from "./setPlacementFromHit";
import type { CompositionKind } from "./compositionKinds";

describe("mapCompositionKindToDefaultSetType", () => {
  it("maps set-eligible kinds to default set types (exotics default gear, not pair)", () => {
    expect(mapCompositionKindToDefaultSetType("weapon")).toBe("weapon");
    expect(mapCompositionKindToDefaultSetType("exotic_weapon")).toBe("weapon");
    expect(mapCompositionKindToDefaultSetType("armor")).toBe("armor");
    expect(mapCompositionKindToDefaultSetType("exotic_armor")).toBe("armor");
    expect(mapCompositionKindToDefaultSetType("mod")).toBe("mod");
  });

  it("returns null for non-set kinds (FR-015 subclass kit)", () => {
    const nonSet: CompositionKind[] = [
      "weapon_perk",
      "origin_trait",
      "armor_set_bonus",
      "artifact_perk",
      "aspect",
      "fragment",
      "ability",
    ];
    for (const kind of nonSet) {
      expect(mapCompositionKindToDefaultSetType(kind)).toBeNull();
    }
  });
});

describe("slotsForSetType", () => {
  it("returns weapon / armor / pair slot lists from SLOTS_BY_SET_TYPE", () => {
    expect(slotsForSetType("weapon")).toEqual(["primary", "special", "heavy"]);
    expect(slotsForSetType("armor")).toEqual([
      "helmet",
      "arms",
      "chest",
      "legs",
      "class_item",
    ]);
    expect(slotsForSetType("pair")).toEqual(["exotic_weapon", "exotic_armor"]);
  });

  it("expands mods_only to ARMOR_SLOTS for piece pick", () => {
    expect(slotsForSetType("mod")).toEqual([
      "helmet",
      "arms",
      "chest",
      "legs",
      "class_item",
    ]);
  });
});

describe("suggestSlotsForHit", () => {
  it("maps weapon Kinetic/Energy/Power buckets to set slots", () => {
    expect(suggestSlotsForHit("weapon", { slot: "Kinetic" })).toEqual(["primary"]);
    expect(suggestSlotsForHit("weapon", { slot: "Energy" })).toEqual(["special"]);
    expect(suggestSlotsForHit("weapon", { slot: "Power" })).toEqual(["heavy"]);
  });

  it("pairs exotic_weapon with bucket slot + exotic_weapon pair slot", () => {
    expect(suggestSlotsForHit("exotic_weapon", { slot: "Power" })).toEqual([
      "heavy",
      "exotic_weapon",
    ]);
    expect(suggestSlotsForHit("exotic_weapon", {})).toEqual(["exotic_weapon"]);
  });

  it("maps armor Helmet/Gauntlets/etc. to set slots", () => {
    expect(suggestSlotsForHit("armor", { slot: "Helmet" })).toEqual(["helmet"]);
    expect(suggestSlotsForHit("armor", { slot: "Gauntlets" })).toEqual(["arms"]);
    expect(suggestSlotsForHit("armor", { slot: "Chest" })).toEqual(["chest"]);
    expect(suggestSlotsForHit("armor", { slot: "Legs" })).toEqual(["legs"]);
    expect(suggestSlotsForHit("armor", { slot: "ClassItem" })).toEqual(["class_item"]);
  });

  it("pairs exotic_armor with piece slot + exotic_armor pair slot", () => {
    expect(suggestSlotsForHit("exotic_armor", { slot: "Helmet" })).toEqual([
      "helmet",
      "exotic_armor",
    ]);
    expect(suggestSlotsForHit("exotic_armor", {})).toEqual(["exotic_armor"]);
  });

  it("suggests armor pieces for mods", () => {
    expect(suggestSlotsForHit("mod", { slotCategory: "helmet" })).toEqual(["helmet"]);
    expect(suggestSlotsForHit("mod", { slotCategory: "general" })).toEqual([
      "helmet",
      "arms",
      "chest",
      "legs",
      "class_item",
    ]);
  });

  it("returns empty for non-set kinds", () => {
    expect(suggestSlotsForHit("weapon_perk")).toEqual([]);
    expect(suggestSlotsForHit("aspect")).toEqual([]);
  });
});

describe("resolveInstancePin", () => {
  it("wishlist when none owned (FR-018)", () => {
    expect(resolveInstancePin([])).toEqual({ mode: "wishlist" });
  });

  it("auto-pins the sole owned instance", () => {
    expect(resolveInstancePin([{ instanceId: "inst-1" }])).toEqual({
      mode: "auto",
      instanceId: "inst-1",
    });
  });

  it("requires pick when multiple owned", () => {
    expect(
      resolveInstancePin([{ instanceId: "a" }, { instanceId: "b" }]),
    ).toEqual({ mode: "pick" });
  });
});
