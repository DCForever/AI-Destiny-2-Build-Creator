/**
 * Partial LLM refine: re-research and re-compose with locked sections.
 */

import { renderMetaPack } from "@/data/meta/renderMetaPack";

import {
  buildJsonSchema,
  generatedBuildSchema,
  type GeneratedBuild,
} from "./buildSchema";
import { composeJsonWithRetry } from "./composeJson";
import type { ChatMessage, LlmClient } from "./llmClient";
import {
  REFINE_COMPOSE_PROMPT,
  composeRefineFinalizePrompt,
  composeRefineResearchPrompt,
  composeRefineUserPrompt,
  type RefineRequest,
} from "./refinePrompts";
import { runResearchLoop } from "./toolLoop";
import type { ToolExecutor } from "./toolTypes";

export interface RefineBuildDeps {
  client: LlmClient;
  executor: ToolExecutor;
  signal?: AbortSignal;
}

export interface RefineBuildResult {
  build: GeneratedBuild;
  toolCallCount: number;
  researchSummary: string;
}

export async function refineBuild(
  req: RefineRequest,
  deps: RefineBuildDeps,
): Promise<RefineBuildResult> {
  const metaPack = renderMetaPack(req.className, req.activity);

  const research = await runResearchLoop({
    client: deps.client,
    executor: deps.executor,
    systemPrompt: composeRefineResearchPrompt(metaPack, req),
    userPrompt: composeRefineUserPrompt(req),
    signal: deps.signal,
    maxToolCalls: 8,
  });

  const [, ...conversation] = research.messages;
  const composeMessages: ChatMessage[] = [
    { role: "system", content: composeRefineFinalizePrompt(metaPack, req) },
    ...conversation,
    { role: "user", content: REFINE_COMPOSE_PROMPT },
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
