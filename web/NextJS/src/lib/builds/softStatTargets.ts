import { ARMOR_STAT_NAMES, STAT_MAX, type ArmorStatName } from "@/data/rules/statBenefits";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";

export type SoftStatTargets = Partial<Record<ArmorStatName, number>>;

/** UI draft: empty string = unset for that stat. */
export type SoftStatDraft = Record<ArmorStatName, string>;

export function parseSoftStatTargets(raw: string | null | undefined): SoftStatTargets {
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return {};
    return normalizeSoftStatTargets(parsed as Record<string, unknown>);
  } catch {
    return {};
  }
}

export function serializeSoftStatTargets(targets: SoftStatTargets): string {
  return JSON.stringify(targets);
}

export function emptySoftStatDraft(): SoftStatDraft {
  return {
    Health: "",
    Melee: "",
    Grenade: "",
    Super: "",
    Class: "",
    Weapons: "",
  };
}

/** Map stored targets into per-stat draft strings for structured editors. */
export function softStatDraftFromTargets(
  targets: SoftStatTargets | null | undefined,
): SoftStatDraft {
  const draft = emptySoftStatDraft();
  if (!targets) return draft;
  for (const name of ARMOR_STAT_NAMES) {
    const value = targets[name];
    if (value != null) draft[name] = String(value);
  }
  return draft;
}

/**
 * Convert structured editor draft → SoftStatTargets payload.
 * Empty/whitespace fields are omitted (cleared). Invalid entries throw ApiError
 * via normalizeSoftStatTargets (same path as the build API).
 */
export function softStatTargetsFromDraft(draft: SoftStatDraft): SoftStatTargets {
  const raw: Record<string, unknown> = {};
  for (const name of ARMOR_STAT_NAMES) {
    const text = (draft[name] ?? "").trim();
    if (!text) continue;
    const n = Number(text);
    if (!Number.isFinite(n)) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_ITEM,
        `softStatTargets.${name} must be an integer`,
      );
    }
    raw[name] = Math.trunc(n);
  }
  return normalizeSoftStatTargets(raw);
}

/** Clamp a numeric draft string into 1..STAT_MAX (or empty). */
export function clampSoftStatDraftValue(raw: string): string {
  const text = raw.trim();
  if (!text) return "";
  const n = Number(text);
  if (!Number.isFinite(n)) return text;
  const clamped = Math.min(STAT_MAX, Math.max(1, Math.trunc(n)));
  return String(clamped);
}

export function normalizeSoftStatTargets(input: Record<string, unknown> | SoftStatTargets): SoftStatTargets {
  const out: SoftStatTargets = {};
  for (const name of ARMOR_STAT_NAMES) {
    if (!(name in input)) continue;
    const value = (input as Record<string, unknown>)[name];
    if (value == null) continue;
    if (typeof value !== "number" || !Number.isInteger(value)) {
      throw new ApiError(API_ERROR_CODES.INVALID_ITEM, `softStatTargets.${name} must be an integer`);
    }
    if (value < 1 || value > STAT_MAX) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_ITEM,
        `softStatTargets.${name} must be between 1 and ${STAT_MAX}`,
      );
    }
    out[name] = value;
  }
  for (const key of Object.keys(input)) {
    if (!(ARMOR_STAT_NAMES as readonly string[]).includes(key)) {
      throw new ApiError(API_ERROR_CODES.INVALID_ITEM, `Unknown soft stat "${key}"`);
    }
  }
  return out;
}

export function mergeSoftStatTargets(
  existing: SoftStatTargets,
  incoming: SoftStatTargets,
): SoftStatTargets {
  const out: SoftStatTargets = { ...existing };
  for (const name of ARMOR_STAT_NAMES) {
    const next = incoming[name];
    if (next == null) continue;
    const prev = out[name];
    out[name] = prev == null ? next : Math.max(prev, next);
  }
  return out;
}
