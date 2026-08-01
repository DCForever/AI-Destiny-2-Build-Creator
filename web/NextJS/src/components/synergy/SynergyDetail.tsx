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

const BUILD_PILL_MAX = 6;

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
  const usedBy = synergy.usedByBuilds ?? [];
  const builds = synergy.buildCount ?? usedBy.length;
  const objects = synergy.objectCount ?? synergy.links.length;
  const description = synergy.description?.trim() ?? "";
  const linkTotal = synergy.links.length;
  const shownBuilds = usedBy.slice(0, BUILD_PILL_MAX);
  const extraBuilds = Math.max(0, usedBy.length - shownBuilds.length);

  return (
    <Panel as="article" tone="raised" pad="md" className="w-full">
      <Stack gap={12}>
        {/* 1. Identity strip */}
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
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

        <div className="keyline" />

        {/* 2. Usage strip */}
        <div
          className="border px-2.5 py-2"
          style={{
            borderColor:
              builds > 0
                ? "color-mix(in srgb, var(--success) 35%, var(--line))"
                : "var(--line)",
            background:
              builds > 0
                ? "color-mix(in srgb, var(--success) 6%, var(--surface))"
                : "transparent",
          }}
        >
          <Stack gap={6}>
            <SectionLabel>
              {builds > 0 ? "Used by builds" : "No builds yet"}
            </SectionLabel>
            {builds === 0 ? (
              <Text size="sm" tone="muted">
                No builds list this designation. Attach it on a Build identity
                so coverage can match.
              </Text>
            ) : shownBuilds.length > 0 ? (
              <Cluster gap={6}>
                {shownBuilds.map((b) => (
                  <a
                    key={b.id}
                    href={`/build?build=${encodeURIComponent(b.id)}`}
                    className="inline-flex items-center gap-1 text-[11px] px-2 py-0.5 border border-line bg-surface-raised text-foreground hover:border-accent hover:text-accent transition-colors"
                    title={b.className ? `${b.name} · ${b.className}` : b.name}
                  >
                    <span className="truncate max-w-[12rem]">{b.name}</span>
                    {b.className ? (
                      <span className="text-muted shrink-0">{b.className}</span>
                    ) : null}
                  </a>
                ))}
                {extraBuilds > 0 ? (
                  <span className="text-[11px] text-muted px-2 py-0.5 border border-dashed border-line">
                    +{extraBuilds} more
                  </span>
                ) : null}
              </Cluster>
            ) : (
              <Text size="sm" tone="muted">
                {countLabel(builds, "build lists", "builds list")} this
                designation (names unavailable on this response).
              </Text>
            )}
          </Stack>
        </div>

        {/* 3. Evidence board */}
        <Section
          label={linkTotal > 0 ? `Evidence · ${linkTotal}` : "Evidence"}
          gap={8}
          action={
            linkTotal === 0 ? (
              <Button size="sm" variant="accent" onClick={onEdit}>
                Add links
              </Button>
            ) : (
              <Button size="sm" variant="ghost" onClick={onEdit}>
                Edit links
              </Button>
            )
          }
        >
          {grouped.length === 0 ? (
            <Text size="sm" tone="muted">
              No catalog objects linked. Attach weapons, perks, armor bonuses,
              or artifact perks this designation covers.
            </Text>
          ) : (
            <Stack gap={12}>
              {grouped.map(([kind, links]) => (
                <Stack key={kind} gap={6}>
                  <SectionLabel>
                    {LINK_KIND_LABEL[kind] ?? kind}
                    {` · ${links.length}`}
                  </SectionLabel>
                  <Cluster gap={8}>
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

        {/* 4. Notes secondary */}
        {description ? (
          <details className="border-t border-line pt-2 group">
            <summary className="cursor-pointer text-[10px] tracking-[0.14em] uppercase text-muted font-display list-none flex items-center gap-2">
              <span className="group-open:hidden">▸ Notes</span>
              <span className="hidden group-open:inline">▾ Notes</span>
            </summary>
            <Text
              size="sm"
              className="mt-2 leading-relaxed whitespace-pre-wrap text-muted"
            >
              {description}
            </Text>
          </details>
        ) : (
          <Text size="xs" tone="muted">
            No notes — add them in Edit if you want curator context.
          </Text>
        )}
      </Stack>
    </Panel>
  );
}
