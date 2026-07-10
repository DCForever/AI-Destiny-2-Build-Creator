import type { ArmorStatName } from "@/data/rules/statBenefits";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
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

export function suggestStatNudges(synergies: SynergyWithLinks[]): StatNudge[] {
  const byStat = new Map<ArmorStatName, StatNudge>();
  for (const synergy of synergies) {
    const key = synergy.type.toLowerCase();
    const stat = TYPE_TO_STAT[key];
    if (!stat) continue;
    const existing = byStat.get(stat);
    if (existing) continue;
    byStat.set(stat, {
      stat,
      suggested: DEFAULT_SUGGESTED,
      reason: `Designated synergy "${synergy.name}" (${synergy.type})`,
      synergyId: synergy.id,
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
