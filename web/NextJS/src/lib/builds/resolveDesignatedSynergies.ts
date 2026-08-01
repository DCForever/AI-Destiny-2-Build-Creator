import type { AppDatabase } from "@/lib/db/client";
import {
  getSynergiesByTypeSubType,
  type SynergyWithLinks,
} from "@/lib/db/repositories/synergyRepository";
import type { SynergyType } from "@/lib/synergies/schemas";
import {
  formatSynergyTypeDesignation,
  synergyTypeDesignationKey,
} from "@/lib/synergies/generateSynergyName";
import {
  expandDesignationsWithImpliedElements,
  impliedElementDesignations,
} from "@/lib/synergies/impliedElements";

export type SynergyTypeDesignation = {
  type: SynergyType;
  subType: string | null;
};

export type DesignationBridgeResult = {
  /** Explicit build designations as stored (no implied rows). */
  designations: SynergyTypeDesignation[];
  /**
   * Element designations inferred from verbs (e.g. Ionic Trace → Arc)
   * that were not already explicit on the build.
   */
  impliedDesignations: SynergyTypeDesignation[];
  /**
   * Explicit + implied — used for library matching and coverage.
   */
  effectiveDesignations: SynergyTypeDesignation[];
  matchedSynergies: SynergyWithLinks[];
  byDesignation: Map<string, SynergyWithLinks[]>;
};

export function designationKey(d: SynergyTypeDesignation): string {
  return synergyTypeDesignationKey(d);
}

export function designationLabel(d: SynergyTypeDesignation): string {
  return formatSynergyTypeDesignation(d);
}

export function resolveDesignatedSynergies(
  db: AppDatabase,
  userId: number,
  designations: SynergyTypeDesignation[],
): DesignationBridgeResult {
  const implied = impliedElementDesignations(designations);
  const effective = expandDesignationsWithImpliedElements(designations);
  const byDesignation = new Map<string, SynergyWithLinks[]>();
  const matchedById = new Map<string, SynergyWithLinks>();

  for (const designation of effective) {
    const key = designationKey(designation);
    const matches = getSynergiesByTypeSubType(
      db,
      userId,
      designation.type,
      designation.subType,
    );
    byDesignation.set(key, matches);
    for (const synergy of matches) {
      matchedById.set(synergy.id, synergy);
    }
  }

  return {
    designations,
    impliedDesignations: implied,
    effectiveDesignations: effective,
    matchedSynergies: [...matchedById.values()],
    byDesignation,
  };
}

/** Aggregate links from all library records matching a designation. */
export function aggregateLinksForDesignation(
  matches: SynergyWithLinks[],
): SynergyWithLinks["links"] {
  const seen = new Set<string>();
  const links: SynergyWithLinks["links"] = [];
  for (const synergy of matches) {
    for (const link of synergy.links) {
      const key = [
        link.kind,
        link.itemHash ?? "",
        link.perkHash ?? "",
        link.originTraitHash ?? "",
        link.originTraitName ?? "",
        link.armorSetHash ?? "",
        link.armorSetName ?? "",
        link.bonusPieces ?? "",
        link.bonusName ?? "",
      ].join("|");
      if (seen.has(key)) continue;
      seen.add(key);
      links.push(link);
    }
  }
  return links;
}
