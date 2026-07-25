"use client";

import { useState } from "react";

import { BuildSlotFillHost } from "@/components/build/BuildSlotFillHost";
import { CreateSetAttachForm } from "@/components/build/CreateSetAttachForm";
import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
import { SetAttachPicker } from "@/components/lookups/SetAttachPicker";
import { Button, Chip, Cluster, Row, Section, Stack, Text } from "@/components/ui";
import {
  mergeAttachment,
  removeAttachment,
  type AttachmentInput,
} from "@/lib/builds/attachmentMerge";
import type { WeaponSubPath } from "@/components/build/composer/types";

function attachmentsOf(variant: BuildVariantDetail): AttachmentInput[] {
  return variant.attachments.map((a) => ({
    setId: a.setId,
    mode: a.mode,
    ...(a.snapshotConfigs != null ? { snapshotConfigs: a.snapshotConfigs } : {}),
  }));
}

export function WeaponSetTab({
  build,
  variant,
  mutationsAllowed,
  mutationReason,
  onSaved,
  onMessage,
  onError,
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  mutationsAllowed: boolean;
  mutationReason?: string;
  onSaved: (next: BuildDetail, preferredVariantId?: string) => void;
  onMessage: (m: string | null) => void;
  onError: (e: string | null) => void;
}) {
  const [sub, setSub] = useState<WeaponSubPath>("reuse");
  const [busy, setBusy] = useState(false);
  const [fill, setFill] = useState<{ setId: string; slot: string } | null>(null);

  async function reload() {
    const res = await fetch(`/api/user/builds/${build.id}`);
    const body = (await res.json()) as { build?: BuildDetail };
    if (body.build) onSaved(body.build, variant.id);
  }

  async function patchAttachments(next: AttachmentInput[], msg: string) {
    setBusy(true);
    onError(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}/variants/${variant.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ attachments: next }),
      });
      const body = (await res.json()) as { build?: BuildDetail; error?: string };
      if (!res.ok || !body.build) {
        onError(body.error ?? "Failed to update attachments");
        return;
      }
      onSaved(body.build, variant.id);
      onMessage(msg);
    } catch {
      onError("Failed to update attachments");
    } finally {
      setBusy(false);
    }
  }

  const weaponLive = variant.attachments.filter(
    (a) => a.mode === "live" && a.set?.type === "weapon",
  );

  return (
    <Stack gap={12}>
      <div className="grid grid-cols-2 border border-line">
        <Button size="sm" variant={sub === "reuse" ? "accent" : "ghost"} onClick={() => setSub("reuse")}>
          Reuse
        </Button>
        <Button size="sm" variant={sub === "create" ? "accent" : "ghost"} onClick={() => setSub("create")}>
          Create
        </Button>
      </div>
      {!mutationsAllowed ? (
        <Text size="xs" tone="muted">
          {mutationReason}
        </Text>
      ) : null}

      <Section label="Attached">
        {variant.attachments.length === 0 ? (
          <Text size="xs" tone="muted">
            None
          </Text>
        ) : (
          variant.attachments.map((a) => (
            <Row key={a.setId} justify="between">
              <Cluster gap={4}>
                <Chip accent>{a.set?.name ?? a.setId}</Chip>
                {a.set?.type ? <Chip>{a.set.type}</Chip> : null}
              </Cluster>
              <Button
                size="sm"
                variant="danger"
                disabled={!mutationsAllowed || busy}
                onClick={() =>
                  void patchAttachments(
                    removeAttachment(attachmentsOf(variant), a.setId),
                    "Detached",
                  )
                }
              >
                Detach
              </Button>
            </Row>
          ))
        )}
      </Section>

      {sub === "reuse" ? (
        <SetAttachPicker
          disabled={!mutationsAllowed || busy}
          excludeIds={variant.attachments.map((a) => a.setId)}
          onAttach={(attachment) =>
            void patchAttachments(
              mergeAttachment(attachmentsOf(variant), attachment),
              "Weapon set attached",
            )
          }
        />
      ) : (
        <Stack gap={10}>
          <CreateSetAttachForm
            buildId={build.id}
            variantId={variant.id}
            defaultType="weapon"
            allowPair={false}
            busy={!mutationsAllowed || busy}
            onCreated={(r) => {
              onMessage(`Created ${r.set.name}`);
              void reload();
            }}
          />
          <Text size="xs" tone="muted">
            Primary / Secondary / Heavy fills: use Fill on a live weapon set. Catalog search
            surfaces synergy-matching weapons first when ranking helpers are wired in the fill
            host.
          </Text>
          {weaponLive.map((a) => (
            <Row key={a.setId} gap={6} wrap>
              <Text size="xs">{a.set?.name}</Text>
              {(["primary", "special", "heavy"] as const).map((slot) => (
                <Button
                  key={slot}
                  size="sm"
                  variant="ghost"
                  disabled={!mutationsAllowed}
                  onClick={() => setFill({ setId: a.setId, slot })}
                >
                  Fill {slot}
                </Button>
              ))}
            </Row>
          ))}
          {fill ? (
            <BuildSlotFillHost
              setId={fill.setId}
              slot={fill.slot}
              attachmentMode="live"
              onClose={() => setFill(null)}
              onFilled={() => {
                onMessage("Slot filled");
                void reload();
                setFill(null);
              }}
            />
          ) : null}
        </Stack>
      )}
    </Stack>
  );
}
