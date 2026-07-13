import type { ArtifactRecord, ArtifactPerkRecord, Hash } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import { asRawArtifact, asRawInventoryItem } from "./rawTypes";
import type { RawInventoryItem, RawSocketEntry } from "./rawTypes";
import { normalizeName } from "../normalize";
import {
  getRaw,
  isUsable,
  perkDescription,
  socketPlugHashes,
} from "./common";

type LoadTable = (table: RawTableName) => Promise<RawTable>;

const EMPTY_OR_RESET = /^(empty artifact mod|reset artifact)$/i;

function isSkipPlugName(name: string): boolean {
  return !name.trim() || EMPTY_OR_RESET.test(name.trim());
}

function buildPerksFromTiers(
  artifactName: string,
  tiers: { items: { itemHash: number }[] }[],
  itemTable: RawTable,
  sandboxPerks: RawTable,
): ArtifactPerkRecord[] {
  const perks: ArtifactPerkRecord[] = [];

  for (let col = 0; col < tiers.length; col++) {
    const tier = tiers[col];
    for (let row = 0; row < tier.items.length; row++) {
      const perkItem = asRawInventoryItem(getRaw(itemTable, tier.items[row].itemHash));
      if (!perkItem || isSkipPlugName(perkItem.displayProperties.name)) continue;
      perks.push({
        hash: perkItem.hash,
        name: perkItem.displayProperties.name,
        searchName: normalizeName(perkItem.displayProperties.name),
        icon: perkItem.displayProperties.icon ?? null,
        description: perkDescription(perkItem, sandboxPerks),
        column: col,
        row,
        artifactName,
      });
    }
  }

  return perks;
}

/** Collect plug hashes from a socket (curated + reusable sets + initial). */
function allSocketPlugHashes(socket: RawSocketEntry, plugSets: RawTable): Hash[] {
  const { curated, randomized } = socketPlugHashes(socket, plugSets);
  const hashes = [...curated, ...randomized];
  if (socket.singleInitialItemHash) hashes.push(socket.singleInitialItemHash);
  for (const p of socket.reusablePlugItems ?? []) {
    hashes.push(p.plugItemHash);
  }
  return [...new Set(hashes)];
}

/**
 * Moment of Triumph permanent multi-artifacts are inventory items
 * (itemTypeDisplayName "Artifact") with socket plug pools — not only
 * DestinyArtifactDefinition (which may still list a single seasonal tree).
 */
function buildPerksFromInventorySockets(
  artifactName: string,
  item: RawInventoryItem,
  itemTable: RawTable,
  plugSets: RawTable,
  sandboxPerks: RawTable,
): ArtifactPerkRecord[] {
  const perks: ArtifactPerkRecord[] = [];
  const sockets = item.sockets?.socketEntries ?? [];

  for (let col = 0; col < sockets.length; col++) {
    const socket = sockets[col]!;
    const hashes = allSocketPlugHashes(socket, plugSets);
    let row = 0;
    for (const hash of hashes) {
      const perkItem = asRawInventoryItem(getRaw(itemTable, hash));
      if (!perkItem || isSkipPlugName(perkItem.displayProperties.name)) continue;
      perks.push({
        hash: perkItem.hash,
        name: perkItem.displayProperties.name,
        searchName: normalizeName(perkItem.displayProperties.name),
        icon: perkItem.displayProperties.icon ?? null,
        description: perkDescription(perkItem, sandboxPerks),
        column: col,
        row,
        artifactName,
      });
      row += 1;
    }
  }

  return perks;
}

function unionPerks(a: ArtifactPerkRecord[], b: ArtifactPerkRecord[]): ArtifactPerkRecord[] {
  const byHash = new Map<number, ArtifactPerkRecord>();
  for (const p of [...a, ...b]) {
    const existing = byHash.get(p.hash);
    if (!existing) {
      byHash.set(p.hash, p);
      continue;
    }
    // Prefer longer description / non-empty artifactName
    const preferNext =
      (p.description?.length ?? 0) > (existing.description?.length ?? 0) ||
      (!existing.artifactName && !!p.artifactName);
    if (preferNext) byHash.set(p.hash, { ...p, artifactName: p.artifactName || existing.artifactName });
  }
  return [...byHash.values()];
}

function mergeArtifactRecords(records: ArtifactRecord[]): ArtifactRecord[] {
  const byName = new Map<string, ArtifactRecord>();
  for (const rec of records) {
    const key = rec.name.trim().toLowerCase();
    const existing = byName.get(key);
    if (!existing) {
      byName.set(key, rec);
      continue;
    }
    // Prefer inventory item hash when both exist (equippable MoT artifact).
    const preferIncoming =
      rec.perks.length > existing.perks.length ||
      (rec.hash !== existing.hash && rec.perks.length >= existing.perks.length);
    byName.set(key, {
      hash: preferIncoming ? rec.hash : existing.hash,
      name: existing.name || rec.name,
      searchName: existing.searchName || rec.searchName,
      icon: existing.icon ?? rec.icon,
      description: existing.description || rec.description,
      perks: unionPerks(existing.perks, rec.perks).map((p) => ({
        ...p,
        artifactName: existing.name || rec.name,
      })),
    });
  }
  return [...byName.values()];
}

async function extractArtifacts(loadTable: LoadTable): Promise<ArtifactRecord[]> {
  const [artifactTable, itemTable, sandboxPerks, plugSets] = await Promise.all([
    loadTable("DestinyArtifactDefinition"),
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
    loadTable("DestinyPlugSetDefinition"),
  ]);

  const fromDefs: ArtifactRecord[] = [];
  for (const v of Object.values(artifactTable)) {
    const artifact = asRawArtifact(v);
    if (!artifact || artifact.redacted) continue;
    if (!artifact.displayProperties.name.trim()) continue;
    const name = artifact.displayProperties.name;
    fromDefs.push({
      hash: artifact.hash,
      name,
      searchName: normalizeName(name),
      icon: artifact.displayProperties.icon ?? null,
      description: artifact.displayProperties.description,
      perks: buildPerksFromTiers(name, artifact.tiers, itemTable, sandboxPerks),
    });
  }

  const fromInventory: ArtifactRecord[] = [];
  for (const v of Object.values(itemTable)) {
    const item = asRawInventoryItem(v);
    if (!item || !isUsable(item)) continue;
    // Post–Moment of Triumph permanent multi-artifacts: equippable "Artifact" with sockets.
    const typeName = item.itemTypeDisplayName?.trim() ?? "";
    if (typeName !== "Artifact") continue;
    if (!item.sockets?.socketEntries?.length) continue;
    const name = item.displayProperties.name?.trim() ?? "";
    if (!name) continue;

    const perks = buildPerksFromInventorySockets(
      name,
      item,
      itemTable,
      plugSets,
      sandboxPerks,
    );
    if (perks.length === 0) continue;

    fromInventory.push({
      hash: item.hash,
      name,
      searchName: normalizeName(name),
      icon: item.displayProperties.icon ?? null,
      description: item.displayProperties.description ?? "",
      perks,
    });
  }

  return mergeArtifactRecords([...fromDefs, ...fromInventory]);
}

export const artifactsExtractor: Extractor<"artifacts"> = {
  store: "artifacts",
  extract: (loadTable) => extractArtifacts(loadTable),
};
