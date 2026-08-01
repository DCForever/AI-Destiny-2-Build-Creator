import type { LlmClient } from "@/lib/llm/llmClient";
import { composeJsonWithRetry } from "@/lib/llm/composeJson";
import {
  proposePassLlmOutputSchema,
  type Proposal,
  type ProposePassLlmOutput,
} from "@/lib/llm/propose/proposalSchemas";
import { saveProposePass } from "@/lib/llm/propose/proposalStore";

const SYSTEM = `You propose Destiny 2 synergies, keywords, and evidence links from user descriptions.
Return JSON only. Do not invent impossible link kinds. Prefer creatable synergy types
(melee, verb, grenade, super, element, primary_weapon, special_weapon, heavy_weapon, dps,
healing, solo, damage_resist, general_weapon, weapon_archetype, team).
Proposals are for user confirmation — keep them concise.`;

function mockOutput(descriptions: string): ProposePassLlmOutput {
  return {
    proposals: [
      {
        kind: "synergy",
        rationale: "Mock proposal from descriptions",
        synergy: {
          name: "Mock Scorch Loop",
          type: "verb",
          subType: "Scorch",
          description: descriptions.slice(0, 200),
          links: [],
        },
      },
      {
        kind: "keyword",
        rationale: "Suggested vocabulary term",
        keyword: { term: "MockKeyword", facet: "playstyle", isNew: true },
      },
    ],
  };
}

function assignIds(raw: ProposePassLlmOutput): Proposal[] {
  return raw.proposals.map((p, index) => ({
    id: `p${index + 1}`,
    kind: p.kind,
    rationale: p.rationale,
    synergy: p.synergy,
    keyword: p.keyword,
    evidence: p.evidence,
  }));
}

export type RunProposePassDeps = {
  client?: LlmClient | null;
  useMock?: boolean;
  /** Authenticated user that owns the resulting pass (required for confirm). */
  userId?: number;
};

export async function runProposePass(
  descriptions: string,
  deps: RunProposePassDeps = {},
): Promise<{ passId: string; proposals: Proposal[] }> {
  const useMock =
    deps.useMock === true ||
    process.env.LLM_PROPOSE_MOCK === "1" ||
    !deps.client;

  let raw: ProposePassLlmOutput;
  if (useMock) {
    raw = mockOutput(descriptions);
  } else {
    raw = await composeJsonWithRetry(
      deps.client!,
      [
        { role: "system", content: SYSTEM },
        {
          role: "user",
          content: `Propose synergies/keywords/evidence from:\n${descriptions}`,
        },
      ],
      {
        type: "object",
        properties: {
          proposals: { type: "array" },
        },
        required: ["proposals"],
      },
      proposePassLlmOutputSchema,
    );
  }

  const proposals = assignIds(raw);
  const passId = crypto.randomUUID();
  saveProposePass({
    passId,
    createdAt: new Date().toISOString(),
    proposals,
    userId: deps.userId,
  });
  return { passId, proposals };
}
