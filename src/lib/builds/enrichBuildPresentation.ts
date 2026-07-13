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

async function presentClaims(
  equipment: Partial<Record<EquipmentSlot, SlotClaim>>,
): Promise<Partial<Record<EquipmentSlot, SlotClaimPresentation>>> {
  const claims = Object.values(equipment).filter(Boolean) as SlotClaim[];
  const itemHashes = claims.map((c) => c.itemHash);
  const perkHashes = claims.flatMap((c) => c.selectedPerks ?? []);

  const [items, perks] = await Promise.all([
    presentByHashes(itemHashes, [
      "weapons",
      "exotic-weapons",
      "exotic-armor",
      "mods",
    ]),
    presentByHashes(perkHashes, ["weapon-perks", "origin-traits", "mods"]),
  ]);

  const out: Partial<Record<EquipmentSlot, SlotClaimPresentation>> = {};
  for (const [slot, claim] of Object.entries(equipment) as [
    EquipmentSlot,
    SlotClaim | undefined,
  ][]) {
    if (!claim) continue;
    const item = items.get(claim.itemHash);
    const perkList = (claim.selectedPerks ?? []).map((h) => {
      const p = perks.get(h);
      return p
        ? toPresented(p)
        : emptyPresented(`Perk ${h}`);
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
  const hashes: number[] = [];
  if (input.exoticWeaponHash != null) hashes.push(input.exoticWeaponHash);
  if (input.artifactHash != null) hashes.push(input.artifactHash);
  for (const h of input.artifactConfig ?? []) hashes.push(h);

  const byHash = await presentByHashes(hashes, [
    "weapons",
    "exotic-weapons",
    "artifacts",
    "weapon-perks",
    "mods",
  ]);

  const equipment = input.resolved
    ? await presentClaims(input.resolved.equipment)
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

export type BuildPresentationExtras = {
  subclassPresentation: SubclassPresentation;
  exoticArmor: PresentedEntity | null;
};

/**
 * Enrich a raw getBuildDetail payload with presentation fields used by
 * EntityHotspot on the client.
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
  const [subclassPresentation, exoticMap, ...variantExtras] = await Promise.all([
    presentSubclass(detail.subclass, detail.pinnedSuper),
    detail.exoticArmorHash != null
      ? presentByHashes([detail.exoticArmorHash], ["exotic-armor"])
      : Promise.resolve(new Map<number, EntityPresentation>()),
    ...detail.variants.map((v) =>
      enrichVariantPresentation({
        resolved: v.resolved,
        exoticWeaponHash: v.exoticWeaponHash,
        exoticWeaponName: v.exoticWeaponName,
        artifactHash: v.artifactHash,
        artifactName: v.artifactName,
        artifactConfig: v.artifactConfig,
      }),
    ),
  ]);

  const exoticArmor =
    detail.exoticArmorHash != null
      ? toPresented(
          exoticMap.get(detail.exoticArmorHash) ??
            emptyPresented(
              detail.exoticArmorName ??
                `Unknown (${detail.exoticArmorHash})`,
            ),
        )
      : detail.exoticArmorName
        ? emptyPresented(detail.exoticArmorName)
        : null;

  const variants = detail.variants.map((v, i) => ({
    ...v,
    ...variantExtras[i]!,
  })) as Array<T["variants"][number] & VariantPresentationFields>;

  return {
    ...detail,
    subclassPresentation,
    exoticArmor,
    variants,
  };
}
