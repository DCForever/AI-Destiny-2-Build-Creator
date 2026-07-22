"use client";

import type { SynergySummary } from "@/components/synergy/types";
import {
  Badge,
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
  survivorId,
  hygieneMode,
  onHygieneModeChange,
  onSelect,
  onToggleCheck,
  onCheckAllVisible,
  onClearChecked,
  onSurvivorChange,
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
  survivorId: string | null;
  hygieneMode: boolean;
  onHygieneModeChange: (next: boolean) => void;
  onSelect: (id: string) => void;
  onToggleCheck: (id: string) => void;
  onCheckAllVisible: () => void;
  onClearChecked: () => void;
  onSurvivorChange: (id: string) => void;
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
          <Row gap={6} align="center">
            {synergies.length > 0 ? (
              <Button
                variant={hygieneMode ? "accent" : "ghost"}
                size="sm"
                onClick={() => onHygieneModeChange(!hygieneMode)}
                aria-pressed={hygieneMode}
                title={
                  hygieneMode
                    ? "Exit library hygiene (hide merge tools)"
                    : "Enter library hygiene to merge duplicate designations"
                }
              >
                {hygieneMode ? "Exit hygiene" : "Hygiene"}
              </Button>
            ) : null}
            <Button variant="accent" size="sm" onClick={onNew}>
              New
            </Button>
          </Row>
        </Row>

        {hygieneMode && synergies.length > 0 ? (
          <Stack gap={6}>
            <Row gap={6} wrap align="center">
              <Badge tone="fuzzy" title="Merge and bulk tools">
                Hygiene
              </Badge>
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
                    ? "Review merge into the chosen survivor"
                    : (mergeBlockedReason ?? "Check rows and pick a survivor")
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
            {checkedCount >= 2 ? (
              <Text size="xs" tone="muted">
                Pick the <strong>survivor</strong> radio on a checked row. That
                designation stays; other checked rows are absorbed (same type +
                subtype only).
              </Text>
            ) : (
              <Text size="xs" tone="muted">
                Check two or more same-type designations, choose which survives,
                then Merge.
              </Text>
            )}
          </Stack>
        ) : synergies.length > 0 ? (
          <Text size="xs" tone="muted">
            Browse and open a designation. Use Hygiene when you need to merge
            duplicates.
          </Text>
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
              const isSurvivor = survivorId === row.id && checked;
              const title = formatSynergyTypeDesignation({
                type: row.type,
                subType: row.subType,
              });
              return (
                <div key={row.id} className="flex gap-2 items-start">
                  {hygieneMode ? (
                    <div className="mt-3 shrink-0 flex flex-col gap-2 items-center">
                      <input
                        type="checkbox"
                        className="accent-current"
                        checked={checked}
                        onChange={() => onToggleCheck(row.id)}
                        aria-label={`Include ${title} in merge`}
                        onClick={(e) => e.stopPropagation()}
                      />
                      {checked ? (
                        <input
                          type="radio"
                          name="synergy-merge-survivor"
                          className="accent-current"
                          checked={isSurvivor}
                          onChange={() => onSurvivorChange(row.id)}
                          aria-label={`Keep ${title} as merge survivor`}
                          onClick={(e) => e.stopPropagation()}
                          title="Survivor — this row is kept"
                        />
                      ) : (
                        <span
                          className="block w-3.5 h-3.5"
                          aria-hidden
                          title="Check this row to choose it as survivor"
                        />
                      )}
                    </div>
                  ) : null}
                  <button
                    type="button"
                    onClick={() => onSelect(row.id)}
                    className="text-left flex-1 min-w-0"
                    aria-current={selected ? "true" : undefined}
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
                          {isSurvivor ? (
                            <Badge tone="verified" title="Kept after merge">
                              Survivor
                            </Badge>
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
