import type { SynergyType } from "@/lib/synergies/schemas";

export type NormalizedSynergyType = {
  type: SynergyType;
  subType: string | null;
};

export function normalizeLegacySynergyType(
  type: SynergyType,
  subType?: string | null,
): NormalizedSynergyType {
  switch (type) {
    case "kinetic_weapon":
      return { type: "element", subType: "Kinetic" };
    case "damage":
      return { type: "dps", subType: null };
    default:
      return { type, subType: subType ?? null };
  }
}
