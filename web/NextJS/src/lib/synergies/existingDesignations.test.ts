import { describe, expect, it } from "vitest";

import {
  buildExistingDesignationIndex,
  normalizeDesignationKey,
  resolveExistingDesignation,
} from "./existingDesignations";
import { resolveVerbSubType } from "@/data/synergyVerbs";

describe("normalizeDesignationKey", () => {
  it("collapses Stasis Shard and Stasis Shards", () => {
    expect(normalizeDesignationKey("Stasis Shards")).toBe(
      normalizeDesignationKey("Stasis Shard"),
    );
  });

  it("collapses Champion and Champions", () => {
    expect(normalizeDesignationKey("Champions")).toBe(
      normalizeDesignationKey("Champion"),
    );
  });
});


describe("resolveVerbSubType aliases", () => {
  it("maps Stasis Shards to Stasis Shard", () => {
    expect(resolveVerbSubType("Stasis Shards")).toBe("Stasis Shard");
    expect(resolveVerbSubType("stasis shards")).toBe("Stasis Shard");
    expect(resolveVerbSubType("Stasis Shard")).toBe("Stasis Shard");
  });

  it("maps element-prefixed phrases to the curated verb (Solar Firesprite)", () => {
    expect(resolveVerbSubType("Solar Firesprite")).toBe("Firesprite");
    expect(resolveVerbSubType("solar firesprites")).toBe("Firesprite");
    expect(resolveVerbSubType("Firesprite")).toBe("Firesprite");
    // Full multi-word curated names still win when they are the whole token
    expect(resolveVerbSubType("Void Breach")).toBe("Void Breach");
  });
});

describe("buildExistingDesignationIndex", () => {
  it("recognizes Glaive as weapon archetype, not a novel verb", () => {
    const index = buildExistingDesignationIndex({
      weaponArchetypeNames: ["Glaive", "Pulse Rifle", "Adaptive Frame"],
    });
    const hit = resolveExistingDesignation("Glaive", index);
    expect(hit).toEqual({
      type: "weapon_archetype",
      subType: "Glaive",
      label: "Glaive",
    });
  });
});
