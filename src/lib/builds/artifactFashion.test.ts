import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { resolveArtifactSelection } from "@/lib/builds/artifactSelection";
import { resolvedArtifactFromVariant } from "@/lib/builds/resolveArtifactFashion";
import { FASHION_SLOTS, isSlotValidForSetType } from "@/lib/sets/schemas";

vi.mock("@/lib/services", () => ({
  getServices: async () => ({
    entityCache: {
      getStore: async (name: string) => {
        if (name !== "artifacts") return [];
        return [
          {
            hash: 1001,
            name: "Test Artifact",
            searchName: "test",
            icon: null,
            description: "",
            perks: [
              { hash: 11, name: "P1", searchName: "p1", icon: null, description: "", column: 0, row: 0 },
              { hash: 22, name: "P2", searchName: "p2", icon: null, description: "", column: 0, row: 1 },
            ],
          },
        ];
      },
    },
  }),
}));

describe("resolveArtifactSelection", () => {
  it("clears selection when hash is null", async () => {
    const result = await resolveArtifactSelection({ artifactHash: null });
    expect(result).toEqual({ artifactHash: null, artifactName: null, artifactConfig: [] });
  });

  it("rejects unknown artifact hash", async () => {
    await expect(resolveArtifactSelection({ artifactHash: 999 })).rejects.toMatchObject({
      code: API_ERROR_CODES.INVALID_ITEM,
    });
  });

  it("accepts known hash and validates config perks", async () => {
    const result = await resolveArtifactSelection({
      artifactHash: 1001,
      artifactConfig: [11],
    });
    expect(result).toMatchObject({
      artifactHash: 1001,
      artifactName: "Test Artifact",
      artifactConfig: [11],
    });
  });

  it("rejects config perks not on the artifact", async () => {
    await expect(
      resolveArtifactSelection({ artifactHash: 1001, artifactConfig: [99] }),
    ).rejects.toBeInstanceOf(ApiError);
  });

  it("clears config when switching artifact without new config", async () => {
    const result = await resolveArtifactSelection({
      artifactHash: 1001,
      previous: { artifactHash: 2002, artifactName: "Old", artifactConfig: [11] },
    });
    expect(result?.artifactConfig).toEqual([]);
  });
});

describe("resolvedArtifactFromVariant", () => {
  it("returns null when unset", () => {
    expect(
      resolvedArtifactFromVariant({ artifactHash: null, artifactName: null, artifactConfig: [] }),
    ).toBeNull();
  });

  it("maps hash/name/config", () => {
    expect(
      resolvedArtifactFromVariant({
        artifactHash: 1,
        artifactName: "A",
        artifactConfig: [2],
      }),
    ).toEqual({ hash: 1, name: "A", config: [2] });
  });
});

describe("fashion slot allowlist", () => {
  it("includes required cosmetic slots", () => {
    expect(FASHION_SLOTS).toEqual(
      expect.arrayContaining(["ghost", "sparrow", "ship", "emblem", "finisher", "shader_ornament"]),
    );
    expect(isSlotValidForSetType("fashion", "ghost")).toBe(true);
  });
});
