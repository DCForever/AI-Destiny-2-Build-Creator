import { describe, expect, it, vi } from "vitest";

import { HttpBungieProfileClient, parseSocketCapture, extractReusablePlugsMap } from "./profile";

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
const FULL_INVENTORY_RESPONSE = {
  ErrorCode: 1,
  Response: {
    profileInventory: {
      data: {
        items: [
          { itemHash: 800001, bucketHash: 1498876634, itemInstanceId: "vault1" },
        ],
      },
    },
    characterInventories: {
      data: {
        char1: {
          items: [
            { itemHash: 800002, bucketHash: 2465295065, itemInstanceId: "charInv1" },
          ],
        },
      },
    },
    characterEquipment: {
      data: {
        char1: {
          items: [
            { itemHash: 800003, bucketHash: 953998645, itemInstanceId: "equip1" },
          ],
        },
      },
    },
    itemComponents: {
      instances: {
        data: {
          vault1: { primaryStat: { value: 1800 }, isMasterwork: true, isCrafted: false },
          charInv1: { primaryStat: { value: 1810 }, isCrafted: true },
          equip1: { primaryStat: { value: 1820 } },
        },
      },
      sockets: {
        data: {
          vault1: { sockets: [{ plugHash: 501, isEnabled: true }] },
          charInv1: { sockets: [{ plugHash: 502, isEnabled: true }] },
          equip1: { sockets: [{ plugHash: 503, isEnabled: true }] },
        },
      },
    },
  },
};

const ARMOR_STATS_RESPONSE = {
  ErrorCode: 1,
  Response: {
    profileInventory: {
      data: {
        items: [
          {
            itemHash: 700001,
            bucketHash: 3448274439,
            itemInstanceId: "armor1",
          },
        ],
      },
    },
    itemComponents: {
      instances: {
        data: {
          armor1: { primaryStat: { value: 1810 } },
        },
      },
      sockets: {
        data: {
          armor1: { sockets: [] },
        },
      },
      stats: {
        data: {
          armor1: {
            stats: [
              { statHash: 392767087, value: 10 },
              { statHash: 4244567218, value: 20 },
              { statHash: 1735777505, value: 5 },
              { statHash: 144602215, value: 8 },
              { statHash: 1943323491, value: 12 },
              { statHash: 2996146975, value: 15 },
            ],
          },
        },
      },
    },
  },
};

describe("HttpBungieProfileClient.getFullInventory", () => {
  const membership = { membershipType: 3, membershipId: "mem1", displayName: "G1" };

  it("parses vault, character, and equipped items with instances and sockets", async () => {
    const items = await makeClient(makeOkFetch(FULL_INVENTORY_RESPONSE)).getFullInventory(
      ACCESS_TOKEN,
      membership,
    );

    expect(items).toHaveLength(3);
    const vault = items.find((i) => i.location === "vault");
    expect(vault?.itemHash).toBe(800001);
    expect(vault?.power).toBe(1800);
    expect(vault?.isMasterwork).toBe(true);
    expect(vault?.plugHashes).toEqual([501]);

    const charItem = items.find((i) => i.location === "character");
    expect(charItem?.characterId).toBe("char1");
    expect(charItem?.isCrafted).toBe(true);

    const equipped = items.find((i) => i.location === "equipped");
    expect(equipped?.itemHash).toBe(800003);
    expect(equipped?.plugHashes).toEqual([503]);
  });

  it("captures reusable plugs from component 310 into weapon socketCapture", async () => {
    const response = {
      ...FULL_INVENTORY_RESPONSE,
      Response: {
        ...FULL_INVENTORY_RESPONSE.Response,
        profileInventory: {
          data: {
            items: [
              {
                itemHash: 900100,
                bucketHash: 1498876634,
                itemInstanceId: "weapon1",
              },
            ],
          },
        },
        itemComponents: {
          ...FULL_INVENTORY_RESPONSE.Response.itemComponents,
          sockets: {
            data: {
              weapon1: {
                sockets: [
                  { plugHash: 101, isEnabled: true },
                  { plugHash: 201, isEnabled: true },
                ],
              },
            },
          },
          reusablePlugs: {
            data: {
              weapon1: {
                plugs: {
                  "0": [
                    { plugItemHash: 101, canInsert: true },
                    { plugItemHash: 102, canInsert: true },
                  ],
                  "1": [{ plugItemHash: 201, canInsert: true }],
                },
              },
            },
          },
        },
      },
    };

    const items = await makeClient(makeOkFetch(response)).getFullInventory(ACCESS_TOKEN, membership);
    const weapon = items.find((item) => item.instanceId === "weapon1");
    expect(weapon?.socketCapture).toEqual([
      { socketIndex: 0, equippedPlugHash: 101, reusablePlugHashes: [101, 102] },
      { socketIndex: 1, equippedPlugHash: 201, reusablePlugHashes: [201] },
    ]);
  });

  it("parseSocketCapture and extractReusablePlugsMap helpers merge 305 and 310", () => {
    const reusable = extractReusablePlugsMap({
      reusablePlugs: {
        data: {
          inst: {
            plugs: {
              "0": [{ plugItemHash: 11, canInsert: true }],
            },
          },
        },
      },
    });
    const capture = parseSocketCapture(
      "inst",
      [{ plugHash: 10, isEnabled: true }],
      reusable,
    );
    expect(capture).toEqual([
      { socketIndex: 0, equippedPlugHash: 10, reusablePlugHashes: [11] },
    ]);
  });

  it("reports diagnostics for dropped items (unknown bucket, missing instance id)", async () => {
    const response = {
      ...FULL_INVENTORY_RESPONSE,
      Response: {
        ...FULL_INVENTORY_RESPONSE.Response,
        profileInventory: {
          data: {
            items: [
              ...FULL_INVENTORY_RESPONSE.Response.profileInventory.data.items,
              { itemHash: 900001, bucketHash: 215593132, itemInstanceId: "postmaster1" },
              { itemHash: 900002, bucketHash: 1498876634 },
              { itemHash: 900003, bucketHash: 138197802, itemInstanceId: "vault-general1" },
            ],
          },
        },
      },
    };
    const { items, diagnostics } = await makeClient(makeOkFetch(response)).getFullInventoryWithDiagnostics(
      ACCESS_TOKEN,
      membership,
    );

    expect(items).toHaveLength(5);
    expect(diagnostics.raw.total).toBe(6);
    expect(diagnostics.parsed.total).toBe(5);
    expect(diagnostics.dropped.total).toBe(1);
    expect(diagnostics.dropped.unknownBucket).toBe(0);
    expect(diagnostics.dropped.missingInstanceId).toBe(1);
    expect(items.some((item) => item.instanceId === "vault-general1")).toBe(true);
  });

  it("parses armor stat values from itemComponents.stats", async () => {
    const items = await makeClient(makeOkFetch(ARMOR_STATS_RESPONSE)).getFullInventory(
      ACCESS_TOKEN,
      membership,
    );

    expect(items).toHaveLength(1);
    const armor = items[0]!;
    expect(armor.statValues).toEqual({
      Health: 10,
      Melee: 20,
      Grenade: 5,
      Super: 8,
      Class: 12,
      Weapons: 15,
    });
  });

  it("parses weapon combat stats when present", async () => {
    const weaponStatsResponse = {
      Response: {
        profileInventory: {
          data: {
            items: [
              {
                itemHash: 900001,
                itemInstanceId: "w1",
                bucketHash: 1498876634, // Kinetic Weapons
              },
            ],
          },
        },
        characterInventories: { data: {} },
        characterEquipment: { data: {} },
        itemComponents: {
          instances: {
            data: {
              w1: { primaryStat: { value: 400 }, isMasterworked: false },
            },
          },
          sockets: { data: { w1: { sockets: [] } } },
          stats: {
            data: {
              w1: {
                stats: {
                  "4284893193": { statHash: 4284893193, value: 260 },
                  "4043523819": { statHash: 4043523819, value: 45 },
                },
              },
            },
          },
        },
      },
      ErrorCode: 1,
    };
    const items = await makeClient(makeOkFetch(weaponStatsResponse)).getFullInventory(
      ACCESS_TOKEN,
      membership,
    );
    expect(items[0]?.statValues).toEqual({ RPM: 260, Impact: 45 });
  });

  it("omits full armor stats requirement for partial armor stats", async () => {
    const partialStatsResponse = {
      ...ARMOR_STATS_RESPONSE,
      Response: {
        ...ARMOR_STATS_RESPONSE.Response,
        itemComponents: {
          ...ARMOR_STATS_RESPONSE.Response.itemComponents,
          stats: {
            data: {
              armor1: {
                stats: [
                  { statHash: 392767087, value: 10 },
                  { statHash: 4244567218, value: 20 },
                ],
              },
            },
          },
        },
      },
    };
    const items = await makeClient(makeOkFetch(partialStatsResponse)).getFullInventory(
      ACCESS_TOKEN,
      membership,
    );

    expect(items[0]?.statValues).toEqual({ Health: 10, Melee: 20 });
  });

  it("captures the API gearTier from the instance component", async () => {
    const response = {
      ...ARMOR_STATS_RESPONSE,
      Response: {
        ...ARMOR_STATS_RESPONSE.Response,
        itemComponents: {
          ...ARMOR_STATS_RESPONSE.Response.itemComponents,
          instances: {
            data: {
              armor1: { primaryStat: { value: 1810 }, gearTier: 4 },
            },
          },
        },
      },
    };
    const items = await makeClient(makeOkFetch(response)).getFullInventory(ACCESS_TOKEN, membership);
    expect(items[0]?.gearTier).toBe(4);
  });

  it("returns a null gearTier when the instance component omits it", async () => {
    const items = await makeClient(makeOkFetch(ARMOR_STATS_RESPONSE)).getFullInventory(
      ACCESS_TOKEN,
      membership,
    );
    expect(items[0]?.gearTier ?? null).toBeNull();
  });
});

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
