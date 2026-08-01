import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { resolveVerbSubType, SYNERGY_VERB_NAMES } from "@/data/synergyVerbs";
import type { CreatableSynergyType } from "@/lib/synergies/schemas";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";
import { normalizeDesignationKey } from "@/lib/synergies/existingDesignations";
import {
  requiresSubType,
  type SubTypeRequiredType,
} from "@/lib/synergies/synergyTypeRules";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

/** type::subType or type:: for types without subtype. */
export function typeCoverageKey(
  type: string,
  subType: string | null | undefined,
): string {
  const sub = subType?.trim() || "";
  return `${type}::${sub}`;
}

/** Canonical coverage key with normalized subtype (aliases/plurals). */
export function normalizedTypeCoverageKey(
  type: string,
  subType: string | null | undefined,
): string {
  let sub = subType?.trim() || "";
  if (type === "verb" && sub) {
    sub = resolveVerbSubType(sub) ?? sub;
  }
  return `${type}::${normalizeDesignationKey(sub)}`;
}

export type TypeObjectReference = {
  store: string;
  hash?: number;
  name: string;
  snippet: string;
};

export type TypeDesignationCandidate = {
  coverageKey: string;
  type: CreatableSynergyType;
  subType: string | null;
  displayName: string;
  description?: string;
  /** object_text = discovered by scanning item/perk descriptions. */
  origin?: "vocab" | "manifest" | "object_text";
  mentionCount?: number;
  sampleObjectNames?: string[];
  /** First references (name + snippet) from object scan. */
  references?: TypeObjectReference[];
};

export type MissingTypeGap = {
  gapKind: "type";
  coverageKey: string;
  displayName: string;
  suggestedType: CreatableSynergyType;
  suggestedSubType: string | null;
  rationale: string;
  sources: Array<"vocab" | "manifest" | "object_text">;
  mentionCount?: number;
  sampleObjectNames?: string[];
  references?: TypeObjectReference[];
};

/** Types that never take a subType — one library row of that type covers the designation. */
const TYPE_ONLY: CreatableSynergyType[] = CREATABLE_SYNERGY_TYPES.filter(
  (t) => !requiresSubType(t),
) as CreatableSynergyType[];

/**
 * Build designation candidates from curated vocabularies (no I/O).
 * Ability/archetype names are passed in from manifest loaders.
 */
export function buildTypeDesignationCandidates(input?: {
  meleeNames?: string[];
  grenadeNames?: string[];
  superNames?: string[];
  weaponArchetypeNames?: string[];
  /** Keywords found by scanning object descriptions across stores (not names). */
  objectKeywords?: Array<{
    keyword: string;
    kind: "verb" | "element";
    origin: "curated" | "object_text";
    mentionCount: number;
    sampleObjectNames?: string[];
    references?: TypeObjectReference[];
  }>;
  /**
   * When true (default for object-driven scans), only emit candidates from
   * objectKeywords / ability lists that were passed in — not the full curated
   * verb dump or empty type-only categories.
   */
  objectDrivenOnly?: boolean;
}): TypeDesignationCandidate[] {
  const out: TypeDesignationCandidate[] = [];
  const seen = new Set<string>();
  const objectDrivenOnly = input?.objectDrivenOnly === true;

  function push(c: TypeDesignationCandidate) {
    if (seen.has(c.coverageKey)) {
      // Prefer object_text enrichment on existing curated row
      const idx = out.findIndex((x) => x.coverageKey === c.coverageKey);
      if (idx >= 0 && c.mentionCount) {
        out[idx] = {
          ...out[idx]!,
          mentionCount: c.mentionCount,
          sampleObjectNames: c.sampleObjectNames,
          references: c.references ?? out[idx]!.references,
          origin: c.origin ?? out[idx]!.origin,
          description: c.description ?? out[idx]!.description,
        };
      }
      return;
    }
    seen.add(c.coverageKey);
    out.push(c);
  }

  if (!objectDrivenOnly) {
    for (const type of TYPE_ONLY) {
      push({
        coverageKey: typeCoverageKey(type, null),
        type,
        subType: null,
        displayName: typeLabel(type),
        origin: "vocab",
      });
    }

    for (const name of SYNERGY_VERB_NAMES) {
      push({
        coverageKey: typeCoverageKey("verb", name),
        type: "verb",
        subType: name,
        displayName: `Verb: ${name}`,
        origin: "vocab",
      });
    }

    for (const name of SYNERGY_ELEMENTS) {
      push({
        coverageKey: typeCoverageKey("element", name),
        type: "element",
        subType: name,
        displayName: `Element: ${name}`,
        origin: "vocab",
      });
    }

    pushAbilityCategory(out, seen, "melee", input?.meleeNames);
    pushAbilityCategory(out, seen, "grenade", input?.grenadeNames);
    pushAbilityCategory(out, seen, "super", input?.superNames);

    for (const name of input?.weaponArchetypeNames ?? []) {
      push({
        coverageKey: typeCoverageKey("weapon_archetype", name),
        type: "weapon_archetype",
        subType: name,
        displayName: `Weapon Archetype: ${name}`,
        origin: "manifest",
      });
    }
  }

  for (const kw of input?.objectKeywords ?? []) {
    const type: CreatableSynergyType =
      kw.kind === "element" ? "element" : "verb";
    push({
      coverageKey: typeCoverageKey(type, kw.keyword),
      type,
      subType: kw.keyword,
      displayName:
        type === "element" ? `Element: ${kw.keyword}` : `Verb: ${kw.keyword}`,
      origin: kw.origin === "object_text" ? "object_text" : "vocab",
      mentionCount: kw.mentionCount,
      sampleObjectNames: kw.sampleObjectNames,
      references: kw.references,
      description:
        kw.origin === "object_text"
          ? `Discovered in ${kw.mentionCount} object description(s).`
          : `Mentioned in ${kw.mentionCount} object(s).`,
    });
  }

  return out;
}

function pushAbilityCategory(
  out: TypeDesignationCandidate[],
  seen: Set<string>,
  type: SubTypeRequiredType & ("melee" | "grenade" | "super"),
  names: string[] | undefined,
): void {
  const base: TypeDesignationCandidate = {
    coverageKey: typeCoverageKey(type, "Base"),
    type,
    subType: "Base",
    displayName: `${typeLabel(type)}: Base`,
    origin: "manifest",
  };
  if (!seen.has(base.coverageKey)) {
    seen.add(base.coverageKey);
    out.push(base);
  }
  for (const name of names ?? []) {
    if (!name.trim() || name === "Base") continue;
    const c: TypeDesignationCandidate = {
      coverageKey: typeCoverageKey(type, name),
      type,
      subType: name,
      displayName: `${typeLabel(type)}: ${name}`,
      origin: "manifest",
    };
    if (seen.has(c.coverageKey)) continue;
    seen.add(c.coverageKey);
    out.push(c);
  }
}

function typeLabel(type: string): string {
  return type
    .split("_")
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
    .join(" ");
}

/** True when type+subType is already part of curated vocabulary. */
export function isKnownVocabularyDesignation(
  type: string,
  subType: string | null | undefined,
): boolean {
  const sub = subType?.trim() ?? "";
  if (type === "verb") {
    return sub.length > 0 && resolveVerbSubType(sub) != null;
  }
  if (type === "element") {
    return (SYNERGY_ELEMENTS as readonly string[]).some(
      (e) => e.toLowerCase() === sub.toLowerCase(),
    );
  }
  return false;
}

/**
 * Library designations already present (including Unlinked rows with zero links).
 * Keys are stored both raw and normalized so "Ionic Trace" matches aliases.
 */
export function collectCoveredTypeKeys(
  synergies: Array<{
    type: string;
    subType?: string | null;
    name?: string | null;
  }>,
): Set<string> {
  const keys = new Set<string>();
  for (const s of synergies) {
    keys.add(typeCoverageKey(s.type, s.subType));
    keys.add(normalizedTypeCoverageKey(s.type, s.subType));

    // Parse "Verb: Ionic Trace — Unlinked" / "Verb: Ionic Trace — Some Object"
    const parsed = parseDesignationFromSynergyName(s.name ?? "");
    if (parsed) {
      keys.add(typeCoverageKey(parsed.type, parsed.subType));
      keys.add(normalizedTypeCoverageKey(parsed.type, parsed.subType));
    }
  }
  return keys;
}

/** Parse "Melee: Base — …" / "Verb: Ionic Trace — Unlinked" style library names. */
export function parseDesignationFromSynergyName(
  name: string,
): { type: string; subType: string | null } | null {
  const trimmed = name.trim();
  if (!trimmed) return null;

  // "Verb: Ionic Trace — Unlinked" or "Verb: Ionic Trace"
  const withSub = trimmed.match(
    /^([A-Za-z][A-Za-z /]+?):\s*(.+?)(?:\s*[—–-]\s*.*)?$/,
  );
  if (withSub) {
    const label = withSub[1]!.trim();
    const sub = withSub[2]!.trim();
    const type = typeFromCategoryLabel(label);
    if (type && sub) {
      const canonicalSub =
        type === "verb" ? resolveVerbSubType(sub) ?? sub : sub;
      return { type, subType: canonicalSub };
    }
  }

  // "DPS — Unlinked" / "Solo — Alacrity"
  const typeOnly = trimmed.match(
    /^([A-Za-z][A-Za-z /]+?)\s*[—–-]\s*.+$/,
  );
  if (typeOnly) {
    const type = typeFromCategoryLabel(typeOnly[1]!.trim());
    if (type) return { type, subType: null };
  }
  return null;
}

function typeFromCategoryLabel(label: string): string | null {
  const lower = label.toLowerCase();
  for (const type of CREATABLE_SYNERGY_TYPES) {
    if (getSynergyTypeLabel(type).toLowerCase() === lower) return type;
    if (type.replace(/_/g, " ") === lower) return type;
  }
  return null;
}

export function isCoveredTypeKey(
  coverageKey: string,
  covered: ReadonlySet<string>,
): boolean {
  if (covered.has(coverageKey)) return true;
  const [type, ...rest] = coverageKey.split("::");
  const sub = rest.join("::");
  if (!type) return false;
  return covered.has(normalizedTypeCoverageKey(type, sub || null));
}

/** Client/server filter for type-gap search (name, type, subtype). */
export function matchesTypeGapQuery(
  row: {
    displayName: string;
    type?: string;
    subType?: string | null;
    suggestedType?: string;
    suggestedSubType?: string | null;
    coverageKey?: string;
  },
  query: string,
): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const hay = [
    row.displayName,
    row.type,
    row.subType,
    row.suggestedType,
    row.suggestedSubType,
    row.coverageKey,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  return hay.includes(q);
}

export function findMissingTypeGaps(
  candidates: TypeDesignationCandidate[],
  coveredTypeKeys: Set<string>,
  opts?: {
    limit?: number;
    query?: string;
    /**
     * When true (default for object-driven scans), only report **novel**
     * keywords discovered from object text. Known vocabulary types (e.g.
     * curated Verb: Ionic Trace) that simply have no library row yet are
     * "unlinked designations", not missing types.
     */
    onlyNovel?: boolean;
  },
): MissingTypeGap[] {
  const limit = opts?.limit ?? 200;
  const query = opts?.query?.trim() ?? "";
  const onlyNovel = opts?.onlyNovel !== false;
  const missing: MissingTypeGap[] = [];

  for (const c of candidates) {
    if (isCoveredTypeKey(c.coverageKey, coveredTypeKeys)) continue;
    if (
      onlyNovel &&
      c.origin !== "object_text" &&
      isKnownVocabularyDesignation(c.type, c.subType)
    ) {
      // Known type/subtype already in the system — library may still lack an
      // (unlinked) row, but that is not a "missing type".
      continue;
    }
    if (
      query &&
      !matchesTypeGapQuery(
        {
          displayName: c.displayName,
          type: c.type,
          subType: c.subType,
          coverageKey: c.coverageKey,
        },
        query,
      )
    ) {
      continue;
    }
    const sources: MissingTypeGap["sources"] = [];
    if (c.origin === "object_text") sources.push("object_text");
    else if (c.origin === "manifest") sources.push("manifest");
    else sources.push("vocab");
    if (c.mentionCount && c.origin !== "object_text") sources.push("object_text");

    const sample =
      c.sampleObjectNames && c.sampleObjectNames.length > 0
        ? ` Seen on: ${c.sampleObjectNames.slice(0, 3).join(", ")}.`
        : "";
    const mentions =
      c.mentionCount != null ? ` (${c.mentionCount} object mention(s))` : "";

    missing.push({
      gapKind: "type",
      coverageKey: c.coverageKey,
      displayName: c.displayName,
      suggestedType: c.type,
      suggestedSubType: c.subType,
      rationale: `No library synergy uses designation ${c.displayName} yet.${mentions}${sample}`,
      sources: [...new Set(sources)],
      mentionCount: c.mentionCount,
      sampleObjectNames: c.sampleObjectNames,
      references: c.references,
    });
  }

  // Prefer object-backed / high mention counts, then slice to limit
  return missing
    .sort(
      (a, b) =>
        (b.mentionCount ?? 0) - (a.mentionCount ?? 0) ||
        Number(b.sources.includes("object_text")) -
          Number(a.sources.includes("object_text")) ||
        a.displayName.localeCompare(b.displayName, undefined, {
          sensitivity: "base",
        }),
    )
    .slice(0, limit);
}

export function proposalsFromTypeGaps(gaps: MissingTypeGap[]): Proposal[] {
  return gaps.map((gap, index) => ({
    id: `type-gap-${index + 1}`,
    kind: "synergy" as const,
    rationale: gap.rationale,
    synergy: {
      type: gap.suggestedType,
      subType: gap.suggestedSubType,
      description: `Auto-proposed type designation gap: ${gap.displayName}.`,
      links: [],
    },
  }));
}
