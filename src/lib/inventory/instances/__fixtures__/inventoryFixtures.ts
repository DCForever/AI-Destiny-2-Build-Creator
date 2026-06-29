import type { UserInventoryItem } from "@/lib/db/types";

const SYNCED_AT = "2026-06-28T12:00:00.000Z";

export const funnelCopyVault: UserInventoryItem = {
  instanceId: "inst-vault-1",
  itemHash: 1363886209,
  bucket: "Kinetic",
  location: "vault",
  power: 1810,
  isMasterwork: true,
  isCrafted: false,
  plugHashes: [1001, 2001, 3001],
  rollTags: [],
  syncedAt: SYNCED_AT,
};

export const funnelCopyCharacter: UserInventoryItem = {
  instanceId: "inst-char-1",
  itemHash: 1363886209,
  bucket: "Kinetic",
  location: "character",
  characterId: "char-warlock",
  power: 1805,
  isMasterwork: false,
  isCrafted: true,
  plugHashes: [1001, 2002],
  rollTags: ["Crafted"],
  syncedAt: SYNCED_AT,
};

export const helmetCopy: UserInventoryItem = {
  instanceId: "inst-helm-1",
  itemHash: 99887766,
  bucket: "Helmet",
  location: "equipped",
  characterId: "char-titan",
  power: 1815,
  isMasterwork: true,
  isCrafted: false,
  plugHashes: [5001],
  rollTags: [],
  syncedAt: SYNCED_AT,
};

export const subclassItem: UserInventoryItem = {
  instanceId: "inst-sub",
  itemHash: 111,
  bucket: "Subclass",
  location: "character",
  characterId: "char-titan",
  power: 0,
  isMasterwork: false,
  isCrafted: false,
  plugHashes: [],
  rollTags: [],
  syncedAt: SYNCED_AT,
};

export const samplePlugNameMap = new Map<number, string>([
  [1001, "Subsistence"],
  [2001, "Frenzy"],
  [2002, "Rampage"],
  [3001, "Arrowhead Brake"],
  [5001, "Solar Mod"],
  [9999999999, "Unknown"],
]);
