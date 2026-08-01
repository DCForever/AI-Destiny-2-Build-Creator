"use client";

import { useEffect, useMemo, useState } from "react";

import { BuildActions } from "@/components/build/BuildActions";
import type {
  BuildDetail,
  BuildVariantDetail,
  BungieCharacter,
} from "@/components/build/types";
import { Callout, Section, Stack, Text } from "@/components/ui";
import { finishMissingReasons } from "@/lib/builds/finishMissingReasons";
import { evaluateFinishGapsFromVariant } from "@/lib/builds/finishGapsFromDetail";

export function FinishTab({
  build,
  variant,
  characters,
  characterId,
  onCharacterId,
  busy,
  message,
  onEquip,
  onDimExport,
  onDimJson,
}: {
  build: BuildDetail | null;
  variant: BuildVariantDetail | null;
  characters: BungieCharacter[];
  characterId: string;
  onCharacterId: (id: string) => void;
  busy: string | null;
  message: string | null;
  onEquip: () => void;
  onDimExport: () => void;
  onDimJson: () => void;
}) {
  const [equipment, setEquipment] = useState<
    Partial<Record<string, { slot?: string; itemHash?: number; itemName?: string }>>
  >({});

  useEffect(() => {
    if (!build || !variant) return;
    void (async () => {
      try {
        const res = await fetch(
          `/api/user/builds/${build.id}/variants/${variant.id}/resolved`,
        );
        if (!res.ok) return;
        const body = (await res.json()) as {
          equipment?: Partial<
            Record<string, { slot?: string; itemHash?: number; itemName?: string }>
          >;
        };
        setEquipment(body.equipment ?? {});
      } catch {
        /* optional */
      }
    })();
  }, [build, variant]);

  const gaps = useMemo(() => {
    if (!variant) return null;
    const hasModCoverage = variant.attachments.some((a) => a.set?.type === "mod");
    return evaluateFinishGapsFromVariant({
      variantId: variant.id,
      isDefaultVariant: Boolean(variant.isDefault),
      attachments: variant.attachments.map((a) => ({
        setId: a.setId,
        mode: a.mode,
        set: a.set,
      })),
      equipment,
      hasModCoverage,
    });
  }, [variant, equipment]);

  const reasons = gaps ? finishMissingReasons(gaps) : ["Select or create a build to finish"];
  const complete = Boolean(gaps?.complete);
  const canAct = Boolean(build && variant && complete);

  return (
    <Stack gap={12}>
      <Section label="Readiness">
        {!complete ? (
          <Callout tone="warning">
            <Stack gap={4}>
              <Text size="sm">Finish is always available — equip/export stay locked until complete.</Text>
              {reasons.map((r) => (
                <Text key={r} size="xs">
                  · {r}
                </Text>
              ))}
            </Stack>
          </Callout>
        ) : (
          <Callout tone="success">
            Combat categories satisfied. Equip still requires owned-instance pins (equip-ready).
          </Callout>
        )}
      </Section>

      {build && variant ? (
        <div className={!canAct ? "opacity-60 pointer-events-none" : undefined}>
          <BuildActions
            className={build.className}
            characters={characters}
            characterId={characterId}
            onCharacterId={onCharacterId}
            equipReadyHint={
              canAct
                ? null
                : "Complete armor, weapons, and mods coverage before equip/export."
            }
            busy={canAct ? busy : "locked"}
            message={message}
            onEquip={onEquip}
            onDimExport={onDimExport}
            onDimJson={onDimJson}
          />
        </div>
      ) : (
        <Text size="xs" tone="muted">
          Save General to create a build, then complete sets to unlock equip.
        </Text>
      )}
    </Stack>
  );
}
