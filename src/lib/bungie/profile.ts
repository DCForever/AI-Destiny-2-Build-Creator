import { getBungieOAuthConfig } from "@/lib/config/env";
import type { DestinyClassName } from "@/lib/manifest/types/records";
import type {
  BungieProfileClient,
  CharacterEquipment,
  CharacterSummary,
  DestinyMembership,
  EquippedItemSummary,
} from "./types";

const BUNGIE_BASE = "https://www.bungie.net/Platform";

const CLASS_NAMES: Record<number, DestinyClassName> = {
  0: "Titan",
  1: "Hunter",
  2: "Warlock",
};

const BUCKET_LABELS: Record<number, string> = {
  1498876634: "Kinetic Weapons",
  2465295065: "Energy Weapons",
  953998645: "Power Weapons",
  3448274439: "Helmet",
  3551918588: "Gauntlets",
  14239492: "Chest Armor",
  20886954: "Leg Armor",
  1585787867: "Class Armor",
  3284755031: "Subclass",
};

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
  const bucket = BUCKET_LABELS[Number(item.bucketHash)];
  if (!bucket) return [];
  const itemHash = Number(item.itemHash);
  const instanceId = typeof item.itemInstanceId === "string" ? item.itemInstanceId : null;
  const plugHashes = instanceId ? parsePlugHashes(socketsMap[instanceId] ?? []) : [];
  return [{ itemHash, bucket, plugHashes }];
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
