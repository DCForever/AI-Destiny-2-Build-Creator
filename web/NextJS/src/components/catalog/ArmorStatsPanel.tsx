"use client";

import {
  ARMOR_STAT_NAMES,
  STAT_MAX,
  type ArmorStatName,
} from "@/data/rules/statBenefits";
import { Stack, Text } from "@/components/ui";

/** Dense Armor 3.0 stat rows (same visual language as WeaponStatsPanel). */
export function ArmorStatsPanel({
  statValues,
  totalStats,
  statsIncomplete,
}: {
  statValues?: Partial<Record<string, number>> | null;
  totalStats?: number | null;
  statsIncomplete?: boolean;
}) {
  const hasAny =
    statValues &&
    ARMOR_STAT_NAMES.some((n) => typeof statValues[n] === "number");

  if (!hasAny) {
    return (
      <Text size="xs" tone="muted">
        {statsIncomplete
          ? "Stats incomplete — re-sync inventory."
          : "No armor stats on this copy."}
      </Text>
    );
  }

  return (
    <Stack gap={6}>
      <Stack gap={4}>
        {ARMOR_STAT_NAMES.map((name: ArmorStatName) => {
          const value = statValues?.[name];
          if (typeof value !== "number") return null;
          const ratio = Math.min(1, Math.max(0, value / STAT_MAX));
          return (
            <div
              key={name}
              className="grid grid-cols-[minmax(3.25rem,auto)_1.75rem_1fr] items-center gap-x-1.5"
            >
              <Text size="xs" tone="muted" className="text-right truncate">
                {name}
              </Text>
              <Text
                size="xs"
                weight="medium"
                className="tabular-nums text-right"
              >
                {value}
              </Text>
              <div className="h-1.5 rounded-sm bg-surface-raised border border-line overflow-hidden">
                <div
                  className="h-full bg-foreground/70"
                  style={{ width: `${Math.round(ratio * 100)}%` }}
                />
              </div>
            </div>
          );
        })}
      </Stack>
      {typeof totalStats === "number" ? (
        <Text size="xs" tone="muted">
          Total {totalStats}
          {statsIncomplete ? " · incomplete" : ""}
        </Text>
      ) : null}
    </Stack>
  );
}
