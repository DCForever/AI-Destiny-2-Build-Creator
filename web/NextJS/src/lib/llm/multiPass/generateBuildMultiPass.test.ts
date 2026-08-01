import { describe, expect, it, vi } from "vitest";

import type { BuildRequest } from "../buildSchema";
import { generateBuildMultiPass } from "./generateBuildMultiPass";
import type {
  AbilitiesPassOutput,
  ArmorPassOutput,
  ArtifactPassOutput,
  SynthesisPassOutput,
  WeaponsPassOutput,
} from "./passSchemas";
import type { ChatMessage, ChatOptions, ChatResponse, LlmClient } from "../llmClient";
import type { ToolExecutor } from "../toolTypes";

const request: BuildRequest = {
  className: "Titan",
  subclass: "Sunbreaker",
  activity: "Grandmaster Nightfall",
  playstyle: "aggressive melee",
  generationMode: "multi-pass",
};

function abilitiesOutput(): AbilitiesPassOutput {
  return {
    name: "Hammer Forge",
    subclass: {
      name: "Sunbreaker",
      super: "Burning Maul",
      classAbility: "Rally Barricade",
      movement: "Catapult Lift",
      melee: "Hammer Strike",
      grenade: "Healing Grenade",
      aspects: ["Consecration"],
      fragments: ["Ember of Torches"],
      rationale: "Melee engine.",
    },
    statTargets: (["Health", "Melee", "Grenade", "Super", "Class", "Weapons"] as const).map(
      (stat) => ({ stat, target: 100, rationale: "r" }),
    ),
  };
}

function weaponsOutput(): WeaponsPassOutput {
  return {
    weapons: [
      { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [], rationale: "r" },
      { slot: "Energy", name: "Sunshot", isExotic: true, perks: [], rationale: "r" },
      { slot: "Power", name: "The Hothead", isExotic: false, perks: [], rationale: "r" },
    ],
  };
}

function armorOutput(): ArmorPassOutput {
  return {
    exoticArmor: { name: "Synthoceps", rationale: "r", alternatives: [] },
    armor: { archetype: "Brawler", rationale: "r" },
    mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "r" },
  };
}

function artifactOutput(): ArtifactPassOutput {
  return { artifact: null };
}

function synthesisOutput(): SynthesisPassOutput {
  return {
    summary: "A hammer-centric GM build.",
    gameplayLoop: "Throw hammer, punch, repeat.",
    acquisitionNotes: "Farm Synthoceps from Xur.",
  };
}

function assistantMessage(content: string): ChatResponse {
  return { message: { role: "assistant", content }, done: true };
}

function scriptedMultiPassClient(): {
  client: LlmClient;
  composeCallCount: number;
} {
  const composeReplies = [
    JSON.stringify(abilitiesOutput()),
    JSON.stringify(weaponsOutput()),
    JSON.stringify(armorOutput()),
    JSON.stringify(artifactOutput()),
    JSON.stringify(synthesisOutput()),
  ];
  let composeIndex = 0;

  const client: LlmClient = {
    chat: vi.fn(async (messages: ChatMessage[], options?: ChatOptions) => {
      if (options?.tools) return assistantMessage("research done");
      const reply = composeReplies[Math.min(composeIndex, composeReplies.length - 1)];
      composeIndex += 1;
      return assistantMessage(reply);
    }),
    listModels: vi.fn(async () => []),
    healthCheck: vi.fn(async () => ({ healthy: true, detail: "" })),
  };

  return { client, composeCallCount: 0 };
}

const noopExecutor: ToolExecutor = { execute: vi.fn(async () => ({})) };

describe("generateBuildMultiPass", () => {
  it("runs five compose passes and merges into a full build", async () => {
    const { client } = scriptedMultiPassClient();
    const result = await generateBuildMultiPass(request, { client, executor: noopExecutor });

    expect(result.build.name).toBe("Hammer Forge");
    expect(result.build.summary).toBe("A hammer-centric GM build.");
    expect(result.build.weapons).toHaveLength(3);
    expect(result.build.weapons[0]?.name).toBe("Fatebringer");
    expect(result.researchSummary).toContain("Abilities:");
    expect(result.researchSummary).toContain("Synthesis:");
  });

  it("invokes compose with schema format for each pass", async () => {
    const { client } = scriptedMultiPassClient();
    await generateBuildMultiPass(request, { client, executor: noopExecutor });

    const chatMock = vi.mocked(client.chat);
    const composeCalls = chatMock.mock.calls.filter(([, opts]) => opts?.format && !opts?.tools);
    expect(composeCalls.length).toBe(5);
    expect(composeCalls.every(([, opts]) => opts?.format !== undefined)).toBe(true);
  });
});
