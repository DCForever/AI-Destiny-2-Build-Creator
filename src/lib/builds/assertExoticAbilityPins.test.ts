import { beforeEach, describe, expect, it, vi } from "vitest";
import { API_ERROR_CODES } from "@/lib/api/errors";

const lookupExoticAbilityRequirements = vi.fn();
const hasAbilityRequirements = vi.fn();

vi.mock("@/data/exoticAbilityRequirements", () => ({
  lookupExoticAbilityRequirements: (...args: unknown[]) =>
    lookupExoticAbilityRequirements(...args),
  hasAbilityRequirements: (...args: unknown[]) =>
    hasAbilityRequirements(...args),
}));

import {
  applyAbilityRequirementPins,
  assertExoticAbilityPins,
} from "@/lib/builds/assertExoticAbilityPins";

const REQUIRED = {
  super: "Golden Gun",
  melee: "Knife Trick",
};

describe("assertExoticAbilityPins", () => {
  beforeEach(() => {
    lookupExoticAbilityRequirements.mockReset();
    hasAbilityRequirements.mockReset();
  });

  it("no-ops when exotic has no ability requirements", () => {
    lookupExoticAbilityRequirements.mockReturnValue(null);
    hasAbilityRequirements.mockReturnValue(false);

    expect(() =>
      assertExoticAbilityPins({
        exoticArmorHash: 42,
        subclass: { super: "Nova Bomb" },
      }),
    ).not.toThrow();
  });

  it("allows kit that matches required abilities", () => {
    lookupExoticAbilityRequirements.mockReturnValue(REQUIRED);
    hasAbilityRequirements.mockReturnValue(true);

    expect(() =>
      assertExoticAbilityPins({
        exoticArmorHash: 42,
        exoticArmorName: "Test Exotic",
        subclass: {
          super: "Golden Gun",
          melee: "Knife Trick",
        },
      }),
    ).not.toThrow();
  });

  it("allows match via pinnedSuper when subclass super differs", () => {
    lookupExoticAbilityRequirements.mockReturnValue({ super: "Golden Gun" });
    hasAbilityRequirements.mockReturnValue(true);

    expect(() =>
      assertExoticAbilityPins({
        exoticArmorHash: 42,
        pinnedSuper: "Golden Gun",
        subclass: { super: "Something Else" },
      }),
    ).not.toThrow();
  });

  it("blocks mismatched required abilities with EXOTIC_ABILITY_MISMATCH", () => {
    lookupExoticAbilityRequirements.mockReturnValue(REQUIRED);
    hasAbilityRequirements.mockReturnValue(true);

    expect(() =>
      assertExoticAbilityPins({
        exoticArmorHash: 42,
        subclass: {
          super: "Nova Bomb",
          melee: "Pocket Singularity",
        },
      }),
    ).toThrow(
      expect.objectContaining({
        code: API_ERROR_CODES.EXOTIC_ABILITY_MISMATCH,
        status: 400,
      }),
    );
  });
});

describe("applyAbilityRequirementPins", () => {
  it("overlays required ability fields onto subclass draft", () => {
    const next = applyAbilityRequirementPins(
      { super: "Old Super", grenade: "Keep Me" },
      { super: "Golden Gun", melee: "Knife Trick" },
    );
    expect(next).toEqual({
      super: "Golden Gun",
      grenade: "Keep Me",
      melee: "Knife Trick",
    });
  });
});
