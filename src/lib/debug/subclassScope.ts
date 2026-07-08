import { getSubclassMeta } from "@/data/subclasses";

export type SubclassScope = {
  classType: "Titan" | "Hunter" | "Warlock";
  element: string;
};

export type SubclassFormValue = {
  name: string;
  super: string;
  classAbility: string;
  movement: string;
  melee: string;
  grenade: string;
  aspects: string[];
  fragments: string[];
  rationale: string;
};

export type SubclassValidNames = {
  abilities: Set<string>;
  aspects: Set<string>;
  fragments: Set<string>;
};

export function resolveSubclassScope(subclassName: string): SubclassScope | null {
  const meta = getSubclassMeta(subclassName);
  if (!meta) return null;
  return { classType: meta.classType, element: meta.element };
}

function keepValidName(name: string, validNames: Set<string>): string {
  return validNames.has(name) ? name : "";
}

export function clearIncompatibleSubclassSelections(
  value: SubclassFormValue,
  validNames: SubclassValidNames,
): SubclassFormValue {
  return {
    ...value,
    super: keepValidName(value.super, validNames.abilities),
    classAbility: keepValidName(value.classAbility, validNames.abilities),
    movement: keepValidName(value.movement, validNames.abilities),
    melee: keepValidName(value.melee, validNames.abilities),
    grenade: keepValidName(value.grenade, validNames.abilities),
    aspects: value.aspects.filter((name) => validNames.aspects.has(name)),
    fragments: value.fragments.filter((name) => validNames.fragments.has(name)),
  };
}
