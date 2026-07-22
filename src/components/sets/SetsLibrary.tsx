"use client";

import type { SetSummary } from "@/components/sets/types";
import {
  Button,
  Chip,
  ConceptTagChip,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";

export function SetsLibrary({
  sets,
  selectedId,
  onSelect,
  onNew,
  loading,
}: {
  sets: SetSummary[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  loading: boolean;
}) {
  return (
    <Panel as="aside" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={8} className="shrink-0">
        <Row justify="between" align="center">
          <SectionLabel>
            Library
            {sets.length > 0 ? ` · ${sets.length}` : ""}
          </SectionLabel>
          <Button variant="accent" size="sm" onClick={onNew}>
            New
          </Button>
        </Row>
        {sets.length > 0 ? (
          <Text size="xs" tone="muted">
            Browse kits by type, then open a set to fill slots for Build
            variants.
          </Text>
        ) : null}
      </Stack>

      <div className="flex-1 min-h-0 overflow-y-auto mt-2">
        {loading ? (
          <Text size="sm" tone="muted">
            Loading sets…
          </Text>
        ) : sets.length === 0 ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              No sets match these filters.
            </Text>
            <Button variant="ghost" size="sm" onClick={onNew}>
              Create set
            </Button>
          </Stack>
        ) : (
          <Stack gap={8}>
            {sets.map((row) => {
              const selected = row.id === selectedId;
              return (
                <button
                  key={row.id}
                  type="button"
                  onClick={() => onSelect(row.id)}
                  className="text-left"
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
                      <Text size="sm" weight="medium">
                        {row.name}
                      </Text>
                      <Row gap={6} wrap align="center">
                        <Chip accent>{row.type}</Chip>
                        {(row.tagIds ?? []).slice(0, 3).map((t) => (
                          <ConceptTagChip key={t} tagId={t} size={18} />
                        ))}
                      </Row>
                    </Stack>
                  </Panel>
                </button>
              );
            })}
          </Stack>
        )}
      </div>
    </Panel>
  );
}
