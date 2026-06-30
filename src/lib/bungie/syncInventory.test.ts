import { afterEach, describe, expect, it, vi } from "vitest";

import type { ManifestService } from "@/lib/manifest/types/services";

import { clearSyncLocksForTests, syncUserInventory } from "@/lib/bungie/syncInventory";
import type {
  BungieProfileClient,
  InventoryParseDiagnostics,
  RawInventoryItem,
} from "@/lib/bungie/types";
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

const emptyDiagnostics: InventoryParseDiagnostics = {
  membership: destinyMembership,
  raw: {
    vault: 1,
    characterInventories: {},
    characterInventoriesTotal: 0,
    characterEquipment: {},
    characterEquipmentTotal: 0,
    total: 1,
  },
  parsed: {
    total: 1,
    equipmentTotal: 1,
    subclassTotal: 0,
    byLocation: { vault: 1, character: 0, equipped: 0 },
    byBucket: { Kinetic: 1 },
  },
  dropped: {
    total: 0,
    invalidShape: 0,
    unknownBucket: 0,
    missingInstanceId: 0,
    unknownBuckets: {},
  },
};

function createMockProfileClient(): BungieProfileClient {
  return {
    getMemberships: vi.fn().mockResolvedValue([destinyMembership]),
    getCharacters: vi.fn(),
    getCharacterEquipment: vi.fn(),
    getFullInventory: vi.fn().mockResolvedValue(rawItems),
    getFullInventoryWithDiagnostics: vi.fn().mockResolvedValue({
      items: rawItems,
      diagnostics: emptyDiagnostics,
    }),
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

function createMockManifest(): ManifestService {
  return {
    loadRawTable: async () => ({}),
    getStatus: async () => ({
      cachedVersion: "test",
      remoteVersion: "test",
      isStale: false,
    }),
    ensureCurrent: async () => "test",
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
      createMockManifest(),
      "test",
    );

    expect(profileClient.getMemberships).toHaveBeenCalledWith("token");
    expect(profileClient.getFullInventoryWithDiagnostics).toHaveBeenCalledWith(
      "token",
      destinyMembership,
    );
    expect(result.itemCount).toBe(1);
    expect(result.diagnostics.parsed.total).toBe(1);

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
      getFullInventoryWithDiagnostics: vi.fn(),
    };

    await expect(
      syncUserInventory(db, user, "token", profileClient, createMockCache(), createMockManifest(), "test"),
    ).rejects.toThrow("No Destiny memberships found");
    expect(profileClient.getFullInventoryWithDiagnostics).not.toHaveBeenCalled();
  });
});
