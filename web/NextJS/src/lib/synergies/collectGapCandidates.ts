import type {
  ExoticWeaponRecord,
  OriginTraitRecord,
  PerkRecord,
  SetBonusRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";
import { coverageKeyFromLink } from "@/lib/synergies/coverageKeys";
import type { CoverageLinkKind } from "@/lib/synergies/coverageKeys";
import type { GapCandidate, GapScanKindFilter } from "@/lib/synergies/gapScanTypes";
import { DEFAULT_GAP_KINDS } from "@/lib/synergies/gapScanTypes";
import { mergeCandidates } from "@/lib/synergies/gapScan";

function linkKindsOnly(kinds: GapScanKindFilter[]): CoverageLinkKind[] {
  return kinds.filter((k): k is CoverageLinkKind => k !== "type");
}

export type GapCandidateStores = {
  weapons: WeaponRecord[];
  exoticWeapons: ExoticWeaponRecord[];
  weaponPerks: PerkRecord[];
  originTraits: OriginTraitRecord[];
  setBonuses: SetBonusRecord[];
};

function weaponCandidate(
  w: WeaponRecord | ExoticWeaponRecord,
  source: "owned" | "manifest",
): GapCandidate {
  const key = coverageKeyFromLink({ kind: "weapon", itemHash: w.hash })!;
  return {
    coverageKey: key,
    kind: "weapon",
    displayName: w.name,
    itemHash: w.hash,
    ammo: w.ammo,
    sources: [source],
  };
}

/**
 * Build gap-scan candidates from entity stores.
 * - manifest: all weapons / origin traits / set bonuses (and optional perks)
 * - owned: owned weapon hashes that resolve in weapon stores
 * Callers merge via scope "both" by including both source tags.
 */
export function collectGapCandidates(input: {
  stores: GapCandidateStores;
  ownedWeaponHashes?: Iterable<number>;
  kinds?: GapScanKindFilter[];
  /** Cap per kind to keep scans usable (manifest is large). */
  maxPerKind?: number;
}): GapCandidate[] {
  const kinds = new Set(linkKindsOnly(input.kinds ?? DEFAULT_GAP_KINDS));
  const maxPerKind = input.maxPerKind ?? 500;
  const owned = new Set(input.ownedWeaponHashes ?? []);
  const { weapons, exoticWeapons, weaponPerks, originTraits, setBonuses } =
    input.stores;

  const weaponByHash = new Map<number, WeaponRecord | ExoticWeaponRecord>();
  for (const w of weapons) weaponByHash.set(w.hash, w);
  for (const w of exoticWeapons) weaponByHash.set(w.hash, w);

  const lists: GapCandidate[] = [];

  if (kinds.has("weapon")) {
    const manifestWeapons: GapCandidate[] = [];
    for (const w of weaponByHash.values()) {
      manifestWeapons.push(weaponCandidate(w, "manifest"));
      if (manifestWeapons.length >= maxPerKind) break;
    }

    const ownedWeapons: GapCandidate[] = [];
    for (const hash of owned) {
      const w = weaponByHash.get(hash);
      if (!w) continue;
      ownedWeapons.push(weaponCandidate(w, "owned"));
      if (ownedWeapons.length >= maxPerKind) break;
    }

    lists.push(...mergeCandidates(manifestWeapons, ownedWeapons));
  }

  if (kinds.has("origin_trait")) {
    let n = 0;
    for (const trait of originTraits) {
      const key = coverageKeyFromLink({
        kind: "origin_trait",
        originTraitHash: trait.hash,
        originTraitName: trait.name,
      });
      if (!key) continue;
      lists.push({
        coverageKey: key,
        kind: "origin_trait",
        displayName: trait.name,
        originTraitHash: trait.hash,
        originTraitName: trait.name,
        // Origin traits appear on many weapons; owned flag if any owned weapon lists this trait.
        sources: originTraitOwned(trait.hash, owned, weaponByHash)
          ? ["manifest", "owned"]
          : ["manifest"],
      });
      n += 1;
      if (n >= maxPerKind) break;
    }
  }

  if (kinds.has("armor_set_bonus")) {
    let n = 0;
    for (const set of setBonuses) {
      for (const perk of set.perks) {
        if (perk.requiredCount !== 2 && perk.requiredCount !== 4) continue;
        const pieces = perk.requiredCount as 2 | 4;
        const key = coverageKeyFromLink({
          kind: "armor_set_bonus",
          armorSetName: set.name,
          bonusPieces: pieces,
          bonusName: perk.name,
        });
        if (!key) continue;
        lists.push({
          coverageKey: key,
          kind: "armor_set_bonus",
          displayName: `${set.name} ${pieces}pc — ${perk.name}`,
          armorSetName: set.name,
          bonusPieces: pieces,
          bonusName: perk.name,
          armorSetHash: set.hash,
          sources: ["manifest"],
        });
        n += 1;
        if (n >= maxPerKind) break;
      }
      if (n >= maxPerKind) break;
    }
  }

  if (kinds.has("weapon_perk")) {
    let n = 0;
    for (const perk of weaponPerks) {
      const key = coverageKeyFromLink({
        kind: "weapon_perk",
        perkHash: perk.hash,
      });
      if (!key) continue;
      lists.push({
        coverageKey: key,
        kind: "weapon_perk",
        displayName: perk.name,
        perkHash: perk.hash,
        sources: ["manifest"],
      });
      n += 1;
      if (n >= maxPerKind) break;
    }
  }

  return mergeCandidates(lists, []);
}

function originTraitOwned(
  traitHash: number,
  owned: Set<number>,
  weaponByHash: Map<number, WeaponRecord | ExoticWeaponRecord>,
): boolean {
  if (owned.size === 0) return false;
  for (const hash of owned) {
    const w = weaponByHash.get(hash);
    if (!w || !("originTraitHashes" in w)) continue;
    if (w.originTraitHashes?.includes(traitHash)) return true;
  }
  return false;
}
