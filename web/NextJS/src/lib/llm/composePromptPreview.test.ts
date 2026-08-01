import { describe, expect, it } from "vitest";

import type { AnalyzeRequest } from "./analyzeSchema";
import type { BuildRequest } from "./buildSchema";
import {
  composeAnalyzePromptPreview,
  composeBuildPromptPreview,
  formatPromptPreview,
} from "./composePromptPreview";

const buildRequest: BuildRequest = {
  className: "Titan",
  subclass: "Sunbreaker",
  activity: "Grandmaster Nightfall",
  playstyle: "aggressive melee",
  notes: "Prefer incandescent",
};

const analyzeRequest: AnalyzeRequest = {
  className: "Hunter",
  activity: "Raid",
  loadoutText: "Subclass: Nightstalker\nKinetic: Fatebringer",
  playstyle: "ranged",
  notes: "Keep Orpheus Rig if possible",
};

describe("composeBuildPromptPreview", () => {
  it("returns six non-empty sections", () => {
    const preview = composeBuildPromptPreview(buildRequest);
    expect(preview.sections).toHaveLength(6);
    for (const section of preview.sections) {
      expect(section.title.length).toBeGreaterThan(0);
      expect(section.content.length).toBeGreaterThan(0);
    }
  });

  it("includes request fields in the user prompt section", () => {
    const preview = composeBuildPromptPreview(buildRequest);
    const userPrompt = preview.sections.find((s) => s.title === "Phase A — User prompt");
    expect(userPrompt?.content).toContain("Sunbreaker");
    expect(userPrompt?.content).toContain("Grandmaster Nightfall");
    expect(userPrompt?.content).toContain("aggressive melee");
    expect(userPrompt?.content).toContain("Prefer incandescent");
  });

  it("includes sandbox digest and meta pack in system prompts", () => {
    const preview = composeBuildPromptPreview(buildRequest);
    const researchSystem = preview.sections.find(
      (s) => s.title === "Phase A — Research system prompt",
    );
    expect(researchSystem?.content).toContain("9.7.0 sandbox digest");
    expect(researchSystem?.content).toContain("Proven Titan builds on 9.7.0");
  });

  it("includes tool definitions as JSON", () => {
    const preview = composeBuildPromptPreview(buildRequest);
    const tools = preview.sections.find((s) => s.title === "Phase A — Tool definitions");
    expect(tools?.content).toContain('"search_items"');
  });
});

describe("composeAnalyzePromptPreview", () => {
  it("returns six non-empty sections", () => {
    const preview = composeAnalyzePromptPreview(analyzeRequest);
    expect(preview.sections).toHaveLength(6);
    for (const section of preview.sections) {
      expect(section.content.length).toBeGreaterThan(0);
    }
  });

  it("includes loadout text in the user prompt section", () => {
    const preview = composeAnalyzePromptPreview(analyzeRequest);
    const userPrompt = preview.sections.find((s) => s.title === "Phase A — User prompt");
    expect(userPrompt?.content).toContain("Nightstalker");
    expect(userPrompt?.content).toContain("Fatebringer");
    expect(userPrompt?.content).toContain("Keep Orpheus Rig if possible");
  });

  it("includes analysis focus in research system prompt", () => {
    const preview = composeAnalyzePromptPreview(analyzeRequest);
    const researchSystem = preview.sections.find(
      (s) => s.title === "Phase A — Research system prompt",
    );
    expect(researchSystem?.content).toContain("Analysis focus");
    expect(researchSystem?.content).toContain("Proven Hunter builds on 9.7.0");
  });
});

describe("formatPromptPreview", () => {
  it("joins sections with headings", () => {
    const preview = composeBuildPromptPreview(buildRequest);
    const formatted = formatPromptPreview(preview);
    expect(formatted).toContain("## Phase A — Research system prompt");
    expect(formatted).toContain("Sunbreaker");
  });
});
