import { describe, expect, it } from "vitest";

import { composerTabAccess, type ComposerTabAccessInput } from "./composerTabAccess";

function base(over: Partial<ComposerTabAccessInput> = {}): ComposerTabAccessInput {
  return {
    tab: "general",
    className: null,
    subclassName: null,
    buildId: null,
    ...over,
  };
}

describe("composerTabAccess", () => {
  it("allows general and finish always", () => {
    expect(composerTabAccess(base({ tab: "general" })).allowed).toBe(true);
    expect(composerTabAccess(base({ tab: "finish" })).allowed).toBe(true);
  });

  it("blocks subclass without class and subclass", () => {
    expect(composerTabAccess(base({ tab: "subclass", className: "Warlock" })).allowed).toBe(false);
    expect(
      composerTabAccess(base({ tab: "subclass", className: "Warlock", subclassName: "Chaos Reach" }))
        .allowed,
    ).toBe(true);
  });

  it("blocks armor/weapon without class", () => {
    expect(composerTabAccess(base({ tab: "armor" })).allowed).toBe(false);
    expect(composerTabAccess(base({ tab: "weapon", className: "Titan" })).allowed).toBe(true);
  });

  it("reports mutation needs buildId separately", () => {
    const r = composerTabAccess(
      base({ tab: "armor", className: "Titan", buildId: null }),
    );
    expect(r.allowed).toBe(true);
    expect(r.mutationsAllowed).toBe(false);
    expect(r.mutationReason).toMatch(/save General/i);
    expect(
      composerTabAccess(base({ tab: "armor", className: "Titan", buildId: "b1" }))
        .mutationsAllowed,
    ).toBe(true);
  });
});
