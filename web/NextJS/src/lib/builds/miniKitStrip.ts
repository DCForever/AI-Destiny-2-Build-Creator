/**
 * Mini kit strip model (DBR-BLD-010).
 *
 * Full strip: element + aspects + fragments + all five ability icons
 * (Super, Melee, Grenade, Class ability, Movement) — empty slots still occupy
 * the strip so chrome is stable.
 */

export const MINI_KIT_ABILITY_SLOTS = [
  { key: "super", label: "Super" },
  { key: "melee", label: "Melee" },
  { key: "grenade", label: "Grenade" },
  { key: "classAbility", label: "Class ability" },
  { key: "movement", label: "Movement" },
] as const;

export type MiniKitAbilityKey = (typeof MINI_KIT_ABILITY_SLOTS)[number]["key"];

export type MiniKitEntity = {
  name: string;
  icon?: string | null;
  description?: string | null;
  element?: string | null;
};

export type MiniKitAbilitySlot = {
  key: MiniKitAbilityKey;
  label: string;
  /** Null when empty — still rendered as a placeholder. */
  entity: MiniKitEntity | null;
};

export type MiniKitStripModel = {
  treeName: string;
  abilities: MiniKitAbilitySlot[];
  aspects: MiniKitEntity[];
  fragments: MiniKitEntity[];
};

type SubclassLike = {
  name?: string;
  super?: string | null;
  classAbility?: string | null;
  movement?: string | null;
  melee?: string | null;
  grenade?: string | null;
  aspects?: string[] | null;
  fragments?: string[] | null;
};

type PresentationLike = {
  name?: string;
  super?: MiniKitEntity | null;
  classAbility?: MiniKitEntity | null;
  movement?: MiniKitEntity | null;
  melee?: MiniKitEntity | null;
  grenade?: MiniKitEntity | null;
  aspects?: MiniKitEntity[] | null;
  fragments?: MiniKitEntity[] | null;
};

function entityFromName(name: string | null | undefined): MiniKitEntity | null {
  const t = name?.trim();
  if (!t) return null;
  return { name: t, icon: null, description: null, element: null };
}

function coalesceEntity(
  presented: MiniKitEntity | null | undefined,
  fallbackName: string | null | undefined,
): MiniKitEntity | null {
  if (presented?.name?.trim()) {
    return {
      name: presented.name.trim(),
      icon: presented.icon ?? null,
      description: presented.description ?? null,
      element: presented.element ?? null,
    };
  }
  return entityFromName(fallbackName);
}

/**
 * Build the stable mini-kit strip model from presentation + raw subclass kit.
 * Always returns five ability slots (some may be empty).
 */
export function buildMiniKitStripModel(input: {
  subclass?: SubclassLike | null;
  presentation?: PresentationLike | null;
  pinnedSuper?: string | null;
}): MiniKitStripModel {
  const sc = input.subclass ?? {};
  const sp = input.presentation ?? {};
  const treeName =
    (typeof sp.name === "string" && sp.name.trim()) ||
    (typeof sc.name === "string" && sc.name.trim()) ||
    "";

  const abilities: MiniKitAbilitySlot[] = MINI_KIT_ABILITY_SLOTS.map((slot) => {
    const presented = sp[slot.key] as MiniKitEntity | null | undefined;
    let fallback: string | null | undefined;
    if (slot.key === "super") {
      fallback = input.pinnedSuper ?? sc.super;
    } else {
      fallback = sc[slot.key] as string | null | undefined;
    }
    return {
      key: slot.key,
      label: slot.label,
      entity: coalesceEntity(presented, fallback),
    };
  });

  const aspects =
    sp.aspects && sp.aspects.length > 0
      ? sp.aspects.filter((a) => a.name?.trim())
      : (sc.aspects ?? [])
          .map((n) => entityFromName(n))
          .filter((e): e is MiniKitEntity => e != null);

  const fragments =
    sp.fragments && sp.fragments.length > 0
      ? sp.fragments.filter((f) => f.name?.trim())
      : (sc.fragments ?? [])
          .map((n) => entityFromName(n))
          .filter((e): e is MiniKitEntity => e != null);

  return { treeName, abilities, aspects, fragments };
}

/** True when at least one ability/aspect/fragment is filled. */
export function miniKitStripHasAnyFill(model: MiniKitStripModel): boolean {
  if (model.abilities.some((a) => a.entity != null)) return true;
  if (model.aspects.length > 0) return true;
  if (model.fragments.length > 0) return true;
  return false;
}
