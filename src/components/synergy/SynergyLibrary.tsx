"use client";

import type { SynergySummary } from "@/components/synergy/types";
import {
  Button,
  Chip,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";

export function SynergyLibrary({
  synergies,
  selectedId,
  checkedIds,
  onSelect,
  onToggleCheck,
  onCheckAllVisible,
  onClearChecked,
  onNew,
  onMerge,
  mergeBusy,
  mergeEnabled,
  mergeBlockedReason,
  loading,
}: {
  synergies: SynergySummary[];
  selectedId: string | null;
  checkedIds: ReadonlySet<string>;
  onSelect: (id: string) => void;
  onToggleCheck: (id: string) => void;
  onCheckAllVisible: () => void;
  onClearChecked: () => void;
  onNew: () => void;
  onMerge: () => void;
  mergeBusy: boolean;
  /** True when 2+ checked and designations match, with a survivor chosen. */
  mergeEnabled: boolean;
  mergeBlockedReason: string | null;
  loading: boolean;
}) {
  const checkedCount = checkedIds.size;

  return (
    <Panel as="aside" className="flex flex-col min-h-[420px]">
      <Stack gap={12}>
        <Row justify="between" align="center">
          <SectionLabel>
            Library
            {synergies.length > 0 ? ` · ${synergies.length}` : ""}
          </SectionLabel>
          <Button variant="accent" size="sm" onClick={onNew}>
            New
          </Button>
        </Row>

        {synergies.length > 0 ? (
          <Stack gap={8}>
            <Row gap={8} wrap align="center">
              <Button
                variant="ghost"
                size="sm"
                onClick={onCheckAllVisible}
                disabled={loading}
              >
                Check all
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={onClearChecked}
                disabled={checkedCount === 0}
              >
                Clear
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={onMerge}
                disabled={!mergeEnabled || mergeBusy}
                title={
                  mergeEnabled
                    ? "Merge checked rows into the selected survivor"
                    : (mergeBlockedReason ?? "Select rows to merge")
                }
              >
                {mergeBusy
                  ? "Merging…"
                  : checkedCount > 1
                    ? `Merge ${checkedCount}`
                    : "Merge"}
              </Button>
            </Row>
            {checkedCount > 0 && !mergeEnabled && mergeBlockedReason ? (
              <Text size="xs" tone="muted">
                {mergeBlockedReason}
              </Text>
            ) : null}
            {mergeEnabled ? (
              <Text size="xs" tone="muted">
                Merge keeps the <strong>selected</strong> row and absorbs the
                other checked rows (same type + subtype only).
              </Text>
            ) : null}
          </Stack>
        ) : null}

        {loading ? (
          <Text size="sm" tone="muted">
            Loading synergies…
          </Text>
        ) : synergies.length === 0 ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              No synergies match these filters.
            </Text>
            <Button variant="ghost" size="sm" onClick={onNew}>
              Create synergy
            </Button>
          </Stack>
        ) : (
          <Stack gap={8}>
            {synergies.map((row) => {
              const selected = row.id === selectedId;
              const checked = checkedIds.has(row.id);
              const linkCount = row.links?.length ?? 0;
              return (
                <div key={row.id} className="flex gap-2 items-start">
                  <input
                    type="checkbox"
                    className="mt-3 shrink-0 accent-current"
                    checked={checked}
                    onChange={() => onToggleCheck(row.id)}
                    aria-label={`Select ${row.name} for merge`}
                    onClick={(e) => e.stopPropagation()}
                  />
                  <button
                    type="button"
                    onClick={() => onSelect(row.id)}
                    className="text-left flex-1 min-w-0"
                  >
                    <Panel
                      tone={selected ? "accent" : "muted"}
                      pad="sm"
                      className={
                        selected
                          ? ""
                          : "hover:border-line-strong transition-colors"
                      }
                    >
                      <Stack gap={4}>
                        <Text size="sm" weight="medium">
                          {row.name}
                          {selected && checkedCount > 1 ? (
                            <Text size="xs" tone="muted" as="span">
                              {" "}
                              · survivor
                            </Text>
                          ) : null}
                        </Text>
                        <Row gap={6} wrap>
                          <Chip accent>{getSynergyTypeLabel(row.type)}</Chip>
                          {row.subType ? <Chip>{row.subType}</Chip> : null}
                          <Text size="xs" tone="muted" as="span">
                            {linkCount} link{linkCount === 1 ? "" : "s"}
                          </Text>
                        </Row>
                      </Stack>
                    </Panel>
                  </button>
                </div>
              );
            })}
          </Stack>
        )}
      </Stack>
    </Panel>
  );
}
