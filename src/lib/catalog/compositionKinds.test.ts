import { describe, expect, it } from "vitest";

import {
  COMPOSITION_KINDS,
  compositionKindLabel,
  hitActions,
  parseKindsParam,
  setTypesForHit,
  type CompositionKind,
} from "./compositionKinds";

describe("COMPOSITION_KINDS", () => {
  it("includes all v1 composition kinds from the data model", () => {
    expect([...COMPOSITION_KINDS]).toEqual([
      "weapon",
      "exotic_weapon",
      "armor",
      "exotic_armor",
      "mod",
      "weapon_perk",
      "origin_trait",
      "armor_set_bonus",
      "artifact_perk",
      "aspect",
      "fragment",
      "ability",
    ]);
  });
});

describe("compositionKindLabel", () => {
  it("returns display labels", () => {
    expect(compositionKindLabel("exotic_weapon")).toBe("Exotic weapon");
    expect(compositionKindLabel("armor_set_bonus")).toBe("Armor set bonus");
    expect(compositionKindLabel("weapon_perk")).toBe("Weapon perk");
  });
});

describe("hitActions", () => {
  const cases: Array<{
    kind: CompositionKind;
    set: boolean;
    synergy: boolean;
  }> = [
    { kind: "weapon", set: true, synergy: true },
    { kind: "exotic_weapon", set: true, synergy: true },
    { kind: "armor", set: true, synergy: false },
    { kind: "exotic_armor", set: true, synergy: true },
    { kind: "mod", set: true, synergy: false },
    { kind: "weapon_perk", set: false, synergy: true },
    { kind: "origin_trait", set: false, synergy: true },
    { kind: "armor_set_bonus", set: false, synergy: true },
    { kind: "artifact_perk", set: false, synergy: true },
    { kind: "aspect", set: false, synergy: false },
    { kind: "fragment", set: false, synergy: false },
    { kind: "ability", set: false, synergy: false },
  ];

  it.each(cases)("$kind → set=$set synergy=$synergy", ({ kind, set, synergy }) => {
    expect(hitActions(kind)).toEqual({ set, synergy });
  });
});

describe("setTypesForHit", () => {
  it("maps gear kinds to set types including Pair for exotics (FR-017)", () => {
    expect(setTypesForHit("weapon")).toEqual(["weapon"]);
    expect(setTypesForHit("exotic_weapon")).toEqual(["weapon", "pair"]);
    expect(setTypesForHit("armor")).toEqual(["armor"]);
    expect(setTypesForHit("exotic_armor")).toEqual(["armor", "pair"]);
    expect(setTypesForHit("mod")).toEqual(["mod"]);
  });

  it("returns empty for non-set kinds", () => {
    expect(setTypesForHit("weapon_perk")).toEqual([]);
    expect(setTypesForHit("origin_trait")).toEqual([]);
    expect(setTypesForHit("aspect")).toEqual([]);
    expect(setTypesForHit("fragment")).toEqual([]);
    expect(setTypesForHit("ability")).toEqual([]);
    expect(setTypesForHit("armor_set_bonus")).toEqual([]);
    expect(setTypesForHit("artifact_perk")).toEqual([]);
  });
});

describe("parseKindsParam", () => {
  it("returns all kinds when undefined (omit = all)", () => {
    expect(parseKindsParam(undefined)).toEqual([...COMPOSITION_KINDS]);
  });

  it("returns empty array for empty or whitespace-only CSV", () => {
    expect(parseKindsParam("")).toEqual([]);
    expect(parseKindsParam("   ")).toEqual([]);
    expect(parseKindsParam(",,,")).toEqual([]);
  });

  it("parses comma-separated kinds and trims", () => {
    expect(parseKindsParam("weapon_perk, origin_trait")).toEqual([
      "weapon_perk",
      "origin_trait",
    ]);
  });

  it("dedupes while preserving first-seen order", () => {
    expect(parseKindsParam("mod,weapon,mod")).toEqual(["mod", "weapon"]);
  });

  it("returns error for invalid kind values", () => {
    const result = parseKindsParam("weapon,not_a_kind");
    expect(result).toEqual({ error: "Invalid kind: not_a_kind" });
  });

  it("returns error when the only token is invalid", () => {
    expect(parseKindsParam("fashion")).toEqual({ error: "Invalid kind: fashion" });
  });
});
