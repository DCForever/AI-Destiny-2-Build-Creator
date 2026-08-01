/**
 * Multi-pass build generation: Abilities → Weapons → Armor → Artifact → Synthesis.
 * Each specialist pass runs its own research loop (with a domain tool budget)
 * followed by schema-constrained composition.
 */

import { renderMetaPack } from "@/data/meta/renderMetaPack";

import type { BuildRequest, GeneratedBuild } from "../buildSchema";
import { composeJsonWithRetry } from "../composeJson";
import type { ChatMessage, LlmClient } from "../llmClient";
import { runResearchLoop } from "../toolLoop";
import type { ToolExecutor } from "../toolTypes";
import type { GenerateBuildResult } from "../generateBuild";
import { applySynthesis, mergePasses } from "./mergePasses";
import {
  PASS_COMPOSE_PROMPTS,
  composeAbilitiesFinalizePrompt,
  composeAbilitiesResearchPrompt,
  composeAbilitiesUserPrompt,
  composeArmorFinalizePrompt,
  composeArmorResearchPrompt,
  composeArmorUserPrompt,
  composeArtifactFinalizePrompt,
  composeArtifactResearchPrompt,
  composeArtifactUserPrompt,
  composeSynthesisSystemPrompt,
  composeSynthesisUserPrompt,
  composeWeaponsFinalizePrompt,
  composeWeaponsResearchPrompt,
  composeWeaponsUserPrompt,
} from "./passPrompts";
import {
  abilitiesPassJsonSchema,
  abilitiesPassSchema,
  armorPassJsonSchema,
  armorPassSchema,
  artifactPassJsonSchema,
  artifactPassSchema,
  synthesisPassJsonSchema,
  synthesisPassSchema,
  weaponsPassJsonSchema,
  weaponsPassSchema,
} from "./passSchemas";

export interface GenerateBuildMultiPassDeps {
  client: LlmClient;
  executor: ToolExecutor;
  signal?: AbortSignal;
  inventorySummary?: string | null;
}

const PASS_TOOL_BUDGETS = {
  abilities: 4,
  weapons: 6,
  armor: 4,
  artifact: 2,
} as const;

async function runPass<T>(
  deps: GenerateBuildMultiPassDeps,
  params: {
    researchPrompt: string;
    finalizePrompt: string;
    userPrompt: string;
    composePrompt: string;
    jsonSchema: Record<string, unknown>;
    schema: import("zod").ZodType<T>;
    maxToolCalls: number;
  },
): Promise<{ output: T; toolCallCount: number; summary: string }> {
  const research = await runResearchLoop({
    client: deps.client,
    executor: deps.executor,
    systemPrompt: params.researchPrompt,
    userPrompt: params.userPrompt,
    signal: deps.signal,
    maxToolCalls: params.maxToolCalls,
  });

  const [, ...conversation] = research.messages;
  const composeMessages: ChatMessage[] = [
    { role: "system", content: params.finalizePrompt },
    ...conversation,
    { role: "user", content: params.composePrompt },
  ];

  const output = await composeJsonWithRetry(
    deps.client,
    composeMessages,
    params.jsonSchema,
    params.schema,
    deps.signal,
  );

  return {
    output,
    toolCallCount: research.toolCallCount,
    summary: research.finalSummary,
  };
}

export async function generateBuildMultiPass(
  request: BuildRequest,
  deps: GenerateBuildMultiPassDeps,
): Promise<GenerateBuildResult> {
  const metaPack = renderMetaPack(request.className, request.activity);
  let totalToolCalls = 0;
  const summaries: string[] = [];

  const abilitiesResult = await runPass(deps, {
    researchPrompt: composeAbilitiesResearchPrompt(metaPack, request),
    finalizePrompt: composeAbilitiesFinalizePrompt(metaPack),
    userPrompt: composeAbilitiesUserPrompt(request),
    composePrompt: PASS_COMPOSE_PROMPTS.abilities,
    jsonSchema: abilitiesPassJsonSchema(),
    schema: abilitiesPassSchema,
    maxToolCalls: PASS_TOOL_BUDGETS.abilities,
  });
  totalToolCalls += abilitiesResult.toolCallCount;
  summaries.push(`Abilities: ${abilitiesResult.summary}`);

  const weaponsResult = await runPass(deps, {
    researchPrompt: composeWeaponsResearchPrompt(metaPack, request, abilitiesResult.output),
    finalizePrompt: composeWeaponsFinalizePrompt(metaPack),
    userPrompt: composeWeaponsUserPrompt(request, deps.inventorySummary),
    composePrompt: PASS_COMPOSE_PROMPTS.weapons,
    jsonSchema: weaponsPassJsonSchema(),
    schema: weaponsPassSchema,
    maxToolCalls: PASS_TOOL_BUDGETS.weapons,
  });
  totalToolCalls += weaponsResult.toolCallCount;
  summaries.push(`Weapons: ${weaponsResult.summary}`);

  const armorResult = await runPass(deps, {
    researchPrompt: composeArmorResearchPrompt(
      metaPack,
      request,
      abilitiesResult.output,
      weaponsResult.output,
    ),
    finalizePrompt: composeArmorFinalizePrompt(metaPack),
    userPrompt: composeArmorUserPrompt(request),
    composePrompt: PASS_COMPOSE_PROMPTS.armor,
    jsonSchema: armorPassJsonSchema(),
    schema: armorPassSchema,
    maxToolCalls: PASS_TOOL_BUDGETS.armor,
  });
  totalToolCalls += armorResult.toolCallCount;
  summaries.push(`Armor: ${armorResult.summary}`);

  const artifactResult = await runPass(deps, {
    researchPrompt: composeArtifactResearchPrompt(metaPack, request, {
      abilities: abilitiesResult.output,
      weapons: weaponsResult.output,
      armor: armorResult.output,
    }),
    finalizePrompt: composeArtifactFinalizePrompt(metaPack),
    userPrompt: composeArtifactUserPrompt(request),
    composePrompt: PASS_COMPOSE_PROMPTS.artifact,
    jsonSchema: artifactPassJsonSchema(),
    schema: artifactPassSchema,
    maxToolCalls: PASS_TOOL_BUDGETS.artifact,
  });
  totalToolCalls += artifactResult.toolCallCount;
  summaries.push(`Artifact: ${artifactResult.summary}`);

  const draft = mergePasses({
    abilities: abilitiesResult.output,
    weapons: weaponsResult.output,
    armor: armorResult.output,
    artifact: artifactResult.output,
  });

  const synthesisMessages: ChatMessage[] = [
    { role: "system", content: composeSynthesisSystemPrompt(metaPack) },
    { role: "user", content: composeSynthesisUserPrompt(JSON.stringify(draft, null, 2)) },
  ];

  const synthesis = await composeJsonWithRetry(
    deps.client,
    synthesisMessages,
    synthesisPassJsonSchema(),
    synthesisPassSchema,
    deps.signal,
  );

  const build: GeneratedBuild = applySynthesis(draft, synthesis);
  summaries.push("Synthesis: narrative complete");

  return {
    build,
    toolCallCount: totalToolCalls,
    researchSummary: summaries.join(" | "),
  };
}
