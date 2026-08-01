import { describe, expect, it } from "vitest";

import { applySynthesis, mergePasses } from "./mergePasses";
import type {
  AbilitiesPassOutput,
  ArmorPassOutput,
  ArtifactPassOutput,
  SynthesisPassOutput,
  WeaponsPassOutput,
} from "./passSchemas";

const abilities: AbilitiesPassOutput = {
  name: "Test Build",
  subclass: {
    name: "Sunbreaker",
    super: "Burning Maul",
    classAbility: "Rally Barricade",
    movement: "Catapult Lift",
    melee: "Hammer Strike",
    grenade: "Healing Grenade",
    aspects: ["Consecration"],
    fragments: ["Ember of Torches"],
    rationale: "sub",
  },
  statTargets: (["Health", "Melee", "Grenade", "Super", "Class", "Weapons"] as const).map(
    (stat) => ({ stat, target: 100, rationale: "stat" }),
  ),
};

const weapons: WeaponsPassOutput = {
  weapons: [
    { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [], rationale: "k" },
    { slot: "Energy", name: "Sunshot", isExotic: true, perks: [], rationale: "e" },
    { slot: "Power", name: "Hothead", isExotic: false, perks: [], rationale: "p" },
  ],
};

const armor: ArmorPassOutput = {
  exoticArmor: { name: "Synthoceps", rationale: "exo", alternatives: [] },
  armor: { archetype: "Brawler", rationale: "arch" },
  mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "mods" },
};

const artifact: ArtifactPassOutput = { artifact: null };

describe("mergePasses", () => {
  it("mechanically merges pass outputs into a draft build", () => {
    const draft = mergePasses({ abilities, weapons, armor, artifact });
    expect(draft.name).toBe("Test Build");
    expect(draft.weapons).toHaveLength(3);
    expect(draft.exoticArmor.name).toBe("Synthoceps");
    expect(draft.summary).toBe("Pending synthesis.");
  });

  it("applySynthesis overlays narrative fields only", () => {
    const draft = mergePasses({ abilities, weapons, armor, artifact });
    const synthesis: SynthesisPassOutput = {
      summary: "Final summary.",
      gameplayLoop: "Loop.",
      acquisitionNotes: "Notes.",
      weapons: [{ rationale: "new k" }, { rationale: "e" }, { rationale: "p" }],
    };
    const build = applySynthesis(draft, synthesis);
    expect(build.summary).toBe("Final summary.");
    expect(build.weapons[0]?.name).toBe("Fatebringer");
    expect(build.weapons[0]?.rationale).toBe("new k");
  });
});
