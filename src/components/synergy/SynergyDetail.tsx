"use client";

import {
  LINK_KIND_LABEL,
  type SynergyDetail,
} from "@/components/synergy/types";
import {
  Button,
  Chip,
  Cluster,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  Heading,
} from "@/components/ui";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";

function groupLinks(detail: SynergyDetail) {
  const groups = new Map<string, SynergyDetail["links"]>();
  for (const link of detail.links) {
    const list = groups.get(link.kind) ?? [];
    list.push(link);
    groups.set(link.kind, list);
  }
  return [...groups.entries()].sort(([a], [b]) => a.localeCompare(b));
}

export function SynergyDetail({
  synergy,
  onEdit,
  onDelete,
  deleteBusy,
}: {
  synergy: SynergyDetail;
  onEdit: () => void;
  onDelete: () => void;
  deleteBusy?: boolean;
}) {
  const grouped = groupLinks(synergy);

  return (
    <Panel tone="raised" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Heading level={1}>{synergy.name}</Heading>
            <Cluster>
              <Chip accent>{getSynergyTypeLabel(synergy.type)}</Chip>
              {synergy.subType ? <Chip>{synergy.subType}</Chip> : null}
            </Cluster>
          </Stack>
          <Row gap={4} wrap>
            <Button size="sm" onClick={onEdit}>
              Edit
            </Button>
            <Button
              size="sm"
              variant="danger"
              disabled={deleteBusy}
              onClick={onDelete}
            >
              Delete
            </Button>
          </Row>
        </Row>

        {synergy.description ? (
          <Section label="Description">
            <Text size="sm" className="leading-relaxed whitespace-pre-wrap">
              {synergy.description}
            </Text>
          </Section>
        ) : (
          <Text size="xs" tone="muted">
            No description
          </Text>
        )}

        <Section label="Links">
          {grouped.length === 0 ? (
            <Text size="xs" tone="muted">
              No links
            </Text>
          ) : (
            <Stack gap={12}>
              {grouped.map(([kind, links]) => (
                <Stack key={kind} gap={6}>
                  <Text size="xs" tone="muted" className="uppercase tracking-widest">
                    {LINK_KIND_LABEL[kind] ?? kind}
                  </Text>
                  <Cluster>
                    {links.map((link) => (
                      <Chip key={link.id} accent>
                        {link.displayName}
                      </Chip>
                    ))}
                  </Cluster>
                </Stack>
              ))}
            </Stack>
          )}
        </Section>
      </Stack>
    </Panel>
  );
}
