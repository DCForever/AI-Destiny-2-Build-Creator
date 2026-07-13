/**
 * Expand synergy type designations with element implications from verbs.
 * e.g. Verb: Ionic Trace → also Element: Arc (for matching / coverage).
 */

import { impliedElementForVerb } from "@/data/synergyVerbs";
import type { SynergyType } from "@/lib/synergies/schemas";
import { synergyTypeDesignationKey } from "@/lib/synergies/generateSynergyName";

export type DesignationLike = {
  type: SynergyType | string;
  subType: string | null;
};

function keyOf(d: DesignationLike): string {
  return synergyTypeDesignationKey({
    type: d.type as SynergyType,
    subType: d.subType,
  });
}

/**
 * Element designations implied by verb designations that are not already
 * explicitly present on the list.
 */
export function impliedElementDesignations(
  designations: readonly DesignationLike[],
): Array<{ type: "element"; subType: string }> {
  const existing = new Set(designations.map((d) => keyOf(d)));
  const out: Array<{ type: "element"; subType: string }> = [];
  const seenImplied = new Set<string>();

  for (const d of designations) {
    if (d.type !== "verb" || !d.subType?.trim()) continue;
    const element = impliedElementForVerb(d.subType);
    if (!element) continue;
    const implied = { type: "element" as const, subType: element };
    const key = keyOf(implied);
    if (existing.has(key) || seenImplied.has(key)) continue;
    seenImplied.add(key);
    out.push(implied);
  }

  return out;
}

/**
 * Explicit designations plus any implied element designations (deduped).
 * Use for library matching / coverage so Verb: Ionic Trace also hits Element: Arc.
 */
export function expandDesignationsWithImpliedElements<T extends DesignationLike>(
  designations: readonly T[],
): Array<T | { type: "element"; subType: string }> {
  const implied = impliedElementDesignations(designations);
  if (implied.length === 0) return [...designations];
  return [...designations, ...implied];
}
