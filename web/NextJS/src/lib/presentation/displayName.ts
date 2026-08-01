/**
 * Primary label vs hash footer (DBR-UI-006 / DAC-DST-015).
 *
 * Item/plug hashes are never primary UI labels. Readable name first;
 * hashes only as a footer addendum for support/debug.
 */

export type EntityLabelKind = "item" | "plug" | "entity";

export type EntityLabelParts = {
  /** Primary headline / chip / row title — never a bare numeric hash. */
  primary: string;
  /** Optional footer addendum e.g. `#1234567890`. Null when no hash. */
  footer: string | null;
  /** True when the primary is a generic unknown placeholder (no real name). */
  unknown: boolean;
};

const UNKNOWN_BY_KIND: Record<EntityLabelKind, string> = {
  item: "Unknown item",
  plug: "Unknown plug",
  entity: "Unknown",
};

/**
 * True when `name` is only digits (bare hash string) or empty after trim.
 */
export function isBareHashLabel(name: string | null | undefined): boolean {
  if (name == null) return true;
  const t = name.trim();
  if (!t) return true;
  return /^\d+$/.test(t);
}

/** Footer form for a hash. Never use as a primary label. */
export function hashFooter(hash: number | null | undefined): string | null {
  if (hash == null || !Number.isFinite(hash) || hash <= 0) return null;
  return `#${Math.trunc(hash)}`;
}

/**
 * Split a display name + optional hash into primary label and hash footer.
 * If name is missing or is itself a bare hash, primary becomes a readable
 * unknown placeholder for the kind.
 */
export function entityLabelParts(input: {
  name?: string | null;
  hash?: number | null;
  kind?: EntityLabelKind;
}): EntityLabelParts {
  const kind = input.kind ?? "entity";
  const raw = input.name?.trim() ?? "";
  const footer = hashFooter(input.hash);

  if (!raw || isBareHashLabel(raw)) {
    // Prefer matching footer hash when name was the hash digits
    const fromName =
      isBareHashLabel(raw) && raw ? hashFooter(Number(raw)) : null;
    return {
      primary: UNKNOWN_BY_KIND[kind],
      footer: footer ?? fromName,
      unknown: true,
    };
  }

  return {
    primary: raw,
    footer,
    unknown: false,
  };
}

/** Convenience: primary label only (never bare hash). */
export function primaryEntityLabel(
  name: string | null | undefined,
  hash?: number | null,
  kind: EntityLabelKind = "entity",
): string {
  return entityLabelParts({ name, hash, kind }).primary;
}
