"use client";

import { useEffect, useState } from "react";

import { FinishArmorOptimizeWorkspace } from "@/components/build/FinishArmorOptimizeWorkspace";
import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
import { SetAttachPicker } from "@/components/lookups/SetAttachPicker";
import { Button, Chip, Cluster, Row, Section, Stack, Text } from "@/components/ui";
import {
  mergeAttachment,
  removeAttachment,
  type AttachmentInput,
} from "@/lib/builds/attachmentMerge";
import type { ArmorSubPath } from "@/components/build/composer/types";

function attachmentsOf(variant: BuildVariantDetail): AttachmentInput[] {
  return variant.attachments.map((a) => ({
    setId: a.setId,
    mode: a.mode,
    ...(a.snapshotConfigs != null ? { snapshotConfigs: a.snapshotConfigs } : {}),
  }));
}

export function ArmorModSetTab({
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
  const [sub, setSub] = useState<ArmorSubPath>("reuse");
  const [improve, setImprove] = useState(false);
  const [busy, setBusy] = useState(false);
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

  const armorAttached = variant.attachments.filter((a) => a.set?.type === "armor");
  const armorLive =
    armorAttached.find((a) => a.mode === "live") ?? armorAttached[0] ?? null;

  // Create path: ensure a live armor set under the hood for optimizer goals (FR-009–011).
  useEffect(() => {
    if (sub !== "create" || !mutationsAllowed || armorLive || ensuringCreate || busy) return;
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
            type: "armor",
            attachNow: true,
          }),
        });
        const body = (await res.json()) as {
          build?: BuildDetail;
          set?: { id: string; name: string; type: string };
          error?: string;
        };
        if (cancelled) return;
        if (!res.ok || !body.set) {
          onError(body.error ?? "Failed to start armor create");
          return;
        }
        await reload();
      } catch {
        if (!cancelled) onError("Failed to start armor create");
      } finally {
        if (!cancelled) setEnsuringCreate(false);
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- ensure once when entering Create without armor
  }, [sub, mutationsAllowed, armorLive?.setId, build.id, variant.id]);

  return (
    <Stack gap={12}>
      <div className="grid grid-cols-2 border border-line">
        <Button
          size="sm"
          variant={sub === "reuse" ? "accent" : "ghost"}
          onClick={() => setSub("reuse")}
        >
          Reuse
        </Button>
        <Button
          size="sm"
          variant={sub === "create" ? "accent" : "ghost"}
          onClick={() => setSub("create")}
        >
          Create
        </Button>
      </div>

      {!mutationsAllowed ? (
        <Text size="xs" tone="muted">
          {mutationReason ?? "Save General first"}
        </Text>
      ) : null}

      {sub === "reuse" ? (
        <>
          <Section label="Attached">
            {variant.attachments.length === 0 ? (
              <Text size="xs" tone="muted">
                No sets attached
              </Text>
            ) : (
              <Stack gap={6}>
                {variant.attachments.map((a) => (
                  <Row key={a.setId} justify="between" align="center">
                    <Cluster gap={6}>
                      <Chip accent>{a.set?.name ?? a.setId}</Chip>
                      <Chip>{a.mode}</Chip>
                      {a.set?.type ? <Chip>{a.set.type}</Chip> : null}
                    </Cluster>
                    <Button
                      size="sm"
                      variant="danger"
                      disabled={!mutationsAllowed || busy}
                      onClick={() =>
                        void patchAttachments(
                          removeAttachment(attachmentsOf(variant), a.setId),
                          "Set detached",
                        )
                      }
                    >
                      Detach
                    </Button>
                  </Row>
                ))}
              </Stack>
            )}
          </Section>

          <Section label="Attach from library">
            <SetAttachPicker
              disabled={!mutationsAllowed || busy}
              excludeIds={variant.attachments.map((a) => a.setId)}
              onAttach={(attachment) =>
                void patchAttachments(
                  mergeAttachment(attachmentsOf(variant), attachment),
                  "Set attached",
                )
              }
            />
            {armorAttached.length > 0 ? (
              <Stack gap={6} className="mt-3">
                <Button
                  size="sm"
                  variant="outline"
                  disabled={!mutationsAllowed}
                  onClick={() => setImprove((v) => !v)}
                >
                  {improve ? "Hide improve kit" : "Improve kit (optional)"}
                </Button>
                {improve ? (
                  <FinishArmorOptimizeWorkspace
                    build={build}
                    setId={armorAttached[0]!.setId}
                    setName={armorAttached[0]!.set?.name}
                    onApplied={() => {
                      onMessage("Improve applied");
                      void reload();
                    }}
                    onManualFill={() => setImprove(false)}
                    onBack={() => setImprove(false)}
                  />
                ) : null}
              </Stack>
            ) : null}
          </Section>
        </>
      ) : (
        <Section label="Create armor set">
          <Text size="xs" tone="muted">
            Choose armor set bonuses / goals and run Optimize. Suggestions never auto-apply.
          </Text>
          {!mutationsAllowed ? null : ensuringCreate || !armorLive ? (
            <Text size="xs" tone="muted">
              Preparing armor create workspace…
            </Text>
          ) : (
            <FinishArmorOptimizeWorkspace
              build={build}
              setId={armorLive.setId}
              setName={armorLive.set?.name}
              onApplied={() => {
                onMessage("Armor kit applied");
                void reload();
              }}
              onManualFill={() => {
                onMessage("Use Reuse to attach an existing set, or keep optimizing.");
              }}
              onBack={() => setSub("reuse")}
            />
          )}
        </Section>
      )}
    </Stack>
  );
}
