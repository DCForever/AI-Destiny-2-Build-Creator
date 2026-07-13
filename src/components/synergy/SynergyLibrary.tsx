"use client";

import type { SynergySummary } from "@/components/synergy/types";
import {
  Button,
  DesignationLabel,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";

function usageSubtitle(row: SynergySummary): string {
  const builds = row.buildCount ?? 0;
  const objects = row.objectCount ?? row.links?.length ?? 0;
  const buildLabel = builds === 1 ? "1 build linked" : `${builds} builds linked`;
  const objectLabel =
    objects === 1 ? "1 object linked" : `${objects} objects linked`;
  return `${buildLabel} · ${objectLabel}`;
}

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
  onDuplicate,
  mergeBusy,
  duplicateBusy,
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
  onDuplicate: () => void;
  mergeBusy: boolean;
  duplicateBusy: boolean;
  mergeEnabled: boolean;
  mergeBlockedReason: string | null;
  loading: boolean;
}) {
  const checkedCount = checkedIds.size;

  return (
    <Panel as="aside" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={8} className="shrink-0">
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
          <Stack gap={6}>
            <Row gap={6} wrap align="center">
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
                variant="accent"
                size="sm"
                onClick={onMerge}
                disabled={!mergeEnabled || mergeBusy || duplicateBusy}
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
              <Button
                variant="outline"
                size="sm"
                onClick={onDuplicate}
                disabled={
                  loading ||
                  mergeBusy ||
                  duplicateBusy ||
                  (selectedId == null && checkedCount !== 1)
                }
                title={
                  selectedId
                    ? "Duplicate the selected library row"
                    : checkedCount === 1
                      ? "Duplicate the checked library row"
                      : "Select a row to duplicate"
                }
              >
                {duplicateBusy ? "Duplicating…" : "Duplicate"}
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
      </Stack>

      <div className="flex-1 min-h-0 overflow-y-auto mt-2">
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
              const title = formatSynergyTypeDesignation({
                type: row.type,
                subType: row.subType,
              });
              return (
                <div key={row.id} className="flex gap-2 items-start">
                  <input
                    type="checkbox"
                    className="mt-3 shrink-0 accent-current"
                    checked={checked}
                    onChange={() => onToggleCheck(row.id)}
                    aria-label={`Select ${title} for merge`}
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
                      <Stack gap={4} className="min-w-0">
                        <Row gap={6} align="center" wrap>
                          <DesignationLabel
                            type={row.type}
                            subType={row.subType}
                            size={28}
                            className="text-sm font-medium text-foreground"
                          />
                          {selected && checkedCount > 1 ? (
                            <Text size="xs" tone="muted" as="span">
                              · survivor
                            </Text>
                          ) : null}
                        </Row>
                        <Text size="xs" tone="muted">
                          {usageSubtitle(row)}
                        </Text>
                      </Stack>
                    </Panel>
                  </button>
                </div>
              );
            })}
          </Stack>
        )}
      </div>
    </Panel>
  );
}
