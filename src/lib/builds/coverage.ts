import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import type { SlotClaim } from "@/lib/builds/resolveVariant";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import { softStatWarnings, type SoftStatWarningRow, type StatEstimate } from "@/lib/builds/statEstimate";
import type { SetBonusRecord } from "@/lib/manifest/types/records";

export type CoverageTier = "supported" | "weak" | "missing";

export type LinkMatchSummary = {
  kind: string;
  displayName: string;
  id?: string;
};

export type SynergyCoverageRow = {
  /** Designation key (`type::subType`) */
  synergyId: string;
  name: string;
  tier: CoverageTier;
  matchedLinks: LinkMatchSummary[];
  unmatchedLinks: LinkMatchSummary[];
  hint: string | null;
};

export type SetBonusSoftRow = {
  setName: string;
  armorSetHash: number | null;
  pieceCount: number;
  status: "active" | "partial" | "inactive";
  activeBonuses: string[];
  supportedSynergyIds: string[];
  hint: string | null;
};

export type ElementSoftMismatch = {
  slot: EquipmentSlot;
  weaponElement: string;
  subclassElement: string;
  hint: string;
};

export type CoverageResult = {
  synergies: SynergyCoverageRow[];
  setBonuses: SetBonusSoftRow[];
  elementMismatches: ElementSoftMismatch[];
  targets: SoftStatTargets;
  statEstimate: StatEstimate | null;
  softStats: SoftStatWarningRow[];
};

export type CoverageEvalInput = {
  claims: SlotClaim[];
  synergies: SynergyWithLinks[];
  subclass: unknown;
  /** itemHash → set bonus record */
  setBonusByItemHash?: Map<number, SetBonusRecord>;
  /** itemHash → element name for weapons */
  weaponElementByHash?: Map<number, string>;
  softStatTargets?: SoftStatTargets;
  statEstimate?: StatEstimate | null;
};

const ARMOR_SLOTS: EquipmentSlot[] = ["helmet", "arms", "chest", "legs", "class_item"];
const WEAPON_SLOTS: EquipmentSlot[] = ["primary", "special", "heavy"];

function linkSummary(link: SynergyLinkRecord): LinkMatchSummary {
  return { kind: link.kind, displayName: link.displayName, id: link.id };
}

export function matchEvidenceLink(
  link: SynergyLinkRecord,
  claims: SlotClaim[],
  setBonusByItemHash?: Map<number, SetBonusRecord>,
): boolean {
  switch (link.kind) {
    case "weapon":
      return link.itemHash != null && claims.some((c) => c.itemHash === link.itemHash);
    case "weapon_perk":
      return (
        link.perkHash != null &&
        claims.some((c) => (c.selectedPerks ?? []).includes(link.perkHash!))
      );
    case "origin_trait":
      if (link.originTraitHash != null) {
        return claims.some((c) => (c.selectedPerks ?? []).includes(link.originTraitHash!));
      }
      return false;
    case "armor_set_bonus": {
      const needed = link.bonusPieces ?? 2;
      if (link.armorSetHash != null && setBonusByItemHash) {
        let count = 0;
        for (const claim of claims) {
          if (!ARMOR_SLOTS.includes(claim.slot)) continue;
          const bonus = setBonusByItemHash.get(claim.itemHash);
          if (bonus?.hash === link.armorSetHash) count += 1;
        }
        return count >= needed;
      }
      if (link.armorSetName) {
        // Name-only fallback: count claims whose set bonus name matches
        if (!setBonusByItemHash) return false;
        let count = 0;
        for (const claim of claims) {
          if (!ARMOR_SLOTS.includes(claim.slot)) continue;
          const bonus = setBonusByItemHash.get(claim.itemHash);
          if (bonus?.name === link.armorSetName) count += 1;
        }
        return count >= needed;
      }
      return false;
    }
    default:
      return false;
  }
}

export function tierForMatches(matched: number, total: number): CoverageTier {
  if (total === 0 || matched === 0) return "missing";
  if (matched >= total) return "supported";
  return "weak";
}

function hintForTier(tier: CoverageTier, name: string): string | null {
  if (tier === "supported") return null;
  if (tier === "weak") return `Add remaining links to fully support ${name}.`;
  return `No evidence links matched for ${name}.`;
}

function subclassElement(subclass: unknown): string | null {
  if (!subclass || typeof subclass !== "object") return null;
  const record = subclass as Record<string, unknown>;
  if (typeof record.element === "string" && record.element.trim()) {
    return record.element.trim();
  }
  const text = JSON.stringify(subclass).toLowerCase();
  for (const el of ["solar", "arc", "void", "stasis", "strand", "prismatic"]) {
    if (text.includes(el)) return el[0]!.toUpperCase() + el.slice(1);
  }
  return null;
}

export function evaluateCoverage(input: CoverageEvalInput): CoverageResult {
  const { claims, synergies, subclass, setBonusByItemHash, weaponElementByHash } = input;
  const softStatTargets = input.softStatTargets ?? {};
  const statEstimate = input.statEstimate ?? null;

  const synergyRows: SynergyCoverageRow[] = synergies.map((synergy) => {
    const matchedLinks: LinkMatchSummary[] = [];
    const unmatchedLinks: LinkMatchSummary[] = [];
    for (const link of synergy.links) {
      if (matchEvidenceLink(link, claims, setBonusByItemHash)) {
        matchedLinks.push(linkSummary(link));
      } else {
        unmatchedLinks.push(linkSummary(link));
      }
    }
    const tier = tierForMatches(matchedLinks.length, synergy.links.length);
    return {
      synergyId: synergy.id,
      name: synergy.name,
      tier,
      matchedLinks,
      unmatchedLinks,
      hint: hintForTier(tier, synergy.name),
    };
  });

  const setBonuses: SetBonusSoftRow[] = [];
  if (setBonusByItemHash) {
    const bySet = new Map<number, { record: SetBonusRecord; count: number }>();
    for (const claim of claims) {
      if (!ARMOR_SLOTS.includes(claim.slot)) continue;
      const record = setBonusByItemHash.get(claim.itemHash);
      if (!record) continue;
      const entry = bySet.get(record.hash) ?? { record, count: 0 };
      entry.count += 1;
      bySet.set(record.hash, entry);
    }
    for (const { record, count } of bySet.values()) {
      const activeBonuses = record.perks
        .filter((p) => count >= p.requiredCount)
        .map((p) => `${p.requiredCount}pc`);
      const maxRequired = Math.max(0, ...record.perks.map((p) => p.requiredCount));
      let status: SetBonusSoftRow["status"] = "inactive";
      if (activeBonuses.length > 0) status = "active";
      else if (count > 0 && count < maxRequired) status = "partial";

      const supportedSynergyIds = synergies
        .filter((s) =>
          s.links.some(
            (l) =>
              l.kind === "armor_set_bonus" &&
              (l.armorSetHash === record.hash || l.armorSetName === record.name),
          ),
        )
        .map((s) => s.id);

      setBonuses.push({
        setName: record.name,
        armorSetHash: record.hash,
        pieceCount: count,
        status,
        activeBonuses,
        supportedSynergyIds,
        hint:
          status === "partial"
            ? `Need more pieces of ${record.name} for the next bonus.`
            : status === "inactive"
              ? `No set bonus active for ${record.name}.`
              : null,
      });
    }
  }

  const elementMismatches: ElementSoftMismatch[] = [];
  const subEl = subclassElement(subclass);
  if (subEl && subEl.toLowerCase() !== "prismatic" && weaponElementByHash) {
    for (const claim of claims) {
      if (!WEAPON_SLOTS.includes(claim.slot)) continue;
      const weaponEl = weaponElementByHash.get(claim.itemHash);
      if (!weaponEl || weaponEl.toLowerCase() === "kinetic") continue;
      if (weaponEl.toLowerCase() !== subEl.toLowerCase()) {
        elementMismatches.push({
          slot: claim.slot,
          weaponElement: weaponEl,
          subclassElement: subEl,
          hint: `${claim.slot} is ${weaponEl}; subclass is ${subEl}.`,
        });
      }
    }
  }

  const softStats =
    statEstimate != null ? softStatWarnings(softStatTargets, statEstimate) : [];

  return {
    synergies: synergyRows,
    setBonuses,
    elementMismatches,
    targets: softStatTargets,
    statEstimate,
    softStats,
  };
}

/** Unmatched item/perk hashes for suggest-sets gap bias. */
export function coverageGapsForSuggest(coverage: CoverageResult, synergies: SynergyWithLinks[]) {
  const byId = new Map(synergies.map((s) => [s.id, s]));
  return coverage.synergies
    .filter((row) => row.tier === "missing" || row.tier === "weak")
    .map((row) => {
      const synergy = byId.get(row.synergyId);
      const unmatched = synergy?.links.filter((l) =>
        row.unmatchedLinks.some((u) => u.id === l.id || u.displayName === l.displayName),
      );
      return {
        synergyName: row.name,
        itemHashes: (unmatched ?? [])
          .map((l) => l.itemHash)
          .filter((h): h is number => h != null),
        perkHashes: (unmatched ?? [])
          .map((l) => l.perkHash ?? l.originTraitHash)
          .filter((h): h is number => h != null),
      };
    });
}
