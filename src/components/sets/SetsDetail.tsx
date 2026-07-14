"use client";

import { useState } from "react";
import Link from "next/link";

import { ArmorStatsPanel } from "@/components/catalog/ArmorStatsPanel";
import { SLOT_LABEL, type SetDetail, type SetItem } from "@/components/sets/types";
import {
  Button,
  Chip,
  Cluster,
  ConceptTagChip,
  EntityHotspot,
  Heading,
  Panel,
  Row,
  Section,
  Stack,
  Text,
} from "@/components/ui";
import { ARMOR_STAT_NAMES } from "@/data/rules/statBenefits";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import { armorEnergyCapacity, sumEnergyCosts } from "@/lib/builds/modEnergy";
import { buildDetailHref } from "@/lib/sets/buildDetailHref";
import { isLegacyModItem } from "@/lib/sets/modSetEnergy";
import {
  ARMOR_SLOTS,
  modSetArmorSlotOf,
  SLOTS_BY_SET_TYPE,
  type SetType,
} from "@/lib/sets/schemas";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

function itemMetaChips(item: SetItem): string[] {
  const meta: string[] = [];
  if (item.isExotic) meta.push("Exotic");
  if (item.element) meta.push(item.element);
  if (item.ammo) meta.push(item.ammo);
  if (item.itemTypeName) meta.push(item.itemTypeName);
  if (item.frame) meta.push(item.frame);
  if (item.classType) meta.push(item.classType);
  if (item.tierLabel) meta.push(item.tierLabel);
  else if (item.tier != null) meta.push(`Tier ${item.tier}`);
  if (item.originTraitName) meta.push(item.originTraitName);
  if (item.power != null) meta.push(`P${item.power}`);
  if (item.location) meta.push(item.location);
  if (item.instanceId) meta.push("Instance pinned");
  if (item.stale) meta.push("Stale hash");
  return meta;
}

function ItemExtras({ item }: { item: SetItem }) {
  const traits = item.selectedTraitPerks ?? [];
  const available = item.availableTraitPerks ?? [];
  const synergies = item.linkedSynergies ?? [];
  const hasExtras =
    traits.length > 0 || available.length > 0 || synergies.length > 0;

  return (
    <Stack gap={4} className="min-w-0 w-full">
      {hasExtras ? (
        <Stack gap={3}>
          {traits.length > 0 ? (
            <Stack gap={2}>
              <Text size="xs" tone="muted" className="uppercase tracking-wide">
                Selected perks
              </Text>
              <Cluster gap={3}>
                {traits.map((p) => (
                  <Chip key={p.hash} accent>
                    {p.name}
                  </Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
          {available.length > 0 ? (
            <Stack gap={2}>
              <Text size="xs" tone="muted" className="uppercase tracking-wide">
                Available perks
              </Text>
              <Cluster gap={3}>
                {available.map((p) => (
                  <Chip key={p.hash}>{p.name}</Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
          {synergies.length > 0 ? (
            <Stack gap={2}>
              <Text size="xs" tone="muted" className="uppercase tracking-wide">
                Linked synergies
              </Text>
              <Cluster gap={3}>
                {synergies.map((s) => (
                  <Chip key={s.id} accent>
                    {s.label}
                  </Chip>
                ))}
              </Cluster>
            </Stack>
          ) : null}
        </Stack>
      ) : null}
      {item.statValues ? (
        <ArmorStatsPanel
          statValues={item.statValues}
          totalStats={item.totalStats}
          statsIncomplete={item.statsIncomplete ?? false}
        />
      ) : item.instanceId &&
        ["helmet", "arms", "chest", "legs", "class_item", "exotic_armor"].includes(
          item.slot,
        ) ? (
        <Text size="xs" tone="muted">
          No armor stats on this copy — re-sync inventory.
        </Text>
      ) : !item.instanceId &&
        ["helmet", "arms", "chest", "legs", "class_item", "exotic_armor"].includes(
          item.slot,
        ) ? (
        <Text size="xs" tone="muted">
          No instance — stats unknown (wishlist).
        </Text>
      ) : null}
    </Stack>
  );
}

export function SetsDetail({
  set,
  onEdit,
  onFillSlot,
  onDelete,
  onUpdated,
  deleteBusy,
}: {
  set: SetDetail;
  onEdit: () => void;
  onFillSlot: (slot: string) => void;
  onDelete: () => void;
  onUpdated?: (next: SetDetail) => void;
  deleteBusy?: boolean;
}) {
  const activeItems = set.items.filter((i) => !i.removedAt);
  const slots = SLOTS_BY_SET_TYPE[set.type as SetType];
  const isMods = slots === "mods_only";
  const isArmor = set.type === "armor" || set.type === "Armor";
  const [removeBusy, setRemoveBusy] = useState<string | null>(null);
  const [removeError, setRemoveError] = useState<string | null>(null);

  async function removeItem(itemId: string) {
    setRemoveBusy(itemId);
    setRemoveError(null);
    try {
      const res = await fetch(
        `/api/user/sets/${set.id}/items?itemId=${encodeURIComponent(itemId)}`,
        { method: "DELETE" },
      );
      const body = (await res.json()) as { set?: SetDetail; error?: string };
      if (!res.ok || !body.set) {
        setRemoveError(body.error ?? "Failed to remove item");
        return;
      }
      onUpdated?.(body.set);
    } catch {
      setRemoveError("Failed to remove item");
    } finally {
      setRemoveBusy(null);
    }
  }

  const totals = set.armorStatTotals;

  return (
    <Panel tone="raised" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Heading level={1}>{set.name}</Heading>
            <Cluster>
              <Chip accent>{set.type}</Chip>
              {(set.tagIds ?? []).map((t) => (
                <ConceptTagChip key={t} tagId={t} size={22} />
              ))}
            </Cluster>
          </Stack>
          <Row gap={4} wrap>
            <Button size="sm" onClick={onEdit}>
              Edit meta
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

        {removeError ? (
          <Text size="xs" tone="danger">
            {removeError}
          </Text>
        ) : null}

        {isArmor ? (
          <Section label="Armor stats">
            <Stack gap={6}>
              <Text size="xs" tone="muted">
                Totals use pinned inventory copies; wishlist pieces have no
                rolls.
              </Text>
              {totals && totals.piecesWithStats > 0 ? (
                <Stack gap={4}>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-x-3 gap-y-1">
                    {ARMOR_STAT_NAMES.map((name) => (
                      <Row key={name} justify="between" gap={8}>
                        <Text size="xs" tone="muted">
                          {name}
                        </Text>
                        <Text size="xs" weight="medium" className="tabular-nums">
                          {totals.statValues[name] ?? "—"}
                        </Text>
                      </Row>
                    ))}
                  </div>
                  <Text size="xs" weight="medium">
                    Total {totals.grandTotal}
                    {totals.incomplete ? " · incomplete" : ""}
                  </Text>
                </Stack>
              ) : (
                <Text size="xs" tone="muted">
                  No instance stats yet — pin owned armor copies when filling
                  slots.
                </Text>
              )}
            </Stack>
          </Section>
        ) : null}

        <Section label="Used by builds">
          {(set.usedByBuilds?.length ?? 0) === 0 ? (
            <Text size="sm" tone="muted">
              No curated builds use this set yet.
            </Text>
          ) : (
            <Stack gap={6}>
              {set.usedByBuilds!.map((b) => (
                <Link
                  key={b.buildId}
                  href={buildDetailHref(b.buildId)}
                  className="block"
                >
                  <Panel tone="muted" pad="sm">
                    <Text size="sm" weight="medium">
                      {b.buildName}
                    </Text>
                    {b.variantNames.length > 0 ? (
                      <Text size="xs" tone="muted">
                        {b.variantNames.join(" · ")}
                      </Text>
                    ) : null}
                  </Panel>
                </Link>
              ))}
            </Stack>
          )}
        </Section>

        {isMods ? (
          <Section label="Mods by armor piece">
            <Stack gap={12}>
              <Text size="xs" tone="muted">
                Add mods under each armor piece. Slot-scoped plugs must match
                the piece; general / tuning mods work on any piece. Multiple
                mods per piece up to energy capacity (10 by default).
              </Text>
              {ARMOR_SLOTS.map((armorSlot) => {
                const pieceMods = activeItems.filter(
                  (i) => modSetArmorSlotOf(i.slot) === armorSlot,
                );
                const capacity = armorEnergyCapacity(null);
                const used = sumEnergyCosts(
                  pieceMods.map((m) => m.energyCost),
                );
                return (
                  <Panel key={armorSlot} tone="muted" pad="sm">
                    <Stack gap={8}>
                      <Row justify="between" align="center" gap={8} wrap>
                        <Stack gap={2}>
                          <Text size="sm" weight="medium">
                            {SLOT_LABEL[armorSlot] ?? armorSlot}
                          </Text>
                          <Text
                            size="xs"
                            tone={used > capacity ? "danger" : "muted"}
                          >
                            Energy {used}/{capacity} · {pieceMods.length} mod
                            {pieceMods.length === 1 ? "" : "s"}
                          </Text>
                        </Stack>
                        <Button
                          size="sm"
                          variant="accent"
                          onClick={() => onFillSlot(armorSlot)}
                        >
                          Add mod
                        </Button>
                      </Row>
                      {pieceMods.length === 0 ? (
                        <Text size="xs" tone="muted">
                          No mods on this piece yet.
                        </Text>
                      ) : (
                        <Stack gap={6}>
                          {pieceMods.map((item) => (
                            <Row
                              key={item.id}
                              justify="between"
                              align="start"
                              gap={8}
                              wrap
                            >
                              <EntityHotspot
                                kind="Mod"
                                name={item.itemName}
                                description={item.description}
                                icon={item.icon}
                                accentColor={accentFor(item.element)}
                                size={32}
                                showLabel="auto"
                                meta={[
                                  ...itemMetaChips(item),
                                  ...(item.energyCost != null
                                    ? [`${item.energyCost} energy`]
                                    : []),
                                  ...(item.slotCategory
                                    ? [item.slotCategory]
                                    : []),
                                ]}
                              />
                              <Button
                                size="sm"
                                variant="danger"
                                disabled={removeBusy === item.id}
                                onClick={() => void removeItem(item.id)}
                              >
                                Remove
                              </Button>
                            </Row>
                          ))}
                        </Stack>
                      )}
                    </Stack>
                  </Panel>
                );
              })}
              {(() => {
                const legacy = activeItems.filter((i) => isLegacyModItem(i.slot));
                if (legacy.length === 0) return null;
                return (
                  <Panel tone="muted" pad="sm">
                    <Stack gap={8}>
                      <Text size="sm" weight="medium">
                        Unscoped (legacy)
                      </Text>
                      <Text size="xs" tone="muted">
                        Older free-list mods. Remove and re-add under an armor
                        piece to organize.
                      </Text>
                      {legacy.map((item) => (
                        <Row
                          key={item.id}
                          justify="between"
                          align="start"
                          gap={8}
                          wrap
                        >
                          <EntityHotspot
                            kind="Mod"
                            name={item.itemName}
                            description={item.description}
                            icon={item.icon}
                            size={32}
                            showLabel="auto"
                          />
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={removeBusy === item.id}
                            onClick={() => void removeItem(item.id)}
                          >
                            Remove
                          </Button>
                        </Row>
                      ))}
                    </Stack>
                  </Panel>
                );
              })()}
            </Stack>
          </Section>
        ) : (
          <Section label="Slots">
            <Stack gap={8}>
              {(slots as readonly string[]).map((slot) => {
                const item = activeItems.find((i) => i.slot === slot);
                return (
                  <Panel key={slot} tone="muted" pad="sm">
                    <Row justify="between" align="start" gap={8} wrap>
                      <Stack gap={4} className="min-w-0 flex-1">
                        <Text
                          size="xs"
                          tone="muted"
                          className="uppercase tracking-widest"
                        >
                          {SLOT_LABEL[slot] ?? slot}
                        </Text>
                        {item ? (
                          <>
                            <EntityHotspot
                              kind={SLOT_LABEL[slot] ?? slot}
                              name={item.itemName}
                              description={item.description}
                              icon={item.icon}
                              accentColor={accentFor(item.element)}
                              size={40}
                              showLabel="auto"
                              meta={itemMetaChips(item)}
                            />
                            {item.description ? (
                              <Text
                                size="xs"
                                tone="muted"
                                className="line-clamp-2"
                              >
                                {item.description}
                              </Text>
                            ) : null}
                            <ItemExtras item={item} />
                          </>
                        ) : (
                          <Text size="xs" tone="muted">
                            Empty
                          </Text>
                        )}
                      </Stack>
                      <Stack gap={4}>
                        <Button size="sm" onClick={() => onFillSlot(slot)}>
                          {item ? "Replace" : "Fill"}
                        </Button>
                        {item ? (
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={removeBusy === item.id}
                            onClick={() => void removeItem(item.id)}
                          >
                            Remove
                          </Button>
                        ) : null}
                      </Stack>
                    </Row>
                  </Panel>
                );
              })}
            </Stack>
          </Section>
        )}

        {set.modEncourage ? (
          <Text size="xs" tone="warning">
            Some armor pieces may have empty mod slots.
          </Text>
        ) : null}
      </Stack>
    </Panel>
  );
}
