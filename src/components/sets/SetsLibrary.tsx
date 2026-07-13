"use client";

import type { SetSummary } from "@/components/sets/types";
import {
  Button,
  Chip,
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
    <Panel as="aside" className="flex flex-col min-h-[420px]">
      <Stack gap={12}>
        <Row justify="between" align="center">
          <SectionLabel>
            Library
            {sets.length > 0 ? ` · ${sets.length}` : ""}
          </SectionLabel>
          <Button variant="accent" size="sm" onClick={onNew}>
            New
          </Button>
        </Row>

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
                >
                  <Panel
                    tone={selected ? "accent" : "muted"}
                    pad="sm"
                    className={
                      selected ? "" : "hover:border-line-strong transition-colors"
                    }
                  >
                    <Stack gap={4}>
                      <Text size="sm" weight="medium">
                        {row.name}
                      </Text>
                      <Row gap={6} wrap>
                        <Chip accent>{row.type}</Chip>
                        {(row.tagIds ?? []).slice(0, 3).map((t) => (
                          <Chip key={t}>{t}</Chip>
                        ))}
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
