import { eq } from "drizzle-orm";

import type { AppDatabase } from "@/lib/db/client";
import { inventoryItems } from "@/lib/db/schema";
import { listSynergies } from "@/lib/db/repositories/synergyRepository";
import { ownedHashesFromInventory } from "@/lib/catalog/filterItems";
import type { InventoryBucketRow } from "@/lib/catalog/filterItems";
import { saveProposePass } from "@/lib/llm/propose/proposalStore";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";
import { collectGapCandidates } from "@/lib/synergies/collectGapCandidates";
import { collectCoveredKeys } from "@/lib/synergies/coverageKeys";
import {
  filterCandidatesByScope,
  gapsFromSynergiesAndCandidates,
  proposalsFromGaps,
} from "@/lib/synergies/gapScan";
import { filterGapsAndProposals } from "@/lib/synergies/ignoredTypeGaps";
import type {
  GapScanKindFilter,
  GapScanScope,
  MissingSynergyGap,
} from "@/lib/synergies/gapScanTypes";
import { DEFAULT_GAP_KINDS } from "@/lib/synergies/gapScanTypes";
import { collectObjectTexts } from "@/lib/synergies/collectObjectTexts";
import { discoverKeywordsFromObjects } from "@/lib/synergies/keywordScan";
import {
  buildExistingDesignationIndex,
  resolveExistingDesignation,
} from "@/lib/synergies/existingDesignations";
import {
  buildTypeDesignationCandidates,
  collectCoveredTypeKeys,
  findMissingTypeGaps,
} from "@/lib/synergies/typeCoverage";
import { listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";
import { getServices } from "@/lib/services";

export type RunGapScanInput = {
  scope?: GapScanScope;
  kinds?: GapScanKindFilter[];
  /** Max missing gaps returned / proposed (type + link combined). */
  limit?: number;
  maxPerKind?: number;
  /** Prefer type designation gaps before link gaps when filling limit. */
  preferTypeGaps?: boolean;
  /** Filter type gaps by name/type/subtype (e.g. "Sliding"). */
  query?: string;
  /** Coverage keys the user chose to hide permanently. */
  ignoredKeys?: readonly string[];
};

export type RunGapScanResult = {
  scope: GapScanScope;
  kinds: GapScanKindFilter[];
  candidateCount: number;
  coveredCount: number;
  missingCount: number;
  typeGapCount: number;
  linkGapCount: number;
  ignoredCount: number;
  ignoredKeys: string[];
  gaps: MissingSynergyGap[];
  passId: string;
  proposals: Proposal[];
  ownedWeaponCount: number;
  syncPrompt: boolean;
};

export async function runGapScan(
  db: AppDatabase,
  userId: number,
  input: RunGapScanInput = {},
): Promise<RunGapScanResult> {
  const scope: GapScanScope = input.scope ?? "both";
  const kinds = input.kinds ?? [...DEFAULT_GAP_KINDS];
  const limit = input.limit ?? 150;
  const maxPerKind = input.maxPerKind ?? 400;
  const preferTypeGaps = input.preferTypeGaps !== false;
  const includeTypes = kinds.includes("type");
  const linkKinds = kinds.filter((k) => k !== "type");
  const query = input.query?.trim() ?? "";
  const ignoredKeys = [...(input.ignoredKeys ?? [])].filter(Boolean);
  const ignoredSet = new Set(ignoredKeys);
  // Over-fetch so ignore list does not starve the visible result cap.
  const fetchLimit = Math.min(500, limit + ignoredSet.size);

  const { entityCache } = await getServices();
  // Keyword sources for missing types (restricted set). Legendary weapons /
  // abilities / mods / artifacts are intentionally excluded.
  const [
    weapons,
    exoticWeapons,
    exoticArmor,
    weaponPerks,
    originTraits,
    setBonuses,
    aspects,
    fragments,
    artifacts,
  ] = await Promise.all([
    entityCache.getStore("weapons"),
    entityCache.getStore("exotic-weapons"),
    entityCache.getStore("exotic-armor"),
    entityCache.getStore("weapon-perks"),
    entityCache.getStore("origin-traits"),
    entityCache.getStore("set-bonuses"),
    entityCache.getStore("aspects"),
    entityCache.getStore("fragments"),
    entityCache.getStore("artifacts"),
  ]);

  const invRows = db
    .select({
      itemHash: inventoryItems.itemHash,
      bucket: inventoryItems.bucket,
    })
    .from(inventoryItems)
    .where(eq(inventoryItems.userId, userId))
    .all() as InventoryBucketRow[];

  const ownedMap = ownedHashesFromInventory(invRows, "weapons");
  const ownedWeaponHashes = [...ownedMap.keys()];
  const syncPrompt = ownedWeaponHashes.length === 0;

  const synergies = listSynergies(db, userId);

  // --- Type gaps: keywords read ONLY from the allowed object sources ---
  let typeGaps: MissingSynergyGap[] = [];
  if (includeTypes) {
    const objectTexts = collectObjectTexts({
      originTraits,
      setBonuses,
      weaponPerks,
      aspects,
      fragments,
      exoticArmor,
      exoticWeapons,
      artifacts,
      // Legendary weapons only used to exclude barrel/magazine perk hashes
      weapons,
    });

    // Load existing type/subtype vocab so we don't re-propose Glaive as a verb, etc.
    const [meleeOpts, grenadeOpts, superOpts, archetypeOpts] =
      await Promise.all([
        listSubTypeOptions("melee"),
        listSubTypeOptions("grenade"),
        listSubTypeOptions("super"),
        listSubTypeOptions("weapon_archetype"),
      ]);
    const designationIndex = buildExistingDesignationIndex({
      meleeNames: meleeOpts.map((o) => o.name),
      grenadeNames: grenadeOpts.map((o) => o.name),
      superNames: superOpts.map((o) => o.name),
      weaponArchetypeNames: archetypeOpts.map((o) => o.name),
    });

    const objectKeywords = discoverKeywordsFromObjects(objectTexts, {
      minNovelMentions: 2,
      minCuratedMentions: 1,
      existingDesignationKeys: designationIndex.keys,
      resolveExisting: (token) =>
        resolveExistingDesignation(token, designationIndex),
    });

    // Type candidates = designations discovered on those objects (not the full
    // curated type dump / ability lists).
    const typeCandidates = buildTypeDesignationCandidates({
      objectDrivenOnly: true,
      objectKeywords: objectKeywords.map((k) => ({
        keyword: k.keyword,
        kind: k.kind,
        origin: k.origin,
        mentionCount: k.mentionCount,
        sampleObjectNames: k.sampleObjects.map((s) => s.name),
        references: k.sampleObjects.map((s) => ({
          store: s.store,
          hash: s.hash,
          name: s.name,
          snippet: s.snippet,
        })),
      })),
    });
    const coveredTypes = collectCoveredTypeKeys(synergies);
    typeGaps = findMissingTypeGaps(typeCandidates, coveredTypes, {
      limit: preferTypeGaps ? fetchLimit : Math.ceil(fetchLimit / 2),
      query: query || undefined,
      // Curated verbs/elements (Ionic Trace, Bolt Charge, …) are known types.
      // Only novel object-discovered keywords are "missing types".
      onlyNovel: true,
    });
  }

  // --- Link-object gaps (weapon / origin / set bonus not linked) ---
  let linkGaps: MissingSynergyGap[] = [];
  let scopedCandidatesCount = 0;
  let coveredLinkCount = 0;
  if (linkKinds.length > 0) {
    const candidates = collectGapCandidates({
      stores: {
        weapons,
        exoticWeapons,
        weaponPerks,
        originTraits,
        setBonuses,
      },
      ownedWeaponHashes,
      kinds: linkKinds,
      maxPerKind,
    });
    const covered = collectCoveredKeys(synergies);
    const scopedCandidates = filterCandidatesByScope(candidates, scope);
    scopedCandidatesCount = scopedCandidates.length;
    coveredLinkCount = scopedCandidates.filter((c) =>
      covered.has(c.coverageKey),
    ).length;
    const linkBudget = Math.max(0, fetchLimit - typeGaps.length);
    linkGaps = gapsFromSynergiesAndCandidates(synergies, candidates, scope, {
      limit: preferTypeGaps ? linkBudget : fetchLimit,
    });
  }

  const combined = preferTypeGaps
    ? [...typeGaps, ...linkGaps]
    : [...linkGaps, ...typeGaps];
  const rawProposals = proposalsFromGaps(combined);
  const filtered = filterGapsAndProposals(combined, rawProposals, ignoredSet);
  const gaps = filtered.gaps.slice(0, limit);
  const proposals = filtered.proposals.slice(0, limit);

  const passId = crypto.randomUUID();
  saveProposePass({
    passId,
    createdAt: new Date().toISOString(),
    proposals,
  });

  return {
    scope,
    kinds,
    candidateCount: scopedCandidatesCount + (includeTypes ? typeGaps.length : 0),
    coveredCount: coveredLinkCount,
    missingCount: gaps.length,
    typeGapCount: gaps.filter((g) => g.gapKind === "type").length,
    linkGapCount: gaps.filter((g) => g.gapKind === "link").length,
    ignoredCount: ignoredSet.size,
    ignoredKeys: [...ignoredSet].sort((a, b) => a.localeCompare(b)),
    gaps,
    passId,
    proposals,
    ownedWeaponCount: ownedWeaponHashes.length,
    syncPrompt,
  };
}
