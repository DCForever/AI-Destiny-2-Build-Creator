import type { AppDatabase } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import type { AttachmentInput } from "@/lib/builds/attachmentMerge";
import type { EquipmentSlot } from "@/lib/sets/schemas";

const WEAPON_SLOTS: EquipmentSlot[] = ["primary", "special", "heavy"];
const ARMOR_SLOTS: EquipmentSlot[] = ["helmet", "arms", "chest", "legs", "class_item"];

/**
 * Subclass kit that satisfies DBR-SUB-006 when fragment capacity is unknown
 * (non-empty fragments) or known capacity ≤ fragment count.
 */
export const COMPLETE_DEFAULT_SUBCLASS_KIT = {
  name: "Sunbreaker",
  super: "Hammer of Sol",
  classAbility: "Rally Barricade",
  movement: "Strafe Lift",
  melee: "Hammer Strike",
  grenade: "Thermite Grenade",
  aspects: ["Roaring Flames", "Consecration"],
  fragments: [
    "Ember of Ashes",
    "Ember of Beams",
    "Ember of Char",
    "Ember of Combustion",
  ],
  rationale: "",
} as const;

/** Artifact selection that satisfies DBR-ART-003a on default. */
export const COMPLETE_DEFAULT_ARTIFACT = {
  artifactHash: 9_001,
  artifactName: "Test Artifact",
  artifactConfig: [11, 22],
} as const;

/** Seeds weapon + armor + mod sets that satisfy default full-combat-loadout validation. */
export async function seedFullCombatAttachments(
  db: AppDatabase,
  userId: number,
  prefix = "full",
): Promise<AttachmentInput[]> {
  const now = new Date().toISOString();
  const weaponId = `${prefix}-weapons`;
  const armorId = `${prefix}-armor`;
  const modId = `${prefix}-mods`;

  createSetRecord(db, userId, { id: weaponId, name: `${prefix} Weapons`, type: "weapon", tagIds: [], now });
  for (const [index, slot] of WEAPON_SLOTS.entries()) {
    await upsertSetItem(db, weaponId, "weapon", {
      slot,
      itemHash: 1000 + index,
      itemName: `${slot} item`,
    });
  }

  createSetRecord(db, userId, { id: armorId, name: `${prefix} Armor`, type: "armor", tagIds: [], now });
  for (const [index, slot] of ARMOR_SLOTS.entries()) {
    await upsertSetItem(db, armorId, "armor", {
      slot,
      itemHash: 2000 + index,
      itemName: `${slot} item`,
    });
  }

  createSetRecord(db, userId, { id: modId, name: `${prefix} Mods`, type: "mod", tagIds: [], now });
  // Two pieces so Mod set meets DBR-CMP-009 if occupancy is checked while attached.
  await upsertSetItem(db, modId, "mod", {
    slot: "helmet",
    itemHash: 3001,
    itemName: "Helmet mod",
  });
  await upsertSetItem(db, modId, "mod", {
    slot: "arms",
    itemHash: 3002,
    itemName: "Arms mod",
  });

  return [
    { setId: weaponId, mode: "live" },
    { setId: armorId, mode: "live" },
    { setId: modId, mode: "live" },
  ];
}
