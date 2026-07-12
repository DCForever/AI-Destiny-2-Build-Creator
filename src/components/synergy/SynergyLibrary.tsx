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
  onSelect,
  onNew,
  loading,
}: {
  synergies: SynergySummary[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  loading: boolean;
}) {
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
              const linkCount = row.links?.length ?? 0;
              return (
                <button
                  key={row.id}
                  type="button"
                  onClick={() => onSelect(row.id)}
                  className="text-left"
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
              );
            })}
          </Stack>
        )}
      </Stack>
    </Panel>
  );
}
