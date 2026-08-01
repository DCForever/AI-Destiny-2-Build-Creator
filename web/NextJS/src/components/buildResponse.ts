import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";

export interface BuildApiResponse {
  build: GeneratedBuild;
  sheet: ResolvedBuildSheet;
  toolCallCount: number;
  researchSummary: string;
  /** Server-rendered export texts; may be absent until the export feature lands. */
  exports?: { wishlistText: string; loParamsText: string; skipped: string[] };
}
