/**
 * Mechanical merge of specialist pass outputs into a GeneratedBuild draft.
 * Synthesis pass overlays narrative fields and rationales only.
 */

import type { GeneratedBuild } from "../buildSchema";
import type {
  AbilitiesPassOutput,
  ArmorPassOutput,
  ArtifactPassOutput,
  SynthesisPassOutput,
  WeaponsPassOutput,
} from "./passSchemas";

export interface PassOutputs {
  abilities: AbilitiesPassOutput;
  weapons: WeaponsPassOutput;
  armor: ArmorPassOutput;
  artifact: ArtifactPassOutput;
}

export function mergePasses(outputs: PassOutputs): GeneratedBuild {
  return {
    name: outputs.abilities.name,
    summary: "Pending synthesis.",
    subclass: outputs.abilities.subclass,
    statTargets: outputs.abilities.statTargets,
    exoticArmor: outputs.armor.exoticArmor,
    armor: outputs.armor.armor,
    weapons: outputs.weapons.weapons,
    mods: outputs.armor.mods,
    artifact: outputs.artifact.artifact,
    gameplayLoop: "Pending synthesis.",
    acquisitionNotes: "Pending synthesis.",
  };
}

export function applySynthesis(
  draft: GeneratedBuild,
  synthesis: SynthesisPassOutput,
): GeneratedBuild {
  const next: GeneratedBuild = {
    ...draft,
    name: synthesis.name ?? draft.name,
    summary: synthesis.summary,
    gameplayLoop: synthesis.gameplayLoop,
    acquisitionNotes: synthesis.acquisitionNotes,
    subclass: synthesis.subclass
      ? { ...draft.subclass, rationale: synthesis.subclass.rationale }
      : draft.subclass,
    exoticArmor: synthesis.exoticArmor
      ? { ...draft.exoticArmor, rationale: synthesis.exoticArmor.rationale }
      : draft.exoticArmor,
    armor: synthesis.armor
      ? { ...draft.armor, rationale: synthesis.armor.rationale }
      : draft.armor,
    mods: synthesis.mods
      ? { ...draft.mods, rationale: synthesis.mods.rationale }
      : draft.mods,
    artifact: synthesis.artifact === null
      ? draft.artifact
      : synthesis.artifact && draft.artifact
        ? { ...draft.artifact, rationale: synthesis.artifact.rationale }
        : draft.artifact,
    statTargets: synthesis.statTargets
      ? draft.statTargets.map((target, i) =>
          synthesis.statTargets?.[i]
            ? { ...target, rationale: synthesis.statTargets[i]!.rationale }
            : target,
        )
      : draft.statTargets,
    weapons: synthesis.weapons
      ? draft.weapons.map((weapon, i) =>
          synthesis.weapons?.[i]
            ? { ...weapon, rationale: synthesis.weapons[i]!.rationale }
            : weapon,
        )
      : draft.weapons,
  };
  return next;
}
