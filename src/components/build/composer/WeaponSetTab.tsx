"use client";

import { useEffect, useState } from "react";

import { BuildSlotFillHost } from "@/components/build/BuildSlotFillHost";
import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
import { SetAttachPicker } from "@/components/lookups/SetAttachPicker";
import { Button, Chip, Cluster, Row, Section, Stack, Text } from "@/components/ui";
import {
  mergeAttachment,
  removeAttachment,
  type AttachmentInput,
} from "@/lib/builds/attachmentMerge";
import type { WeaponSubPath } from "@/components/build/composer/types";

const WEAPON_CREATE_SLOTS = [
  { slot: "primary", label: "Primary" },
  { slot: "special", label: "Secondary" },
  { slot: "heavy", label: "Heavy" },
] as const;

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
  const [ensuringCreate, setEnsuringCreate] = useState(false);

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
  const liveWeapon = weaponLive[0] ?? null;

  // Create path: auto-ensure a live weapon set under the hood (no attach chrome).
  useEffect(() => {
    if (sub !== "create" || !mutationsAllowed || liveWeapon || ensuringCreate || busy) return;
    let cancelled = false;
    setEnsuringCreate(true);
    onError(null);
    void (async () => {
      try {
        const res = await fetch(`/api/user/builds/${build.id}/create-set-attach`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            variantId: variant.id,
            type: "weapon",
            attachNow: true,
          }),
        });
        const body = (await res.json()) as {
          set?: { id: string; name: string; type: string };
          error?: string;
        };
        if (cancelled) return;
        if (!res.ok || !body.set) {
          onError(body.error ?? "Failed to start weapon create");
          return;
        }
        await reload();
      } catch {
        if (!cancelled) onError("Failed to start weapon create");
      } finally {
        if (!cancelled) setEnsuringCreate(false);
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- ensure once when entering Create without weapon set
  }, [sub, mutationsAllowed, liveWeapon?.setId, build.id, variant.id]);

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

      {sub === "reuse" ? (
        <>
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
        </>
      ) : (
        <Stack gap={10}>
          <Text size="xs" tone="muted">
            Pick Primary, Secondary, and Heavy. Catalog search is slot-constrained; synergy matches
            rank first when available.
          </Text>
          {!mutationsAllowed ? null : ensuringCreate || !liveWeapon ? (
            <Text size="xs" tone="muted">
              Preparing weapon slots…
            </Text>
          ) : (
            <div className="grid gap-3 md:grid-cols-3">
              {WEAPON_CREATE_SLOTS.map(({ slot, label }) => (
                <Section key={slot} label={label}>
                  {fill?.setId === liveWeapon.setId && fill.slot === slot ? (
                    <BuildSlotFillHost
                      setId={liveWeapon.setId}
                      slot={slot}
                      attachmentMode="live"
                      onClose={() => setFill(null)}
                      onFilled={() => {
                        onMessage(`${label} filled`);
                        void reload();
                        setFill(null);
                      }}
                    />
                  ) : (
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={!mutationsAllowed || busy}
                      onClick={() => setFill({ setId: liveWeapon.setId, slot })}
                    >
                      Choose {label}
                    </Button>
                  )}
                </Section>
              ))}
            </div>
          )}
        </Stack>
      )}
    </Stack>
  );
}
