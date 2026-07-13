"use client";

import type {
  BuildDetail,
  BuildVariantDetail,
  PresentedEntity,
  SlotClaimSummary,
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
import type { EquipmentSlot } from "@/lib/sets/schemas";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element];
  }
  return undefined;
}

function claimSourceLabel(source: string | undefined): string | null {
  switch (source) {
    case "set":
      return "Set";
    case "pair_set":
      return "Pair";
    case "build_exotic_armor":
      return "Identity";
    case "variant_exotic_weapon":
      return "Variant";
    default:
      return source?.trim() ? source : null;
  }
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

/** Compact loadout strip: one icon per filled slot (at-a-glance density). */
function GearStrip({
  equipment,
  slots,
  kind,
}: {
  equipment: Partial<Record<EquipmentSlot, SlotClaimSummary>>;
  slots: readonly EquipmentSlot[];
  kind: "Weapon" | "Armor";
}) {
  const filled = slots
    .map((slot) => ({ slot, claim: equipment[slot] }))
    .filter((x): x is { slot: EquipmentSlot; claim: SlotClaimSummary } =>
      Boolean(x.claim?.itemName),
    );

  if (filled.length === 0) {
    return (
      <Text size="xs" tone="muted">
        No {kind.toLowerCase()} filled
      </Text>
    );
  }

  return (
    <Cluster gap={6}>
      {filled.map(({ slot, claim }) => (
        <EntityHotspot
          key={slot}
          kind={kind}
          name={claim.itemName}
          description={claim.description}
          icon={claim.icon}
          accentColor={accentFor(claim.element)}
          size={40}
          showLabel="never"
          meta={[
            SLOT_LABEL[slot] ?? slot,
            claim.element,
            claimSourceLabel(claim.source),
            !claim.instanceId ? "Wishlist" : null,
          ].filter(Boolean) as string[]}
        />
      ))}
    </Cluster>
  );
}

/**
 * Dense gear row: slot · icon+name · meta chips · perk icons on one line.
 */
function GearSlotRow({
  slot,
  claim,
  kind,
}: {
  slot: EquipmentSlot;
  claim: SlotClaimSummary | undefined;
  kind: "Weapon" | "Armor";
}) {
  const source = claimSourceLabel(claim?.source);
  const perks = claim?.perks ?? [];

  return (
    <div className="grid grid-cols-[4.5rem_minmax(0,1fr)] gap-x-3 gap-y-1 items-start py-1 border-b border-line/60 last:border-b-0">
      <Text
        size="xs"
        tone="muted"
        className="uppercase tracking-widest pt-2"
      >
        {SLOT_LABEL[slot] ?? slot}
      </Text>
      <Stack gap={4} className="min-w-0">
        {claim?.itemName ? (
          <>
            <Row gap={8} align="center" wrap className="min-w-0">
              <EntityHotspot
                kind={kind}
                name={claim.itemName}
                description={claim.description}
                icon={claim.icon}
                accentColor={accentFor(claim.element)}
                size={36}
                showLabel="always"
                meta={[
                  claim.element,
                  source,
                  !claim.instanceId ? "Wishlist" : "Inventory",
                ].filter(Boolean) as string[]}
              />
              <Cluster gap={4}>
                {claim.element ? (
                  <span
                    className="inline-flex items-center text-[10px] tracking-wide px-2 py-0.5 border whitespace-nowrap"
                    style={{
                      borderColor: accentFor(claim.element) ?? "var(--line)",
                      color: accentFor(claim.element) ?? undefined,
                    }}
                  >
                    {claim.element}
                  </span>
                ) : null}
                {source ? <Chip>{source}</Chip> : null}
                {!claim.instanceId ? <Chip accent>Wishlist</Chip> : null}
              </Cluster>
            </Row>
            {perks.length > 0 ? (
              <Cluster gap={4}>
                {perks.map((p) => (
                  <EntityHotspot
                    key={p.hash ?? p.name}
                    kind="Weapon perk"
                    name={p.name}
                    description={p.description}
                    icon={p.icon}
                    size={24}
                    showLabel="never"
                  />
                ))}
              </Cluster>
            ) : (claim.selectedPerks?.length ?? 0) > 0 ? (
              <Text size="xs" tone="muted">
                {claim.selectedPerks!.length} perk
                {claim.selectedPerks!.length === 1 ? "" : "s"} selected
              </Text>
            ) : null}
          </>
        ) : (
          <Text size="xs" tone="muted" className="pt-2">
            Empty
          </Text>
        )}
      </Stack>
    </div>
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
  const conflicts = variant.resolved?.conflicts ?? [];
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

  const weaponFilled = WEAPON_SLOTS.some((s) => equipment[s]?.itemName);
  const armorFilled = ARMOR_SLOTS.some((s) => equipment[s]?.itemName);

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

        {/* At-a-glance loadout when any gear resolved */}
        {focused && (weaponFilled || armorFilled) ? (
          <Section label="Loadout">
            <Stack gap={8}>
              {weaponFilled ? (
                <Stack gap={4}>
                  <Text size="xs" tone="muted" className="uppercase tracking-widest">
                    Weapons
                  </Text>
                  <GearStrip
                    equipment={equipment}
                    slots={WEAPON_SLOTS}
                    kind="Weapon"
                  />
                </Stack>
              ) : null}
              {armorFilled ? (
                <Stack gap={4}>
                  <Text size="xs" tone="muted" className="uppercase tracking-widest">
                    Armor
                  </Text>
                  <GearStrip
                    equipment={equipment}
                    slots={ARMOR_SLOTS}
                    kind="Armor"
                  />
                </Stack>
              ) : null}
            </Stack>
          </Section>
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

        {conflicts.length > 0 ? (
          <Section label="Slot conflicts">
            <Stack gap={4}>
              {conflicts.map((c) => (
                <Text key={c.slot} size="xs" tone="warning">
                  {(SLOT_LABEL[c.slot] ?? c.slot) +
                    `: ${c.claimants.map((x) => x.itemName).join(" vs ")}`}
                </Text>
              ))}
            </Stack>
          </Section>
        ) : null}

        <Section label="Weapons">
          <Stack gap={0}>
            {WEAPON_SLOTS.map((slot) => (
              <GearSlotRow
                key={slot}
                slot={slot}
                claim={equipment[slot]}
                kind="Weapon"
              />
            ))}
          </Stack>
        </Section>

        <Section label="Armor">
          <Stack gap={0}>
            {ARMOR_SLOTS.map((slot) => (
              <GearSlotRow
                key={slot}
                slot={slot}
                claim={equipment[slot]}
                kind="Armor"
              />
            ))}
          </Stack>
        </Section>
      </Stack>
    </Panel>
  );
}
