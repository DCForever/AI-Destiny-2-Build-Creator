/**
 * Derive SynergyLinkInput from a universal catalog hit (027 T023).
 * Returns null when the kind is not synergy-eligible or identity fields are missing.
 */

import type { CompositionSearchHit } from "./universalSearch";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";

function metaString(
  meta: Record<string, unknown> | undefined,
  key: string,
): string | undefined {
  const v = meta?.[key];
  return typeof v === "string" && v.trim() ? v.trim() : undefined;
}

function metaNumber(
  meta: Record<string, unknown> | undefined,
  key: string,
): number | undefined {
  const v = meta?.[key];
  return typeof v === "number" && Number.isFinite(v) ? v : undefined;
}

/**
 * Map a composition search hit to a synergy link payload for create/add.
 * Aligns with composition-actions-contract link derivation table.
 */
export function synergyLinkFromHit(hit: CompositionSearchHit): SynergyLinkInput | null {
  if (!hit.actions.synergy) return null;

  switch (hit.kind) {
    case "weapon":
    case "exotic_weapon": {
      if (hit.hash == null) return null;
      return {
        kind: "weapon",
        displayName: hit.name,
        itemHash: hit.hash,
      };
    }

    case "weapon_perk": {
      if (hit.hash == null) return null;
      return {
        kind: "weapon_perk",
        displayName: hit.name,
        perkHash: hit.hash,
      };
    }

    case "origin_trait": {
      if (hit.hash == null && !hit.name.trim()) return null;
      return {
        kind: "origin_trait",
        displayName: hit.name,
        originTraitName: hit.name,
        ...(hit.hash != null ? { originTraitHash: hit.hash } : {}),
      };
    }

    case "armor_set_bonus": {
      const armorSetName = metaString(hit.meta, "armorSetName");
      const bonusName = metaString(hit.meta, "bonusName");
      const piecesRaw = metaNumber(hit.meta, "bonusPieces");
      const bonusPieces =
        piecesRaw === 2 || piecesRaw === 4 ? (piecesRaw as 2 | 4) : undefined;
      if (!armorSetName || !bonusName || bonusPieces == null) return null;
      const armorSetHash =
        metaNumber(hit.meta, "armorSetHash") ?? hit.hash ?? undefined;
      return {
        kind: "armor_set_bonus",
        displayName: hit.name,
        armorSetName,
        bonusPieces,
        bonusName,
        ...(armorSetHash != null ? { armorSetHash } : {}),
      };
    }

    case "exotic_armor": {
      if (hit.hash == null) return null;
      return {
        kind: "exotic_armor",
        displayName: hit.name,
        itemHash: hit.hash,
      };
    }

    case "artifact_perk": {
      if (hit.hash == null) return null;
      const parentItemHash = metaNumber(hit.meta, "parentItemHash");
      return {
        kind: "artifact_perk",
        displayName: hit.name,
        perkHash: hit.hash,
        ...(parentItemHash != null ? { parentItemHash } : {}),
      };
    }

    default:
      return null;
  }
}
