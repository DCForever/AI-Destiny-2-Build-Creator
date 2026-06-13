/**
 * Two-phase build generation. Phase A: bounded tool-call research loop
 * (tools enabled, no format constraint). Phase B: replay the research
 * conversation with the JSON-schema `format` constraint to produce the
 * structured build, validated by zod with one corrective retry.
 *
 * Ollama cannot combine tool emission and schema-constrained decoding in a
 * single call, hence the split. The same two-phase split applies to OpenAI-
 * compatible servers when tools and response_format cannot be combined.
 */

import { renderMetaPack } from "@/data/meta/renderMetaPack";

import {
  buildJsonSchema,
  generatedBuildSchema,
  type BuildRequest,
  type GeneratedBuild,
} from "./buildSchema";
import { composeJsonWithRetry } from "./composeJson";
import type { ChatMessage, LlmClient } from "./llmClient";
import {
  composeFinalizeSystemPrompt,
  composeResearchSystemPrompt,
  composeUserPrompt,
} from "./prompts";
import { runResearchLoop } from "./toolLoop";
import type { ToolExecutor } from "./toolTypes";

export interface GenerateBuildDeps {
  client: LlmClient;
  executor: ToolExecutor;
  signal?: AbortSignal;
}

export interface GenerateBuildResult {
  build: GeneratedBuild;
  toolCallCount: number;
  researchSummary: string;
}

const COMPOSE_PROMPT =
  "Now output the final build as a single JSON object matching the required schema. No prose.";

export async function generateBuild(
  request: BuildRequest,
  deps: GenerateBuildDeps,
): Promise<GenerateBuildResult> {
  const metaPack = renderMetaPack(request.className, request.activity);

  const research = await runResearchLoop({
    client: deps.client,
    executor: deps.executor,
    systemPrompt: composeResearchSystemPrompt(metaPack),
    userPrompt: composeUserPrompt(request),
    signal: deps.signal,
  });

  // Replay the research conversation under the composition system prompt.
  const [, ...conversation] = research.messages;
  const composeMessages: ChatMessage[] = [
    { role: "system", content: composeFinalizeSystemPrompt(metaPack) },
    ...conversation,
    { role: "user", content: COMPOSE_PROMPT },
  ];

  const build = await composeJsonWithRetry(
    deps.client,
    composeMessages,
    buildJsonSchema(),
    generatedBuildSchema,
    deps.signal,
  );
  return {
    build,
    toolCallCount: research.toolCallCount,
    researchSummary: research.finalSummary,
  };
}
