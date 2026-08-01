import { beforeEach, describe, expect, it, vi } from "vitest";
import { API_ERROR_CODES } from "@/lib/api/errors";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

import { assertModEnergyForConfigs } from "@/lib/builds/assertModEnergy";

const MOD_GENERAL_3 = 301;
const MOD_GENERAL_4 = 302;
const MOD_GENERAL_5 = 303;
const MOD_HELMET_3 = 310;
const MOD_ARMS_2 = 320;

describe("assertModEnergyForConfigs", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "mods") {
        return [
          {
            hash: MOD_GENERAL_3,
            name: "General 3",
            energyCost: 3,
            slotCategory: "general",
          },
          {
            hash: MOD_GENERAL_4,
            name: "General 4",
            energyCost: 4,
            slotCategory: "general",
          },
          {
            hash: MOD_GENERAL_5,
            name: "General 5",
            energyCost: 5,
            slotCategory: "general",
          },
          {
            hash: MOD_HELMET_3,
            name: "Helmet Locked",
            energyCost: 3,
            slotCategory: "helmet",
          },
          {
            hash: MOD_ARMS_2,
            name: "Arms Locked",
            energyCost: 2,
            slotCategory: "arms",
          },
        ];
      }
      return [];
    });
  });

  it("allows empty configs (no mods / progressive create)", async () => {
    await expect(assertModEnergyForConfigs([])).resolves.toBeUndefined();
  });

  it("allows under-capacity mod loadout on a piece", async () => {
    await expect(
      assertModEnergyForConfigs([
        {
          slot: "helmet",
          modHashes: [MOD_GENERAL_3, MOD_GENERAL_4],
          tier: null,
        },
      ]),
    ).resolves.toBeUndefined();
  });

  it("blocks over-capacity energy with MOD_ENERGY_EXCEEDED", async () => {
    // default capacity 10; 5+4+3 = 12
    await expect(
      assertModEnergyForConfigs([
        {
          slot: "chest",
          modHashes: [MOD_GENERAL_5, MOD_GENERAL_4, MOD_GENERAL_3],
        },
      ]),
    ).rejects.toMatchObject({
      code: API_ERROR_CODES.MOD_ENERGY_EXCEEDED,
      status: 400,
    });
  });

  it("blocks illegal slot-category mods with MOD_ENERGY_EXCEEDED", async () => {
    await expect(
      assertModEnergyForConfigs([
        {
          slot: "legs",
          modHashes: [MOD_HELMET_3],
        },
      ]),
    ).rejects.toMatchObject({
      code: API_ERROR_CODES.MOD_ENERGY_EXCEEDED,
      status: 400,
    });
  });

  it("skips unknown mod hashes when summing energy (characterization)", async () => {
    await expect(
      assertModEnergyForConfigs([
        {
          slot: "arms",
          modHashes: [999_999, MOD_ARMS_2],
        },
      ]),
    ).resolves.toBeUndefined();
  });
});
