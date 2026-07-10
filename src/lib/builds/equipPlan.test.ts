import { describe, expect, it, vi } from "vitest";

import { planEquipSteps } from "@/lib/builds/equipPlan";
import { executeEquipPlan } from "@/lib/builds/equipOrchestrator";
import { createMockWriteClient } from "@/lib/bungie/writeClient";
import type { UserInventoryItem } from "@/lib/db/types";

function inv(
  partial: Pick<UserInventoryItem, "instanceId" | "itemHash" | "location"> & {
    characterId?: string;
  },
): UserInventoryItem {
  return {
    bucket: "Helmet",
    power: 100,
    isMasterwork: false,
    isCrafted: false,
    plugHashes: [],
    rollTags: [],
    syncedAt: "2026-01-01T00:00:00.000Z",
    ...partial,
  };
}

describe("planEquipSteps (US2)", () => {
  it("orders transfer → equip → artifact → fashion", () => {
    const plan = planEquipSteps({
      characterId: "char-a",
      equipment: {
        helmet: {
          slot: "helmet",
          itemHash: 10,
          itemName: "Helm",
          source: "set",
          instanceId: "i-helm",
        },
      },
      artifact: { hash: 99, name: "Artifact", config: [1, 2] },
      fashion: {
        setId: "f1",
        slots: { ghost: { itemHash: 50, itemName: "Ghost" } },
      },
      inventory: [
        inv({ instanceId: "i-helm", itemHash: 10, location: "vault" }),
        inv({ instanceId: "i-ghost", itemHash: 50, location: "vault" }),
      ],
    });

    expect(plan.map((s) => s.kind)).toEqual(["transfer", "equip", "artifact", "fashion"]);
    expect(plan[0]?.id).toBe("transfer-helmet");
    expect(plan[0]?.transferToVault).toBe(false);
    expect(plan[1]?.id).toBe("equip-helmet");
    expect(plan[2]?.id).toBe("artifact");
    expect(plan[3]?.id).toBe("fashion-ghost");
  });

  it("vault-hops when item is on another character", () => {
    const plan = planEquipSteps({
      characterId: "char-a",
      equipment: {
        primary: {
          slot: "primary",
          itemHash: 1,
          itemName: "Gun",
          source: "set",
          instanceId: "i-gun",
        },
      },
      artifact: null,
      fashion: null,
      inventory: [
        inv({
          instanceId: "i-gun",
          itemHash: 1,
          location: "equipped",
          characterId: "char-b",
        }),
      ],
    });

    expect(plan.map((s) => s.id)).toEqual([
      "transfer-primary-to-vault",
      "transfer-primary-from-vault",
      "equip-primary",
    ]);
  });

  it("skips transfer when already on target character", () => {
    const plan = planEquipSteps({
      characterId: "char-a",
      equipment: {
        arms: {
          slot: "arms",
          itemHash: 2,
          itemName: "Arms",
          source: "set",
          instanceId: "i-arms",
        },
      },
      artifact: null,
      fashion: null,
      inventory: [
        inv({
          instanceId: "i-arms",
          itemHash: 2,
          location: "character",
          characterId: "char-a",
        }),
      ],
    });

    expect(plan.map((s) => s.kind)).toEqual(["equip"]);
  });

  it("omits empty fashion slots and missing artifact", () => {
    const plan = planEquipSteps({
      characterId: "char-a",
      equipment: {},
      artifact: null,
      fashion: { setId: "f1", slots: {} },
      inventory: [],
    });
    expect(plan).toEqual([]);
  });
});

describe("executeEquipPlan (US2/US3)", () => {
  const ctx = { accessToken: "t", membershipType: 3 };

  it("executes steps via write client in plan order", async () => {
    const calls: string[] = [];
    const client = createMockWriteClient({
      transferItem: async () => {
        calls.push("transfer");
      },
      equipItem: async () => {
        calls.push("equip");
      },
      applyArtifactConfig: async () => {
        calls.push("artifact");
      },
      applyFashionSlot: async () => {
        calls.push("fashion");
      },
    });

    const status = await executeEquipPlan(client, ctx, "char-a", [
      {
        id: "transfer-helmet",
        kind: "transfer",
        itemHash: 10,
        instanceId: "i1",
        transferToVault: false,
      },
      { id: "equip-helmet", kind: "equip", itemHash: 10, instanceId: "i1" },
      { id: "artifact", kind: "artifact", itemHash: 99, artifactConfig: [1] },
      { id: "fashion-ghost", kind: "fashion", slot: "ghost", itemHash: 50 },
    ]);

    expect(calls).toEqual(["transfer", "equip", "artifact", "fashion"]);
    expect(status.completed).toBe(4);
    expect(status.failed).toBe(0);
  });

  it("keeps prior ok steps when a later step fails (partial status)", async () => {
    const client = createMockWriteClient({
      equipItem: async (_ctx, args) => {
        if (args.instanceId === "fail") throw new Error("bungie denied");
      },
    });

    const status = await executeEquipPlan(client, ctx, "char-a", [
      {
        id: "transfer-helmet",
        kind: "transfer",
        itemHash: 10,
        instanceId: "ok",
        transferToVault: false,
      },
      { id: "equip-helmet", kind: "equip", itemHash: 10, instanceId: "fail" },
      { id: "equip-arms", kind: "equip", itemHash: 11, instanceId: "ok2" },
    ]);

    expect(status.steps[0]?.ok).toBe(true);
    expect(status.steps[1]?.ok).toBe(false);
    expect(status.steps[1]?.error).toMatch(/bungie denied/);
    expect(status.steps[2]?.ok).toBe(true);
    expect(status.completed).toBe(2);
    expect(status.failed).toBe(1);
  });
});

void vi;
