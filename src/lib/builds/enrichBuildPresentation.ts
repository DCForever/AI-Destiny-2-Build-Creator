/**
 * Attach icon/description/element presentation to build detail for UI hotspots.
 * Server-side only (entity cache).
 */

import {
  presentByHashes,
  presentByNames,
  type EntityPresentation,
  SUBCLASS_STORES,
} from "@/lib/catalog/entityPresentation";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import type { ResolvedVariantEquipment, SlotClaim } from "@/lib/builds/resolveVariant";

export type PresentedEntity = {
  hash: number | null;
  name: string;
  icon: string | null;
  description: string;
  element: string | null;
  kindLabel: string | null;
};

export type SlotClaimPresentation = SlotClaim & {
  icon: string | null;
  description: string;
  element: string | null;
  perks?: PresentedEntity[];
};

export type ResolvedVariantPresentation = {
  equipment: Partial<Record<EquipmentSlot, SlotClaimPresentation>>;
  conflicts: ResolvedVariantEquipment["conflicts"];
};

function toPresented(
  p: Pick<
    EntityPresentation,
    "hash" | "name" | "icon" | "description" | "element" | "kindLabel"
  >,
): PresentedEntity {
  return {
    hash: p.hash,
    name: p.name,
    icon: p.icon,
    description: p.description,
    element: p.element,
    kindLabel: p.kindLabel,
  };
}

function emptyPresented(name: string): PresentedEntity {
  return {
    hash: null,
    name,
    icon: null,
    description: "",
    element: null,
    kindLabel: null,
  };
}

type SubclassShape = {
  name?: string;
  super?: string;
  classAbility?: string;
  movement?: string;
  melee?: string;
  grenade?: string;
  aspects?: string[];
  fragments?: string[];
  rationale?: string;
};

export type SubclassPresentation = {
  name: string;
  super: PresentedEntity | null;
  classAbility: PresentedEntity | null;
  movement: PresentedEntity | null;
  melee: PresentedEntity | null;
  grenade: PresentedEntity | null;
  aspects: PresentedEntity[];
  fragments: PresentedEntity[];
};

async function presentSubclass(
  subclass: unknown,
  pinnedSuper: string | null | undefined,
): Promise<SubclassPresentation> {
  const sc = (subclass && typeof subclass === "object" ? subclass : {}) as SubclassShape;
  const names: string[] = [];
  const push = (n?: string | null) => {
    if (n?.trim()) names.push(n.trim());
  };
  push(sc.super);
  push(pinnedSuper);
  push(sc.classAbility);
  push(sc.movement);
  push(sc.melee);
  push(sc.grenade);
  for (const a of sc.aspects ?? []) push(a);
  for (const f of sc.fragments ?? []) push(f);

  const byName = await presentByNames(names, [...SUBCLASS_STORES]);

  const one = (n?: string | null): PresentedEntity | null => {
    if (!n?.trim()) return null;
    const key = n.trim();
    return toPresented(byName.get(key) ?? emptyPresented(key));
  };

  return {
    name: typeof sc.name === "string" ? sc.name : "",
    super: one(pinnedSuper) ?? one(sc.super),
    classAbility: one(sc.classAbility),
    movement: one(sc.movement),
    melee: one(sc.melee),
    grenade: one(sc.grenade),
    aspects: (sc.aspects ?? []).map((a) => one(a) ?? emptyPresented(a)),
    fragments: (sc.fragments ?? []).map((f) => one(f) ?? emptyPresented(f)),
  };
}

export type VariantPresentationFields = {
  resolved?: ResolvedVariantPresentation;
  artifact?: PresentedEntity | null;
  artifactPerks?: PresentedEntity[];
  exoticWeapon?: PresentedEntity | null;
};

export async function enrichVariantPresentation(input: {
  resolved?: ResolvedVariantEquipment;
  exoticWeaponHash?: number | null;
  exoticWeaponName?: string | null;
  artifactHash?: number | null;
  artifactName?: string | null;
  artifactConfig?: number[] | null;
}): Promise<VariantPresentationFields> {
  // Single-variant path still used by tests/callers; batch path is enrichBuildPresentation.
  const hashes: number[] = [];
  if (input.exoticWeaponHash != null) hashes.push(input.exoticWeaponHash);
  if (input.artifactHash != null) hashes.push(input.artifactHash);
  for (const h of input.artifactConfig ?? []) hashes.push(h);
  for (const claim of Object.values(input.resolved?.equipment ?? {})) {
    if (!claim) continue;
    hashes.push(claim.itemHash);
    for (const p of claim.selectedPerks ?? []) hashes.push(p);
  }

  const byHash = await presentByHashes(hashes, [
    "weapons",
    "exotic-weapons",
    "exotic-armor",
    "artifacts",
    "weapon-perks",
    "origin-traits",
    "mods",
  ]);

  return assembleVariantPresentation(input, byHash);
}

function assembleVariantPresentation(
  input: {
    resolved?: ResolvedVariantEquipment;
    exoticWeaponHash?: number | null;
    exoticWeaponName?: string | null;
    artifactHash?: number | null;
    artifactName?: string | null;
    artifactConfig?: number[] | null;
  },
  byHash: Map<number, EntityPresentation>,
): VariantPresentationFields {
  const equipment = input.resolved
    ? presentClaimsFromMap(input.resolved.equipment, byHash)
    : undefined;

  return {
    resolved: input.resolved
      ? {
          equipment: equipment ?? {},
          conflicts: input.resolved.conflicts,
        }
      : undefined,
    exoticWeapon:
      input.exoticWeaponHash != null
        ? toPresented(
            byHash.get(input.exoticWeaponHash) ??
              emptyPresented(
                input.exoticWeaponName ?? `Unknown (${input.exoticWeaponHash})`,
              ),
          )
        : input.exoticWeaponName
          ? emptyPresented(input.exoticWeaponName)
          : null,
    artifact:
      input.artifactHash != null
        ? toPresented(
            byHash.get(input.artifactHash) ??
              emptyPresented(
                input.artifactName ?? `Unknown (${input.artifactHash})`,
              ),
          )
        : input.artifactName
          ? emptyPresented(input.artifactName)
          : null,
    artifactPerks: (input.artifactConfig ?? []).map((h) =>
      toPresented(byHash.get(h) ?? emptyPresented(`Perk ${h}`)),
    ),
  };
}

function presentClaimsFromMap(
  equipment: Partial<Record<EquipmentSlot, SlotClaim>>,
  byHash: Map<number, EntityPresentation>,
): Partial<Record<EquipmentSlot, SlotClaimPresentation>> {
  const out: Partial<Record<EquipmentSlot, SlotClaimPresentation>> = {};
  for (const [slot, claim] of Object.entries(equipment) as [
    EquipmentSlot,
    SlotClaim | undefined,
  ][]) {
    if (!claim) continue;
    const item = byHash.get(claim.itemHash);
    const perkList = (claim.selectedPerks ?? []).map((h) => {
      const p = byHash.get(h);
      return p ? toPresented(p) : emptyPresented(`Perk ${h}`);
    });
    out[slot] = {
      ...claim,
      itemName: item?.name && item.hash != null ? item.name : claim.itemName,
      icon: item?.icon ?? null,
      description: item?.description ?? "",
      element: item?.element ?? null,
      perks: perkList.length > 0 ? perkList : undefined,
    };
  }
  return out;
}

export type BuildPresentationExtras = {
  subclassPresentation: SubclassPresentation;
  exoticArmor: PresentedEntity | null;
};

/**
 * Enrich a raw getBuildDetail payload with presentation fields used by
 * EntityHotspot on the client.
 *
 * Batches all entity lookups across variants into two store loads (subclass
 * names + gear hashes) instead of N per-variant presentByHashes calls.
 */
export async function enrichBuildPresentation<T extends {
  subclass: unknown;
  pinnedSuper?: string | null;
  exoticArmorHash?: number | null;
  exoticArmorName?: string | null;
  variants: Array<{
    exoticWeaponHash?: number | null;
    exoticWeaponName?: string | null;
    artifactHash?: number | null;
    artifactName?: string | null;
    artifactConfig?: number[] | null;
    resolved?: ResolvedVariantEquipment;
  }>;
}>(
  detail: T,
): Promise<T & BuildPresentationExtras & { variants: Array<T["variants"][number] & VariantPresentationFields> }> {
  const gearHashes: number[] = [];
  if (detail.exoticArmorHash != null) gearHashes.push(detail.exoticArmorHash);

  for (const v of detail.variants) {
    if (v.exoticWeaponHash != null) gearHashes.push(v.exoticWeaponHash);
    if (v.artifactHash != null) gearHashes.push(v.artifactHash);
    for (const h of v.artifactConfig ?? []) gearHashes.push(h);
    for (const claim of Object.values(v.resolved?.equipment ?? {})) {
      if (!claim) continue;
      gearHashes.push(claim.itemHash);
      for (const p of claim.selectedPerks ?? []) gearHashes.push(p);
    }
  }

  const [subclassPresentation, byHash] = await Promise.all([
    presentSubclass(detail.subclass, detail.pinnedSuper),
    presentByHashes(gearHashes, [
      "weapons",
      "exotic-weapons",
      "exotic-armor",
      "artifacts",
      "weapon-perks",
      "origin-traits",
      "mods",
    ]),
  ]);

  const exoticArmor =
    detail.exoticArmorHash != null
      ? toPresented(
          byHash.get(detail.exoticArmorHash) ??
            emptyPresented(
              detail.exoticArmorName ??
                `Unknown (${detail.exoticArmorHash})`,
            ),
        )
      : detail.exoticArmorName
        ? emptyPresented(detail.exoticArmorName)
        : null;

  const variants = detail.variants.map((v) => ({
    ...v,
    ...assembleVariantPresentation(
      {
        resolved: v.resolved,
        exoticWeaponHash: v.exoticWeaponHash,
        exoticWeaponName: v.exoticWeaponName,
        artifactHash: v.artifactHash,
        artifactName: v.artifactName,
        artifactConfig: v.artifactConfig,
      },
      byHash,
    ),
  })) as Array<T["variants"][number] & VariantPresentationFields>;

  return {
    ...detail,
    subclassPresentation,
    exoticArmor,
    variants,
  };
}
