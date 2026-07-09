/**
 * Build query params for subclass structured form ability/aspect/fragment search.
 */

import type { AbilityKind } from "@/lib/manifest/types/records";
import { resolveSubclassScope } from "@/lib/debug/subclassScope";

export type ManifestSearchFilters = {
  subclassAffinity?: string;
  verb?: string;
};

export function buildSubclassSearchParams(input: {
  category: "abilities" | "aspects" | "fragments";
  q: string;
  subclassName: string;
  kind?: AbilityKind;
  filters?: ManifestSearchFilters;
}): URLSearchParams {
  const params = new URLSearchParams({
    category: input.category,
    q: input.q,
    limit: input.q ? "8" : "50",
  });
  const scope = resolveSubclassScope(input.subclassName);
  if (scope) {
    params.set("classType", scope.classType);
    params.set("element", scope.element);
  }
  if (input.kind) params.set("kind", input.kind);
  if (input.category === "abilities") {
    const subclass = input.filters?.subclassAffinity?.trim();
    const verb = input.filters?.verb?.trim();
    if (subclass) params.set("subclass", subclass);
    if (verb) params.set("verb", verb);
  }
  return params;
}
