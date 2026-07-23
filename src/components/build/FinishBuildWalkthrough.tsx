"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import { BuildSlotFillHost } from "@/components/build/BuildSlotFillHost";
import { FinishArmorOptimizeWorkspace } from "@/components/build/FinishArmorOptimizeWorkspace";
import { CaptureSetsFromBuild } from "@/components/build/CaptureSetsFromBuild";
import type { BuildDetail, BuildVariantDetail } from "@/components/build/types";
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
import {
  finishCategoryToSetType,
  resolvePostMutationStep,
  showFinishCreateActions,
  type FinishWalkthroughStep,
} from "@/lib/builds/finishNextSlot";

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
  const [step, setStep] = useState<FinishWalkthroughStep>("overview");
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
    setMessage(null);
    const gap = gapsResult.gaps.find((g) => g.category === cat);
    const target = resolvePostMutationStep({ gap });
    // Armor with live covering set opens optimizer workspace (031).
    if (target.step === "fill" && target.fillSlot) {
      setFillSlot(target.fillSlot);
      setStep("fill");
      return;
    }
    setFillSlot(null);
    setStep("category");
  }

  function skipCategory(cat: FinishCategory) {
    setSkippedKeys((prev) =>
      prev.includes(cat) ? prev : [...prev, cat],
    );
    setMessage(`${finishCategoryLabel(cat)} skipped for now`);
    setStep("overview");
    setActiveCategory(null);
    setFillSlot(null);
  }

  async function oneTapCreate(cat: FinishCategory) {
    setBusy(true);
    setMessage(null);
    try {
      const res = await fetch(`/api/user/builds/${build.id}/create-set-attach`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          variantId: variant.id,
          type: finishCategoryToSetType(cat),
          attachNow: true,
        }),
      });
      const body = (await res.json()) as {
        error?: string;
        set?: { id: string; name: string; type: string };
      };
      if (!res.ok || !body.set) {
        setMessage(
          body.error ??
            (res.status === 401
              ? "Sign in to create a Set."
              : "Failed to create set"),
        );
        return;
      }
      setMessage(`Created ${body.set.name}`);
      await refresh();
      // Parent will pass updated variant on next render; use equipment after loadResolved.
      // Defer step decision to effect on gapsResult when activeCategory set.
      setActiveCategory(cat);
      setPendingAdvance(cat);
    } catch {
      setMessage("Failed to create set");
    } finally {
      setBusy(false);
    }
  }

  const [pendingAdvance, setPendingAdvance] = useState<FinishCategory | null>(
    null,
  );

  useEffect(() => {
    if (!pendingAdvance) return;
    const gap = gapsResult.gaps.find((g) => g.category === pendingAdvance);
    if (!gap) return;
    // Wait until covering set appears or status left needs_set
    if (gap.status === "needs_set") return;
    const target = resolvePostMutationStep({ gap });
    setFillSlot(target.fillSlot);
    setStep(target.step === "overview" && gapsResult.complete ? "done" : target.step);
    if (target.step === "overview") {
      setActiveCategory(null);
    } else {
      setActiveCategory(target.category ?? pendingAdvance);
    }
    setPendingAdvance(null);
  }, [pendingAdvance, gapsResult]);

  useEffect(() => {
    if (gapsResult.complete) setStep("done");
  }, [gapsResult.complete]);

  async function afterFill(slot: string) {
    setMessage(`Filled ${slot}`);
    await refresh();
    if (activeCategory) setPendingAdvance(activeCategory);
  }

  async function afterCapture(cat: FinishCategory, createdNames: string[]) {
    setMessage(
      createdNames.length
        ? `Captured ${createdNames.join(", ")}`
        : "Capture finished",
    );
    await refresh();
    setActiveCategory(cat);
    setPendingAdvance(cat);
  }

  return (
    <Panel tone="accent" className="w-full">
      <Stack gap={12}>
        <Row justify="between" align="center" wrap gap={8}>
          <Stack gap={2}>
            <Text size="sm" weight="medium">
              Finish build · {variant.name}
            </Text>
            <Text size="xs" tone="muted">
              Armor → Weapons → Mods. Create or capture a Set, then fill empty
              slots. Skip for now leaves gaps unfinished.
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
              <Stack gap={4}>
                <Text size="xs" weight="medium">
                  Preferred · capture current gear
                </Text>
                <CaptureSetsFromBuild
                  buildId={build.id}
                  variantId={variant.id}
                  categories={[finishCategoryToSetType(activeGap.category)]}
                  onDone={async (r) => {
                    await afterCapture(
                      activeGap.category,
                      r.createdSets.map((s) => s.name),
                    );
                  }}
                />
              </Stack>
            ) : null}

            {showFinishCreateActions(activeGap.status) ? (
              <Stack gap={6}>
                <Text size="xs" tone="muted">
                  Creates{" "}
                  <strong className="text-foreground font-medium">
                    {build.name}{" "}
                    {finishCategoryLabel(activeGap.category)}
                  </strong>{" "}
                  · live-attach · no tags
                </Text>
                <Button
                  variant="accent"
                  size="sm"
                  disabled={busy}
                  onClick={() => void oneTapCreate(activeGap.category)}
                >
                  {busy
                    ? "Creating…"
                    : `Create ${finishCategoryLabel(activeGap.category)} set & fill`}
                </Button>
              </Stack>
            ) : null}

            {activeGap.status === "needs_fill" &&
            activeGap.coveringSetId &&
            activeGap.coveringMode === "live" ? (
              <Stack gap={6}>
                <Text size="xs" tone="muted">
                  Empty slots — continuing slot-first
                </Text>
                <Button
                  size="sm"
                  variant="accent"
                  disabled={busy || activeGap.emptySlots.length === 0}
                  onClick={() => {
                    const slot = activeGap.emptySlots[0];
                    if (!slot) return;
                    setFillSlot(slot);
                    setStep("fill");
                  }}
                >
                  Fill {activeGap.emptySlots[0] ?? "slot"}
                </Button>
              </Stack>
            ) : null}

            {activeGap.status === "needs_fill" &&
            activeGap.coveringMode === "snapshot" ? (
              <Callout tone="warning">
                Covering Set is snapshot-only. Create a live Set from Finish or
                link a live Set on the variant Sets tab to fill from Builds.
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
                  setFillSlot(null);
                }}
              >
                Back
              </Button>
            </Row>
          </Stack>
        ) : null}

        {step === "armor_optimize" && activeGap?.coveringSetId && activeGap.category === "armor" ? (
          <FinishArmorOptimizeWorkspace
            build={build}
            setId={activeGap.coveringSetId}
            setName={activeGap.coveringSetName}
            onApplied={async () => {
              setMessage("Armor kit applied");
              await refresh();
              setPendingAdvance("armor");
            }}
            onManualFill={() => {
              const slot = activeGap.emptySlots[0];
              if (slot) {
                setFillSlot(slot);
                setStep("fill");
              } else {
                setStep("category");
              }
            }}
            onBack={() => {
              setStep("category");
            }}
          />
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
              void afterFill(fillSlot);
            }}
          />
        ) : null}
      </Stack>
    </Panel>
  );
}
