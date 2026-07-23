import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";

import { allocateUniqueSetName } from "./uniqueSetName";

describe("allocateUniqueSetName", () => {
  it("returns base name when free", () => {
    const db = createTestDb();
    const user = ensureUser(db, "1", 1, "t");
    expect(allocateUniqueSetName(db, user.id, "armor", "Melee Kit")).toBe("Melee Kit");
  });

  it("suffixes when name collides", () => {
    const db = createTestDb();
    const user = ensureUser(db, "2", 1, "t");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "s1",
      name: "Melee Kit",
      type: "armor",
      tagIds: [],
      now,
    });
    expect(allocateUniqueSetName(db, user.id, "armor", "Melee Kit")).toBe("Melee Kit (2)");
    createSetRecord(db, user.id, {
      id: "s2",
      name: "Melee Kit (2)",
      type: "armor",
      tagIds: [],
      now,
    });
    expect(allocateUniqueSetName(db, user.id, "armor", "Melee Kit")).toBe("Melee Kit (3)");
  });
});
