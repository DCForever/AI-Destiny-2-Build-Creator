import { describe, expect, it, vi } from "vitest";

import type { ChatMessage, ChatOptions, ChatResponse, LlmClient } from "./llmClient";
import { runResearchLoop } from "./toolLoop";
import { MAX_TOOL_CALLS } from "./toolTypes";
import type { ToolExecutor, ToolResult } from "./toolTypes";

function toolCall(name: string, args: Record<string, unknown>): ChatMessage {
  return {
    role: "assistant",
    content: "",
    tool_calls: [{ function: { name, arguments: args } }],
  };
}

function assistant(content: string): ChatMessage {
  return { role: "assistant", content };
}

function createScriptedClient(script: ChatMessage[]): LlmClient {
  let index = 0;
  return {
    chat: vi.fn(async (_messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse> => {
      const next = script[index] ?? assistant("done");
      index += 1;
      if (!options?.tools && next.tool_calls?.length) {
        return { message: assistant("forced summary"), done: true };
      }
      return { message: next, done: !next.tool_calls?.length };
    }),
    listModels: vi.fn(async () => []),
    healthCheck: vi.fn(async () => ({ healthy: true, detail: "ok" })),
  };
}

describe("runResearchLoop", () => {
  it("executes tools, appends tool messages, and ends on plain content", async () => {
    const client = createScriptedClient([
      toolCall("search_items", { query: "fatebringer" }),
      toolCall("get_weapon_perks", { weaponName: "Fatebringer" }),
      assistant("Verified Fatebringer perks for the build."),
    ]);
    const execute = vi.fn(async (): Promise<ToolResult> => ({ ok: true }));
    const executor: ToolExecutor = { execute };

    const result = await runResearchLoop({
      client,
      executor,
      systemPrompt: "You are a researcher.",
      userPrompt: "Research a Fatebringer build.",
    });

    expect(execute).toHaveBeenCalledTimes(2);
    expect(result.toolCallCount).toBe(2);
    expect(result.finalSummary).toBe("Verified Fatebringer perks for the build.");

    const toolMessages = result.messages.filter((m) => m.role === "tool");
    expect(toolMessages).toHaveLength(2);
    expect(toolMessages[0]?.content).toBe(JSON.stringify({ ok: true }));
    expect(toolMessages[0]?.tool_name).toBe("search_items");
    expect(result.messages[0]).toEqual({ role: "system", content: "You are a researcher." });
  });

  it("finalizes without tools after MAX_TOOL_CALLS when the model keeps requesting tools", async () => {
    const client: LlmClient = {
      chat: vi.fn(async (_messages: ChatMessage[], options?: ChatOptions) => {
        if (!options?.tools) {
          return { message: assistant("Budget summary with verified notes."), done: true };
        }
        return { message: toolCall("web_search", { query: "meta" }), done: false };
      }),
      listModels: vi.fn(async () => []),
      healthCheck: vi.fn(async () => ({ healthy: true, detail: "ok" })),
    };
    const execute = vi.fn(async (): Promise<ToolResult> => ({ hit: true }));
    const executor: ToolExecutor = { execute };

    const result = await runResearchLoop({
      client,
      executor,
      systemPrompt: "sys",
      userPrompt: "user",
    });

    expect(execute).toHaveBeenCalledTimes(MAX_TOOL_CALLS);
    expect(result.toolCallCount).toBe(MAX_TOOL_CALLS);
    expect(result.finalSummary).toBe("Budget summary with verified notes.");

    const chatMock = client.chat as ReturnType<typeof vi.fn>;
    const noToolsCall = chatMock.mock.calls.find((call) => !(call[1] as ChatOptions | undefined)?.tools);
    expect(noToolsCall).toBeDefined();
    expect(
      result.messages.some(
        (m) => m.content === "Tool budget exhausted. Summarize your verified findings now.",
      ),
    ).toBe(true);
  });
});
