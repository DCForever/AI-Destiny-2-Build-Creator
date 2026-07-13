"use client";

import type { BuildDetail } from "@/components/build/types";
import {
  Button,
  Chip,
  ClassIcon,
  Cluster,
  DesignationIcon,
  ElementIcon,
  IconBadge,
  InfoHotspot,
  Panel,
  Row,
  Section,
  Stack,
  SuperIcon,
  Text,
  Heading,
  useDesignationIcons,
} from "@/components/ui";
import {
  CLASS_CSS_COLOR,
  CLASS_TEXT_CLASS,
  ELEMENT_CSS_COLOR,
  elementFromSubclass,
  isGuardianClass,
} from "@/lib/destiny/identityVisuals";

export function BuildIdentity({
  build,
  onEdit,
  onDelete,
  deleteBusy,
}: {
  build: BuildDetail;
  onEdit?: () => void;
  onDelete?: () => void;
  deleteBusy?: boolean;
}) {
  const subclass = build.subclass;
  const softStats = build.softStatTargets
    ? Object.entries(build.softStatTargets)
    : [];
  const cls = isGuardianClass(build.className) ? build.className : "Titan";
  const element = elementFromSubclass(subclass.name);
  const superName = build.pinnedSuper ?? subclass.super ?? null;
  const classColor = CLASS_CSS_COLOR[cls];
  const elementColor = ELEMENT_CSS_COLOR[element];

  const designationRefs = (build.synergyTypes ?? []).map((t) => ({
    type: t.type,
    subType: t.subType,
  }));
  const { getIcon } = useDesignationIcons(designationRefs);

  return (
    <Panel tone="raised">
      <Stack gap={12}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={8} className="min-w-0 flex-1">
            <Heading level={1}>{build.name}</Heading>
            <Row gap={10} wrap align="center">
              <InfoHotspot
                kind="Class"
                title={cls}
                lines={[
                  "Guardian class for this curated build",
                  `Subclass: ${subclass.name}`,
                ]}
              >
                <Row gap={4} align="center">
                  <IconBadge label={cls}>
                    <ClassIcon className={cls} color={classColor} size={16} />
                  </IconBadge>
                  <Text
                    size="xs"
                    as="span"
                    className={`tracking-widest uppercase ${CLASS_TEXT_CLASS[cls]}`}
                  >
                    {cls}
                  </Text>
                </Row>
              </InfoHotspot>

              <InfoHotspot
                kind="Subclass"
                title={subclass.name}
                lines={[
                  `Element: ${element}`,
                  superName ? `Super: ${superName}` : "No pinned super",
                ]}
              >
                <Row gap={4} align="center">
                  <IconBadge label={element}>
                    <ElementIcon
                      element={element}
                      color={elementColor}
                      size={14}
                      title={subclass.name}
                    />
                  </IconBadge>
                  <Text size="xs" tone="muted" as="span">
                    {subclass.name}
                  </Text>
                </Row>
              </InfoHotspot>

              {superName ? (
                <InfoHotspot
                  kind="Super"
                  title={superName}
                  lines={["Pinned super for identity / create kits"]}
                >
                  <Row gap={4} align="center">
                    <IconBadge label={superName}>
                      <SuperIcon
                        color={elementColor}
                        size={14}
                        title={superName}
                      />
                    </IconBadge>
                    <Text size="xs" tone="accent" as="span">
                      {superName}
                    </Text>
                  </Row>
                </InfoHotspot>
              ) : null}

              {build.exoticArmorName ? (
                <InfoHotspot
                  kind="Exotic armor"
                  title={build.exoticArmorName}
                  lines={["Build identity exotic armor"]}
                >
                  <Text size="xs" as="span">
                    {build.exoticArmorName}
                  </Text>
                </InfoHotspot>
              ) : (
                <Text size="xs" tone="muted" as="span">
                  No exotic armor
                </Text>
              )}
            </Row>
          </Stack>
          <Row gap={4} wrap>
            {onEdit ? (
              <Button size="sm" onClick={onEdit}>
                Edit
              </Button>
            ) : null}
            {onDelete ? (
              <Button
                size="sm"
                variant="danger"
                disabled={deleteBusy}
                onClick={onDelete}
              >
                Delete
              </Button>
            ) : null}
          </Row>
        </Row>

        {(build.synergyTypes?.length ?? 0) > 0 ? (
          <Section label="Synergy Types">
            <div className="flex flex-wrap gap-2 items-center">
              {build.synergyTypes!.map((t) => {
                const chipLabel = t.subType?.trim() || t.label;
                return (
                  <InfoHotspot
                    key={t.key}
                    kind="Synergy type"
                    title={t.label}
                    lines={[
                      `Type: ${t.type}`,
                      t.subType ? `Subtype: ${t.subType}` : "No subtype",
                      "Designation matched against library synergies for coverage",
                    ]}
                  >
                    <span className="inline-flex items-center gap-1.5 border border-line px-2 py-0.5">
                      <DesignationIcon
                        type={t.type}
                        subType={t.subType}
                        icon={getIcon(t.type, t.subType)}
                        size={18}
                        label={t.label}
                      />
                      <span className="text-[10px] tracking-wide text-muted whitespace-nowrap">
                        {chipLabel}
                      </span>
                    </span>
                  </InfoHotspot>
                );
              })}
            </div>
          </Section>
        ) : build.synergies.length > 0 ? (
          <Section label="Synergies">
            <div className="flex flex-wrap gap-2 items-center">
              {build.synergies.map((synergy) => (
                <InfoHotspot
                  key={synergy.id}
                  kind="Library synergy"
                  title={synergy.name}
                  lines={[
                    synergy.type,
                    synergy.subType
                      ? `Subtype: ${synergy.subType}`
                      : "No subtype",
                  ]}
                >
                  <Chip className="whitespace-nowrap">{synergy.name}</Chip>
                </InfoHotspot>
              ))}
            </div>
          </Section>
        ) : null}

        {softStats.length > 0 ? (
          <Section label="Soft stat targets">
            <Row gap={8} wrap>
              {softStats.map(([stat, value]) => (
                <Text key={stat} size="xs" as="span">
                  {stat}{" "}
                  <Text size="xs" tone="accent" as="span">
                    {value}
                  </Text>
                </Text>
              ))}
            </Row>
          </Section>
        ) : null}
      </Stack>
    </Panel>
  );
}
