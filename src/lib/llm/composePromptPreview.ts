import { renderMetaPack } from "@/data/meta/renderMetaPack";

import {
  composeAnalyzeFinalizeSystemPrompt,
  composeAnalyzeResearchSystemPrompt,
  composeAnalyzeUserPrompt,
} from "./analyzePrompts";
import { analysisJsonSchema, type AnalyzeRequest } from "./analyzeSchema";
import { buildJsonSchema, type BuildRequest } from "./buildSchema";
import {
  composeFinalizeSystemPrompt,
  composeResearchSystemPrompt,
  composeUserPrompt,
} from "./prompts";
import { buildToolDefinitions } from "./tools";

export const BUILD_COMPOSE_PROMPT =
  "Now output the final build as a single JSON object matching the required schema. No prose.";

export const ANALYZE_COMPOSE_PROMPT =
  "Now output the analysis as a single JSON object matching the required schema. No prose.";

export interface PromptPreviewSection {
  title: string;
  content: string;
}

export interface PromptPreview {
  sections: PromptPreviewSection[];
}

function section(title: string, content: string): PromptPreviewSection {
  return { title, content };
}

function toolDefinitionsSection(): PromptPreviewSection {
  return section(
    "Phase A — Tool definitions",
    JSON.stringify(buildToolDefinitions(), null, 2),
  );
}

export function formatPromptPreview(preview: PromptPreview): string {
  return preview.sections
    .map(({ title, content }) => `## ${title}\n\n${content}`)
    .join("\n\n");
}

export function composeBuildPromptPreview(request: BuildRequest): PromptPreview {
  const metaPack = renderMetaPack(request.className, request.activity);
  return {
    sections: [
      section("Phase A — Research system prompt", composeResearchSystemPrompt(metaPack)),
      section("Phase A — User prompt", composeUserPrompt(request)),
      toolDefinitionsSection(),
      section("Phase B — Finalize system prompt", composeFinalizeSystemPrompt(metaPack)),
      section("Phase B — Compose user message", BUILD_COMPOSE_PROMPT),
      section("Phase B — JSON schema", JSON.stringify(buildJsonSchema(), null, 2)),
    ],
  };
}

export function composeAnalyzePromptPreview(request: AnalyzeRequest): PromptPreview {
  const metaPack = renderMetaPack(request.className, request.activity);
  return {
    sections: [
      section(
        "Phase A — Research system prompt",
        composeAnalyzeResearchSystemPrompt(metaPack),
      ),
      section("Phase A — User prompt", composeAnalyzeUserPrompt(request)),
      toolDefinitionsSection(),
      section(
        "Phase B — Finalize system prompt",
        composeAnalyzeFinalizeSystemPrompt(metaPack),
      ),
      section("Phase B — Compose user message", ANALYZE_COMPOSE_PROMPT),
      section("Phase B — JSON schema", JSON.stringify(analysisJsonSchema(), null, 2)),
    ],
  };
}
