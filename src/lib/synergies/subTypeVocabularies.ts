import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { SYNERGY_VERBS } from "@/data/synergyVerbs";
import type { AbilityKind } from "@/lib/manifest/types/records";
import { getServices } from "@/lib/services";
import { sortByName } from "@/lib/sortByName";
import type { SubTypeRequiredType } from "@/lib/synergies/synergyTypeRules";
import { allowsBaseSubType } from "@/lib/synergies/synergyTypeRules";
import { collectLegendaryWeaponArchetypeSubTypeNames } from "@/lib/synergies/weaponArchetypeSubType";

export type SynergySubTypeOption = {
  id: string;
  name: string;
  description?: string;
};

const BASE_OPTION: SynergySubTypeOption = {
  id: "base",
  name: "Base",
  description: "Applies to all abilities of this category.",
};

function slugId(value: string): string {
  return value.toLowerCase().replace(/\s+/g, "-");
}

function listAllVerbs(): SynergySubTypeOption[] {
  return sortByName(
    SYNERGY_VERBS.map((verb) => ({
      id: slugId(verb.name),
      name: verb.name,
      description: verb.description,
    })),
  );
}

function listElementOptions(): SynergySubTypeOption[] {
  return SYNERGY_ELEMENTS.map((name) => ({ id: name.toLowerCase(), name }));
}

type AbilityOptionCandidate = SynergySubTypeOption & { hash: number };

function shouldPreferAbilityOption(
  current: AbilityOptionCandidate,
  next: AbilityOptionCandidate,
): boolean {
  const currentDesc = current.description?.trim() ?? "";
  const nextDesc = next.description?.trim() ?? "";
  if (nextDesc.length !== currentDesc.length) {
    return nextDesc.length > currentDesc.length;
  }
  return next.hash < current.hash;
}

function dedupeAbilityOptionsByName(candidates: AbilityOptionCandidate[]): SynergySubTypeOption[] {
  const seen = new Map<string, AbilityOptionCandidate>();
  for (const candidate of candidates) {
    const existing = seen.get(candidate.name);
    if (!existing || shouldPreferAbilityOption(existing, candidate)) {
      seen.set(candidate.name, candidate);
    }
  }
  return [...seen.values()]
    .map(({ hash: _hash, ...option }) => option)
    .sort((a, b) => a.name.localeCompare(b.name));
}

async function listAbilityOptions(kind: AbilityKind): Promise<SynergySubTypeOption[]> {
  const { entityCache } = await getServices();
  const abilities = await entityCache.getStore("abilities");
  const candidates = abilities
    .filter((a) => a.kind === kind)
    .map((a) => ({
      hash: a.hash,
      id: String(a.hash),
      name: a.name,
      description: a.description,
    }));

  return [BASE_OPTION, ...dedupeAbilityOptionsByName(candidates)];
}

async function listWeaponArchetypeOptions(): Promise<SynergySubTypeOption[]> {
  const { manifest } = await getServices();
  const status = await manifest.getStatus();
  if (!status.cachedVersion) return [];

  const itemTable = await manifest.loadRawTable(
    status.cachedVersion,
    "DestinyInventoryItemDefinition",
  );
  const names = collectLegendaryWeaponArchetypeSubTypeNames(itemTable);

  return sortByName(
    names.map((name) => ({
      id: slugId(name),
      name,
    })),
  );
}

export function filterSubTypeOptions(
  options: SynergySubTypeOption[],
  query: string,
  limit: number,
): SynergySubTypeOption[] {
  const q = query.trim().toLowerCase();
  const filtered = q
    ? options.filter((option) => option.name.toLowerCase().includes(q))
    : options;
  return filtered.slice(0, limit);
}

export async function listSubTypeOptions(
  category: SubTypeRequiredType,
): Promise<SynergySubTypeOption[]> {
  switch (category) {
    case "verb":
      return listAllVerbs();
    case "element":
      return listElementOptions();
    case "melee":
      return listAbilityOptions("melee");
    case "grenade":
      return listAbilityOptions("grenade");
    case "super":
      return listAbilityOptions("super");
    case "weapon_archetype":
      return listWeaponArchetypeOptions();
  }
}

export function isValidSubTypeForCategory(
  category: SubTypeRequiredType,
  subType: string,
  options: SynergySubTypeOption[],
): boolean {
  if (allowsBaseSubType(category) && subType === "Base") return true;
  return options.some((o) => o.name === subType);
}
