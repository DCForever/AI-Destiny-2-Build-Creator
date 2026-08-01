"use client";

import { Badge, Chip, Cluster, Section, Stack, Text } from "@/components/ui";
import {
  weaponRollDetailHasContent,
  type WeaponRollDetail,
} from "@/lib/presentation/weaponRollDetail";

/**
 * Weapon detail: selected plugs, can-roll pool, craft flags when known (DBR-UI-007).
 * Hash footers are muted addenda only (DBR-UI-006).
 */
export function WeaponRollDetailPanel({
  detail,
  compact = false,
}: {
  detail: WeaponRollDetail | null | undefined;
  /** Fewer columns / plugs for dense set cards. */
  compact?: boolean;
}) {
  if (!detail || !weaponRollDetailHasContent(detail)) return null;

  const maxCols = compact ? 3 : 8;
  const maxPlugs = compact ? 6 : 16;

  return (
    <Stack gap={12}>
      {detail.craft ? (
        <Cluster gap={4}>
          {detail.craft.isCrafted === true ? (
            <Badge tone="verified">Crafted</Badge>
          ) : null}
          {detail.craft.isCraftable === true ? (
            <Badge tone="accent">Craftable</Badge>
          ) : null}
          {detail.craft.isCrafted === false ? (
            <Text size="xs" tone="muted" as="span">
              Not crafted
            </Text>
          ) : null}
        </Cluster>
      ) : null}

      {detail.selectedPlugs.length > 0 ? (
        <Section label="Selected plugs">
          <Cluster gap={4}>
            {detail.selectedPlugs.map((p) => (
              <Chip key={p.hash} accent title={p.footer ?? undefined}>
                {p.primary}
                {p.footer ? (
                  <span className="ml-1 opacity-50 text-[0.65rem] font-normal">
                    {p.footer}
                  </span>
                ) : null}
              </Chip>
            ))}
          </Cluster>
        </Section>
      ) : null}

      {detail.canRollColumns.length > 0 ? (
        <Section label="Can-roll pool">
          <Stack gap={8}>
            {detail.canRollColumns.slice(0, maxCols).map((col) => (
              <Stack key={col.column} gap={4}>
                <Text size="xs" tone="muted" className="uppercase tracking-wide">
                  {col.label}
                </Text>
                <Cluster gap={4}>
                  {col.plugs.slice(0, maxPlugs).map((p) => (
                    <Chip
                      key={p.hash}
                      title={
                        [p.footer, p.curated ? "Curated" : null]
                          .filter(Boolean)
                          .join(" · ") || undefined
                      }
                    >
                      {p.primary}
                      {p.curated ? (
                        <span className="ml-1 opacity-60 text-[0.65rem]">★</span>
                      ) : null}
                    </Chip>
                  ))}
                  {col.plugs.length > maxPlugs ? (
                    <Text size="xs" tone="muted" as="span">
                      +{col.plugs.length - maxPlugs} more
                    </Text>
                  ) : null}
                </Cluster>
              </Stack>
            ))}
            {detail.canRollColumns.length > maxCols ? (
              <Text size="xs" tone="muted">
                +{detail.canRollColumns.length - maxCols} more columns
              </Text>
            ) : null}
          </Stack>
        </Section>
      ) : null}
    </Stack>
  );
}

/** Parse rollDetail from composition-search meta (JSON-safe shape). */
export function rollDetailFromMeta(
  meta: Record<string, unknown> | undefined,
): WeaponRollDetail | null {
  if (!meta || typeof meta !== "object") return null;
  const raw = meta.rollDetail;
  if (!raw || typeof raw !== "object") return null;
  const d = raw as WeaponRollDetail;
  if (!Array.isArray(d.selectedPlugs) || !Array.isArray(d.canRollColumns)) {
    return null;
  }
  return d;
}
