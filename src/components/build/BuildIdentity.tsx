"use client";

import type { BuildDetail } from "@/components/build/types";
import { CLASS_COLOR } from "@/components/build/types";
import {
  Chip,
  Cluster,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  Heading,
} from "@/components/ui";

export function BuildIdentity({ build }: { build: BuildDetail }) {
  const subclass = build.subclass;
  const softStats = build.softStatTargets
    ? Object.entries(build.softStatTargets)
    : [];

  return (
    <Panel tone="raised">
      <Stack gap={12}>
        <Stack gap={8}>
          <Heading level={1}>{build.name}</Heading>
          <Row gap={12} wrap>
            <Text
              size="xs"
              as="span"
              className={`tracking-widest uppercase ${CLASS_COLOR[build.className]}`}
            >
              {build.className}
            </Text>
            <Text size="xs" tone="muted" as="span">
              {subclass.name}
            </Text>
            {build.pinnedSuper || subclass.super ? (
              <Text size="xs" tone="accent" as="span">
                {build.pinnedSuper ?? subclass.super}
              </Text>
            ) : null}
            {build.exoticArmorName ? (
              <Text size="xs" as="span">
                {build.exoticArmorName}
              </Text>
            ) : (
              <Text size="xs" tone="muted" as="span">
                No exotic armor
              </Text>
            )}
          </Row>
        </Stack>

        {(build.synergyTypes?.length ?? 0) > 0 ? (
          <Section label="Synergy Types">
            <Cluster>
              {build.synergyTypes!.map((t) => (
                <Chip key={t.key}>{t.label}</Chip>
              ))}
            </Cluster>
          </Section>
        ) : build.synergies.length > 0 ? (
          <Section label="Synergies">
            <Cluster>
              {build.synergies.map((synergy) => (
                <Chip key={synergy.id}>{synergy.name}</Chip>
              ))}
            </Cluster>
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
