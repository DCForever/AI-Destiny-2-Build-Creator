"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { BuildSlotFillHost } from "@/components/build/BuildSlotFillHost";
import { CaptureSetsFromBuild } from "@/components/build/CaptureSetsFromBuild";
import { CreateSetAttachForm } from "@/components/build/CreateSetAttachForm";
import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
import { SetAttachPicker } from "@/components/lookups/SetAttachPicker";
import {
  Button,
  Callout,
  Cluster,
  Panel,
  Row,
  Stack,
  Text,
} from "@/components/ui";
import {
  finishCategoryLabel,
  type FinishCategory,
  type FinishGap,
  type FinishGapsResult,
} from "@/lib/builds/finishGaps";
import { evaluateFinishGapsFromVariant } from "@/lib/builds/finishGapsFromDetail";

type Step = "overview" | "category" | "fill" | "done";

export function FinishBuildWalkthrough({
  build,
  variant,
  onClose,
  onBuildMutated,
}: {
  build: BuildDetail;
  variant: BuildVariantDetail;
  onClose: () => void;
  /** Reload build detail after mutations. */
  onBuildMutated: () => void | Promise<void>;
}) {
  const [skippedKeys, setSkippedKeys] = useState<string[]>([]);
  const [equipment, setEquipment] = useState<
    Partial<Record<string, { slot?: string; itemHash?: number; itemName?: string }>>
  >({});
  const [step, setStep] = useState<Step>("overview");
  const [activeCategory, setActiveCategory] = useState<FinishCategory | null>(
    null,
  );
  const [fillSlot, setFillSlot] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const loadResolved = useCallback(async () => {
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
  }, [build.id, variant.id]);

  useEffect(() => {
    void loadResolved();
  }, [loadResolved, variant.attachments]);

  const gapsResult: FinishGapsResult = useMemo(() => {
    const hasModCoverage = variant.attachments.some(
      (a) => a.set?.type === "mod" || (a.mode === "snapshot" && false),
    );
    // armor-embedded mods: treat any attachment snapshot/live with mods later;
    // for now mod set attachment or skip.
    return evaluateFinishGapsFromVariant({
      variantId: variant.id,
      isDefaultVariant: Boolean(variant.isDefault),
      attachments: variant.attachments.map((a) => ({
        setId: a.setId,
        mode: a.mode,
        set: a.set,
      })),
      equipment,
      hasModCoverage:
        hasModCoverage ||
        variant.attachments.some((a) => a.set?.type === "mod"),
      skippedKeys,
    });
  }, [variant, equipment, skippedKeys]);

  const activeGap: FinishGap | null = useMemo(() => {
    if (!activeCategory) return gapsResult.nextActionable;
    return (
      gapsResult.gaps.find((g) => g.category === activeCategory) ??
      gapsResult.nextActionable
    );
  }, [activeCategory, gapsResult]);

  async function refresh() {
    await onBuildMutated();
    await loadResolved();
  }

  function openCategory(cat: FinishCategory) {
    setActiveCategory(cat);
    setFillSlot(null);
    setStep("category");
    setMessage(null);
  }

  function skipCategory(cat: FinishCategory) {
    setSkippedKeys((prev) =>
      prev.includes(cat) ? prev : [...prev, cat],
    );
    setMessage(`${finishCategoryLabel(cat)} skipped for now`);
    setStep("overview");
    setActiveCategory(null);
  }

  async function attachExisting(setId: string, type: string) {
    setBusy(true);
    setMessage(null);
    try {
      // Replace-by-type via create-set-attach is empty-only; for link use variant PATCH
      // after detach same type: send full attachment list with new set live.
      const others = variant.attachments.filter((a) => a.set?.type !== type);
      const attachments = [
        ...others.map((a) => ({
          setId: a.setId,
          mode: a.mode as "live" | "snapshot",
          snapshotConfigs: a.snapshotConfigs ?? undefined,
        })),
        { setId, mode: "live" as const },
      ];
      const res = await fetch(
        `/api/user/builds/${build.id}/variants/${variant.id}`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ attachments }),
        },
      );
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setMessage(body.error ?? "Failed to attach set");
        return;
      }
      setMessage("Set linked");
      await refresh();
    } catch {
      setMessage("Failed to attach set");
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    if (gapsResult.complete) setStep("done");
  }, [gapsResult.complete]);

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={12}>
        <Row justify="between" align="center" wrap gap={8}>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              Finish build · {variant.name}
            </Text>
            <Text size="xs" tone="muted">
              Armor → Weapons → Mods. Create, link, or capture Sets, then fill
              empty slots. Skip for now leaves gaps unfinished.
            </Text>
          </Stack>
          <Button size="sm" variant="ghost" onClick={onClose} disabled={busy}>
            Exit
          </Button>
        </Row>

        <Cluster gap={6}>
          {gapsResult.gaps.map((g) => {
            const skipped = skippedKeys.includes(g.category);
            const active = activeCategory === g.category && step !== "overview";
            const label = finishCategoryLabel(g.category);
            const state =
              g.status === "satisfied"
                ? "done"
                : skipped
                  ? "skipped"
                  : active
                    ? "current"
                    : "todo";
            return (
              <Button
                key={g.category}
                size="sm"
                variant={state === "current" ? "accent" : "ghost"}
                disabled={busy}
                onClick={() => openCategory(g.category)}
                title={g.status}
              >
                {label}
                {state === "done" ? " ✓" : skipped ? " · skip" : ""}
              </Button>
            );
          })}
        </Cluster>

        {message ? <Callout tone="info">{message}</Callout> : null}

        {step === "done" || gapsResult.complete ? (
          <Callout tone="success">
            Combat categories are satisfied for this variant. You can exit the
            walkthrough.
          </Callout>
        ) : null}

        {step === "overview" && !gapsResult.complete ? (
          <Stack gap={8}>
            <Text size="sm">Missing pieces</Text>
            {gapsResult.gaps
              .filter((g) => g.status !== "satisfied")
              .map((g) => (
                <Row key={g.category} justify="between" align="center" gap={8}>
                  <Text size="sm">
                    {finishCategoryLabel(g.category)} · {g.status}
                    {g.emptySlots.length
                      ? ` · empty ${g.emptySlots.length}`
                      : ""}
                  </Text>
                  <Button
                    size="sm"
                    variant="accent"
                    onClick={() => openCategory(g.category)}
                  >
                    Continue
                  </Button>
                </Row>
              ))}
            {gapsResult.nextActionable ? (
              <Button
                variant="accent"
                size="sm"
                onClick={() =>
                  openCategory(gapsResult.nextActionable!.category)
                }
              >
                Next: {finishCategoryLabel(gapsResult.nextActionable.category)}
              </Button>
            ) : null}
          </Stack>
        ) : null}

        {step === "category" && activeGap ? (
          <Stack gap={12}>
            <Text size="sm" weight="medium">
              {finishCategoryLabel(activeGap.category)}
            </Text>
            <Text size="xs" tone="muted">
              Status: {activeGap.status}
              {activeGap.coveringSetName
                ? ` · Set: ${activeGap.coveringSetName}`
                : ""}
            </Text>

            {activeGap.canCapture ? (
              <CaptureSetsFromBuild
                buildId={build.id}
                variantId={variant.id}
                categories={[activeGap.category === "weapon" ? "weapon" : activeGap.category === "mod" ? "mod" : "armor"]}
                onDone={async () => {
                  setMessage("Captured gear into Set(s)");
                  await refresh();
                }}
              />
            ) : null}

            {activeGap.status === "needs_set" ||
            activeGap.status === "capture_available" ? (
              <>
                <CreateSetAttachForm
                  buildId={build.id}
                  variantId={variant.id}
                  defaultType={
                    activeGap.category === "weapon"
                      ? "weapon"
                      : activeGap.category === "mod"
                        ? "mod"
                        : "armor"
                  }
                  allowPair={false}
                  busy={busy}
                  onCreated={async (r) => {
                    setMessage(`Created ${r.set.name}`);
                    await refresh();
                  }}
                />
                <Stack gap={4}>
                  <Text size="xs" tone="muted">
                    Or link an existing Set
                  </Text>
                  <SetAttachPicker
                    disabled={busy}
                    excludeIds={variant.attachments.map((a) => a.setId)}
                    onAttach={(att, selected) => {
                      void attachExisting(
                        att.setId,
                        selected?.type === "weapon"
                          ? "weapon"
                          : selected?.type === "mod"
                            ? "mod"
                            : selected?.type === "pair"
                              ? "pair"
                              : "armor",
                      );
                    }}
                  />
                </Stack>
              </>
            ) : null}

            {activeGap.status === "needs_fill" &&
            activeGap.coveringSetId &&
            activeGap.coveringMode === "live" ? (
              <Stack gap={6}>
                <Text size="xs" tone="muted">
                  Empty slots
                </Text>
                {activeGap.emptySlots.map((slot) => (
                  <Button
                    key={slot}
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setFillSlot(slot);
                      setStep("fill");
                    }}
                  >
                    Fill {slot}
                  </Button>
                ))}
              </Stack>
            ) : null}

            {activeGap.status === "needs_fill" &&
            activeGap.coveringMode === "snapshot" ? (
              <Callout tone="warning">
                Covering Set is snapshot-only. Create or link a live Set to fill
                from Builds.
              </Callout>
            ) : null}

            <Row gap={8} wrap>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => skipCategory(activeGap.category)}
              >
                Skip for now
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => {
                  setStep("overview");
                  setActiveCategory(null);
                }}
              >
                Back
              </Button>
            </Row>
          </Stack>
        ) : null}

        {step === "fill" &&
        activeGap?.coveringSetId &&
        fillSlot &&
        activeGap.coveringMode === "live" ? (
          <BuildSlotFillHost
            setId={activeGap.coveringSetId}
            slot={fillSlot}
            attachmentMode="live"
            onClose={() => {
              setFillSlot(null);
              setStep("category");
            }}
            onFilled={() => {
              setMessage(`Filled ${fillSlot}`);
              void refresh();
            }}
          />
        ) : null}
      </Stack>
    </Panel>
  );
}

// silence unused import if tree-shaken differently
