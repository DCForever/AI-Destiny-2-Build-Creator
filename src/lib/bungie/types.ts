/**
 * Contracts for the Bungie OAuth + profile import layer. OAuth is strictly
 * optional: when env config or the session secret is missing, auth routes
 * return 503 and the rest of the app keeps working.
 */

import type { DestinyClassName } from "@/lib/manifest/types/records";

/** Stored inside the encrypted iron-session cookie. */
export interface BungieTokens {
  accessToken: string;
  refreshToken: string;
  /** Epoch milliseconds when the access token expires. */
  expiresAt: number;
  /** Epoch milliseconds when the refresh token expires. */
  refreshExpiresAt: number;
  bungieMembershipId: string;
}

export interface SessionData {
  tokens?: BungieTokens;
  /** CSRF state for the in-flight OAuth redirect. */
  oauthState?: string;
}

export interface DestinyMembership {
  membershipType: number;
  membershipId: string;
  displayName: string;
}

export interface CharacterSummary {
  characterId: string;
  classType: DestinyClassName;
  light: number;
  emblemPath: string | null;
  dateLastPlayed: string;
}

export interface EquippedItemSummary {
  itemHash: number;
  /** Equipment bucket display label (e.g. "Kinetic Weapons", "Helmet"). */
  bucket: string;
  /** Plug hashes from item sockets (perks, aspects, fragments, mods). */
  plugHashes: number[];
}

export interface CharacterEquipment {
  character: CharacterSummary;
  items: EquippedItemSummary[];
}

/** Token + profile operations, implemented over fetch with injected deps. */
export interface BungieAuthClient {
  buildAuthorizeUrl(state: string): string;
  exchangeCode(code: string): Promise<BungieTokens>;
  refreshTokens(tokens: BungieTokens): Promise<BungieTokens>;
}

export interface BungieProfileClient {
  getMemberships(accessToken: string): Promise<DestinyMembership[]>;
  getCharacters(
    accessToken: string,
    membership: DestinyMembership,
  ): Promise<CharacterSummary[]>;
  getCharacterEquipment(
    accessToken: string,
    membership: DestinyMembership,
    characterId: string,
  ): Promise<CharacterEquipment>;
}
