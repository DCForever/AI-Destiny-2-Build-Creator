import { describe, expect, it, vi } from "vitest";

import { analyzeLoadout } from "./analyzeLoadout";
import type { AnalyzeRequest, LoadoutAnalysis } from "./analyzeSchema";
import type { GeneratedBuild } from "./buildSchema";
import type { ChatMessage, ChatOptions, ChatResponse, OllamaClient } from "./ollamaClient";
import type { ToolExecutor } from "./toolTypes";

const request: AnalyzeRequest = {
  className: "Hunter",
  activity: "Grandmaster Nightfall",
  loadoutText: "Subclass: Nightstalker\nKinetic: Fatebringer\nExotic: Orpheus Rig",
};

function validBuild(): GeneratedBuild {
  return {
    name: "Optimized Tether",
    summary: "Tether uptime engine.",
    subclass: {
      name: "Nightstalker",
      super: "Shadowshot: Deadfall",
      classAbility: "Gambler's Dodge",
      movement: "Triple Jump",
      melee: "Snare Bomb",
      grenade: "Vortex Grenade",
      aspects: ["Vanishing Step"],
      fragments: ["Echo of Persistence"],
      rationale: "r",
    },
    statTargets: (["Health", "Melee", "Grenade", "Super", "Class", "Weapons"] as const).map(
      (stat) => ({ stat, target: 100, rationale: "r" }),
    ),
    exoticArmor: { name: "Orpheus Rig", rationale: "r", alternatives: [] },
    armor: { archetype: "Paragon", rationale: "r" },
    weapons: [
      { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [], rationale: "r" },
      { slot: "Energy", name: "Sunshot", isExotic: true, perks: [], rationale: "r" },
      { slot: "Power", name: "The Hothead", isExotic: false, perks: [], rationale: "r" },
    ],
    mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "r" },
    artifact: null,
    gameplayLoop: "Loop.",
    acquisitionNotes: "Notes.",
  };
}

function validAnalysis(): LoadoutAnalysis {
  return {
    assessment: "Solid foundation but no Barrier counter for this Grandmaster.",
    strengths: ["Orpheus Rig super loop holds up in 9.7.0"],
    gaps: ["No Barrier champion coverage across the three weapons"],
    swaps: [
      { replace: "Sunshot", with: "Polaris Lance", rationale: "Barrier via frame" },
    ],
    optimizedBuild: validBuild(),
  };
}

function assistantMessage(content: string): ChatResponse {
  return { message: { role: "assistant", content }, done: true };
}

function scriptedClient(composeReplies: string[]): {
  client: OllamaClient;
  chatCalls: { messages: ChatMessage[]; options?: ChatOptions }[];
} {
  const chatCalls: { messages: ChatMessage[]; options?: ChatOptions }[] = [];
  let composeIndex = 0;
  const client: OllamaClient = {
    chat: vi.fn(async (messages: ChatMessage[], options?: ChatOptions) => {
      chatCalls.push({ messages, options });
      if (options?.tools) return assistantMessage("verified findings");
      const reply = composeReplies[Math.min(composeIndex, composeReplies.length - 1)];
      composeIndex += 1;
      return assistantMessage(reply);
    }),
    listModels: vi.fn(async () => []),
    healthCheck: vi.fn(async () => ({ healthy: true, detail: "" })),
  };
  return { client, chatCalls };
}

const noopExecutor: ToolExecutor = { execute: vi.fn(async () => ({})) };

describe("analyzeLoadout", () => {
  it("runs research then composes the analysis with the JSON schema format", async () => {
    const { client, chatCalls } = scriptedClient([JSON.stringify(validAnalysis())]);
    const result = await analyzeLoadout(request, { client, executor: noopExecutor });

    expect(result.analysis.optimizedBuild.name).toBe("Optimized Tether");
    expect(result.analysis.swaps[0].with).toBe("Polaris Lance");
    expect(result.researchSummary).toBe("verified findings");

    const researchCall = chatCalls[0];
    expect(researchCall.options?.tools).toBeDefined();
    expect(researchCall.messages[0].content).toContain("Analysis focus");
    const lastUser = researchCall.messages[researchCall.messages.length - 1];
    expect(lastUser.content).toContain("Current loadout");
    expect(lastUser.content).toContain("Orpheus Rig");

    const composeCall = chatCalls[chatCalls.length - 1];
    expect(composeCall.options?.format).toBeDefined();
    expect(composeCall.options?.tools).toBeUndefined();
  });

  it("retries once with validation feedback on schema failure", async () => {
    const { client, chatCalls } = scriptedClient([
      JSON.stringify({ assessment: "missing everything" }),
      JSON.stringify(validAnalysis()),
    ]);
    const result = await analyzeLoadout(request, { client, executor: noopExecutor });

    expect(result.analysis.gaps).toHaveLength(1);
    const retryCall = chatCalls[chatCalls.length - 1];
    const lastUserMessage = retryCall.messages[retryCall.messages.length - 1];
    expect(lastUserMessage.content).toContain("rejected");
  });

  it("throws after the retry also fails", async () => {
    const { client } = scriptedClient(["not json", "still not json"]);
    await expect(
      analyzeLoadout(request, { client, executor: noopExecutor }),
    ).rejects.toThrow(/not valid JSON/);
  });
});
