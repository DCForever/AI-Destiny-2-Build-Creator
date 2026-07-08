import type { RawSocketCapture, StoredSocketPlug } from "./types";
import { classifyWeaponSocket, type SocketClassifyInput } from "./classifyWeaponSocket";

export interface BuildStoredSocketPlugsInput {
  socketCapture: RawSocketCapture[];
  plugCategoryByHash: Map<number, string>;
  weaponPerkSocketIndexes: number[];
}

export function buildStoredSocketPlugs(input: BuildStoredSocketPlugsInput): StoredSocketPlug[] {
  const result: StoredSocketPlug[] = [];

  for (const row of input.socketCapture) {
    const classified = classifyWeaponSocket({
      socketIndex: row.socketIndex,
      equippedPlugHash: row.equippedPlugHash,
      plugCategoryByHash: input.plugCategoryByHash,
      weaponPerkSocketIndexes: input.weaponPerkSocketIndexes,
    } satisfies SocketClassifyInput);

    if (!classified.includeInGrid) continue;

    const reusable = [...new Set([row.equippedPlugHash, ...row.reusablePlugHashes])];
    result.push({
      socketIndex: row.socketIndex,
      equippedPlugHash: row.equippedPlugHash,
      reusablePlugHashes: reusable,
      columnKind: classified.columnKind,
      columnLabel: classified.columnLabel,
    });
  }

  return result;
}

export function deriveCaptureStatus(
  socketPlugs: StoredSocketPlug[] | null | undefined,
): "complete" | "pending" | "unavailable" {
  if (socketPlugs === null || socketPlugs === undefined) return "pending";
  if (socketPlugs.length === 0) return "unavailable";
  return "complete";
}
