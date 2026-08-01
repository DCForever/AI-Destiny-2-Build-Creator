import type { UserInventoryItem } from "@/lib/db/types";
import type { InstancePerkColumn, InstancePerkGrid, StoredSocketPlug } from "./types";
import {
  classifyWeaponSocket,
  formatPerkDisplayName,
  isEnhancedPlug,
} from "./classifyWeaponSocket";
import { deriveCaptureStatus, buildStoredSocketPlugs } from "./buildStoredSocketPlugs";
import {
  plugNameFromMap,
  plugPresentationFromMap,
  type PlugLookup,
} from "./resolvePlugs";

const COLUMN_ORDER: Record<InstancePerkColumn["columnKind"], number> = {
  barrel: 0,
  magazine: 1,
  trait: 2,
  intrinsic: 3,
  origin: 4,
  masterwork: 5,
  catalyst: 6,
};

export interface ResolveInstancePerkGridInput {
  item: UserInventoryItem;
  plugMap: PlugLookup;
  plugCategoryByHash: Map<number, string>;
  plugItemTypeByHash?: Map<number, string>;
  weaponPerkSocketIndexes: number[];
}

function buildColumnOptions(
  stored: StoredSocketPlug,
  plugMap: PlugLookup,
  plugCategoryByHash: Map<number, string>,
  includeAlternates: boolean,
) {
  // Always include every reusable plug hash for this socket (DIM-style full column).
  const hashes = includeAlternates
    ? [
        ...new Set([
          stored.equippedPlugHash,
          ...stored.reusablePlugHashes,
        ]),
      ]
    : [stored.equippedPlugHash];

  // Equipped first, then remaining options in stable hash order for density scan.
  const ordered = [
    stored.equippedPlugHash,
    ...hashes
      .filter((h) => h !== stored.equippedPlugHash)
      .sort((a, b) => a - b),
  ];

  return ordered.map((hash) => {
    const presentation = plugPresentationFromMap(plugMap, hash);
    const name = presentation?.name ?? plugNameFromMap(plugMap, hash);
    const category = plugCategoryByHash.get(hash) ?? "";
    const enhanced = isEnhancedPlug(name, category);
    return {
      hash,
      name,
      displayName: formatPerkDisplayName(name, hash, enhanced),
      isEnhanced: enhanced,
      isEquipped: hash === stored.equippedPlugHash,
      icon: presentation?.icon ?? null,
      description: presentation?.description ?? "",
    };
  });
}

function sortColumns(columns: InstancePerkColumn[]): InstancePerkColumn[] {
  return [...columns].sort((a, b) => {
    const kindDiff = COLUMN_ORDER[a.columnKind] - COLUMN_ORDER[b.columnKind];
    if (kindDiff !== 0) return kindDiff;
    return a.socketIndex - b.socketIndex;
  });
}

/** When multiple columns share a label, prefer the equipped plug name. */
function disambiguateColumnLabels(
  columns: InstancePerkColumn[],
  plugMap: PlugLookup,
): InstancePerkColumn[] {
  const labelCounts = new Map<string, number>();
  for (const col of columns) {
    labelCounts.set(col.label, (labelCounts.get(col.label) ?? 0) + 1);
  }

  return columns.map((col) => {
    if ((labelCounts.get(col.label) ?? 0) <= 1) return col;
    const equippedName = plugNameFromMap(plugMap, col.equippedPlugHash);
    if (equippedName) return { ...col, label: equippedName };
    return { ...col, label: `${col.label} (socket ${col.socketIndex + 1})` };
  });
}

function buildPendingEquippedColumns(input: ResolveInstancePerkGridInput): InstancePerkColumn[] {
  const capture = input.item.plugHashes.map((equippedPlugHash, socketIndex) => ({
    socketIndex,
    equippedPlugHash,
    reusablePlugHashes: [] as number[],
  }));
  const stored = buildStoredSocketPlugs({
    socketCapture: capture,
    plugCategoryByHash: input.plugCategoryByHash,
    weaponPerkSocketIndexes: input.weaponPerkSocketIndexes,
  });

  return stored.map((row) => ({
    columnKind: row.columnKind,
    label: row.columnLabel,
    socketIndex: row.socketIndex,
    equippedPlugHash: row.equippedPlugHash,
    options: buildColumnOptions(row, input.plugMap, input.plugCategoryByHash, false),
  }));
}

export function resolveInstancePerkGrid(input: ResolveInstancePerkGridInput): InstancePerkGrid {
  const captureStatus = deriveCaptureStatus(input.item.socketPlugs);
  const includeAlternates = captureStatus === "complete";
  const storedRows = input.item.socketPlugs ?? [];

  const columns: InstancePerkColumn[] = [];

  if (captureStatus === "pending" && storedRows.length === 0 && input.item.plugHashes.length > 0) {
    columns.push(...buildPendingEquippedColumns(input));
  } else {
    for (const stored of storedRows) {
      // Re-classify at read time so vault-era rows get correct Trait vs Frame
      // labels without requiring another inventory sync.
      const reclass = classifyWeaponSocket({
        socketIndex: stored.socketIndex,
        equippedPlugHash: stored.equippedPlugHash,
        plugCategoryByHash: input.plugCategoryByHash,
        plugItemTypeByHash: input.plugItemTypeByHash,
        weaponPerkSocketIndexes: input.weaponPerkSocketIndexes,
      });
      if (!reclass.includeInGrid) continue;

      const options = buildColumnOptions(
        stored,
        input.plugMap,
        input.plugCategoryByHash,
        includeAlternates,
      );
      if (options.length === 0) continue;
      columns.push({
        columnKind: reclass.columnKind,
        label: reclass.columnLabel,
        socketIndex: stored.socketIndex,
        equippedPlugHash: stored.equippedPlugHash,
        options,
      });
    }
  }

  return {
    instanceId: input.item.instanceId,
    itemHash: input.item.itemHash,
    captureStatus,
    columns: disambiguateColumnLabels(sortColumns(columns), input.plugMap),
  };
}

export function selectionFromGrid(
  grid: InstancePerkGrid,
  overrides: Record<number, number>,
): number[] {
  return grid.columns.map((column) => overrides[column.socketIndex] ?? column.equippedPlugHash);
}

/** @internal test helper */
export function classifySocketForTests(
  socketIndex: number,
  equippedPlugHash: number,
  plugCategoryByHash: Map<number, string>,
  weaponPerkSocketIndexes: number[],
) {
  return classifyWeaponSocket({
    socketIndex,
    equippedPlugHash,
    plugCategoryByHash,
    weaponPerkSocketIndexes,
  });
}
