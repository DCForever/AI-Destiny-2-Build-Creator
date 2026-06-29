import type { ConceptTagId } from "@/data/conceptTags";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";
import type { SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import type { SetRecord } from "@/lib/db/repositories/setRepository";

export type SuggestionContext = {
  build: Pick<BuildRecord, "subclass" | "exoticArmorHash" | "tagIds">;
  variant: { exoticWeaponHash: number | null };
  synergies: SynergyWithLinks[];
  buildTagIds: ConceptTagId[];
  goal?: string;
};

export type SetSuggestion = {
  setId: string;
  name: string;
  type: string;
  score: number;
  reasons: string[];
};

const ELEMENT_TAGS: Record<string, ConceptTagId[]> = {
  solar: ["solar"],
  sunbreaker: ["solar"],
  arc: ["arc"],
  void: ["void"],
  stasis: ["stasis"],
  strand: ["strand"],
};

function subclassElementTags(subclass: unknown): ConceptTagId[] {
  const text = JSON.stringify(subclass).toLowerCase();
  const tags = new Set<ConceptTagId>();
  for (const [key, ids] of Object.entries(ELEMENT_TAGS)) {
    if (text.includes(key)) ids.forEach((id) => tags.add(id));
  }
  return [...tags];
}

function scoreSet(set: SetRecord, ctx: SuggestionContext): SetSuggestion {
  let score = 0;
  const reasons: string[] = [];

  const tagOverlap = set.tagIds.filter((t) => ctx.buildTagIds.includes(t));
  if (tagOverlap.length) {
    score += tagOverlap.length * 3;
    reasons.push(`Build tag overlap: ${tagOverlap.join(", ")}`);
  }

  const elementTags = subclassElementTags(ctx.build.subclass);
  const elementOverlap = set.tagIds.filter((t) => elementTags.includes(t));
  if (elementOverlap.length) {
    score += elementOverlap.length * 2;
    reasons.push(`Subclass element match: ${elementOverlap.join(", ")}`);
  }

  for (const synergy of ctx.synergies) {
    if (set.tagIds.some((t) => synergy.type.includes(t) || t === synergy.type)) {
      score += 2;
      reasons.push(`Synergy type ${synergy.type}`);
    }
  }

  if (ctx.goal) {
    const goal = ctx.goal.toLowerCase();
    if (set.name.toLowerCase().includes(goal)) {
      score += 2;
      reasons.push(`Name matches goal "${ctx.goal}"`);
    }
    const goalTag = set.tagIds.find((t) => goal.includes(t));
    if (goalTag) {
      score += 2;
      reasons.push(`Tag matches goal: ${goalTag}`);
    }
  }

  return { setId: set.id, name: set.name, type: set.type, score, reasons };
}

export function suggestSets(availableSets: SetRecord[], ctx: SuggestionContext, limit = 5): SetSuggestion[] {
  return availableSets
    .map((set) => scoreSet(set, ctx))
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

export async function suggestSetsWithGoal(
  availableSets: SetRecord[],
  ctx: SuggestionContext,
  limit = 5,
): Promise<SetSuggestion[]> {
  const base = suggestSets(availableSets, ctx, limit * 2);
  if (!ctx.goal?.trim()) return base.slice(0, limit);
  const { rankSuggestionsWithGoal } = await import("./llmGoalRanking");
  const ranked = await rankSuggestionsWithGoal(
    ctx.goal,
    base.map((s) => ({ ...s, id: s.setId })),
    "set",
  );
  return ranked.slice(0, limit).map(({ id: _id, ...rest }) => ({ ...rest, setId: _id }));
}

export function buildAutomaticSuggestionContext(
  build: BuildRecord,
  variant: { exoticWeaponHash: number | null },
  synergies: SynergyWithLinks[],
): SuggestionContext {
  return {
    build: { subclass: build.subclass, exoticArmorHash: build.exoticArmorHash, tagIds: build.tagIds },
    variant: { exoticWeaponHash: variant.exoticWeaponHash },
    synergies,
    buildTagIds: build.tagIds,
  };
}
