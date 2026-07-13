"use client";

import type {
  BuildDetail,
  BuildVariantDetail,
  PresentedEntity,
} from "@/components/build/types";
import {
  ARMOR_SLOTS,
  SLOT_LABEL,
  WEAPON_SLOTS,
} from "@/components/build/types";
import {
  Button,
  Chip,
  Cluster,
  EntityHotspot,
  Panel,
  Row,
  Section,
  Stack,
  Text,
} from "@/components/ui";
import {
  ELEMENT_CSS_COLOR,
  elementFromSubclass,
  isDestinyElement,
} from "@/lib/destiny/identityVisuals";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element];
  }
  return undefined;
}

function AbilityHotspot({
  entity,
  kind,
  fallbackName,
  elementColor,
}: {
  entity?: PresentedEntity | null;
  kind: string;
  fallbackName?: string | null;
  elementColor?: string;
}) {
  const name = entity?.name || fallbackName;
  if (!name) return null;
  return (
    <EntityHotspot
      kind={entity?.kindLabel ?? kind}
      name={name}
      description={entity?.description}
      icon={entity?.icon}
      accentColor={accentFor(entity?.element) ?? elementColor}
      size={28}
      showLabel="auto"
      meta={entity?.element ? [entity.element] : undefined}
    />
  );
}

/**
 * Read-only variant surface.
 * - `card`: selectable tile in a multi-variant grid (legacy compact layout)
 * - `detail`: focused Details mode (single variant; Edit switches to edit panel)
 */
export function VariantCard({
  build,
  variant,
  selected,
  onSelect,
  onEdit,
  layout = "card",
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  selected: boolean;
  onSelect: () => void;
  onEdit?: () => void;
  layout?: "card" | "detail";
}) {
  const focused = layout === "detail";
  const equipment = variant.resolved?.equipment ?? {};
  const setNames = variant.attachments
    .map((a) => a.set?.name)
    .filter((name): name is string => Boolean(name));
  const subclass = build.subclass;
  const sp = build.subclassPresentation;
  const elementColor = ELEMENT_CSS_COLOR[elementFromSubclass(subclass.name)];

  const exoticWeapon =
    variant.exoticWeapon ??
    (variant.exoticWeaponName || build.exoticWeaponName
      ? {
          hash: variant.exoticWeaponHash,
          name:
            variant.exoticWeaponName ??
            build.exoticWeaponName ??
            "Exotic weapon",
          icon: null,
          description: "",
          element: null,
          kindLabel: "Exotic weapon",
        }
      : null);

  const artifact = variant.artifact;
  const artifactPerks = variant.artifactPerks ?? [];

  return (
    <Panel
      as="article"
      tone={focused || selected ? "accent" : "default"}
      className="h-full"
    >
      <Stack gap={12}>
        <Row justify="between" align="center" gap={8} wrap>
          {focused ? (
            <Stack gap={2} className="min-w-0">
              <Text size="sm" weight="medium">
                {variant.name}
                {variant.isDefault ? (
                  <Text
                    size="xs"
                    tone="muted"
                    as="span"
                    className="ml-2 uppercase tracking-widest"
                  >
                    Default
                  </Text>
                ) : null}
              </Text>
              <Text size="xs" tone="muted">
                Details · read-only overview
              </Text>
            </Stack>
          ) : (
            <button
              type="button"
              onClick={onSelect}
              className="text-left text-sm font-medium text-foreground hover:text-accent"
            >
              {variant.name}
              {variant.isDefault ? (
                <Text
                  size="xs"
                  tone="muted"
                  as="span"
                  className="ml-2 uppercase tracking-widest"
                >
                  Default
                </Text>
              ) : null}
            </button>
          )}
          <Row gap={4}>
            {!focused ? (
              <Button
                variant={selected ? "accent" : "outline"}
                size="sm"
                onClick={onSelect}
              >
                {selected ? "Selected" : "Select"}
              </Button>
            ) : null}
            {onEdit ? (
              <Button
                size="sm"
                variant={focused ? "accent" : "outline"}
                onClick={onEdit}
              >
                Edit
              </Button>
            ) : null}
          </Row>
        </Row>

        {focused && variant.notes?.trim() ? (
          <Text size="sm" tone="muted">
            {variant.notes.trim()}
          </Text>
        ) : null}

        <Section label="Abilities">
          <Cluster gap={8}>
            <AbilityHotspot
              entity={sp?.classAbility}
              kind="Class ability"
              fallbackName={subclass.classAbility}
              elementColor={elementColor}
            />
            <AbilityHotspot
              entity={sp?.movement}
              kind="Movement"
              fallbackName={subclass.movement}
              elementColor={elementColor}
            />
            <AbilityHotspot
              entity={sp?.melee}
              kind="Melee"
              fallbackName={subclass.melee}
              elementColor={elementColor}
            />
            <AbilityHotspot
              entity={sp?.grenade}
              kind="Grenade"
              fallbackName={subclass.grenade}
              elementColor={elementColor}
            />
          </Cluster>
        </Section>

        {(sp?.aspects?.length ?? subclass.aspects?.length ?? 0) > 0 ? (
          <Section label="Aspects">
            <Cluster gap={8}>
              {(sp?.aspects?.length
                ? sp.aspects
                : subclass.aspects.map((name) => ({
                    hash: null,
                    name,
                    icon: null,
                    description: "",
                    element: null,
                    kindLabel: "Aspect" as const,
                  }))
              ).map((a) => (
                <EntityHotspot
                  key={a.name}
                  kind="Aspect"
                  name={a.name}
                  description={a.description}
                  icon={a.icon}
                  accentColor={accentFor(a.element) ?? elementColor}
                  size={28}
                />
              ))}
            </Cluster>
          </Section>
        ) : null}

        {(sp?.fragments?.length ?? subclass.fragments?.length ?? 0) > 0 ? (
          <Section label="Fragments">
            <Cluster gap={8}>
              {(sp?.fragments?.length
                ? sp.fragments
                : subclass.fragments.map((name) => ({
                    hash: null,
                    name,
                    icon: null,
                    description: "",
                    element: null,
                    kindLabel: "Fragment" as const,
                  }))
              ).map((f) => (
                <EntityHotspot
                  key={f.name}
                  kind="Fragment"
                  name={f.name}
                  description={f.description}
                  icon={f.icon}
                  accentColor={accentFor(f.element) ?? elementColor}
                  size={28}
                />
              ))}
            </Cluster>
          </Section>
        ) : null}

        <Section label="Exotic weapon">
          {exoticWeapon ? (
            <EntityHotspot
              kind="Exotic weapon"
              name={exoticWeapon.name}
              description={exoticWeapon.description}
              icon={exoticWeapon.icon}
              accentColor={accentFor(exoticWeapon.element)}
              size={32}
              showLabel="auto"
            />
          ) : (
            <Text size="sm" tone="muted">
              None
            </Text>
          )}
        </Section>

        {artifact || artifactPerks.length > 0 || variant.artifactName ? (
          <Section label="Artifact">
            <Cluster gap={8}>
              {artifact || variant.artifactName ? (
                <EntityHotspot
                  kind="Artifact"
                  name={artifact?.name ?? variant.artifactName!}
                  description={artifact?.description}
                  icon={artifact?.icon}
                  size={28}
                  showLabel="auto"
                />
              ) : null}
              {artifactPerks.map((p) => (
                <EntityHotspot
                  key={p.hash ?? p.name}
                  kind="Artifact perk"
                  name={p.name}
                  description={p.description}
                  icon={p.icon}
                  size={28}
                />
              ))}
              {!artifactPerks.length &&
                (variant.artifactConfig ?? []).map((hash) => (
                  <Chip key={hash}>Perk {hash}</Chip>
                ))}
            </Cluster>
          </Section>
        ) : null}

        <Section label="Attached sets">
          {setNames.length > 0 ? (
            <Cluster>
              {setNames.map((name) => (
                <Chip key={name} accent>
                  {name}
                </Chip>
              ))}
            </Cluster>
          ) : (
            <Text size="xs" tone="muted">
              No sets attached
            </Text>
          )}
        </Section>

        <Section label="Weapons">
          <Stack gap={8}>
            {WEAPON_SLOTS.map((slot) => {
              const claim = equipment[slot];
              return (
                <Stack key={slot} gap={4}>
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-widest"
                  >
                    {SLOT_LABEL[slot]}
                  </Text>
                  {claim ? (
                    <Stack gap={4}>
                      <Row gap={6} wrap align="center">
                        <EntityHotspot
                          kind="Weapon"
                          name={claim.itemName}
                          description={claim.description}
                          icon={claim.icon}
                          accentColor={accentFor(claim.element)}
                          size={32}
                          showLabel="auto"
                          meta={[
                            claim.element,
                            !claim.instanceId ? "Wishlist" : null,
                          ].filter(Boolean) as string[]}
                        />
                        {!claim.instanceId ? <Chip>Wishlist</Chip> : null}
                      </Row>
                      {(claim.perks?.length ?? 0) > 0 ? (
                        <Cluster gap={6}>
                          {claim.perks!.map((p) => (
                            <EntityHotspot
                              key={p.hash ?? p.name}
                              kind="Weapon perk"
                              name={p.name}
                              description={p.description}
                              icon={p.icon}
                              size={28}
                            />
                          ))}
                        </Cluster>
                      ) : (claim.selectedPerks?.length ?? 0) > 0 ? (
                        <Chip>{claim.selectedPerks!.length} perks</Chip>
                      ) : null}
                    </Stack>
                  ) : (
                    <Text size="xs" tone="muted">
                      Empty
                    </Text>
                  )}
                </Stack>
              );
            })}
          </Stack>
        </Section>

        <Section label="Armor">
          <Stack gap={6}>
            {ARMOR_SLOTS.map((slot) => {
              const claim = equipment[slot];
              return (
                <Row key={slot} justify="between" align="center" gap={8}>
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-widest shrink-0"
                  >
                    {SLOT_LABEL[slot]}
                  </Text>
                  {claim?.itemName ? (
                    <EntityHotspot
                      kind="Armor"
                      name={claim.itemName}
                      description={claim.description}
                      icon={claim.icon}
                      size={32}
                      showLabel="auto"
                    />
                  ) : (
                    <Text size="xs" tone="muted" as="span">
                      Empty
                    </Text>
                  )}
                </Row>
              );
            })}
          </Stack>
        </Section>
      </Stack>
    </Panel>
  );
}
