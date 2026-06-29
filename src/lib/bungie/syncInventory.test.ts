import { afterEach, describe, expect, it, vi } from "vitest";

import { clearSyncLocksForTests, syncUserInventory } from "@/lib/bungie/syncInventory";
import type { BungieProfileClient, RawInventoryItem } from "@/lib/bungie/types";
import { createTestDb } from "@/lib/db/client";
import { ensureUser, getUserById } from "@/lib/db/repositories/userRepository";
import type { EntityCache } from "@/lib/manifest/types/services";

const destinyMembership = {
  membershipType: 3,
  membershipId: "destiny-mem-111",
  displayName: "Guardian",
};

const rawItems: RawInventoryItem[] = [
  {
    instanceId: "inst1",
    itemHash: 123,
    bucketHash: 1498876634,
    location: "vault",
    power: 1800,
    plugHashes: [],
    isMasterwork: false,
    isCrafted: false,
  },
];

function createMockProfileClient(): BungieProfileClient {
  return {
    getMemberships: vi.fn().mockResolvedValue([destinyMembership]),
    getCharacters: vi.fn(),
    getCharacterEquipment: vi.fn(),
    getFullInventory: vi.fn().mockResolvedValue(rawItems),
  };
}

function createMockCache(): EntityCache {
  return {
    getStore: vi.fn(async () => []),
    getMeta: vi.fn(async () => null),
    rebuild: vi.fn(async () => ({
      manifestVersion: "test",
      builtAt: new Date().toISOString(),
      counts: {
        "exotic-armor": 0,
        "exotic-weapons": 0,
        weapons: 0,
        "weapon-perks": 0,
        "origin-traits": 0,
        artifacts: 0,
        aspects: 0,
        fragments: 0,
        abilities: 0,
        mods: 0,
        "set-bonuses": 0,
        stats: 0,
      },
    })),
  };
}

describe("syncUserInventory", () => {
  afterEach(() => {
    clearSyncLocksForTests();
  });

  it("resolves Destiny membership via getMemberships instead of stored user fields", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "bungie-net-id", 0, "");
    const profileClient = createMockProfileClient();

    const result = await syncUserInventory(
      db,
      user,
      "token",
      profileClient,
      createMockCache(),
    );

    expect(profileClient.getMemberships).toHaveBeenCalledWith("token");
    expect(profileClient.getFullInventory).toHaveBeenCalledWith("token", destinyMembership);
    expect(result.itemCount).toBe(1);

    const updated = getUserById(db, user.id);
    expect(updated?.membershipType).toBe(3);
    expect(updated?.displayName).toBe("Guardian");
  });

  it("throws when no Destiny memberships are found", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "bungie-net-id", 0, "");
    const profileClient: BungieProfileClient = {
      getMemberships: vi.fn().mockResolvedValue([]),
      getCharacters: vi.fn(),
      getCharacterEquipment: vi.fn(),
      getFullInventory: vi.fn(),
    };

    await expect(
      syncUserInventory(db, user, "token", profileClient, createMockCache()),
    ).rejects.toThrow("No Destiny memberships found");
    expect(profileClient.getFullInventory).not.toHaveBeenCalled();
  });
});
