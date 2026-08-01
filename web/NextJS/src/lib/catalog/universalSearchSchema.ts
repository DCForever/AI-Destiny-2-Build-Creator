import { z } from "zod";

import {
  COMPOSITION_KINDS,
  parseKindsParam,
  type CompositionKind,
} from "./compositionKinds";

export { COMPOSITION_KINDS, parseKindsParam };
export type { CompositionKind };

/**
 * Raw query params for GET /api/catalog/universal-search.
 * `kinds` remains a string here; use `parseUniversalSearchQuery` for full parse.
 */
export const universalSearchQuerySchema = z.object({
  q: z.string().max(80).optional().default(""),
  kinds: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(48),
  includeOwned: z.enum(["0", "1"]).optional(),
});

export type UniversalSearchQueryRaw = z.infer<typeof universalSearchQuerySchema>;

export type UniversalSearchQuery = {
  q: string;
  /** Undefined when kinds param omitted (caller uses all v1 kinds). */
  kinds: CompositionKind[] | undefined;
  limit: number;
  includeOwned: "0" | "1" | undefined;
};

export type ParseUniversalSearchQueryResult =
  | { ok: true; data: UniversalSearchQuery }
  | { ok: false; error: string };

/**
 * Parse + validate query object (already stringified from URLSearchParams).
 */
export function parseUniversalSearchQuery(
  input: unknown,
): ParseUniversalSearchQueryResult {
  const parsed = universalSearchQuerySchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      error: parsed.error.issues.map((i) => i.message).join("; "),
    };
  }

  // Omit kinds param → undefined (search uses all kinds). Explicit CSV → list or error.
  let kinds: CompositionKind[] | undefined;
  if (parsed.data.kinds !== undefined) {
    const kindsResult = parseKindsParam(parsed.data.kinds);
    if ("error" in kindsResult) {
      return { ok: false, error: kindsResult.error };
    }
    kinds = kindsResult;
  }

  return {
    ok: true,
    data: {
      q: parsed.data.q,
      kinds,
      limit: parsed.data.limit,
      includeOwned: parsed.data.includeOwned,
    },
  };
}
