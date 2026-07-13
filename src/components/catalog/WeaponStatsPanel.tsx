"use client";

import { Stack, Text } from "@/components/ui";
import type { WeaponStatLine } from "@/lib/inventory/instances/weaponStats";

/** DIM-style weapon combat stat rows with fill bars. */
export function WeaponStatsPanel({
  stats,
  frameLabel,
  frameSub,
}: {
  stats: WeaponStatLine[];
  frameLabel?: string | null;
  frameSub?: string | null;
}) {
  if (stats.length === 0 && !frameLabel) return null;

  return (
    <Stack gap={10}>
      {stats.length > 0 ? (
        <Stack gap={4}>
          {stats.map((line) => (
            <div
              key={line.name}
              className="grid grid-cols-[minmax(6.5rem,auto)_2.5rem_1fr] items-center gap-x-2 gap-y-0.5"
            >
              <Text size="xs" tone="muted" className="text-right truncate">
                {line.name}
              </Text>
              <Text size="xs" weight="medium" className="tabular-nums text-right">
                {line.value}
              </Text>
              <div className="h-2 rounded-sm bg-surface-raised border border-line overflow-hidden">
                <div
                  className="h-full bg-foreground/70"
                  style={{ width: `${Math.round(line.ratio * 100)}%` }}
                />
              </div>
            </div>
          ))}
        </Stack>
      ) : null}

      {frameLabel ? (
        <div className="flex items-start gap-2 border border-line bg-surface-raised px-2 py-1.5">
          <Stack gap={2} className="min-w-0">
            <Text size="sm" weight="medium">
              {frameLabel}
            </Text>
            {frameSub ? (
              <Text size="xs" tone="muted">
                {frameSub}
              </Text>
            ) : null}
          </Stack>
        </div>
      ) : null}
    </Stack>
  );
}
