import type { ArmorSlotName } from "@/lib/manifest/types/records";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getSynergiesByIds } from "@/lib/db/repositories/synergyRepository";
import {
  getVariant,
  listAttachments,
  listVariants,
} from "@/lib/db/repositories/variantRepository";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import {
  armorManifestSlotToEquipment,
  resolveVariantEquipment,
  weaponManifestSlotToEquipment,
} from "@/lib/builds/resolveVariant";
import { getServices } from "@/lib/services";

async function lookupExoticSlots(
  exoticWeaponHash: number | null,
  exoticArmorHash: number,
): Promise<{ weaponSlot: EquipmentSlot | null; armorSlot: EquipmentSlot | null }> {
  try {
    const { entityCache } = await getServices();
    let weaponSlot: EquipmentSlot | null = null;
    let armorSlot: EquipmentSlot | null = null;

    if (exoticWeaponHash) {
      const exotics = await entityCache.getStore("exotic-weapons");
      const match = exotics.find((w) => w.hash === exoticWeaponHash);
      if (match) weaponSlot = weaponManifestSlotToEquipment(match.slot);
    }

    const armor = await entityCache.getStore("exotic-armor");
    const armorMatch = armor.find((a) => a.hash === exoticArmorHash);
    if (armorMatch) armorSlot = armorManifestSlotToEquipment(armorMatch.slot as ArmorSlotName);

    return { weaponSlot, armorSlot };
  } catch {
    return { weaponSlot: exoticWeaponHash ? "primary" : null, armorSlot: "chest" };
  }
}

export type VariantCompareResult = {
  shared: {
    exoticArmor: { hash: number; name: string };
    subclass: unknown;
    synergies: Array<{ id: string; name: string; type: string }>;
  };
  variants: Array<{
    id: string;
    name: string;
    notes: string | null;
    exoticWeapon?: { hash: number; name: string };
    attachments: ReturnType<typeof listAttachments>;
    diffSlots: EquipmentSlot[];
    diffNotes: boolean;
  }>;
};

async function resolveSlots(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
): Promise<Partial<Record<EquipmentSlot, unknown>>> {
  const build = getBuild(db, userId, buildId);
  const variant = getVariant(db, buildId, variantId);
  if (!build || !variant) return {};

  const attachments = listAttachments(db, variantId);
  const slots = await lookupExoticSlots(variant.exoticWeaponHash, build.exoticArmorHash);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: slots.weaponSlot,
    exoticArmorSlot: slots.armorSlot,
  });
  return resolved.equipment;
}

export async function compareBuildVariants(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantIds?: string[],
): Promise<VariantCompareResult | null> {
  const build = getBuild(db, userId, buildId);
  if (!build) return null;

  const allVariants = listVariants(db, buildId);
  const selected =
    variantIds?.length
      ? allVariants.filter((v) => variantIds.includes(v.id))
      : allVariants;
  if (selected.length === 0) return null;

  const defaultVariant = allVariants.find((v) => v.isDefault) ?? selected[0]!;
  const defaultEquipment = await resolveSlots(db, userId, buildId, defaultVariant.id);
  const defaultNotes = defaultVariant.notes;

  const synergies = getSynergiesByIds(db, userId, build.synergyIds);

  const variants = await Promise.all(
    selected.map(async (variant) => {
      const equipment = await resolveSlots(db, userId, buildId, variant.id);
      const diffSlots = Object.keys(equipment).filter((slot) => {
        const key = slot as EquipmentSlot;
        const a = equipment[key];
        const b = defaultEquipment[key];
        if (!a && !b) return false;
        if (!a || !b) return true;
        return JSON.stringify(a) !== JSON.stringify(b);
      }) as EquipmentSlot[];

      return {
        id: variant.id,
        name: variant.name,
        notes: variant.notes,
        exoticWeapon: variant.exoticWeaponHash
          ? { hash: variant.exoticWeaponHash, name: variant.exoticWeaponName ?? `Exotic (${variant.exoticWeaponHash})` }
          : undefined,
        attachments: listAttachments(db, variant.id),
        diffSlots,
        diffNotes: variant.notes !== defaultNotes,
      };
    }),
  );

  return {
    shared: {
      exoticArmor: { hash: build.exoticArmorHash, name: build.exoticArmorName },
      subclass: build.subclass,
      synergies: synergies.map((s) => ({ id: s.id, name: s.name, type: s.type })),
    },
    variants,
  };
}
