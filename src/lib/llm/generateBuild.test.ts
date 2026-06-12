import { describe, expect, it, vi } from "vitest";

import type { BuildRequest, GeneratedBuild } from "./buildSchema";
import { generateBuild } from "./generateBuild";
import type { ChatMessage, ChatOptions, ChatResponse, OllamaClient } from "./ollamaClient";
import type { ToolExecutor } from "./toolTypes";

const request: BuildRequest = {
  className: "Titan",
  subclass: "Sunbreaker",
  activity: "Grandmaster Nightfall",
  playstyle: "aggressive melee",
};

function validBuild(): GeneratedBuild {
  return {
    name: "Test Build",
    summary: "A test build summary.",
    subclass: {
      name: "Sunbreaker",
      super: "Burning Maul",
      classAbility: "Rally Barricade",
      movement: "Catapult Lift",
      melee: "Hammer Strike",
      grenade: "Healing Grenade",
      aspects: ["Consecration"],
      fragments: ["Ember of Torches"],
      rationale: "r",
    },
    statTargets: (["Health", "Melee", "Grenade", "Super", "Class", "Weapons"] as const).map(
      (stat) => ({ stat, target: 100, rationale: "r" }),
    ),
    exoticArmor: { name: "Synthoceps", rationale: "r", alternatives: [] },
    armor: { archetype: "Brawler", rationale: "r" },
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

function assistantMessage(content: string): ChatResponse {
  return { message: { role: "assistant", content }, done: true };
}

/** Client scripted per call: research reply (no tools), then compose replies. */
function scriptedClient(composeReplies: string[]): {
  client: OllamaClient;
  chatCalls: { messages: ChatMessage[]; options?: ChatOptions }[];
} {
  const chatCalls: { messages: ChatMessage[]; options?: ChatOptions }[] = [];
  let composeIndex = 0;
  const client: OllamaClient = {
    chat: vi.fn(async (messages: ChatMessage[], options?: ChatOptions) => {
      chatCalls.push({ messages, options });
      if (options?.tools) return assistantMessage("research done");
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

describe("generateBuild", () => {
  it("runs research then composes with the JSON schema format", async () => {
    const { client, chatCalls } = scriptedClient([JSON.stringify(validBuild())]);
    const result = await generateBuild(request, { client, executor: noopExecutor });

    expect(result.build.name).toBe("Test Build");
    expect(result.researchSummary).toBe("research done");

    const composeCall = chatCalls[chatCalls.length - 1];
    expect(composeCall.options?.format).toBeDefined();
    expect(composeCall.options?.tools).toBeUndefined();
    expect(composeCall.messages[0].role).toBe("system");
    expect(composeCall.messages[0].content).toContain("Composition instructions");
  });

  it("retries once with validation feedback on schema failure", async () => {
    const { client, chatCalls } = scriptedClient([
      JSON.stringify({ name: "missing everything" }),
      JSON.stringify(validBuild()),
    ]);
    const result = await generateBuild(request, { client, executor: noopExecutor });

    expect(result.build.summary).toBe("A test build summary.");
    const retryCall = chatCalls[chatCalls.length - 1];
    const lastUserMessage = retryCall.messages[retryCall.messages.length - 1];
    expect(lastUserMessage.content).toContain("rejected");
  });

  it("throws after the retry also fails", async () => {
    const { client } = scriptedClient(["not json", "still not json"]);
    await expect(
      generateBuild(request, { client, executor: noopExecutor }),
    ).rejects.toThrow(/not valid JSON/);
  });
});
