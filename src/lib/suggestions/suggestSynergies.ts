import type { ConceptTagId } from "@/data/conceptTags";
import type { SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";

export type SynergySuggestion = {
  synergyId: string;
  name: string;
  type: string;
  score: number;
  reasons: string[];
};

export type SynergySuggestionContext = {
  build: Pick<BuildRecord, "subclass" | "tagIds">;
  designatedSynergyIds: string[];
  available: SynergyWithLinks[];
};

function subclassKeywords(subclass: unknown): string[] {
  return JSON.stringify(subclass).toLowerCase().split(/[^a-z]+/).filter(Boolean);
}

export function suggestSynergies(
  ctx: SynergySuggestionContext,
  limit = 5,
): SynergySuggestion[] {
  const keywords = subclassKeywords(ctx.build.subclass);
  const buildTags = new Set(ctx.build.tagIds);

  return ctx.available
    .filter((s) => !ctx.designatedSynergyIds.includes(s.id))
    .map((synergy) => {
      let score = 0;
      const reasons: string[] = [];

      if (keywords.some((k) => synergy.type.includes(k) || synergy.name.toLowerCase().includes(k))) {
        score += 2;
        reasons.push("Subclass keyword match");
      }

      const typeAsTag = synergy.type.replace("_", " ");
      if ([...buildTags].some((t) => typeAsTag.includes(t) || t.includes(synergy.type.split("_")[0] ?? ""))) {
        score += 2;
        reasons.push("Build tag overlap");
      }

      if (synergy.links.length) {
        score += 1;
        reasons.push(`${synergy.links.length} manifest link(s)`);
      }

      return { synergyId: synergy.id, name: synergy.name, type: synergy.type, score, reasons };
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

export function tagOverlapScore(buildTags: ConceptTagId[], candidateTags: ConceptTagId[]): number {
  return candidateTags.filter((t) => buildTags.includes(t)).length;
}
