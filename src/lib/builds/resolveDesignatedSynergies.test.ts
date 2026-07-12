import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createSynergyRecord } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import {
  aggregateLinksForDesignation,
  designationKey,
  resolveDesignatedSynergies,
} from "@/lib/builds/resolveDesignatedSynergies";
import { evaluateCoverage } from "@/lib/builds/coverage";

describe("resolveDesignatedSynergies", () => {
  it("unions multiple library records sharing type+subType", () => {
    const db = createTestDb();
    const user = ensureUser(db, "bridge-1", 3, "Player");
    const now = new Date().toISOString();

    createSynergyRecord(db, user.id, {
      id: "syn-a",
      name: "Verb: Devour — A",
      type: "verb",
      subType: "Devour",
      description: "",
      links: [
        {
          kind: "weapon",
          displayName: "Weapon A",
          itemHash: 111,
        },
      ],
      now,
    });
    createSynergyRecord(db, user.id, {
      id: "syn-b",
      name: "Verb: Devour — B",
      type: "verb",
      subType: "Devour",
      description: "",
      links: [
        {
          kind: "weapon_perk",
          displayName: "Perk B",
          perkHash: 222,
        },
      ],
      now,
    });

    const bridge = resolveDesignatedSynergies(db, user.id, [
      { type: "verb", subType: "Devour" },
    ]);

    expect(bridge.matchedSynergies).toHaveLength(2);
    const key = designationKey({ type: "verb", subType: "Devour" });
    const links = aggregateLinksForDesignation(bridge.byDesignation.get(key) ?? []);
    expect(links).toHaveLength(2);
    expect(links.map((l) => l.displayName).sort()).toEqual(["Perk B", "Weapon A"]);
  });

  it("aggregates coverage per designation from unioned links", () => {
    const db = createTestDb();
    const user = ensureUser(db, "bridge-2", 3, "Player");
    const now = new Date().toISOString();

    createSynergyRecord(db, user.id, {
      id: "syn-a",
      name: "Verb: Devour — A",
      type: "verb",
      subType: "Devour",
      description: "",
      links: [{ kind: "weapon", displayName: "Weapon A", itemHash: 111 }],
      now,
    });
    createSynergyRecord(db, user.id, {
      id: "syn-b",
      name: "Verb: Devour — B",
      type: "verb",
      subType: "Devour",
      description: "",
      links: [{ kind: "weapon", displayName: "Weapon B", itemHash: 222 }],
      now,
    });

    const bridge = resolveDesignatedSynergies(db, user.id, [
      { type: "verb", subType: "Devour" },
    ]);
    const key = designationKey({ type: "verb", subType: "Devour" });
    const matches = bridge.byDesignation.get(key) ?? [];
    const synthetic = {
      id: key,
      userId: user.id,
      name: "Verb: Devour",
      type: "verb" as const,
      subType: "Devour",
      description: "",
      createdAt: now,
      updatedAt: now,
      links: aggregateLinksForDesignation(matches),
    };

    const coverage = evaluateCoverage({
      claims: [
        {
          slot: "primary",
          itemHash: 111,
          itemName: "Weapon A",
          source: "set",
        },
      ],
      synergies: [synthetic],
      subclass: { element: "Void" },
    });

    expect(coverage.synergies).toHaveLength(1);
    expect(coverage.synergies[0]?.tier).toBe("weak");
    expect(coverage.synergies[0]?.matchedLinks).toHaveLength(1);
    expect(coverage.synergies[0]?.unmatchedLinks).toHaveLength(1);
  });
});
