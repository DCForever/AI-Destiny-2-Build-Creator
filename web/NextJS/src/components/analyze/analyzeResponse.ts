import type { LoadoutAnalysis } from "@/lib/llm/analyzeSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";

export interface AnalyzeApiResponse {
  analysis: LoadoutAnalysis;
  sheet: ResolvedBuildSheet;
  toolCallCount: number;
  researchSummary: string;
  exports: { wishlistText: string; loParamsText: string; skipped: string[] };
}
