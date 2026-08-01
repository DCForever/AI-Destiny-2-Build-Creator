import type { ArmorStatName } from "@/data/rules/statBenefits";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import type { SynergyTypeDesignation } from "@/lib/builds/resolveDesignatedSynergies";
import { designationKey, designationLabel } from "@/lib/builds/resolveDesignatedSynergies";
import type { SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";

export type StatNudge = {
  stat: ArmorStatName;
  suggested: number;
  reason: string;
  synergyId?: string;
};

const TYPE_TO_STAT: Record<string, ArmorStatName> = {
  melee: "Melee",
  grenade: "Grenade",
  super: "Super",
  class: "Class",
  ability: "Class",
  weapons: "Weapons",
  weapon: "Weapons",
  health: "Health",
  survivability: "Health",
};

const DEFAULT_SUGGESTED = 100;

export function suggestStatNudges(
  designations: SynergyTypeDesignation[],
  _matched: SynergyWithLinks[] = [],
): StatNudge[] {
  void _matched;
  const byStat = new Map<ArmorStatName, StatNudge>();
  for (const designation of designations) {
    const key = designation.type.toLowerCase();
    const stat = TYPE_TO_STAT[key];
    if (!stat) continue;
    if (byStat.has(stat)) continue;
    const label = designationLabel(designation);
    byStat.set(stat, {
      stat,
      suggested: DEFAULT_SUGGESTED,
      reason: `Designated synergy type "${label}" (${designation.type})`,
      synergyId: designationKey(designation),
    });
  }
  return [...byStat.values()];
}

export function targetsFromAcceptedNudges(
  existing: SoftStatTargets,
  nudges: StatNudge[],
): SoftStatTargets {
  const out: SoftStatTargets = { ...existing };
  for (const nudge of nudges) {
    const prev = out[nudge.stat];
    out[nudge.stat] = prev == null ? nudge.suggested : Math.max(prev, nudge.suggested);
  }
  return out;
}
