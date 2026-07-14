/**
 * Server: DBR-MOD-001–002 mod energy + illegal piece mods.
 */

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { evaluateModEnergy } from "@/lib/builds/destinyBuildConstraints";
import {
  armorEnergyCapacity,
  isModLegalForArmorSlot,
  sumEnergyCosts,
} from "@/lib/builds/modEnergy";
import type { SlotClaim } from "@/lib/builds/resolveVariant";
import type { AttachmentRecord } from "@/lib/db/repositories/variantRepository";
import { getServices } from "@/lib/services";

export type ModEnergyConfig = {
  slot: string;
  modHashes: number[];
  /** Armor tier when known (owned pin); null → capacity 10. */
  tier?: number | null;
};

export async function assertModEnergyForConfigs(
  configs: ModEnergyConfig[],
): Promise<void> {
  if (configs.length === 0) return;

  const { entityCache } = await getServices();
  const mods = await entityCache.getStore("mods");
  const byHash = new Map(mods.map((m) => [m.hash, m] as const));

  const pieces: Array<{
    slot: string;
    energyUsed: number;
    energyCapacity: number;
  }> = [];
  const illegal: string[] = [];

  for (const cfg of configs) {
    const costs: number[] = [];
    for (const hash of cfg.modHashes) {
      const mod = byHash.get(hash);
      if (!mod) continue;
      if (!isModLegalForArmorSlot(cfg.slot, mod.slotCategory)) {
        illegal.push(
          `${cfg.slot}: mod "${mod.name}" is not legal for this piece (${mod.slotCategory})`,
        );
      }
      if (typeof mod.energyCost === "number") costs.push(mod.energyCost);
    }
    pieces.push({
      slot: cfg.slot,
      energyUsed: sumEnergyCosts(costs),
      energyCapacity: armorEnergyCapacity(cfg.tier),
    });
  }

  if (illegal.length > 0) {
    throw new ApiError(
      API_ERROR_CODES.MOD_ENERGY_EXCEEDED,
      illegal[0] ?? "Illegal mod for armor piece",
      { illegal },
      400,
    );
  }

  const { hardBlocks } = evaluateModEnergy(pieces);
  if (hardBlocks.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.MOD_ENERGY_EXCEEDED,
    hardBlocks.map((b) => b.message).join("; "),
    { hardBlocks },
    400,
  );
}

/**
 * Collect mod hashes from live set items + snapshot attachment configs
 * on armor slots, then assert energy.
 */
export async function assertModEnergyForAttachments(
  attachments: AttachmentRecord[],
  equipment: Partial<Record<string, SlotClaim>>,
  loadSetItems: (
    setId: string,
  ) => Promise<
    Array<{
      slot: string;
      modHashes: number[] | null;
      removedAt?: string | null;
    }>
  >,
): Promise<void> {
  const configs: ModEnergyConfig[] = [];

  for (const att of attachments) {
    if (att.mode === "snapshot" && att.snapshotConfigs) {
      for (const cfg of att.snapshotConfigs) {
        const mods = cfg.modHashes ?? [];
        if (mods.length === 0) continue;
        if (
          !["helmet", "arms", "chest", "legs", "class_item"].includes(cfg.slot)
        ) {
          continue;
        }
        configs.push({ slot: cfg.slot, modHashes: mods });
      }
      continue;
    }

    const items = await loadSetItems(att.setId);
    for (const item of items) {
      if (item.removedAt) continue;
      const mods = item.modHashes ?? [];
      if (mods.length === 0) continue;
      if (
        !["helmet", "arms", "chest", "legs", "class_item"].includes(item.slot)
      ) {
        continue;
      }
      configs.push({ slot: item.slot, modHashes: mods });
    }
  }

  // Prefer equipment claim slots (resolved) only for labeling; tier unknown.
  void equipment;
  await assertModEnergyForConfigs(configs);
}
