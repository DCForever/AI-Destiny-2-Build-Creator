import { filterKnownWeaponTypes, type KnownWeaponType } from "@/data/weaponTypes";
import type { BuildRequest, WeaponTypePreferences } from "@/lib/llm/buildSchema";

export type BuildFormPreferenceState = {
  preferredExotic: string | null;
  preferredWeapon: string | null;
  weaponTypesInclude: readonly string[];
  weaponTypesExclude: readonly string[];
  prioritizeOwned: boolean;
  notes: string;
};

export function buildWeaponTypePreferences(input: {
  include: readonly string[];
  exclude: readonly string[];
  prioritizeOwned: boolean;
}): WeaponTypePreferences | undefined {
  const include = filterKnownWeaponTypes(input.include);
  const exclude = filterKnownWeaponTypes(input.exclude);
  if (include.length === 0 && exclude.length === 0 && !input.prioritizeOwned) {
    return undefined;
  }
  return {
    include: include.length > 0 ? include : undefined,
    exclude: exclude.length > 0 ? exclude : undefined,
    prioritizeOwned: input.prioritizeOwned || undefined,
  };
}

export function buildFormPreferenceFields(
  state: BuildFormPreferenceState,
): Pick<BuildRequest, "preferredExotic" | "preferredWeapon" | "notes" | "weaponTypePreferences"> {
  return {
    preferredExotic: state.preferredExotic?.trim() || undefined,
    preferredWeapon: state.preferredWeapon?.trim() || undefined,
    notes: state.notes.trim() || undefined,
    weaponTypePreferences: buildWeaponTypePreferences({
      include: state.weaponTypesInclude,
      exclude: state.weaponTypesExclude,
      prioritizeOwned: state.prioritizeOwned,
    }),
  };
}

export function selectedWeaponTypes(selected: readonly string[]): KnownWeaponType[] {
  return filterKnownWeaponTypes(selected);
}
