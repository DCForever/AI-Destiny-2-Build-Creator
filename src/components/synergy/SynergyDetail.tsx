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

function linkMeta(link: SynergyDetail["links"][number]): string | null {
  if (link.kind === "armor_set_bonus" && link.bonusPieces != null) {
    const pieces = `${link.bonusPieces}pc`;
    const bonus = link.bonusName?.trim();
    return bonus ? `${pieces} · ${bonus}` : pieces;
  }
  return null;
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
            <Stack gap={14}>
              {grouped.map(([kind, links]) => (
                <Stack key={kind} gap={8}>
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-widest"
                  >
                    {LINK_KIND_LABEL[kind] ?? kind}
                  </Text>
                  <Stack gap={8}>
                    {links.map((link) => {
                      const meta = linkMeta(link);
                      const objectDesc = link.description?.trim() ?? "";
                      return (
                        <Panel key={link.id} tone="muted" pad="sm">
                          <Stack gap={4}>
                            <Text size="sm" weight="medium">
                              {link.displayName}
                            </Text>
                            {meta ? (
                              <Text size="xs" tone="muted">
                                {meta}
                              </Text>
                            ) : null}
                            {objectDesc ? (
                              <Text
                                size="sm"
                                tone="muted"
                                className="leading-relaxed whitespace-pre-wrap"
                              >
                                {objectDesc}
                              </Text>
                            ) : (
                              <Text size="xs" tone="muted">
                                No catalog description
                              </Text>
                            )}
                          </Stack>
                        </Panel>
                      );
                    })}
                  </Stack>
                </Stack>
              ))}
            </Stack>
          )}
        </Section>
      </Stack>
    </Panel>
  );
}
