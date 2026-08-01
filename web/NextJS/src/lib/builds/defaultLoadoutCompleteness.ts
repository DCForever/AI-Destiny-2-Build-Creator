/**
 * Default variant composition completeness (DBR-CMPL-001, DBR-SUB-006–007, DBR-ART-003a).
 * Equipment slots are checked separately; this covers subclass kit bar + artifact fill.
 */

import { MAX_SUBCLASS_ASPECTS } from "@/lib/builds/destinyBuildConstraints";

export type SubclassKitFields = {
  name?: string | null;
  super?: string | null;
  melee?: string | null;
  grenade?: string | null;
  classAbility?: string | null;
  movement?: string | null;
  aspects?: string[] | null;
  fragments?: string[] | null;
};

function nonEmpty(value: string | null | undefined): boolean {
  return typeof value === "string" && value.trim().length > 0;
}

function cleanList(values: string[] | null | undefined): string[] {
  return (values ?? []).filter((v) => typeof v === "string" && v.trim().length > 0);
}

/**
 * Gaps for default-complete subclass kit (DBR-SUB-006).
 * Class ability / movement are not required (DBR-SUB-007).
 */
export function collectSubclassKitCompleteGaps(
  kit: SubclassKitFields | null | undefined,
  opts?: {
    maxAspects?: number;
    /** Sum of fragment capacity from selected aspects. */
    fragmentCapacity?: number;
    /** False when aspect capacities could not be resolved from data. */
    capacityResolved?: boolean;
  },
): string[] {
  const missing: string[] = [];
  if (!kit || typeof kit !== "object") {
    missing.push("subclass");
    return missing;
  }
  if (!nonEmpty(kit.name)) missing.push("subclass");

  if (!nonEmpty(kit.super)) missing.push("super");
  if (!nonEmpty(kit.melee)) missing.push("melee");
  if (!nonEmpty(kit.grenade)) missing.push("grenade");

  const maxAspects = opts?.maxAspects ?? MAX_SUBCLASS_ASPECTS;
  const aspects = cleanList(kit.aspects);
  if (aspects.length < maxAspects) {
    missing.push("aspects");
  }

  const fragments = cleanList(kit.fragments);
  const capacityResolved = opts?.capacityResolved !== false;
  const fragmentCapacity = opts?.fragmentCapacity ?? 0;

  if (capacityResolved) {
    // With aspects filled, capacity should be known and fragments must fill it.
    if (aspects.length >= maxAspects) {
      if (fragmentCapacity <= 0) {
        // Aspects did not resolve capacity — still require at least one fragment signal
        // only when capacity is known; if capacity is 0 with full aspects, data gap:
        // treat as incomplete fragments only when capacity > 0.
      } else if (fragments.length < fragmentCapacity) {
        missing.push("fragments");
      }
    }
  } else if (aspects.length >= maxAspects && fragments.length === 0) {
    // Capacity unknown: require some fragments when aspects are filled (soft data path).
    missing.push("fragments");
  }

  return missing;
}

/**
 * Gaps for default artifact fill (DBR-ART-003a / DBR-CMPL-001a).
 * Selection alone is not enough — config must be non-empty.
 */
export function collectArtifactCompleteGaps(input: {
  artifactHash?: number | null;
  artifactConfig?: number[] | null;
}): string[] {
  const missing: string[] = [];
  if (input.artifactHash == null) {
    missing.push("artifact");
    return missing;
  }
  const config = (input.artifactConfig ?? []).filter(
    (h) => typeof h === "number" && Number.isFinite(h),
  );
  if (config.length === 0) {
    missing.push("artifactConfig");
  }
  return missing;
}

export function isSubclassKitCompositionComplete(
  kit: SubclassKitFields | null | undefined,
  opts?: Parameters<typeof collectSubclassKitCompleteGaps>[1],
): boolean {
  return collectSubclassKitCompleteGaps(kit, opts).length === 0;
}

export function isArtifactCompositionComplete(input: {
  artifactHash?: number | null;
  artifactConfig?: number[] | null;
}): boolean {
  return collectArtifactCompleteGaps(input).length === 0;
}
