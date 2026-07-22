"use client";

import {
  LINK_KIND_LABEL,
  type SynergyDetail,
} from "@/components/synergy/types";
import {
  Badge,
  Button,
  Cluster,
  DesignationLabel,
  EntityHotspot,
  Heading,
  InfoHotspot,
  Panel,
  Row,
  Section,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";

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

function countLabel(n: number, one: string, many: string): string {
  return n === 1 ? `1 ${one}` : `${n} ${many}`;
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
  const title = formatSynergyTypeDesignation({
    type: synergy.type,
    subType: synergy.subType,
  });
  const builds = synergy.buildCount ?? 0;
  const objects = synergy.objectCount ?? synergy.links.length;
  const description = synergy.description?.trim() ?? "";
  const linkTotal = synergy.links.length;

  return (
    <Panel as="article" tone="raised" className="w-full">
      <Stack gap={16}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={8} className="min-w-0 flex-1">
            <InfoHotspot
              kind="Designation"
              title={title}
              lines={[
                "Build matches this type/subtype for coverage",
                "Linked catalog objects are evidence for the designation",
                synergy.subType
                  ? `Subtype: ${synergy.subType}`
                  : "No subtype on this row",
              ]}
            >
              <Heading level={1} className="min-w-0">
                <DesignationLabel
                  type={synergy.type}
                  subType={synergy.subType}
                  size={28}
                  className="text-lg font-medium text-foreground"
                />
              </Heading>
            </InfoHotspot>

            <Cluster gap={6}>
              <Badge
                tone={builds > 0 ? "verified" : "unresolved"}
                title="Builds that list this designation"
              >
                {countLabel(builds, "build", "builds")}
              </Badge>
              <Badge
                tone={objects > 0 ? "accent" : "unresolved"}
                title="Linked catalog objects on this library row"
              >
                {countLabel(objects, "object", "objects")}
              </Badge>
            </Cluster>
          </Stack>

          <Row gap={4} wrap className="shrink-0">
            <Button size="sm" onClick={onEdit}>
              Edit
            </Button>
            <Button
              size="sm"
              variant="danger"
              disabled={deleteBusy}
              onClick={onDelete}
            >
              {deleteBusy ? "Deleting…" : "Delete"}
            </Button>
          </Row>
        </Row>

        <div className="h-px w-full bg-gradient-to-r from-accent/70 to-transparent" />

        <Section label="Description">
          {description ? (
            <Text size="sm" className="leading-relaxed whitespace-pre-wrap">
              {description}
            </Text>
          ) : (
            <Text size="sm" tone="muted">
              No description yet — add notes when you edit so builds know the
              intent behind this designation.
            </Text>
          )}
        </Section>

        <Section
          label={linkTotal > 0 ? `Links · ${linkTotal}` : "Links"}
          gap={10}
        >
          {grouped.length === 0 ? (
            <Stack gap={6}>
              <Text size="sm" tone="muted">
                No catalog objects linked. Edit to attach weapons, perks, armor
                bonuses, or artifact perks this designation covers.
              </Text>
              <div>
                <Button size="sm" variant="accent" onClick={onEdit}>
                  Add links
                </Button>
              </div>
            </Stack>
          ) : (
            <Stack gap={16}>
              {grouped.map(([kind, links]) => (
                <Stack key={kind} gap={8}>
                  <SectionLabel>
                    {LINK_KIND_LABEL[kind] ?? kind}
                    {` · ${links.length}`}
                  </SectionLabel>
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
