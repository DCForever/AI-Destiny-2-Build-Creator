import { beforeEach, describe, expect, it, vi } from "vitest";

import { validateSynergyLink } from "@/lib/synergies/validateSynergyLink";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

describe("validateSynergyLink exotic_armor + artifact_perk", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "exotic-armor") {
        return [
          {
            hash: 501,
            name: "Synthoceps",
            intrinsic: { name: "Biotic", description: "Melee buff." },
          },
        ];
      }
      if (store === "artifacts") {
        return [
          {
            hash: 600,
            name: "Artifact",
            perks: [{ hash: 601, name: "Anti-Barrier", description: "Stun." }],
          },
        ];
      }
      return [];
    });
  });

  it("accepts exotic armor by itemHash", async () => {
    const result = await validateSynergyLink({
      kind: "exotic_armor",
      displayName: "Synthoceps",
      itemHash: 501,
    });
    expect(result.valid).toBe(true);
    if (result.valid) {
      expect(result.link.displayName).toBe("Synthoceps");
      expect(result.link.itemHash).toBe(501);
    }
  });

  it("rejects unknown exotic armor hash", async () => {
    const result = await validateSynergyLink({
      kind: "exotic_armor",
      displayName: "Nope",
      itemHash: 999,
    });
    expect(result.valid).toBe(false);
  });

  it("accepts artifact perk and fills parentItemHash", async () => {
    const result = await validateSynergyLink({
      kind: "artifact_perk",
      displayName: "Anti-Barrier",
      perkHash: 601,
    });
    expect(result.valid).toBe(true);
    if (result.valid) {
      expect(result.link.perkHash).toBe(601);
      expect(result.link.parentItemHash).toBe(600);
    }
  });

  it("rejects unknown artifact perk hash", async () => {
    const result = await validateSynergyLink({
      kind: "artifact_perk",
      displayName: "Nope",
      perkHash: 999,
    });
    expect(result.valid).toBe(false);
  });
});
