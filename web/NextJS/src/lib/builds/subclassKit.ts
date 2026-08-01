/**
 * Build tree vs variant kit split (DBR-SUB-001/003, DBR-BLD-008–009).
 *
 * - Build owns tree identity (`subclass.name` and related display).
 * - Variant owns kit picks (aspects, fragments, abilities) in `subclassKit`.
 * - Effective kit = variant kit if set, else kit fields from build.subclass (legacy).
 */

export type SubclassKitFields = {
  super: string;
  classAbility: string;
  movement: string;
  melee: string;
  grenade: string;
  aspects: string[];
  fragments: string[];
};

export type EffectiveSubclass = SubclassKitFields & {
  name: string;
  rationale: string;
};

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === "string");
}

export function emptySubclassKit(): SubclassKitFields {
  return {
    super: "",
    classAbility: "",
    movement: "",
    melee: "",
    grenade: "",
    aspects: [],
    fragments: [],
  };
}

/** Empty legal baseline after tree change (BR-BLD-040a). */
export function emptyLegalBaselineForTree(_treeName: string): SubclassKitFields {
  return emptySubclassKit();
}

export function treeNameFromSubclass(subclass: unknown): string {
  if (!subclass || typeof subclass !== "object") return "";
  return asString((subclass as { name?: unknown }).name).trim();
}

export function kitFromLegacySubclass(subclass: unknown): SubclassKitFields {
  if (!subclass || typeof subclass !== "object") return emptySubclassKit();
  const s = subclass as Record<string, unknown>;
  return {
    super: asString(s.super),
    classAbility: asString(s.classAbility),
    movement: asString(s.movement),
    melee: asString(s.melee),
    grenade: asString(s.grenade),
    aspects: asStringList(s.aspects),
    fragments: asStringList(s.fragments),
  };
}

export function parseSubclassKitJson(raw: string | null | undefined): SubclassKitFields | null {
  if (!raw?.trim()) return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object") return null;
    return kitFromLegacySubclass(parsed);
  } catch {
    return null;
  }
}

export function serializeSubclassKit(kit: SubclassKitFields): string {
  return JSON.stringify({
    super: kit.super,
    classAbility: kit.classAbility,
    movement: kit.movement,
    melee: kit.melee,
    grenade: kit.grenade,
    aspects: kit.aspects,
    fragments: kit.fragments,
  });
}

/**
 * Prefer explicit variant kit; fall back to kit fields stored on build.subclass (legacy).
 */
export function resolveVariantKit(
  buildSubclass: unknown,
  variantKit: SubclassKitFields | null | undefined,
): SubclassKitFields {
  if (variantKit) return { ...variantKit };
  return kitFromLegacySubclass(buildSubclass);
}

/**
 * Full subclass object for validation / UI: tree name from build + kit from variant.
 * Build-pinned Super overrides kit super when set.
 */
export function effectiveSubclass(
  buildSubclass: unknown,
  variantKit: SubclassKitFields | null | undefined,
  pinnedSuper?: string | null,
): EffectiveSubclass {
  const name = treeNameFromSubclass(buildSubclass) || "Unknown";
  const kit = resolveVariantKit(buildSubclass, variantKit);
  const rationale =
    buildSubclass && typeof buildSubclass === "object"
      ? asString((buildSubclass as { rationale?: unknown }).rationale)
      : "";
  const superName =
    pinnedSuper && pinnedSuper.trim() ? pinnedSuper.trim() : kit.super;
  return {
    name,
    rationale,
    ...kit,
    super: superName,
  };
}

/** True when tree identity (subclass name) differs. */
export function isSubclassTreeChange(
  existingSubclass: unknown,
  nextSubclass: unknown,
): boolean {
  const a = treeNameFromSubclass(existingSubclass);
  const b = treeNameFromSubclass(nextSubclass);
  if (!b) return false;
  return a !== b;
}

/**
 * Build-owned tree blob after a tree change: keep name/rationale, clear kit fields.
 */
export function buildSubclassAfterTreeChange(
  nextSubclass: unknown,
): Record<string, unknown> {
  const name = treeNameFromSubclass(nextSubclass) || "Unknown";
  const rationale =
    nextSubclass && typeof nextSubclass === "object"
      ? asString((nextSubclass as { rationale?: unknown }).rationale)
      : "";
  return {
    name,
    rationale,
    ...emptyLegalBaselineForTree(name),
  };
}

/**
 * When build PATCH sends full subclass with same tree, treat kit fields as kit update payload.
 */
export function kitPayloadFromSubclassInput(subclass: unknown): SubclassKitFields {
  return kitFromLegacySubclass(subclass);
}
