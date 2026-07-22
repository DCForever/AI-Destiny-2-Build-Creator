"use client";

import type { SynergySummary } from "@/components/synergy/types";
import {
  Badge,
  Button,
  DesignationLabel,
  FlapBoard,
  FlapCell,
  FlapHeader,
  FlapRow,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
} from "@/lib/destiny/identityVisuals";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";

/** Soft channel ink by synergy designation category (element uses subType). */
function synergyChannel(type: string, subType: string | null | undefined): string | null {
  if (type === "element" && subType && isDestinyElement(subType)) {
    return ELEMENT_CSS_COLOR[subType];
  }
  switch (type) {
    case "verb":
      return "var(--element-arc)";
    case "melee":
    case "grenade":
    case "super":
      return "var(--element-solar)";
    case "healing":
    case "damage_resist":
    case "solo":
      return "var(--success)";
    case "dps":
    case "primary_weapon":
    case "special_weapon":
    case "heavy_weapon":
    case "general_weapon":
    case "weapon_archetype":
    case "kinetic_weapon":
      return "var(--foreground)";
    case "team":
      return "var(--element-prismatic)";
    case "damage":
      return "var(--danger)";
    default:
      return "var(--accent)";
  }
}

function usageTally(row: SynergySummary): string {
  const builds = row.buildCount ?? 0;
  const objects = row.objectCount ?? row.links?.length ?? 0;
  return `${builds}B · ${objects}O`;
}

const COLS = "minmax(0,1fr) 5.5rem";
const COLS_HYGIENE = "1.5rem minmax(0,1fr) 5.5rem";

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
  const columns = hygieneMode ? COLS_HYGIENE : COLS;

  return (
    <Panel as="aside" pad="sm" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={6} className="shrink-0">
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
          <Stack gap={4}>
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
          <FlapBoard>
            <FlapHeader
              columns={columns}
              cells={
                hygieneMode
                  ? ["", "Designation", "Links"]
                  : ["Designation", "Links"]
              }
            />
            {synergies.map((row) => {
              const selected = row.id === selectedId;
              const checked = checkedIds.has(row.id);
              const isSurvivor = survivorId === row.id && checked;
              const title = formatSynergyTypeDesignation({
                type: row.type,
                subType: row.subType,
              });
const channel = synergyChannel(String(row.type), row.subType);

              return (
                <FlapRow
                  key={row.id}
                  columns={columns}
                  selected={selected}
                  channel={channel}
                  onClick={() => onSelect(row.id)}
                  aria-current={selected ? "true" : undefined}
                  aria-label={title}
                >
                  {hygieneMode ? (
                    <FlapCell
                      className="justify-center gap-1"
                      onClick={(e) => e.stopPropagation()}
                    >
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
                      ) : null}
                    </FlapCell>
                  ) : null}
                  <FlapCell className="min-w-0 gap-2">
                    <DesignationLabel
                      type={row.type}
                      subType={row.subType}
                      size={22}
                      className="text-[13px] font-medium text-foreground min-w-0"
                    />
                    {isSurvivor ? (
                      <Badge tone="verified" title="Kept after merge">
                        Surv
                      </Badge>
                    ) : null}
                  </FlapCell>
                  <FlapCell variant="tally" title={usageTally(row)}>
                    {usageTally(row)}
                  </FlapCell>
                </FlapRow>
              );
            })}
          </FlapBoard>
        )}
      </div>
    </Panel>
  );
}
