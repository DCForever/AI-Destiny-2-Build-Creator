import { CONCEPT_TAGS } from "@/data/conceptTags";

export type SynergyDesignation = { type: string; subType?: string | null };

/** Map build synergy designations to known concept tag ids (filter metadata only). */
export function conceptTagIdsFromSynergyDesignations(
  designations: readonly SynergyDesignation[],
): string[] {
  const byId = new Map(CONCEPT_TAGS.map((t) => [t.id.toLowerCase(), t.id]));
  const byLabel = new Map(CONCEPT_TAGS.map((t) => [t.label.toLowerCase(), t.id]));
  const out = new Set<string>();
  for (const d of designations) {
    const type = d.type?.trim();
    if (!type) continue;
    const sub = d.subType?.trim();
    const candidates = [
      type,
      sub ?? "",
      sub ? `${type} ${sub}` : "",
      sub ? `${type} · ${sub}` : "",
    ].filter(Boolean);
    for (const c of candidates) {
      const key = c.toLowerCase();
      const id = byId.get(key) ?? byLabel.get(key);
      if (id) out.add(id);
    }
  }
  return [...out];
}
