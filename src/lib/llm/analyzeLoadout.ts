/**
 * Two-phase loadout analysis, mirroring generateBuild: a bounded tool-call
 * research loop over the pasted loadout, then schema-constrained composition
 * of the assessment + optimized build.
 */

import { renderMetaPack } from "@/data/meta/renderMetaPack";

import {
  composeAnalyzeFinalizeSystemPrompt,
  composeAnalyzeResearchSystemPrompt,
  composeAnalyzeUserPrompt,
} from "./analyzePrompts";
import {
  analysisJsonSchema,
  loadoutAnalysisSchema,
  type AnalyzeRequest,
  type LoadoutAnalysis,
} from "./analyzeSchema";
import { composeJsonWithRetry } from "./composeJson";
import type { ChatMessage, LlmClient } from "./llmClient";
import { runResearchLoop } from "./toolLoop";
import type { ToolExecutor } from "./toolTypes";

export interface AnalyzeLoadoutDeps {
  client: LlmClient;
  executor: ToolExecutor;
  signal?: AbortSignal;
}

export interface AnalyzeLoadoutResult {
  analysis: LoadoutAnalysis;
  toolCallCount: number;
  researchSummary: string;
}

const COMPOSE_PROMPT =
  "Now output the analysis as a single JSON object matching the required schema. No prose.";

export async function analyzeLoadout(
  request: AnalyzeRequest,
  deps: AnalyzeLoadoutDeps,
): Promise<AnalyzeLoadoutResult> {
  const metaPack = renderMetaPack(request.className, request.activity);

  const research = await runResearchLoop({
    client: deps.client,
    executor: deps.executor,
    systemPrompt: composeAnalyzeResearchSystemPrompt(metaPack),
    userPrompt: composeAnalyzeUserPrompt(request),
    signal: deps.signal,
  });

  const [, ...conversation] = research.messages;
  const composeMessages: ChatMessage[] = [
    { role: "system", content: composeAnalyzeFinalizeSystemPrompt(metaPack) },
    ...conversation,
    { role: "user", content: COMPOSE_PROMPT },
  ];

  const analysis = await composeJsonWithRetry(
    deps.client,
    composeMessages,
    analysisJsonSchema(),
    loadoutAnalysisSchema,
    deps.signal,
  );
  return {
    analysis,
    toolCallCount: research.toolCallCount,
    researchSummary: research.finalSummary,
  };
}
