/**
 * Pure helpers for variant Mods-tab slot editing.
 * Mods persist on attachment snapshot configs (variant path), not a parallel store.
 */

export type SlotModConfig = {
  slot: string;
  itemHash: number;
  itemName: string;
  selectedPerks?: number[];
  masterworkHash?: number | null;
  modHashes?: number[] | null;
  instanceId?: string | null;
};

export type AttachmentWithOptionalSnapshot = {
  setId: string;
  mode: "live" | "snapshot";
  snapshotConfigs?: SlotModConfig[];
};

/** Apply modHashes to one slot in a snapshot config list (immutable). */
export function applySlotModHashes(
  configs: SlotModConfig[],
  slot: string,
  modHashes: number[],
): SlotModConfig[] {
  const unique = [...new Set(modHashes.filter((h) => Number.isInteger(h) && h > 0))];
  let found = false;
  const next = configs.map((cfg) => {
    if (cfg.slot !== slot) return cfg;
    found = true;
    return { ...cfg, modHashes: unique };
  });
  if (!found) {
    throw new Error(`No snapshot config for slot "${slot}"`);
  }
  return next;
}

/** Toggle a mod hash on/off for a slot. */
export function toggleSlotModHash(
  configs: SlotModConfig[],
  slot: string,
  modHash: number,
): SlotModConfig[] {
  const cfg = configs.find((c) => c.slot === slot);
  if (!cfg) throw new Error(`No snapshot config for slot "${slot}"`);
  const current = cfg.modHashes ?? [];
  const next = current.includes(modHash)
    ? current.filter((h) => h !== modHash)
    : [...current, modHash];
  return applySlotModHashes(configs, slot, next);
}

/**
 * Build a full attachments patch: keep other attachments (and their snapshot
 * configs when present), force the edited set into snapshot mode with updated
 * configs (so slot mods save on the variant).
 */
export function attachmentsWithSlotMods(
  current: AttachmentWithOptionalSnapshot[],
  setId: string,
  configs: SlotModConfig[],
): AttachmentWithOptionalSnapshot[] {
  const exists = current.some((a) => a.setId === setId);
  if (!exists) {
    return [
      ...current.map((a) => ({
        setId: a.setId,
        mode: a.mode,
        snapshotConfigs: a.snapshotConfigs ?? undefined,
      })),
      { setId, mode: "snapshot" as const, snapshotConfigs: configs },
    ];
  }
  return current.map((a) =>
    a.setId === setId
      ? { setId, mode: "snapshot" as const, snapshotConfigs: configs }
      : {
          setId: a.setId,
          mode: a.mode,
          snapshotConfigs: a.snapshotConfigs ?? undefined,
        },
  );
}

/** Map set items (or existing snapshot rows) into snapshot config shape. */
export function configsFromSetItems(
  items: Array<{
    slot: string;
    itemHash: number;
    itemName: string;
    selectedPerks?: number[] | null;
    masterworkHash?: number | null;
    modHashes?: number[] | null;
    instanceId?: string | null;
    removedAt?: string | null;
  }>,
): SlotModConfig[] {
  return items
    .filter((i) => !i.removedAt)
    .map((item) => ({
      slot: item.slot,
      itemHash: item.itemHash,
      itemName: item.itemName,
      selectedPerks: item.selectedPerks ?? [],
      masterworkHash: item.masterworkHash ?? null,
      modHashes: item.modHashes ?? [],
      instanceId: item.instanceId ?? null,
    }));
}

/** Armor combat slots that accept per-piece modHashes. */
export const ARMOR_MOD_SLOTS = [
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
] as const;

export type ArmorModSlot = (typeof ARMOR_MOD_SLOTS)[number];

export function isArmorModSlot(slot: string): slot is ArmorModSlot {
  return (ARMOR_MOD_SLOTS as readonly string[]).includes(slot);
}
