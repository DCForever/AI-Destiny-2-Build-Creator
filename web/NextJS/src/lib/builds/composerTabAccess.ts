import type { ComposerTab } from "@/components/build/composer/types";

export type ComposerTabAccessInput = {
  tab: ComposerTab;
  className: string | null | undefined;
  subclassName: string | null | undefined;
  buildId: string | null | undefined;
};

export type ComposerTabAccessResult = {
  allowed: boolean;
  reason?: string;
  /** Attach/create/optimize-apply need a persisted build. */
  mutationsAllowed: boolean;
  mutationReason?: string;
};

function hasText(v: string | null | undefined): boolean {
  return Boolean(v && String(v).trim());
}

/**
 * FR-022 navigation gates + separate mutation gate (tab open ≠ attach).
 */
export function composerTabAccess(input: ComposerTabAccessInput): ComposerTabAccessResult {
  const classOk = hasText(input.className);
  const subclassOk = hasText(input.subclassName);
  const buildOk = hasText(input.buildId);

  let allowed = true;
  let reason: string | undefined;

  switch (input.tab) {
    case "general":
    case "finish":
      allowed = true;
      break;
    case "subclass":
      if (!classOk) {
        allowed = false;
        reason = "Set class on General first";
      } else if (!subclassOk) {
        allowed = false;
        reason = "Set subclass on General first";
      }
      break;
    case "armor":
    case "weapon":
      if (!classOk) {
        allowed = false;
        reason = "Set class on General first";
      }
      break;
    default:
      allowed = false;
      reason = "Unknown tab";
  }

  const mutationsAllowed = buildOk;
  const mutationReason = buildOk ? undefined : "Save General to create the build before attaching sets";

  return { allowed, reason, mutationsAllowed, mutationReason };
}
