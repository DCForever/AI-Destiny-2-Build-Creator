"use client";

import {
  Cluster,
  ElementIcon,
  EntityHotspot,
  IconBadge,
  Row,
  Section,
  Stack,
  Text,
} from "@/components/ui";
import {
  ELEMENT_CSS_COLOR,
  elementFromSubclass,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import {
  buildMiniKitStripModel,
  type MiniKitEntity,
  type MiniKitStripModel,
} from "@/lib/builds/miniKitStrip";
import type { SubclassPresentation } from "@/components/build/types";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

function EmptyAbilitySlot({ label }: { label: string }) {
  return (
    <div
      className="flex h-7 w-7 shrink-0 items-center justify-center border border-dashed border-line/70 bg-surface-raised/40"
      title={`${label} — empty`}
      aria-label={`${label} empty`}
    >
      <Text size="xs" tone="muted" as="span" className="text-[9px] leading-none">
        ·
      </Text>
    </div>
  );
}

function AbilitySlot({
  label,
  entity,
  elementColor,
}: {
  label: string;
  entity: MiniKitEntity | null;
  elementColor: string;
}) {
  if (!entity) return <EmptyAbilitySlot label={label} />;
  return (
    <EntityHotspot
      kind={label}
      name={entity.name}
      description={entity.description ?? undefined}
      icon={entity.icon}
      accentColor={accentFor(entity.element) ?? elementColor}
      size={28}
      showLabel="never"
    />
  );
}

/**
 * Full mini kit strip (DBR-BLD-010): element + five ability icons (always) +
 * aspects + fragments. Empty ability slots stay visible as placeholders.
 */
export function MiniKitStrip({
  model,
  presentation,
  subclass,
  pinnedSuper,
  label = "Kit",
  compact = false,
}: {
  /** Prebuilt model; when omitted, built from presentation/subclass. */
  model?: MiniKitStripModel;
  presentation?: SubclassPresentation | null;
  subclass?: {
    name?: string;
    super?: string;
    classAbility?: string;
    movement?: string;
    melee?: string;
    grenade?: string;
    aspects?: string[];
    fragments?: string[];
  } | null;
  pinnedSuper?: string | null;
  label?: string;
  compact?: boolean;
}) {
  const strip =
    model ??
    buildMiniKitStripModel({
      subclass,
      presentation,
      pinnedSuper,
    });
  const element = elementFromSubclass(strip.treeName);
  const elementColor = ELEMENT_CSS_COLOR[element];
  const size = compact ? 24 : 28;

  return (
    <Section label={label}>
      <Stack gap={compact ? 6 : 8}>
        <Row gap={8} align="center" wrap>
          <IconBadge label={element}>
            <ElementIcon
              element={element}
              color={elementColor}
              size={compact ? 16 : 18}
              title={strip.treeName || element}
            />
          </IconBadge>
          {strip.treeName ? (
            <Text size="xs" tone="muted" as="span">
              {strip.treeName}
            </Text>
          ) : null}
          <Cluster gap={6}>
            {strip.abilities.map((slot) => (
              <AbilitySlot
                key={slot.key}
                label={slot.label}
                entity={slot.entity}
                elementColor={elementColor}
              />
            ))}
          </Cluster>
        </Row>

        {strip.aspects.length > 0 ? (
          <Cluster gap={6}>
            {strip.aspects.map((a) => (
              <EntityHotspot
                key={`aspect-${a.name}`}
                kind="Aspect"
                name={a.name}
                description={a.description ?? undefined}
                icon={a.icon}
                accentColor={accentFor(a.element) ?? elementColor}
                size={size}
                showLabel={compact ? "never" : "auto"}
              />
            ))}
          </Cluster>
        ) : null}

        {strip.fragments.length > 0 ? (
          <Cluster gap={4}>
            {strip.fragments.map((f) => (
              <EntityHotspot
                key={`fragment-${f.name}`}
                kind="Fragment"
                name={f.name}
                description={f.description ?? undefined}
                icon={f.icon}
                accentColor={accentFor(f.element) ?? elementColor}
                size={compact ? 20 : 24}
                showLabel="never"
              />
            ))}
          </Cluster>
        ) : null}
      </Stack>
    </Section>
  );
}
