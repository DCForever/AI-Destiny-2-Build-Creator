"use client";

import {
  LINK_KIND_LABEL,
  type SynergyDetail,
} from "@/components/synergy/types";
import {
  Button,
  Chip,
  Cluster,
  DesignationIcon,
  EntityHotspot,
  InfoHotspot,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  Heading,
  useDesignationIcons,
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
  const typeLabel = getSynergyTypeLabel(synergy.type);
  const { getIcon } = useDesignationIcons([
    { type: synergy.type, subType: synergy.subType },
  ]);
  const designationIcon = getIcon(synergy.type, synergy.subType);

  return (
    <Panel tone="raised" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Row gap={12} align="center">
              <DesignationIcon
                type={synergy.type}
                subType={synergy.subType}
                icon={designationIcon}
                size={40}
                label={synergy.name}
              />
              <Heading level={1}>{synergy.name}</Heading>
            </Row>
            <Cluster>
              <InfoHotspot
                kind="Synergy type"
                title={typeLabel}
                lines={[
                  "Creatable library category",
                  "Drives auto-generated display name",
                  `Internal key: ${synergy.type}`,
                ]}
              >
                <Chip accent>{typeLabel}</Chip>
              </InfoHotspot>
              {synergy.subType ? (
                <InfoHotspot
                  kind="Subtype"
                  title={synergy.subType}
                  icon={designationIcon}
                  lines={[
                    "Required for some types (verb, melee, archetype, …)",
                    "Matched when resolving coverage on builds",
                    designationIcon
                      ? "Official Bungie icon resolved from manifest"
                      : "No matching inventory icon yet",
                  ]}
                >
                  <Row gap={4} align="center">
                    <DesignationIcon
                      type={synergy.type}
                      subType={synergy.subType}
                      icon={designationIcon}
                      size={28}
                      label={synergy.subType}
                    />
                    {!designationIcon ? (
                      <Chip>{synergy.subType}</Chip>
                    ) : null}
                  </Row>
                </InfoHotspot>
              ) : null}
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
                    {links.length > 0 ? ` · ${links.length}` : ""}
                  </Text>
                  <Cluster gap={10}>
                    {links.map((link) => {
                      const meta = linkMeta(link);
                      const objectDesc = link.description?.trim() ?? "";
                      const kindLabel = LINK_KIND_LABEL[kind] ?? kind;
                      return (
                        <EntityHotspot
                          key={link.id}
                          kind={kindLabel}
                          name={link.displayName}
                          description={objectDesc}
                          icon={link.icon}
                          size={32}
                          showLabel="auto"
                          meta={meta ? [meta] : undefined}
                        />
                      );
                    })}
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
