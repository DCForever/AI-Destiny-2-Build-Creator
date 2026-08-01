import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import type { ResolvedArtifact, ResolvedFashion } from "@/lib/builds/resolveArtifactFashion";
import type { ResolvedVariantEquipment } from "@/lib/builds/resolveVariant";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import {
  DIM_CLASS_TYPE,
  DIM_STAT_HASHES,
  type DimLoadout,
  type DimLoadoutItem,
  type DimLoadoutParameters,
  type DimStatConstraint,
} from "@/lib/dim/dimLoadout";

const COMBAT_SLOTS: EquipmentSlot[] = [
  "primary",
  "special",
  "heavy",
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
];

export type VariantDimLoadoutInput = {
  buildName: string;
  className: "Titan" | "Hunter" | "Warlock";
  variantName?: string | null;
  subclass?: unknown;
  softStatTargets?: SoftStatTargets;
  equipment: ResolvedVariantEquipment["equipment"];
  artifact: ResolvedArtifact;
  fashion: ResolvedFashion;
  modHashes: number[];
};

function subclassNote(subclass: unknown): string | null {
  if (!subclass || typeof subclass !== "object") return null;
  const s = subclass as Record<string, unknown>;
  const name = typeof s.name === "string" ? s.name : null;
  const superName = typeof s.super === "string" ? s.super : null;
  if (!name && !superName) return null;
  return `Subclass: ${[name, superName].filter(Boolean).join(" / ")}`;
}

function artifactNote(artifact: ResolvedArtifact): string | null {
  if (!artifact) return null;
  const config = artifact.config.length ? ` unlocks=[${artifact.config.join(",")}]` : "";
  return `Artifact: ${artifact.name} (${artifact.hash})${config}`;
}

function softStatConstraints(targets: SoftStatTargets | undefined): DimStatConstraint[] {
  if (!targets) return [];
  const out: DimStatConstraint[] = [];
  for (const [stat, minStat] of Object.entries(targets)) {
    const statHash = DIM_STAT_HASHES[stat];
    if (statHash == null || minStat == null) continue;
    out.push({ statHash, minStat });
  }
  return out.sort((a, b) => (b.minStat ?? 0) - (a.minStat ?? 0));
}

function buildEquipped(equipment: ResolvedVariantEquipment["equipment"]): DimLoadoutItem[] {
  const items: DimLoadoutItem[] = [];
  for (const slot of COMBAT_SLOTS) {
    const claim = equipment[slot];
    if (!claim) continue;
    const item: DimLoadoutItem = { hash: claim.itemHash };
    if (claim.instanceId) item.id = claim.instanceId;
    if (claim.selectedPerks?.length) {
      const overrides: Record<number, number> = {};
      claim.selectedPerks.forEach((perk, index) => {
        overrides[index] = perk;
      });
      item.socketOverrides = overrides;
    }
    items.push(item);
  }
  return items;
}

function buildUnequipped(fashion: ResolvedFashion): DimLoadoutItem[] {
  if (!fashion) return [];
  const items: DimLoadoutItem[] = [];
  for (const piece of Object.values(fashion.slots)) {
    if (!piece) continue;
    items.push({ hash: piece.itemHash });
  }
  return items;
}

function buildNotes(input: VariantDimLoadoutInput): string | undefined {
  const parts = [subclassNote(input.subclass), artifactNote(input.artifact)].filter(Boolean);
  if (parts.length === 0) return undefined;
  return parts.join("\n").slice(0, 1024);
}

function buildParameters(input: VariantDimLoadoutInput): DimLoadoutParameters {
  const params: DimLoadoutParameters = {
    autoStatMods: true,
    includeRuntimeStatBenefits: true,
  };
  if (input.modHashes.length > 0) params.mods = [...input.modHashes];
  const constraints = softStatConstraints(input.softStatTargets);
  if (constraints.length > 0) params.statConstraints = constraints;

  for (const slot of COMBAT_SLOTS) {
    const claim = input.equipment[slot];
    if (claim?.source === "build_exotic_armor") {
      params.exoticArmorHash = claim.itemHash;
      break;
    }
  }
  return params;
}

/** Map resolved variant (+ mods/soft stats) into a DIM Sync loadout. */
export function buildVariantDimLoadout(input: VariantDimLoadoutInput): DimLoadout {
  const name = (input.variantName
    ? `${input.buildName} — ${input.variantName}`
    : input.buildName
  ).slice(0, 120);

  return {
    id: crypto.randomUUID(),
    name,
    notes: buildNotes(input),
    classType: DIM_CLASS_TYPE[input.className],
    equipped: buildEquipped(input.equipment),
    unequipped: buildUnequipped(input.fashion),
    parameters: buildParameters(input),
  };
}
