import { ARMOR_SLOTS, WEAPON_SLOTS, type SetType } from "@/lib/sets/schemas";

export type FinishCategory = "armor" | "weapon" | "mod";

export type FinishGapStatus =
  | "satisfied"
  | "needs_set"
  | "needs_fill"
  | "capture_available";

export type FinishAttachmentInput = {
  setId: string;
  mode: "live" | "snapshot";
  setType: SetType;
  setName?: string;
};

export type FinishEquipmentClaim = {
  slot: string;
  itemHash: number;
  itemName: string;
  instanceId?: string | null;
};

export type FinishGap = {
  category: FinishCategory;
  status: FinishGapStatus;
  coveringSetId: string | null;
  coveringSetName: string | null;
  coveringMode: "live" | "snapshot" | null;
  emptySlots: string[];
  filledSlotCount: number;
  requiredSlotCount: number;
  resolvedClaimCount: number;
  canCapture: boolean;
};

export type FinishGapsResult = {
  variantId: string;
  isDefaultVariant: boolean;
  complete: boolean;
  gaps: FinishGap[];
  nextActionable: FinishGap | null;
};

export type EvaluateFinishGapsInput = {
  variantId: string;
  isDefaultVariant: boolean;
  attachments: FinishAttachmentInput[];
  equipment: Partial<Record<string, FinishEquipmentClaim | null | undefined>>;
  /** When true, mod category can be satisfied without a mod-type set. */
  hasModCoverage?: boolean;
  /**
   * Session skip keys (`armor`, `weapon`, `mod`, or `armor:helmet`).
   * Does not change status; used only for nextActionable preference.
   */
  skippedKeys?: readonly string[];
};

const CATEGORY_ORDER: FinishCategory[] = ["armor", "weapon", "mod"];

const REQUIRED_SLOTS: Record<FinishCategory, readonly string[]> = {
  armor: ARMOR_SLOTS,
  weapon: WEAPON_SLOTS,
  mod: [],
};

function coveringFor(
  attachments: FinishAttachmentInput[],
  category: FinishCategory,
): FinishAttachmentInput | null {
  const type = category as SetType;
  const matches = attachments.filter((a) => a.setType === type);
  if (matches.length === 0) return null;
  return matches.find((a) => a.mode === "live") ?? matches[0] ?? null;
}

function slotFilled(
  equipment: EvaluateFinishGapsInput["equipment"],
  slot: string,
): boolean {
  const claim = equipment[slot];
  return Boolean(claim && Number.isFinite(claim.itemHash) && claim.itemHash > 0);
}

function claimsInSlots(
  equipment: EvaluateFinishGapsInput["equipment"],
  slots: readonly string[],
): number {
  let n = 0;
  for (const slot of slots) {
    if (slotFilled(equipment, slot)) n += 1;
  }
  return n;
}

function evaluateCategory(
  category: FinishCategory,
  input: EvaluateFinishGapsInput,
): FinishGap {
  const covering = coveringFor(input.attachments, category);
  const required = REQUIRED_SLOTS[category];

  if (category === "mod") {
    const hasSet = covering != null;
    const soft = Boolean(input.hasModCoverage);
    const satisfied = hasSet || soft;
    // create-from-build currently skips mod snapshot — never canCapture for mod
    return {
      category,
      status: satisfied ? "satisfied" : "needs_set",
      coveringSetId: covering?.setId ?? null,
      coveringSetName: covering?.setName ?? null,
      coveringMode: covering?.mode ?? null,
      emptySlots: [],
      filledSlotCount: satisfied ? 1 : 0,
      requiredSlotCount: 1,
      resolvedClaimCount: 0,
      canCapture: false,
    };
  }

  const emptySlots = required.filter((s) => !slotFilled(input.equipment, s));
  const filledSlotCount = required.length - emptySlots.length;
  const resolvedClaimCount = claimsInSlots(input.equipment, required);
  const hasCovering = covering != null;

  let status: FinishGapStatus;
  if (hasCovering && emptySlots.length === 0) {
    status = "satisfied";
  } else if (hasCovering && emptySlots.length > 0) {
    status = "needs_fill";
  } else if (!hasCovering && resolvedClaimCount > 0) {
    status = "capture_available";
  } else {
    status = "needs_set";
  }

  return {
    category,
    status,
    coveringSetId: covering?.setId ?? null,
    coveringSetName: covering?.setName ?? null,
    coveringMode: covering?.mode ?? null,
    emptySlots,
    filledSlotCount,
    requiredSlotCount: required.length,
    resolvedClaimCount,
    canCapture: status === "capture_available",
  };
}

/**
 * Pure finish-gap evaluation for Builds guided walkthrough.
 * Category order: armor → weapon → mod.
 * Satisfied requires covering set + required slots filled (mod: set or hasModCoverage).
 */
export function evaluateFinishGaps(input: EvaluateFinishGapsInput): FinishGapsResult {
  const gaps = CATEGORY_ORDER.map((c) => evaluateCategory(c, input));
  const complete = gaps.every((g) => g.status === "satisfied");
  const skipped = new Set(input.skippedKeys ?? []);

  const nextActionable =
    gaps.find((g) => g.status !== "satisfied" && !skipped.has(g.category)) ??
    gaps.find((g) => g.status !== "satisfied") ??
    null;

  return {
    variantId: input.variantId,
    isDefaultVariant: input.isDefaultVariant,
    complete,
    gaps,
    nextActionable,
  };
}

export function finishCategoryLabel(category: FinishCategory): string {
  switch (category) {
    case "armor":
      return "Armor";
    case "weapon":
      return "Weapons";
    case "mod":
      return "Mods";
  }
}
