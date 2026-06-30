/**
 * Minimal structural interfaces for raw Bungie manifest definition shapes.
 * Extractors read `RawTable = Record<string, unknown>` values through these
 * interfaces — no bungie-api-ts import at runtime.
 */

export interface RawDisplayProperties {
  name: string;
  description: string;
  icon?: string;
}

export interface RawPlugEntry {
  plugItemHash: number;
  currentlyCanRoll?: boolean;
}

export interface RawSocketEntry {
  socketTypeHash?: number;
  singleInitialItemHash?: number;
  reusablePlugSetHash?: number;
  randomizedPlugSetHash?: number;
  reusablePlugItems?: RawPlugEntry[];
  defaultVisible?: boolean;
}

export interface RawSocketCategory {
  socketCategoryHash: number;
  socketIndexes: number[];
}

export interface RawSockets {
  socketEntries?: RawSocketEntry[];
  socketCategories?: RawSocketCategory[];
}

export interface RawInventoryBlock {
  tierType?: number;
  bucketTypeHash?: number;
}

export interface RawEquippingBlock {
  equipmentSlotTypeHash?: number;
  ammoType?: number;
}

export interface RawInvestmentStat {
  statTypeHash: number;
  value: number;
  isConditionallyActive?: boolean;
}

export interface RawEnergyCapacity {
  capacityValue?: number;
}

export interface RawEnergyCost {
  energyCost?: number;
}

export interface RawPlugBlock {
  plugCategoryIdentifier?: string;
  energyCost?: RawEnergyCost;
  energyCapacity?: RawEnergyCapacity;
}

export interface RawPerkEntry {
  perkHash?: number;
}

export interface RawInventoryItem {
  hash: number;
  displayProperties: RawDisplayProperties;
  itemType?: number;
  itemTypeDisplayName?: string;
  flavorText?: string;
  classType?: number;
  defaultDamageTypeHash?: number;
  redacted?: boolean;
  inventory?: RawInventoryBlock;
  equippingBlock?: RawEquippingBlock;
  sockets?: RawSockets;
  investmentStats?: RawInvestmentStat[];
  plug?: RawPlugBlock;
  perks?: RawPerkEntry[];
}

export interface RawPlugSet {
  reusablePlugItems?: RawPlugEntry[];
}

export interface RawSandboxPerk {
  hash: number;
  displayProperties: RawDisplayProperties;
  redacted?: boolean;
}

export interface RawDamageType {
  hash: number;
  displayProperties: RawDisplayProperties;
}

export interface RawEquipmentSlot {
  hash: number;
  displayProperties: RawDisplayProperties;
}

export interface RawStatDef {
  hash: number;
  displayProperties: RawDisplayProperties;
  redacted?: boolean;
}

export interface RawArtifactTierItem {
  itemHash: number;
}

export interface RawArtifactTier {
  items: RawArtifactTierItem[];
}

export interface RawArtifact {
  hash: number;
  displayProperties: RawDisplayProperties;
  tiers: RawArtifactTier[];
  redacted?: boolean;
}

export interface RawSetPerk {
  requiredSetCount: number;
  sandboxPerkHash: number;
}

export interface RawItemSet {
  hash: number;
  displayProperties: RawDisplayProperties;
  setItems: number[];
  setPerks: RawSetPerk[];
  redacted?: boolean;
}

// ─── Type-narrowing helpers ────────────────────────────────────────────────

function hasNumberHash(v: unknown): v is { hash: number } {
  return (
    typeof v === "object" &&
    v !== null &&
    typeof (v as Record<string, unknown>).hash === "number"
  );
}

function hasDisplayProperties(v: unknown): boolean {
  if (typeof v !== "object" || v === null) return false;
  const dp = (v as Record<string, unknown>).displayProperties;
  return (
    typeof dp === "object" &&
    dp !== null &&
    typeof (dp as Record<string, unknown>).name === "string"
  );
}

function hasHashAndDisplay(v: unknown): boolean {
  return hasNumberHash(v) && hasDisplayProperties(v);
}

export function asRawInventoryItem(v: unknown): RawInventoryItem | null {
  if (!hasHashAndDisplay(v)) return null;
  return v as RawInventoryItem;
}

export function asRawPlugSet(v: unknown): RawPlugSet | null {
  if (typeof v !== "object" || v === null) return null;
  return v as RawPlugSet;
}

export function asRawSandboxPerk(v: unknown): RawSandboxPerk | null {
  if (!hasHashAndDisplay(v)) return null;
  return v as RawSandboxPerk;
}

export function asRawDamageType(v: unknown): RawDamageType | null {
  if (!hasHashAndDisplay(v)) return null;
  return v as RawDamageType;
}

export function asRawEquipmentSlot(v: unknown): RawEquipmentSlot | null {
  if (!hasHashAndDisplay(v)) return null;
  return v as RawEquipmentSlot;
}

export function asRawStatDef(v: unknown): RawStatDef | null {
  if (!hasHashAndDisplay(v)) return null;
  return v as RawStatDef;
}

export function asRawArtifact(v: unknown): RawArtifact | null {
  if (!hasHashAndDisplay(v)) return null;
  if (!Array.isArray((v as Record<string, unknown>).tiers)) return null;
  return v as RawArtifact;
}

export function asRawItemSet(v: unknown): RawItemSet | null {
  if (!hasHashAndDisplay(v)) return null;
  const s = v as Record<string, unknown>;
  if (!Array.isArray(s.setItems) || !Array.isArray(s.setPerks)) return null;
  return v as RawItemSet;
}
