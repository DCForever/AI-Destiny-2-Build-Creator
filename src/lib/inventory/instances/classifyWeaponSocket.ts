import type { SocketColumnKind } from "./types";

export interface SocketClassifyInput {
  socketIndex: number;
  equippedPlugHash: number;
  plugCategoryByHash: Map<number, string>;
  /** Optional itemTypeDisplayName by plug hash (e.g. "Enhanced Trait"). */
  plugItemTypeByHash?: Map<number, string>;
  /** Ordered weapon-perk-category socket indexes (barrel, mag, traits). */
  weaponPerkSocketIndexes: number[];
}

export interface SocketClassifyResult {
  columnKind: SocketColumnKind;
  columnLabel: string;
  includeInGrid: boolean;
}

const EXCLUDED_PATTERNS = [
  /shader/i,
  /tracker/i,
  /ornament/i,
  /^enhancements\./i,
  /kill.?tracker/i,
  /objective/i,
  /emote/i,
  /clan.?banner/i,
  /armor\.mods/i,
  /v400\./i, // cosmetic / seasonal UI sockets
];

const COLUMN_LABELS: Record<Exclude<SocketColumnKind, "trait">, string> = {
  barrel: "Barrel",
  magazine: "Magazine",
  intrinsic: "Intrinsic",
  origin: "Origin Trait",
  masterwork: "Masterwork",
  catalyst: "Catalyst",
};

function intrinsicLabel(category: string): string {
  if (/^frames$/i.test(category) || /frames\./i.test(category)) return "Frame";
  return COLUMN_LABELS.intrinsic;
}

function categoryFor(input: SocketClassifyInput): string {
  return input.plugCategoryByHash.get(input.equippedPlugHash) ?? "";
}

function isCosmeticCategory(category: string): boolean {
  return EXCLUDED_PATTERNS.some((pattern) => pattern.test(category));
}

function kindFromCategory(
  category: string,
  itemTypeDisplayName?: string | null,
): SocketColumnKind | null {
  if (/masterwork/.test(category)) return "masterwork";
  if (/catalyst/.test(category)) return "catalyst";
  if (/origins/.test(category)) return "origin";
  if (/^intrinsics$/i.test(category) || /^intrinsics\./i.test(category)) {
    return "intrinsic";
  }
  // Bare "frames" is often Enhanced Traits (Keep Away, Adagio, …) — not the
  // weapon intrinsic. True frames/intrinsics use "intrinsics".
  // Check after origin: "Origin Trait" item type must not become a trait column.
  if (
    /trait/i.test(itemTypeDisplayName ?? "") &&
    !/origin/i.test(itemTypeDisplayName ?? "")
  ) {
    return "trait";
  }
  if (/^frames$/i.test(category)) {
    // Fall through to socket-index trait labeling when type is unknown.
    return null;
  }
  if (/^frames\./i.test(category)) return "intrinsic";
  if (/barrels\.?|launchers\.|sights\.|scopes\./.test(category)) return "barrel";
  if (/magazines\.?|batteries\.|hilt\.|guard\./.test(category)) return "magazine";
  if (/traits\.|perks\.|trait/.test(category)) return "trait";
  return null;
}

function traitLabelForIndex(perkPosition: number): string {
  const traitNumber = perkPosition - 1;
  if (traitNumber <= 1) return "Trait 1";
  if (traitNumber === 2) return "Trait 2";
  return `Trait ${traitNumber}`;
}

export function classifyWeaponSocket(input: SocketClassifyInput): SocketClassifyResult {
  const category = categoryFor(input);
  const itemType =
    input.plugItemTypeByHash?.get(input.equippedPlugHash) ?? null;
  const kind = category
    ? kindFromCategory(category, itemType)
    : itemType && /trait/i.test(itemType)
      ? ("trait" as const)
      : null;

  if (kind === "intrinsic") {
    return {
      columnKind: "intrinsic",
      columnLabel: intrinsicLabel(category),
      includeInGrid: true,
    };
  }
  if (kind === "origin") {
    return {
      columnKind: "origin",
      columnLabel: COLUMN_LABELS.origin,
      includeInGrid: true,
    };
  }
  if (kind === "masterwork") {
    // Kill trackers often use a masterwork-like category; hide pure trackers.
    if (/tracker/i.test(itemType ?? "") || /tracker/i.test(category)) {
      return { columnKind: "masterwork", columnLabel: "", includeInGrid: false };
    }
    return {
      columnKind: "masterwork",
      columnLabel: COLUMN_LABELS.masterwork,
      includeInGrid: true,
    };
  }
  if (kind === "catalyst") {
    return {
      columnKind: "catalyst",
      columnLabel: COLUMN_LABELS.catalyst,
      includeInGrid: true,
    };
  }

  if (category && isCosmeticCategory(category)) {
    return { columnKind: "trait", columnLabel: "", includeInGrid: false };
  }

  if (kind === "barrel") {
    return { columnKind: "barrel", columnLabel: COLUMN_LABELS.barrel, includeInGrid: true };
  }
  if (kind === "magazine") {
    return { columnKind: "magazine", columnLabel: COLUMN_LABELS.magazine, includeInGrid: true };
  }

  const perkPosition = input.weaponPerkSocketIndexes.indexOf(input.socketIndex);
  if (perkPosition === -1) {
    return { columnKind: "trait", columnLabel: "", includeInGrid: false };
  }
  if (perkPosition === 0) {
    return { columnKind: "barrel", columnLabel: COLUMN_LABELS.barrel, includeInGrid: true };
  }
  if (perkPosition === 1) {
    return { columnKind: "magazine", columnLabel: COLUMN_LABELS.magazine, includeInGrid: true };
  }

  return {
    columnKind: "trait",
    columnLabel: traitLabelForIndex(perkPosition),
    includeInGrid: true,
  };
}

export function isEnhancedPlug(name: string | null, category: string): boolean {
  if (/enhanced/i.test(name ?? "")) return true;
  return /enhancements\.v2|enhanced/i.test(category);
}

export function formatPerkDisplayName(name: string | null, hash: number, isEnhanced: boolean): string {
  const base = name ?? String(hash);
  if (isEnhanced && !/enhanced/i.test(base)) {
    return `${base} (Enhanced)`;
  }
  return base;
}
