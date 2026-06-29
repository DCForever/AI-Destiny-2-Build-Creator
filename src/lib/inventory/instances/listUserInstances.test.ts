import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { upsertInventoryBatch } from "@/lib/db/repositories/inventoryRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";

import {
  funnelCopyCharacter,
  funnelCopyVault,
  helmetCopy,
  samplePlugNameMap,
} from "./__fixtures__/inventoryFixtures";
import { listUserInstances, getUserInstanceById } from "./listUserInstances";

function seedUser(db: ReturnType<typeof createTestDb>, membershipId: string) {
  const user = ensureUser(db, membershipId, 3, "Guardian");
  upsertInventoryBatch(db, user.id, [funnelCopyVault, funnelCopyCharacter, helmetCopy]);
  return user;
}

describe("listUserInstances", () => {
  it("returns sync prompt when inventory empty", () => {
    const db = createTestDb();
    const user = ensureUser(db, "inst-empty", 3, "Guardian");
    const result = listUserInstances({
      db,
      userId: user.id,
      criteria: {},
      plugMap: samplePlugNameMap,
    });
    expect(result.syncPrompt).toBe(true);
    expect(result.instances).toEqual([]);
    expect(result.message).toContain("Sync");
  });

  it("returns instances sorted by power descending", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-sort");
    const result = listUserInstances({
      db,
      userId: user.id,
      criteria: { itemHash: 1363886209 },
      plugMap: samplePlugNameMap,
    });
    expect(result.count).toBe(2);
    expect(result.instances[0]?.power).toBe(1810);
    expect(result.instances[1]?.power).toBe(1805);
  });

  it("filters by perk q after projection", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-perk");
    const result = listUserInstances({
      db,
      userId: user.id,
      criteria: { q: "rampage" },
      plugMap: samplePlugNameMap,
    });
    expect(result.instances).toHaveLength(1);
    expect(result.instances[0]?.instanceId).toBe("inst-char-1");
  });

  it("returns empty list for unowned itemHash without sync prompt", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-miss");
    const result = listUserInstances({
      db,
      userId: user.id,
      criteria: { itemHash: 1 },
      plugMap: samplePlugNameMap,
    });
    expect(result.syncPrompt).toBe(false);
    expect(result.instances).toEqual([]);
    expect(result.count).toBe(0);
  });

  it("filters by kind weapons and perk q together", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-and");
    const result = listUserInstances({
      db,
      userId: user.id,
      criteria: { kind: "weapon", q: "frenzy" },
      plugMap: samplePlugNameMap,
    });
    expect(result.instances).toHaveLength(1);
    expect(result.instances[0]?.instanceId).toBe("inst-vault-1");
  });

  it("getUserInstanceById returns single row", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-detail");
    const result = getUserInstanceById({
      db,
      userId: user.id,
      criteria: {},
      plugMap: samplePlugNameMap,
      instanceId: "inst-vault-1",
    });
    expect(result.instance?.instanceId).toBe("inst-vault-1");
  });

  it("getUserInstanceById returns undefined when not found", () => {
    const db = createTestDb();
    const user = seedUser(db, "inst-missing");
    const result = getUserInstanceById({
      db,
      userId: user.id,
      criteria: {},
      plugMap: samplePlugNameMap,
      instanceId: "does-not-exist",
    });
    expect(result.instance).toBeUndefined();
    expect(result.syncPrompt).toBe(false);
  });
});
