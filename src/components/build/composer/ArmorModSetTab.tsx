"use client";

import { useState } from "react";

import { CreateSetAttachForm } from "@/components/build/CreateSetAttachForm";
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

      {sub === "reuse" ? (
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
      ) : (
        <Section label="Create & attach">
          <CreateSetAttachForm
            buildId={build.id}
            variantId={variant.id}
            defaultType="armor"
            busy={!mutationsAllowed || busy}
            onCreated={(r) => {
              onMessage(`Created ${r.set.name}`);
              void reload();
            }}
          />
          <Text size="xs" tone="muted" className="mt-2">
            Optimize goals use the existing armor optimizer workspace after a set exists — open
            Improve kit from Reuse or attach then improve. Suggestions never auto-apply.
          </Text>
        </Section>
      )}
    </Stack>
  );
}
