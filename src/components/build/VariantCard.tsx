"use client";

import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
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
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

export function VariantCard({
  build,
  variant,
  selected,
  onSelect,
  onEdit,
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  selected: boolean;
  onSelect: () => void;
  onEdit?: () => void;
}) {
  const equipment = variant.resolved?.equipment ?? {};
  const setNames = variant.attachments
    .map((a) => a.set?.name)
    .filter((name): name is string => Boolean(name));

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
    <Panel as="article" tone={selected ? "accent" : "default"} className="h-full">
      <Stack gap={12}>
        <Row justify="between" align="center">
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
          <Row gap={4}>
            <Button
              variant={selected ? "accent" : "outline"}
              size="sm"
              onClick={onSelect}
            >
              {selected ? "Selected" : "Select"}
            </Button>
            {onEdit ? (
              <Button size="sm" onClick={onEdit}>
                Edit
              </Button>
            ) : null}
          </Row>
        </Row>

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
