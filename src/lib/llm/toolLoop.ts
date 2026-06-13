import type { ToolExecutor, ToolName } from "./toolTypes";
import { MAX_TOOL_CALLS } from "./toolTypes";
import { buildToolDefinitions } from "./tools";
import type { ChatMessage, LlmClient } from "./llmClient";
import { throwIfAborted } from "./llmClient";

export interface ResearchLoopResult {
  messages: ChatMessage[];
  toolCallCount: number;
  finalSummary: string;
}

const BUDGET_EXHAUSTED_PROMPT =
  "Tool budget exhausted. Summarize your verified findings now.";

async function executeToolCalls(
  messages: ChatMessage[],
  toolCalls: NonNullable<ChatMessage["tool_calls"]>,
  executor: ToolExecutor,
  toolCallCount: number,
  maxToolCalls: number,
): Promise<{ messages: ChatMessage[]; toolCallCount: number }> {
  let next = messages;
  let count = toolCallCount;
  for (const call of toolCalls) {
    if (count >= maxToolCalls) break;
    const name = call.function.name as ToolName;
    const result = await executor.execute(name, call.function.arguments);
    count += 1;
    next = [
      ...next,
      {
        role: "tool",
        tool_name: name,
        tool_call_id: call.id,
        content: JSON.stringify(result),
      },
    ];
  }
  return { messages: next, toolCallCount: count };
}

export async function runResearchLoop(params: {
  client: LlmClient;
  executor: ToolExecutor;
  systemPrompt: string;
  userPrompt: string;
  signal?: AbortSignal;
  maxToolCalls?: number;
}): Promise<ResearchLoopResult> {
  const toolBudget = params.maxToolCalls ?? MAX_TOOL_CALLS;
  const tools = buildToolDefinitions();
  let messages: ChatMessage[] = [
    { role: "system", content: params.systemPrompt },
    { role: "user", content: params.userPrompt },
  ];
  let toolCallCount = 0;

  while (true) {
    throwIfAborted(params.signal);
    const response = await params.client.chat(messages, { tools, signal: params.signal });
    const assistant = response.message;
    messages = [...messages, assistant];

    if (!assistant.tool_calls?.length) {
      return { messages, toolCallCount, finalSummary: assistant.content };
    }

    if (toolCallCount >= toolBudget) {
      messages = [...messages, { role: "user", content: BUDGET_EXHAUSTED_PROMPT }];
      throwIfAborted(params.signal);
      const finalResponse = await params.client.chat(messages, { signal: params.signal });
      messages = [...messages, finalResponse.message];
      return {
        messages,
        toolCallCount,
        finalSummary: finalResponse.message.content,
      };
    }

    const executed = await executeToolCalls(
      messages,
      assistant.tool_calls,
      params.executor,
      toolCallCount,
      toolBudget,
    );
    messages = executed.messages;
    toolCallCount = executed.toolCallCount;
    if (toolCallCount >= toolBudget) {
      messages = [...messages, { role: "user", content: BUDGET_EXHAUSTED_PROMPT }];
    }
  }
}
