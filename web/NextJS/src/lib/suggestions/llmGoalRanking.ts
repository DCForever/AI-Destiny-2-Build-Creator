import { z } from "zod";

import { createLlmClient } from "@/lib/llm/createLlmClient";
import { composeJsonWithRetry } from "@/lib/llm/composeJson";

const rankSchema = z.object({
  rankedIds: z.array(z.string()).min(1),
});

export type RankableSuggestion = {
  id: string;
  name: string;
  score: number;
  reasons: string[];
};

function tokenizeGoal(goal: string): string[] {
  return goal
    .toLowerCase()
    .split(/[^a-z0-9_]+/)
    .filter((t) => t.length > 1);
}

/** Deterministic goal boost used when LLM is unavailable or fails. */
export function applyGoalBoost<T extends RankableSuggestion>(goal: string, items: T[]): T[] {
  const tokens = tokenizeGoal(goal);
  if (!tokens.length) return items;

  return [...items]
    .map((item) => {
      const haystack = `${item.name} ${item.reasons.join(" ")}`.toLowerCase();
      const hits = tokens.filter((t) => haystack.includes(t)).length;
      return hits ? { ...item, score: item.score + hits * 2 } : item;
    })
    .sort((a, b) => b.score - a.score);
}

/** Optional LLM re-ranking for explicit goal requests (FR-010/016 polish path). */
export async function rankSuggestionsWithGoal<T extends RankableSuggestion>(
  goal: string,
  items: T[],
  label: string,
): Promise<T[]> {
  const boosted = applyGoalBoost(goal, items);
  if (!goal.trim() || boosted.length <= 1) return boosted;

  try {
    const client = createLlmClient();
    const prompt = [
      `Rank these ${label} options for the player goal: "${goal}".`,
      "Return JSON { rankedIds: string[] } using only ids from the list.",
      JSON.stringify(boosted.map((i) => ({ id: i.id, name: i.name, score: i.score }))),
    ].join("\n");

    const ranked = await composeJsonWithRetry(
      client,
      [
        { role: "system", content: "You rank Destiny 2 build suggestions. Output JSON only." },
        { role: "user", content: prompt },
      ],
      {
        type: "object",
        properties: { rankedIds: { type: "array", items: { type: "string" } } },
        required: ["rankedIds"],
      },
      rankSchema,
      undefined,
    );

    const byId = new Map(boosted.map((i) => [i.id, i]));
    const ordered: T[] = [];
    for (const id of ranked.rankedIds) {
      const item = byId.get(id);
      if (item) ordered.push(item);
    }
    for (const item of boosted) {
      if (!ordered.some((o) => o.id === item.id)) ordered.push(item);
    }
    return ordered;
  } catch {
    return boosted;
  }
}
