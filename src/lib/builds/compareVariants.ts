import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import {
  designationKey,
  designationLabel,
  resolveDesignatedSynergies,
} from "@/lib/builds/resolveDesignatedSynergies";
import {
  getVariant,
  listAttachments,
  listVariants,
} from "@/lib/db/repositories/variantRepository";
import { lookupExoticSlots } from "@/lib/builds/exoticArmorIntent";
import { resolveVariantEquipment } from "@/lib/builds/resolveVariant";
import type { EquipmentSlot } from "@/lib/sets/schemas";

export type VariantCompareResult = {
  shared: {
    exoticArmor: { hash: number | null; name: string | null };
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
  const weaponHash = build.exoticWeaponHash ?? variant.exoticWeaponHash;
  const slots = await lookupExoticSlots(weaponHash, build.exoticArmorHash);
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

  const bridge = resolveDesignatedSynergies(db, userId, build.synergyTypes);
  const synergies = bridge.designations.map((d) => ({
    id: designationKey(d),
    name: designationLabel(d),
    type: d.type,
  }));

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
