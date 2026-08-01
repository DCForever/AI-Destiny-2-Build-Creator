import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import {
  buildVariants,
  builds,
  variantSetAttachments,
} from "@/lib/db/schema";
import {
  createSetRecord,
  findAttachmentsBySetId,
  findDuplicateName,
  getSet,
  listSets,
  listSetsByTags,
} from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";

describe("setRepository", () => {
  it("creates and lists sets with tags", () => {
    const db = createTestDb();
    const user = ensureUser(db, "m1", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "set-1",
      name: "Solar PVE",
      type: "weapon",
      tagIds: ["solar", "pve"],
      now,
    });

    const list = listSets(db, user.id);
    expect(list).toHaveLength(1);
    expect(list[0]?.tagIds).toEqual(["pve", "solar"]);
    expect(getSet(db, user.id, "set-1")?.name).toBe("Solar PVE");
    expect(getSet(db, user.id + 1, "set-1")).toBeNull();
  });

  it("detects duplicate names within type", () => {
    const db = createTestDb();
    const user = ensureUser(db, "m2", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "set-a",
      name: "Dup",
      type: "armor",
      tagIds: [],
      now,
    });

    expect(findDuplicateName(db, user.id, "armor", "Dup")).toBe(true);
    expect(findDuplicateName(db, user.id, "weapon", "Dup")).toBe(false);
    expect(findDuplicateName(db, user.id, "armor", "Dup", "set-a")).toBe(false);
  });

  it("finds attachments for delete guard", () => {
    const db = createTestDb();
    const user = ensureUser(db, "m3", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "set-attached",
      name: "Attached",
      type: "weapon",
      tagIds: [],
      now,
    });

    db.insert(builds)
      .values({
        id: "build-1",
        userId: user.id,
        name: "Build",
        className: "Titan",
        subclass: "Sunbreaker",
        exoticArmorHash: 1,
        exoticArmorName: "Hallowfire",
        createdAt: now,
        updatedAt: now,
      })
      .run();

    db.insert(buildVariants)
      .values({
        id: "variant-1",
        buildId: "build-1",
        name: "Default",
        isDefault: 1,
        createdAt: now,
        updatedAt: now,
      })
      .run();

    db.insert(variantSetAttachments)
      .values({
        id: "attach-1",
        variantId: "variant-1",
        setId: "set-attached",
        mode: "live",
        attachedAt: now,
      })
      .run();

    const refs = findAttachmentsBySetId(db, "set-attached");
    expect(refs).toHaveLength(1);
    expect(refs[0]).toMatchObject({
      buildId: "build-1",
      variantId: "variant-1",
    });
  });

  it("filters sets by tag AND intersection", () => {
    const db = createTestDb();
    const user = ensureUser(db, "m4", 3, "Player");
    const now = new Date().toISOString();

    createSetRecord(db, user.id, {
      id: "s1",
      name: "Solar Melee",
      type: "weapon",
      tagIds: ["solar", "melee"],
      now,
    });
    createSetRecord(db, user.id, {
      id: "s2",
      name: "Solar Only",
      type: "weapon",
      tagIds: ["solar"],
      now,
    });
    createSetRecord(db, user.id, {
      id: "s3",
      name: "Arc Melee",
      type: "weapon",
      tagIds: ["arc", "melee"],
      now,
    });

    const both = listSetsByTags(db, user.id, ["solar", "melee"]);
    expect(both.map((s) => s.id).sort()).toEqual(["s1"]);

    const solarArmor = listSetsByTags(db, user.id, ["solar"], "armor");
    expect(solarArmor).toHaveLength(0);
  });
});
