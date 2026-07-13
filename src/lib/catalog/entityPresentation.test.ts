import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  presentByHashes,
  presentByNames,
  resolveEntityPresentation,
  resolveEntityPresentations,
} from "./entityPresentation";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

describe("entityPresentation", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "weapons") {
        return [
          {
            hash: 100,
            name: "Fatebringer",
            searchName: "fatebringer",
            icon: "/fate.png",
            itemTypeName: "Hand Cannon",
            frame: "Adaptive Frame",
            element: "Kinetic",
          },
        ];
      }
      if (store === "exotic-weapons") {
        return [
          {
            hash: 101,
            name: "Sunshot",
            searchName: "sunshot",
            icon: "/sun.png",
            element: "Solar",
            intrinsic: {
              name: "Sunburn",
              description: "Targets explode and Scorch nearby foes.",
            },
            catalyst: null,
          },
        ];
      }
      if (store === "exotic-armor") {
        return [
          {
            hash: 201,
            name: "Cuirass of the Falling Star",
            searchName: "cuirass of the falling star",
            icon: "/cuirass.png",
            intrinsic: {
              name: "Impact Induction",
              description: "Super deals more damage.",
            },
          },
        ];
      }
      if (store === "weapon-perks") {
        return [
          {
            hash: 300,
            name: "Firefly",
            searchName: "firefly",
            icon: "/firefly.png",
            description: "Precision kills cause the target to explode.",
          },
        ];
      }
      if (store === "abilities") {
        return [
          {
            hash: 400,
            name: "Stormtrance",
            searchName: "stormtrance",
            icon: "/storm.png",
            description: "Call lightning down on foes.",
            kind: "super",
            element: "Arc",
          },
        ];
      }
      if (store === "aspects") {
        return [
          {
            hash: 500,
            name: "Lightning Surge",
            searchName: "lightning surge",
            icon: "/surge.png",
            description: "Slide melee jolts targets.",
            element: "Arc",
          },
        ];
      }
      if (store === "fragments") {
        return [
          {
            hash: 600,
            name: "Spark of Shock",
            searchName: "spark of shock",
            icon: "/shock.png",
            description: "Arc abilities jolt.",
            element: "Arc",
          },
        ];
      }
      if (store === "mods") {
        return [
          {
            hash: 700,
            name: "Font of Wisdom",
            searchName: "font of wisdom",
            icon: "/font.png",
            description: "Increased intellect while charged with light.",
          },
        ];
      }
      if (store === "artifacts") {
        return [
          {
            hash: 800,
            name: "Heretical Artifact",
            searchName: "heretical artifact",
            icon: "/art.png",
            description: "Seasonal artifact.",
            perks: [
              {
                hash: 801,
                name: "Anti-Barrier Pulse",
                searchName: "anti barrier pulse",
                icon: "/ab.png",
                description: "Pulse rifles pierce barriers.",
                column: 0,
                row: 0,
              },
            ],
          },
        ];
      }
      return [];
    });
  });

  it("resolves weapon by hash with frame description", async () => {
    const p = await resolveEntityPresentation({ by: "hash", hash: 100 });
    expect(p.name).toBe("Fatebringer");
    expect(p.icon).toBe("/fate.png");
    expect(p.description).toContain("Adaptive Frame");
    expect(p.element).toBe("Kinetic");
    expect(p.kindLabel).toBe("Weapon");
  });

  it("resolves exotic weapon intrinsic description", async () => {
    const p = await resolveEntityPresentation({ by: "hash", hash: 101 });
    expect(p.description).toContain("Scorch");
    expect(p.element).toBe("Solar");
  });

  it("resolves exotic armor by hash", async () => {
    const p = await resolveEntityPresentation({ by: "hash", hash: 201 });
    expect(p.name).toContain("Cuirass");
    expect(p.description).toContain("Super");
  });

  it("resolves weapon perk by hash", async () => {
    const p = await resolveEntityPresentation({
      by: "hash",
      hash: 300,
      stores: ["weapon-perks"],
    });
    expect(p.name).toBe("Firefly");
    expect(p.kindLabel).toBe("Weapon perk");
  });

  it("resolves nested artifact perk by hash", async () => {
    const p = await resolveEntityPresentation({
      by: "hash",
      hash: 801,
      stores: ["artifacts"],
    });
    expect(p.name).toBe("Anti-Barrier Pulse");
    expect(p.kindLabel).toBe("Artifact perk");
    expect(p.icon).toBe("/ab.png");
  });

  it("resolves ability / aspect / fragment by name", async () => {
    const results = await resolveEntityPresentations([
      { by: "name", name: "Stormtrance", stores: ["abilities"] },
      { by: "name", name: "Lightning Surge", stores: ["aspects"] },
      { by: "name", name: "Spark of Shock", stores: ["fragments"] },
    ]);
    expect(results[0]?.icon).toBe("/storm.png");
    expect(results[1]?.description).toContain("jolt");
    expect(results[2]?.element).toBe("Arc");
  });

  it("returns empty miss without throwing", async () => {
    const p = await resolveEntityPresentation({ by: "hash", hash: 99999 });
    expect(p.name).toContain("99999");
    expect(p.icon).toBeNull();
    expect(p.description).toBe("");
  });

  it("batches hashes and names", async () => {
    const byHash = await presentByHashes([100, 300], [
      "weapons",
      "weapon-perks",
    ]);
    expect(byHash.get(100)?.name).toBe("Fatebringer");
    expect(byHash.get(300)?.name).toBe("Firefly");

    const byName = await presentByNames(["Font of Wisdom"], ["mods"]);
    expect(byName.get("Font of Wisdom")?.icon).toBe("/font.png");
  });

  it("repeated presentByHashes calls remain correct (index reuse)", async () => {
    const hashes = [100, 101, 201, 300, 400];
    const a = await presentByHashes(hashes);
    const b = await presentByHashes(hashes);
    expect([...a.entries()].map(([h, p]) => [h, p.name])).toEqual(
      [...b.entries()].map(([h, p]) => [h, p.name]),
    );
    expect(a.get(101)?.description).toContain("Scorch");
    expect(b.get(101)?.description).toContain("Scorch");
  });
});
