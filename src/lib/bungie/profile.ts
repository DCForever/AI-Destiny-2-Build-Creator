import { getBungieOAuthConfig } from "@/lib/config/env";
import type { DestinyClassName } from "@/lib/manifest/types/records";
import { parseArmorStatValues } from "@/lib/inventory/instances/parseArmorStats";
import type { BungieStatEntry } from "@/lib/inventory/instances/parseArmorStats";
import {
  EQUIPMENT_BUCKET_DISPLAY_LABELS,
  EQUIPMENT_BUCKET_LABELS,
  isParsableInventoryBucket,
  parseBucketLabel,
  SUBCLASS_BUCKET_HASH,
} from "./inventoryBuckets";
import type {
  BungieProfileClient,
  CharacterEquipment,
  CharacterSummary,
  DestinyMembership,
  EquippedItemSummary,
  FullInventoryParseResult,
  InventoryLocation,
  InventoryParseDiagnostics,
  RawInventoryItem,
} from "./types";

const BUNGIE_BASE = "https://www.bungie.net/Platform";

const CLASS_NAMES: Record<number, DestinyClassName> = {
  0: "Titan",
  1: "Hunter",
  2: "Warlock",
};

const BUCKET_DISPLAY_LABELS = EQUIPMENT_BUCKET_DISPLAY_LABELS;

const ARMOR_BUCKET_HASHES = new Set(
  Object.entries(EQUIPMENT_BUCKET_LABELS)
    .filter(([, label]) => ["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"].includes(label))
    .map(([hash]) => Number(hash)),
);

function isArmorBucketHash(bucketHash: number): boolean {
  return ARMOR_BUCKET_HASHES.has(bucketHash);
}

const INVENTORY_COMPONENTS = "102,201,205,300,305";

function assertBungieEnvelope(data: unknown): unknown {
  if (typeof data !== "object" || data === null) {
    throw new Error("Bungie response is not a JSON object");
  }
  const env = data as Record<string, unknown>;
  if (env.ErrorCode !== 1) {
    const msg = typeof env.Message === "string" ? env.Message : "Bungie API error";
    throw new Error(`Bungie API error: ${msg}`);
  }
  return env.Response;
}

export interface HttpBungieProfileClientOptions {
  apiKey: string;
  fetchFn?: typeof fetch;
}

export class HttpBungieProfileClient implements BungieProfileClient {
  private readonly apiKey: string;
  private readonly fetchFn: typeof fetch;

  constructor(opts: HttpBungieProfileClientOptions) {
    this.apiKey = opts.apiKey;
    this.fetchFn = opts.fetchFn ?? fetch;
  }

  private authHeaders(accessToken: string): HeadersInit {
    return {
      "X-API-Key": this.apiKey,
      Authorization: `Bearer ${accessToken}`,
    };
  }

  private async bungieGet(path: string, accessToken: string): Promise<unknown> {
    const response = await this.fetchFn(`${BUNGIE_BASE}${path}`, {
      headers: this.authHeaders(accessToken),
    });
    if (!response.ok) {
      throw new Error(`Bungie Platform returned ${response.status}: ${response.statusText}`);
    }
    return assertBungieEnvelope(await response.json());
  }

  async getMemberships(accessToken: string): Promise<DestinyMembership[]> {
    const response = await this.bungieGet("/User/GetMembershipsForCurrentUser/", accessToken);
    return parseMembershipsResponse(response);
  }

  async getCharacters(
    accessToken: string,
    membership: DestinyMembership,
  ): Promise<CharacterSummary[]> {
    const path = `/Destiny2/${membership.membershipType}/Profile/${membership.membershipId}/?components=200`;
    const response = await this.bungieGet(path, accessToken);
    const data = extractCharactersData(response);
    return Object.values(data).map(parseCharacterSummary).sort(byDateLastPlayedDesc);
  }

  async getCharacterEquipment(
    accessToken: string,
    membership: DestinyMembership,
    characterId: string,
  ): Promise<CharacterEquipment> {
    const path = `/Destiny2/${membership.membershipType}/Profile/${membership.membershipId}/?components=200,205,305`;
    const response = await this.bungieGet(path, accessToken);
    return parseEquipmentResponse(response, characterId);
  }

  async getFullInventory(
    accessToken: string,
    membership: DestinyMembership,
  ): Promise<RawInventoryItem[]> {
    const { items } = await this.getFullInventoryWithDiagnostics(accessToken, membership);
    return items;
  }

  async getFullInventoryWithDiagnostics(
    accessToken: string,
    membership: DestinyMembership,
  ): Promise<FullInventoryParseResult> {
    const path = `/Destiny2/${membership.membershipType}/Profile/${membership.membershipId}/?components=${INVENTORY_COMPONENTS}`;
    const response = await this.bungieGet(path, accessToken);
    return parseFullInventoryResponseWithDiagnostics(response, membership);
  }
}

function parseMembershipsResponse(response: unknown): DestinyMembership[] {
  if (typeof response !== "object" || response === null) {
    throw new Error("Unexpected memberships response shape");
  }
  const res = response as Record<string, unknown>;
  const primaryId =
    typeof res.primaryMembershipId === "string" ? res.primaryMembershipId : null;
  const rawList = Array.isArray(res.destinyMemberships) ? res.destinyMemberships : [];
  const memberships = rawList.map(parseMembership);
  if (primaryId) {
    memberships.sort((a, b) =>
      a.membershipId === primaryId ? -1 : b.membershipId === primaryId ? 1 : 0,
    );
  }
  return memberships;
}

function parseMembership(raw: unknown): DestinyMembership {
  if (typeof raw !== "object" || raw === null) throw new Error("Invalid membership entry");
  const m = raw as Record<string, unknown>;
  const displayName = String(m.bungieGlobalDisplayName || m.displayName || "");
  return {
    membershipType: Number(m.membershipType),
    membershipId: String(m.membershipId),
    displayName,
  };
}

function extractCharactersData(response: unknown): Record<string, unknown> {
  if (typeof response !== "object" || response === null) return {};
  const res = response as Record<string, unknown>;
  const characters = res.characters as Record<string, unknown> | undefined;
  if (!characters || typeof characters.data !== "object" || characters.data === null) return {};
  return characters.data as Record<string, unknown>;
}

function parseCharacterSummary(raw: unknown): CharacterSummary {
  if (typeof raw !== "object" || raw === null) throw new Error("Invalid character entry");
  const c = raw as Record<string, unknown>;
  return {
    characterId: String(c.characterId),
    classType: CLASS_NAMES[Number(c.classType)] ?? "Titan",
    light: Number(c.light),
    emblemPath: typeof c.emblemPath === "string" ? c.emblemPath : null,
    dateLastPlayed: String(c.dateLastPlayed ?? ""),
  };
}

function byDateLastPlayedDesc(a: CharacterSummary, b: CharacterSummary): number {
  return b.dateLastPlayed.localeCompare(a.dateLastPlayed);
}

function parseEquipmentResponse(response: unknown, characterId: string): CharacterEquipment {
  if (typeof response !== "object" || response === null) {
    throw new Error("Unexpected equipment response shape");
  }
  const res = response as Record<string, unknown>;
  const charData = extractCharactersData(response);
  const charRaw = charData[characterId];
  if (!charRaw) {
    throw new Error(`Character ${characterId} not found in profile response`);
  }
  const character = parseCharacterSummary(charRaw);
  const socketsMap = extractSocketsMap(res.itemComponents);
  const rawItems = extractCharacterItems(res.characterEquipment, characterId);
  const items = rawItems.flatMap((raw) => parseEquippedItem(raw, socketsMap));
  return { character, items };
}

function extractCharacterItems(
  section: unknown,
  charId: string,
): unknown[] {
  if (typeof section !== "object" || section === null) return [];
  const s = section as Record<string, unknown>;
  if (typeof s.data !== "object" || s.data === null) return [];
  const data = s.data as Record<string, unknown>;
  const charSection = data[charId];
  if (typeof charSection !== "object" || charSection === null) return [];
  const c = charSection as Record<string, unknown>;
  return Array.isArray(c.items) ? c.items : [];
}

function extractStatsMap(itemComponents: unknown): Record<string, BungieStatEntry[]> {
  if (typeof itemComponents !== "object" || itemComponents === null) return {};
  const ic = itemComponents as Record<string, unknown>;
  const stats = ic.stats;
  if (typeof stats !== "object" || stats === null) return {};
  const s = stats as Record<string, unknown>;
  if (typeof s.data !== "object" || s.data === null) return {};
  const result: Record<string, BungieStatEntry[]> = {};
  for (const [id, entry] of Object.entries(s.data as Record<string, unknown>)) {
    if (typeof entry !== "object" || entry === null) continue;
    const e = entry as Record<string, unknown>;
    const rows = Array.isArray(e.stats) ? e.stats : [];
    const parsed: BungieStatEntry[] = [];
    for (const row of rows) {
      if (typeof row !== "object" || row === null) continue;
      const stat = row as Record<string, unknown>;
      if (typeof stat.statHash !== "number" || typeof stat.value !== "number") continue;
      parsed.push({ statHash: stat.statHash, value: stat.value });
    }
    if (parsed.length > 0) result[id] = parsed;
  }
  return result;
}

function extractSocketsMap(itemComponents: unknown): Record<string, unknown[]> {
  if (typeof itemComponents !== "object" || itemComponents === null) return {};
  const ic = itemComponents as Record<string, unknown>;
  const sockets = ic.sockets;
  if (typeof sockets !== "object" || sockets === null) return {};
  const s = sockets as Record<string, unknown>;
  if (typeof s.data !== "object" || s.data === null) return {};
  const result: Record<string, unknown[]> = {};
  for (const [id, entry] of Object.entries(s.data as Record<string, unknown>)) {
    if (typeof entry !== "object" || entry === null) continue;
    const e = entry as Record<string, unknown>;
    result[id] = Array.isArray(e.sockets) ? e.sockets : [];
  }
  return result;
}

function parseEquippedItem(
  raw: unknown,
  socketsMap: Record<string, unknown[]>,
): EquippedItemSummary[] {
  if (typeof raw !== "object" || raw === null) return [];
  const item = raw as Record<string, unknown>;
  const bucket = BUCKET_DISPLAY_LABELS[Number(item.bucketHash)];
  if (!bucket) return [];
  const itemHash = Number(item.itemHash);
  const instanceId = typeof item.itemInstanceId === "string" ? item.itemInstanceId : null;
  const plugHashes = instanceId ? parsePlugHashes(socketsMap[instanceId] ?? []) : [];
  return [{ itemHash, bucket, plugHashes }];
}

type InventoryDropReason = "invalid_shape" | "unknown_bucket" | "missing_instance_id";

interface InventoryParseAttempt {
  item: RawInventoryItem | null;
  dropReason: InventoryDropReason | null;
  bucketHash?: number;
}

function parseFullInventoryResponseWithDiagnostics(
  response: unknown,
  membership: DestinyMembership,
): FullInventoryParseResult {
  if (typeof response !== "object" || response === null) {
    throw new Error("Unexpected inventory response shape");
  }
  const res = response as Record<string, unknown>;
  const socketsMap = extractSocketsMap(res.itemComponents);
  const statsMap = extractStatsMap(res.itemComponents);
  const instancesMap = extractInstancesMap(res.itemComponents);
  const items: RawInventoryItem[] = [];
  const diagnostics = createEmptyInventoryDiagnostics(membership);

  const vaultItems = extractItemList(res.profileInventory);
  diagnostics.raw.vault = vaultItems.length;
  for (const raw of vaultItems) {
    recordInventoryParseAttempt(
      parseInventoryItemAttempt(raw, "vault", undefined, socketsMap, instancesMap, statsMap),
      diagnostics,
      items,
    );
  }

  const charInventories = extractCharacterItemSections(res.characterInventories);
  for (const [charId, rawItems] of Object.entries(charInventories)) {
    diagnostics.raw.characterInventories[charId] = rawItems.length;
    diagnostics.raw.characterInventoriesTotal += rawItems.length;
    for (const raw of rawItems) {
      recordInventoryParseAttempt(
        parseInventoryItemAttempt(raw, "character", charId, socketsMap, instancesMap, statsMap),
        diagnostics,
        items,
      );
    }
  }

  const charEquipment = extractCharacterItemSections(res.characterEquipment);
  for (const [charId, rawItems] of Object.entries(charEquipment)) {
    diagnostics.raw.characterEquipment[charId] = rawItems.length;
    diagnostics.raw.characterEquipmentTotal += rawItems.length;
    for (const raw of rawItems) {
      recordInventoryParseAttempt(
        parseInventoryItemAttempt(raw, "equipped", charId, socketsMap, instancesMap, statsMap),
        diagnostics,
        items,
      );
    }
  }

  diagnostics.raw.total =
    diagnostics.raw.vault +
    diagnostics.raw.characterInventoriesTotal +
    diagnostics.raw.characterEquipmentTotal;

  return { items, diagnostics };
}

function createEmptyInventoryDiagnostics(
  membership: DestinyMembership,
): InventoryParseDiagnostics {
  return {
    membership: {
      membershipType: membership.membershipType,
      membershipId: membership.membershipId,
      displayName: membership.displayName,
    },
    raw: {
      vault: 0,
      characterInventories: {},
      characterInventoriesTotal: 0,
      characterEquipment: {},
      characterEquipmentTotal: 0,
      total: 0,
    },
    parsed: {
      total: 0,
      equipmentTotal: 0,
      subclassTotal: 0,
      byLocation: { vault: 0, character: 0, equipped: 0 },
      byBucket: {},
    },
    dropped: {
      total: 0,
      invalidShape: 0,
      unknownBucket: 0,
      missingInstanceId: 0,
      unknownBuckets: {},
    },
  };
}

function recordInventoryParseAttempt(
  attempt: InventoryParseAttempt,
  diagnostics: InventoryParseDiagnostics,
  items: RawInventoryItem[],
): void {
  if (attempt.item) {
    items.push(attempt.item);
    diagnostics.parsed.total += 1;
    diagnostics.parsed.byLocation[attempt.item.location] += 1;
    const bucketLabel = parseBucketLabel(attempt.item.bucketHash);
    diagnostics.parsed.byBucket[bucketLabel] =
      (diagnostics.parsed.byBucket[bucketLabel] ?? 0) + 1;
    if (attempt.item.bucketHash === SUBCLASS_BUCKET_HASH) {
      diagnostics.parsed.subclassTotal += 1;
    } else {
      diagnostics.parsed.equipmentTotal += 1;
    }
    return;
  }

  diagnostics.dropped.total += 1;
  if (attempt.dropReason === "invalid_shape") {
    diagnostics.dropped.invalidShape += 1;
    return;
  }
  if (attempt.dropReason === "missing_instance_id") {
    diagnostics.dropped.missingInstanceId += 1;
    return;
  }
  if (attempt.dropReason === "unknown_bucket" && attempt.bucketHash !== undefined) {
    diagnostics.dropped.unknownBucket += 1;
    const key = String(attempt.bucketHash);
    diagnostics.dropped.unknownBuckets[key] = (diagnostics.dropped.unknownBuckets[key] ?? 0) + 1;
  }
}

function parseInventoryItemAttempt(
  raw: unknown,
  location: InventoryLocation,
  characterId: string | undefined,
  socketsMap: Record<string, unknown[]>,
  instancesMap: Record<string, Record<string, unknown>>,
  statsMap: Record<string, BungieStatEntry[]>,
): InventoryParseAttempt {
  if (typeof raw !== "object" || raw === null) {
    return { item: null, dropReason: "invalid_shape" };
  }
  const item = raw as Record<string, unknown>;
  const bucketHash = Number(item.bucketHash);
  if (!isParsableInventoryBucket(bucketHash)) {
    return { item: null, dropReason: "unknown_bucket", bucketHash };
  }

  const instanceId = typeof item.itemInstanceId === "string" ? item.itemInstanceId : null;
  if (!instanceId) {
    return { item: null, dropReason: "missing_instance_id", bucketHash };
  }

  const instance = instancesMap[instanceId];
  const power = parseItemPower(instance);
  const isMasterwork = parseIsMasterwork(instance);
  const isCrafted = parseIsCrafted(instance);
  const plugHashes = parsePlugHashes(socketsMap[instanceId] ?? []);
  const statValues = isArmorBucketHash(bucketHash)
    ? parseArmorStatValues(statsMap[instanceId])
    : undefined;

  return {
    item: {
      instanceId,
      itemHash: Number(item.itemHash),
      bucketHash,
      location,
      characterId,
      power,
      plugHashes,
      isMasterwork,
      isCrafted,
      statValues: statValues ?? undefined,
    },
    dropReason: null,
  };
}

function extractItemList(section: unknown): unknown[] {
  if (typeof section !== "object" || section === null) return [];
  const s = section as Record<string, unknown>;
  if (typeof s.data !== "object" || s.data === null) return [];
  const data = s.data as Record<string, unknown>;
  return Array.isArray(data.items) ? data.items : [];
}

function extractCharacterItemSections(section: unknown): Record<string, unknown[]> {
  if (typeof section !== "object" || section === null) return {};
  const s = section as Record<string, unknown>;
  if (typeof s.data !== "object" || s.data === null) return {};
  const result: Record<string, unknown[]> = {};
  for (const [charId, entry] of Object.entries(s.data as Record<string, unknown>)) {
    if (typeof entry !== "object" || entry === null) continue;
    const e = entry as Record<string, unknown>;
    result[charId] = Array.isArray(e.items) ? e.items : [];
  }
  return result;
}

function extractInstancesMap(itemComponents: unknown): Record<string, Record<string, unknown>> {
  if (typeof itemComponents !== "object" || itemComponents === null) return {};
  const ic = itemComponents as Record<string, unknown>;
  const instances = ic.instances;
  if (typeof instances !== "object" || instances === null) return {};
  const inst = instances as Record<string, unknown>;
  if (typeof inst.data !== "object" || inst.data === null) return {};
  const result: Record<string, Record<string, unknown>> = {};
  for (const [id, entry] of Object.entries(inst.data as Record<string, unknown>)) {
    if (typeof entry === "object" && entry !== null) {
      result[id] = entry as Record<string, unknown>;
    }
  }
  return result;
}

function parseItemPower(instance: Record<string, unknown> | undefined): number {
  if (!instance) return 0;
  const primaryStat = instance.primaryStat;
  if (typeof primaryStat !== "object" || primaryStat === null) return 0;
  const value = (primaryStat as Record<string, unknown>).value;
  return typeof value === "number" ? value : 0;
}

function parseIsMasterwork(instance: Record<string, unknown> | undefined): boolean {
  if (!instance) return false;
  if (instance.isMasterwork === true) return true;
  const quality = instance.quality;
  if (typeof quality !== "object" || quality === null) return false;
  const tiers = (quality as Record<string, unknown>).versions;
  return Array.isArray(tiers) && tiers.length > 0;
}

function parseIsCrafted(instance: Record<string, unknown> | undefined): boolean {
  if (!instance) return false;
  return instance.isCrafted === true;
}

function parsePlugHashes(sockets: unknown[]): number[] {
  const result: number[] = [];
  for (const sock of sockets) {
    if (typeof sock !== "object" || sock === null) continue;
    const s = sock as Record<string, unknown>;
    if (s.isEnabled === false) continue;
    if (typeof s.plugHash === "number") result.push(s.plugHash);
  }
  return result;
}

export function createBungieProfileClient(): BungieProfileClient | null {
  const config = getBungieOAuthConfig();
  if (!config) return null;
  return new HttpBungieProfileClient({ apiKey: config.apiKey });
}
