"use client";

import { useState } from "react";
import Link from "next/link";

import { SLOT_LABEL, type SetDetail } from "@/components/sets/types";
import {
  Button,
  Chip,
  Cluster,
  EntityHotspot,
  Heading,
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
import { buildDetailHref } from "@/lib/sets/buildDetailHref";
import { SLOTS_BY_SET_TYPE, type SetType } from "@/lib/sets/schemas";

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
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

  return (
    <Panel tone="raised" className="w-full">
      <Stack gap={14}>
        <Row justify="between" align="start" gap={12} wrap>
          <Stack gap={6} className="min-w-0 flex-1">
            <Heading level={1}>{set.name}</Heading>
            <Cluster>
              <Chip accent>{set.type}</Chip>
              {(set.tagIds ?? []).map((t) => (
                <Chip key={t}>{t}</Chip>
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
                  href={buildDetailHref(b.buildId, b.variantNames)}
                  className="block no-underline text-inherit hover:border-accent transition-colors"
                >
                  <Panel
                    tone="muted"
                    pad="sm"
                    className="hover:border-accent transition-colors"
                  >
                    <Stack gap={2}>
                      <Text size="sm" weight="medium" className="text-accent">
                        {b.buildName}
                      </Text>
                      <Text size="xs" tone="muted">
                        Variants: {b.variantNames.join(", ") || "—"}
                        {b.variantNames.length === 1
                          ? " · opens this variant"
                          : " · open build"}
                      </Text>
                    </Stack>
                  </Panel>
                </Link>
              ))}
            </Stack>
          )}
        </Section>

        {isMods ? (
          <Section label="Mods">
            <Stack gap={10}>
              <Text size="xs" tone="muted">
                Mod sets hold combat/armor mods as plug hashes. Add mods from
                the manifest search below.
              </Text>
              {activeItems.length === 0 ? (
                <Text size="xs" tone="muted">
                  No mods in this set yet.
                </Text>
              ) : (
                <Stack gap={6}>
                  {activeItems.map((item) => (
                    <Row
                      key={item.id}
                      justify="between"
                      align="center"
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
              <Button
                size="sm"
                variant="accent"
                onClick={() => onFillSlot("mod")}
              >
                Add mod
              </Button>
            </Stack>
          </Section>
        ) : (
          <Section label="Slots">
            <Stack gap={8}>
              {(slots as readonly string[]).map((slot) => {
                const item = activeItems.find((i) => i.slot === slot);
                return (
                  <Row key={slot} justify="between" align="center" gap={8} wrap>
                    <Stack gap={2} className="min-w-0 flex-1">
                      <Text
                        size="xs"
                        tone="muted"
                        className="uppercase tracking-widest"
                      >
                        {SLOT_LABEL[slot] ?? slot}
                      </Text>
                      {item ? (
                        <EntityHotspot
                          kind={SLOT_LABEL[slot] ?? slot}
                          name={item.itemName}
                          description={item.description}
                          icon={item.icon}
                          accentColor={accentFor(item.element)}
                          size={32}
                          showLabel="auto"
                          meta={[
                            item.stale ? "Stale hash" : null,
                            item.instanceId ? "Instance pinned" : null,
                          ].filter(Boolean) as string[]}
                        />
                      ) : (
                        <Text size="xs" tone="muted">
                          Empty
                        </Text>
                      )}
                    </Stack>
                    <Button size="sm" onClick={() => onFillSlot(slot)}>
                      {item ? "Replace" : "Fill"}
                    </Button>
                  </Row>
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
