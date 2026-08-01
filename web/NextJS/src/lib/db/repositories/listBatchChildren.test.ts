import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { listBuilds } from "@/lib/db/repositories/buildRepository";
import { createSetRecord, listSets } from "@/lib/db/repositories/setRepository";
import {
  createSynergyRecord,
  getSynergiesByIds,
  listSynergies,
} from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";

describe("list batch child hydration", () => {
  it("listBuilds returns tags and synergy types for multiple builds", () => {
    const db = createTestDb();
    const user = ensureUser(db, "batch-b1", 3, "Player");
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "b1",
      name: "Build One",
      className: "Titan",
      subclass: { tree: "Solar" },
      exoticArmorHash: null,
      exoticArmorName: null,
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      softStatTargets: {},
      tagIds: ["pve", "solar"],
      synergyTypes: [
        { type: "verb", subType: "Jolt" },
        { type: "element", subType: null },
      ],
      now,
    });
    createBuildRecord(db, user.id, {
      id: "b2",
      name: "Build Two",
      className: "Hunter",
      subclass: { tree: "Arc" },
      exoticArmorHash: null,
      exoticArmorName: null,
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      softStatTargets: {},
      tagIds: ["pvp"],
      synergyTypes: [{ type: "verb", subType: "" }],
      now,
    });

    const list = listBuilds(db, user.id);
    expect(list).toHaveLength(2);
    const one = list.find((b) => b.id === "b1")!;
    const two = list.find((b) => b.id === "b2")!;
    expect(one.tagIds).toEqual(["pve", "solar"]);
    expect(one.synergyTypes).toEqual(
      expect.arrayContaining([
        { type: "verb", subType: "Jolt" },
        { type: "element", subType: null },
      ]),
    );
    expect(two.tagIds).toEqual(["pvp"]);
    // empty string subType exposed as null
    expect(two.synergyTypes).toEqual([{ type: "verb", subType: null }]);
  });

  it("listSets returns sorted tags for multiple sets", () => {
    const db = createTestDb();
    const user = ensureUser(db, "batch-s1", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "s1",
      name: "Weapons A",
      type: "weapon",
      tagIds: ["solar", "pve"],
      now,
    });
    createSetRecord(db, user.id, {
      id: "s2",
      name: "Armor B",
      type: "armor",
      tagIds: [],
      now,
    });

    const list = listSets(db, user.id);
    expect(list).toHaveLength(2);
    expect(list.find((s) => s.id === "s1")?.tagIds).toEqual(["pve", "solar"]);
    expect(list.find((s) => s.id === "s2")?.tagIds).toEqual([]);
  });

  it("listSynergies and getSynergiesByIds batch-load links", () => {
    const db = createTestDb();
    const user = ensureUser(db, "batch-y1", 3, "Player");
    const now = new Date().toISOString();
    createSynergyRecord(db, user.id, {
      id: "y1",
      name: "Jolt",
      type: "verb",
      subType: "Jolt",
      description: "",
      links: [
        { kind: "weapon", displayName: "Riskrunner", itemHash: 1 },
        { kind: "weapon_perk", displayName: "Arc Conductor", perkHash: 2 },
      ],
      now,
    });
    createSynergyRecord(db, user.id, {
      id: "y2",
      name: "Devour",
      type: "verb",
      subType: "Devour",
      description: "",
      links: [{ kind: "exotic_armor", displayName: "Nezarec", itemHash: 3 }],
      now,
    });

    const listed = listSynergies(db, user.id);
    expect(listed).toHaveLength(2);
    expect(listed.find((s) => s.id === "y1")?.links).toHaveLength(2);
    expect(listed.find((s) => s.id === "y2")?.links).toHaveLength(1);

    const byIds = getSynergiesByIds(db, user.id, ["y2", "y1"]);
    expect(byIds).toHaveLength(2);
    expect(byIds.find((s) => s.id === "y1")?.links.map((l) => l.displayName).sort()).toEqual([
      "Arc Conductor",
      "Riskrunner",
    ]);
  });
});
