import { describe, expect, it, vi } from "vitest";

import { HttpBungieProfileClient } from "./profile";

const API_KEY = "test-api-key";
const ACCESS_TOKEN = "bearer-token";

function makeClient(fetchFn: typeof fetch) {
  return new HttpBungieProfileClient({ apiKey: API_KEY, fetchFn });
}

function makeOkFetch(body: unknown): typeof fetch {
  return vi.fn().mockResolvedValue({
    ok: true,
    json: async () => body,
  }) as unknown as typeof fetch;
}

function makeErrorFetch(status: number): typeof fetch {
  return vi.fn().mockResolvedValue({
    ok: false,
    status,
    statusText: "Unauthorized",
  }) as unknown as typeof fetch;
}

const MEMBERSHIPS_RESPONSE = {
  ErrorCode: 1,
  Response: {
    destinyMemberships: [
      { membershipType: 3, membershipId: "111", displayName: "G1", bungieGlobalDisplayName: "" },
      { membershipType: 1, membershipId: "222", bungieGlobalDisplayName: "Guardian#0001" },
    ],
    primaryMembershipId: "222",
  },
};

const CHARACTERS_RESPONSE = {
  ErrorCode: 1,
  Response: {
    characters: {
      data: {
        char1: {
          characterId: "char1",
          classType: 1,
          light: 1810,
          emblemPath: "/common/emblem.jpg",
          dateLastPlayed: "2024-06-10T12:00:00Z",
        },
        char2: {
          characterId: "char2",
          classType: 0,
          light: 1800,
          emblemPath: null,
          dateLastPlayed: "2024-06-01T00:00:00Z",
        },
      },
    },
  },
};

const EQUIPMENT_RESPONSE = {
  ErrorCode: 1,
  Response: {
    characters: {
      data: {
        char1: {
          characterId: "char1",
          classType: 1,
          light: 1810,
          emblemPath: "/common/emblem.jpg",
          dateLastPlayed: "2024-06-10T12:00:00Z",
        },
      },
    },
    characterEquipment: {
      data: {
        char1: {
          items: [
            { itemHash: 999001, bucketHash: 1498876634, itemInstanceId: "inst1" },
            { itemHash: 999002, bucketHash: 3448274439, itemInstanceId: "inst2" },
            { itemHash: 999003, bucketHash: 99999999 }, // unlisted bucket – should be skipped
          ],
        },
      },
    },
    itemComponents: {
      sockets: {
        data: {
          inst1: {
            sockets: [
              { plugHash: 101, isEnabled: true },
              { plugHash: 102, isEnabled: false }, // disabled – should be skipped
              { plugHash: 103 }, // no isEnabled – treated as enabled
            ],
          },
          inst2: {
            sockets: [{ plugHash: 201, isEnabled: true }],
          },
        },
      },
    },
  },
};

describe("HttpBungieProfileClient.getMemberships", () => {
  it("maps destinyMemberships and uses bungieGlobalDisplayName when present", async () => {
    const memberships = await makeClient(makeOkFetch(MEMBERSHIPS_RESPONSE)).getMemberships(
      ACCESS_TOKEN,
    );

    expect(memberships).toHaveLength(2);
    const primary = memberships[0];
    expect(primary.membershipId).toBe("222");
    expect(primary.displayName).toBe("Guardian#0001");
    expect(primary.membershipType).toBe(1);
  });

  it("puts the primary membership first", async () => {
    const memberships = await makeClient(makeOkFetch(MEMBERSHIPS_RESPONSE)).getMemberships(
      ACCESS_TOKEN,
    );

    expect(memberships[0].membershipId).toBe("222");
  });

  it("throws with Bungie Message when ErrorCode !== 1", async () => {
    const body = { ErrorCode: 99, Message: "Access Denied", Response: null };
    await expect(
      makeClient(makeOkFetch(body)).getMemberships(ACCESS_TOKEN),
    ).rejects.toThrow("Access Denied");
  });

  it("throws on HTTP error", async () => {
    await expect(
      makeClient(makeErrorFetch(401)).getMemberships(ACCESS_TOKEN),
    ).rejects.toThrow(/401/);
  });
});

describe("HttpBungieProfileClient.getCharacters", () => {
  const membership = { membershipType: 3, membershipId: "mem1", displayName: "G1" };

  it("returns characters sorted by dateLastPlayed descending", async () => {
    const chars = await makeClient(makeOkFetch(CHARACTERS_RESPONSE)).getCharacters(
      ACCESS_TOKEN,
      membership,
    );

    expect(chars[0].characterId).toBe("char1");
    expect(chars[1].characterId).toBe("char2");
  });

  it("maps classType numbers to names", async () => {
    const chars = await makeClient(makeOkFetch(CHARACTERS_RESPONSE)).getCharacters(
      ACCESS_TOKEN,
      membership,
    );

    expect(chars[0].classType).toBe("Hunter");
    expect(chars[1].classType).toBe("Titan");
  });

  it("preserves null emblemPath", async () => {
    const chars = await makeClient(makeOkFetch(CHARACTERS_RESPONSE)).getCharacters(
      ACCESS_TOKEN,
      membership,
    );

    expect(chars[1].emblemPath).toBeNull();
  });
});

describe("HttpBungieProfileClient.getCharacterEquipment", () => {
  const membership = { membershipType: 3, membershipId: "mem1", displayName: "G1" };

  it("maps equipment items to correct buckets and plug hashes", async () => {
    const equipment = await makeClient(makeOkFetch(EQUIPMENT_RESPONSE)).getCharacterEquipment(
      ACCESS_TOKEN,
      membership,
      "char1",
    );

    expect(equipment.items).toHaveLength(2); // unlisted bucket skipped
    const weapon = equipment.items.find((i) => i.bucket === "Kinetic Weapons");
    expect(weapon?.itemHash).toBe(999001);
    expect(weapon?.plugHashes).toEqual([101, 103]); // 102 disabled
  });

  it("skips items in unlisted buckets", async () => {
    const equipment = await makeClient(makeOkFetch(EQUIPMENT_RESPONSE)).getCharacterEquipment(
      ACCESS_TOKEN,
      membership,
      "char1",
    );

    const hashes = equipment.items.map((i) => i.itemHash);
    expect(hashes).not.toContain(999003);
  });

  it("throws when the characterId is not found", async () => {
    await expect(
      makeClient(makeOkFetch(EQUIPMENT_RESPONSE)).getCharacterEquipment(
        ACCESS_TOKEN,
        membership,
        "nonexistent",
      ),
    ).rejects.toThrow(/nonexistent/);
  });

  it("throws with Bungie Message when ErrorCode !== 1", async () => {
    const body = { ErrorCode: 5, Message: "Invalid token", Response: null };
    await expect(
      makeClient(makeOkFetch(body)).getCharacterEquipment(ACCESS_TOKEN, membership, "char1"),
    ).rejects.toThrow("Invalid token");
  });
});
