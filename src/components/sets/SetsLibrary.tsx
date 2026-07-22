"use client";

import type { SetSummary } from "@/components/sets/types";
import {
  Button,
  ConceptTagChip,
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

const COLS = "minmax(0,1.4fr) 4.5rem minmax(0,1fr)";

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
    <Panel as="aside" pad="sm" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={6} className="shrink-0">
        <Row justify="between" align="center">
          <SectionLabel>
            Library
            {sets.length > 0 ? ` · ${sets.length}` : ""}
          </SectionLabel>
          <Button variant="accent" size="sm" onClick={onNew}>
            New
          </Button>
        </Row>
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
          <FlapBoard>
            <FlapHeader columns={COLS} cells={["Name", "Type", "Tags"]} />
            {sets.map((row) => {
              const selected = row.id === selectedId;
              const tags = row.tagIds ?? [];
              return (
                <FlapRow
                  key={row.id}
                  columns={COLS}
                  selected={selected}
                  onClick={() => onSelect(row.id)}
                  aria-current={selected ? "true" : undefined}
                >
                  <FlapCell variant="name" title={row.name}>
                    {row.name}
                  </FlapCell>
                  <FlapCell variant="meta" title={String(row.type)}>
                    {row.type}
                  </FlapCell>
                  <FlapCell className="flex-wrap gap-1">
                    {tags.length === 0 ? (
                      <span className="flap-cell-meta">—</span>
                    ) : (
                      tags.slice(0, 4).map((t) => (
                        <ConceptTagChip key={t} tagId={t} size={16} />
                      ))
                    )}
                    {tags.length > 4 ? (
                      <span className="flap-cell-tally">+{tags.length - 4}</span>
                    ) : null}
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
