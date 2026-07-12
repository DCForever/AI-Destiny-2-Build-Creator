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
  Panel,
  Row,
  Section,
  Stack,
  Text,
} from "@/components/ui";

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
  const subclass = build.subclass;
  const exoticWeapon =
    variant.exoticWeaponName ?? build.exoticWeaponName ?? "None";
  const setNames = variant.attachments
    .map((a) => a.set?.name)
    .filter((name): name is string => Boolean(name));

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
              <Text size="xs" tone="muted" as="span" className="ml-2 uppercase tracking-widest">
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
          <Text size="sm">{exoticWeapon}</Text>
        </Section>

        {variant.artifactName || (variant.artifactConfig?.length ?? 0) > 0 ? (
          <Section label="Artifact">
            <Cluster>
              {variant.artifactName ? (
                <Chip accent>{variant.artifactName}</Chip>
              ) : null}
              {(variant.artifactConfig ?? []).map((hash) => (
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
                  <Text size="xs" tone="muted" className="uppercase tracking-widest">
                    {SLOT_LABEL[slot]}
                  </Text>
                  {claim ? (
                    <Row gap={6} wrap>
                      <Text size="sm" as="span">
                        {claim.itemName}
                      </Text>
                      {(claim.selectedPerks?.length ?? 0) > 0 ? (
                        <Chip>{claim.selectedPerks!.length} perks</Chip>
                      ) : null}
                      {!claim.instanceId ? <Chip>Wishlist</Chip> : null}
                    </Row>
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
                <Row key={slot} justify="between" align="baseline" gap={8}>
                  <Text size="xs" tone="muted" className="uppercase tracking-widest shrink-0">
                    {SLOT_LABEL[slot]}
                  </Text>
                  {claim?.itemName ? (
                    <Text size="sm" as="span" className="text-right">
                      {claim.itemName}
                    </Text>
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

        <Section label="Abilities">
          <Cluster>
            <Chip accent>{subclass.melee}</Chip>
            <Chip accent>{subclass.grenade}</Chip>
            <Chip accent>{subclass.classAbility}</Chip>
          </Cluster>
        </Section>

        <Section label="Aspects / fragments">
          <Cluster>
            {subclass.aspects.map((a) => (
              <Chip key={a} accent>
                {a}
              </Chip>
            ))}
            {subclass.fragments.map((f) => (
              <Chip key={f}>
                {f}
              </Chip>
            ))}
          </Cluster>
        </Section>

        {variant.notes ? (
          <Section label="Notes">
            <Text size="xs" tone="muted" className="leading-relaxed">
              {variant.notes}
            </Text>
          </Section>
        ) : null}

        {(variant.resolved?.conflicts.length ?? 0) > 0 ? (
          <Text size="xs" tone="warning">
            {variant.resolved!.conflicts.length} slot conflict
            {variant.resolved!.conflicts.length === 1 ? "" : "s"}
          </Text>
        ) : null}
      </Stack>
    </Panel>
  );
}
