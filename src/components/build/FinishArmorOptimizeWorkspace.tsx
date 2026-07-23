"use client";

import { useCallback, useEffect, useMemo, useState } from "react";

import type { BuildDetail, GuardianClass } from "@/components/build/types";
import {
  Button,
  Callout,
  Chip,
  Cluster,
  Panel,
  Row,
  Stack,
  Text,
} from "@/components/ui";
import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";
import { composeOptimizerConstraints } from "@/lib/optimizer/composeOptimizerConstraints";
import type { RankedSetBonusOption } from "@/lib/optimizer/rankSetBonusesForBuild";
import type {
  ArmorCombination,
  ArmorSetOptimizerConstraints,
  SetBonusCoverageGoal,
} from "@/lib/optimizer/types";

type ContextResponse = {
  className: string;
  seedConstraints: ArmorSetOptimizerConstraints;
  rankedSetBonuses: { linked: RankedSetBonusOption[]; all: RankedSetBonusOption[] };
};

type KitView = "compare" | "all";

export function FinishArmorOptimizeWorkspace({
  build,
  setId,
  setName,
  onApplied,
  onManualFill,
  onBack,
}: {
  build: BuildDetail;
  setId: string;
  setName?: string | null;
  onApplied: () => void | Promise<void>;
  onManualFill: () => void;
  onBack: () => void;
}) {
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [className, setClassName] = useState<GuardianClass>(build.className);
  const [linked, setLinked] = useState<RankedSetBonusOption[]>([]);
  const [allBonuses, setAllBonuses] = useState<RankedSetBonusOption[]>([]);
  const [goals, setGoals] = useState<SetBonusCoverageGoal[]>([]);
  const [thresholds, setThresholds] = useState<Partial<Record<ArmorStatName, number>>>({});
  const [includeMods, setIncludeMods] = useState(true);
  const [preferReuse, setPreferReuse] = useState(false);
  const [lockedExotic, setLockedExotic] = useState<number | null>(null);
  const [combinations, setCombinations] = useState<ArmorCombination[]>([]);
  const [kitView, setKitView] = useState<KitView>("compare");
  const [selectedIdx, setSelectedIdx] = useState(0);
  const [bonusQuery, setBonusQuery] = useState("");

  const loadContext = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(
        `/api/user/builds/${build.id}/armor-optimize-context?setId=${encodeURIComponent(setId)}`,
      );
      const body = (await res.json()) as ContextResponse & { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to load optimizer context");
        return;
      }
      setClassName(body.className as GuardianClass);
      setLinked(body.rankedSetBonuses.linked);
      setAllBonuses(body.rankedSetBonuses.all);
      const seed = body.seedConstraints;
      setLockedExotic(seed.lockedExoticItemHash ?? null);
      setThresholds(seed.statThresholds ?? {});
      setIncludeMods(seed.includeModEstimates ?? true);
      setPreferReuse(seed.preferReuse ?? false);
      // Pre-suggest 2pc from linked when empty goals
      if ((seed.setBonusGoals ?? []).length === 0 && body.rankedSetBonuses.linked.length) {
        const pre = body.rankedSetBonuses.linked.slice(0, 2).map((l) => ({
          setBonusKey: l.setBonusKey,
          minPieces: (l.minPieces === 4 ? 4 : 2) as 2 | 4,
        }));
        setGoals(pre);
      } else {
        setGoals(seed.setBonusGoals ?? []);
      }
    } catch {
      setError("Failed to load optimizer context");
    } finally {
      setLoading(false);
    }
  }, [build.id, setId]);

  useEffect(() => {
    void loadContext();
  }, [loadContext]);

  const constraints = useMemo(
    () =>
      composeOptimizerConstraints({
        seed: {
          exoticArmorHash: lockedExotic,
          softStatTargets: thresholds,
        },
        setBonusGoals: goals,
        includeModEstimates: includeMods,
        preferReuse,
        lockedExoticItemHash: lockedExotic,
      }),
    [goals, thresholds, includeMods, preferReuse, lockedExotic],
  );

  function toggleGoal(opt: RankedSetBonusOption) {
    setGoals((prev) => {
      const exists = prev.find((g) => g.setBonusKey === opt.setBonusKey);
      if (exists) return prev.filter((g) => g.setBonusKey !== opt.setBonusKey);
      return [
        ...prev,
        { setBonusKey: opt.setBonusKey, minPieces: (opt.minPieces === 4 ? 4 : 2) as 2 | 4 },
      ];
    });
  }

  function setThreshold(stat: ArmorStatName, raw: string) {
    const n = raw.trim() === "" ? undefined : Number(raw);
    setThresholds((prev) => {
      const next = { ...prev };
      if (n == null || !Number.isFinite(n)) delete next[stat];
      else next[stat] = Math.max(1, Math.min(200, Math.round(n)));
      return next;
    });
  }

  async function findKits() {
    setBusy(true);
    setError(null);
    setInfo(null);
    try {
      const patch = await fetch(`/api/user/sets/${setId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ optimizerConstraints: constraints }),
      });
      if (!patch.ok) {
        const b = (await patch.json()) as { error?: string };
        setError(b.error ?? "Failed to save constraints");
        return;
      }
      const opt = await fetch(`/api/user/sets/${setId}/optimize`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          classType: className,
          maxResults: 12,
        }),
      });
      const body = (await opt.json()) as {
        error?: string;
        combinations?: ArmorCombination[];
        emptyReason?: { code?: string; message?: string };
      };
      if (!opt.ok) {
        setError(body.error ?? "Optimize failed");
        setCombinations([]);
        return;
      }
      const combos = body.combinations ?? [];
      setCombinations(combos);
      setSelectedIdx(0);
      setKitView("compare");
      if (combos.length === 0) {
        const er = body.emptyReason;
        if (er?.code === "NO_INVENTORY") {
          setError(
            er.message ??
              "No inventory armor found. Sync inventory from Settings, then try again.",
          );
        } else {
          setError(er?.message ?? "No kits found for these goals.");
        }
      } else {
        setInfo(`Found ${combos.length} kit${combos.length === 1 ? "" : "s"}`);
      }
    } catch {
      setError("Optimize failed");
    } finally {
      setBusy(false);
    }
  }

  async function applyKit(combo: ArmorCombination) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/sets/${setId}/apply-combination`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          pieces: combo.pieces.map((p) => ({
            slot: p.slot,
            itemHash: p.itemHash,
            instanceId: p.instanceId,
          })),
          assumedMods: combo.assumedMods?.map((m) => ({
            armorSlot: m.armorSlot,
            itemHash: m.itemHash,
          })),
        }),
      });
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to apply kit");
        return;
      }
      setInfo("Armor kit applied to set");
      await onApplied();
    } catch {
      setError("Failed to apply kit");
    } finally {
      setBusy(false);
    }
  }

  const filteredAll = useMemo(() => {
    const q = bonusQuery.trim().toLowerCase();
    if (!q) return allBonuses;
    return allBonuses.filter(
      (b) => b.label.toLowerCase().includes(q) || b.setBonusKey.toLowerCase().includes(q),
    );
  }, [allBonuses, bonusQuery]);

  const top3 = combinations.slice(0, 3);
  const list = kitView === "compare" ? top3 : combinations;

  if (loading) {
    return (
      <Panel tone="raised" className="w-full">
        <Text size="sm" tone="muted">
          Loading armor goals…
        </Text>
      </Panel>
    );
  }

  return (
    <Stack gap={12} className="w-full">
      <Row justify="between" align="center" wrap gap={8}>
        <Stack gap={2}>
          <Text size="sm" weight="medium">
            Armor optimize · {setName ?? "Armor set"}
          </Text>
          <Text size="xs" tone="muted">
            {className}
            {lockedExotic != null ? ` · exotic locked` : ""} · set bonuses linked to synergies first
          </Text>
        </Stack>
        <Button size="sm" variant="ghost" onClick={onBack} disabled={busy}>
          Back
        </Button>
      </Row>

      {error ? <Callout tone="danger">{error}</Callout> : null}
      {info ? <Callout tone="info">{info}</Callout> : null}

      <div className="grid gap-0 border border-line md:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
        <Stack gap={10} className="border-b border-line p-3 md:border-b-0 md:border-r">
          <Text size="xs" weight="medium" className="uppercase tracking-widest text-muted">
            Goals
          </Text>

          <Stack gap={4}>
            <Text size="xs" tone="muted">
              Selected set bonuses
            </Text>
            <Cluster gap={6}>
              {goals.length === 0 ? (
                <Text size="xs" tone="muted">
                  None yet
                </Text>
              ) : (
                goals.map((g) => (
                  <Chip key={g.setBonusKey} accent>
                    {g.setBonusKey} · {g.minPieces}pc
                    <button
                      type="button"
                      className="ml-1 opacity-70"
                      onClick={() =>
                        setGoals((prev) => prev.filter((x) => x.setBonusKey !== g.setBonusKey))
                      }
                    >
                      ×
                    </button>
                  </Chip>
                ))
              )}
            </Cluster>
          </Stack>

          <Stack gap={4}>
            <Text size="xs" tone="muted">
              Linked to your synergies
            </Text>
            <Cluster gap={6}>
              {linked.length === 0 ? (
                <Text size="xs" tone="muted">
                  No synergy set-bonus links
                </Text>
              ) : (
                linked.map((opt) => {
                  const on = goals.some((g) => g.setBonusKey === opt.setBonusKey);
                  return (
                    <button key={opt.setBonusKey} type="button" onClick={() => toggleGoal(opt)}>
                      <Chip accent={on}>
                        {opt.label}
                        {opt.synergyNames[0] ? ` · via ${opt.synergyNames[0]}` : ""}
                      </Chip>
                    </button>
                  );
                })
              )}
            </Cluster>
          </Stack>

          <Stack gap={4}>
            <Text size="xs" tone="muted">
              All set bonuses
            </Text>
            <input
              className="w-full border border-line bg-surface-raised px-2 py-1 text-sm"
              placeholder="Filter…"
              value={bonusQuery}
              onChange={(e) => setBonusQuery(e.target.value)}
            />
            <Cluster gap={6} className="max-h-28 overflow-auto">
              {filteredAll.slice(0, 24).map((opt) => {
                const on = goals.some((g) => g.setBonusKey === opt.setBonusKey);
                return (
                  <button key={opt.setBonusKey} type="button" onClick={() => toggleGoal(opt)}>
                    <Chip accent={on}>{opt.label}</Chip>
                  </button>
                );
              })}
            </Cluster>
          </Stack>

          <Stack gap={4}>
            <Text size="xs" tone="muted">
              Stat targets
            </Text>
            <div className="grid grid-cols-3 gap-2">
              {ARMOR_STAT_NAMES.map((stat) => (
                <label key={stat} className="block">
                  <span className="text-[10px] uppercase tracking-widest text-muted">{stat}</span>
                  <input
                    className="mt-0.5 w-full border border-line bg-surface-raised px-1 py-1 font-mono text-sm"
                    inputMode="numeric"
                    placeholder="—"
                    value={thresholds[stat] ?? ""}
                    onChange={(e) => setThreshold(stat, e.target.value)}
                  />
                </label>
              ))}
            </div>
          </Stack>

          <Cluster gap={6}>
            <button type="button" onClick={() => setIncludeMods((v) => !v)}>
              <Chip accent={includeMods}>
                Mod estimates {includeMods ? "on" : "off"}
              </Chip>
            </button>
            <button type="button" onClick={() => setPreferReuse((v) => !v)}>
              <Chip accent={preferReuse}>
                Prefer reuse {preferReuse ? "on" : "off"}
              </Chip>
            </button>
          </Cluster>

          <Button variant="accent" size="sm" disabled={busy} onClick={() => void findKits()}>
            {busy ? "Searching…" : "Find armor kits"}
          </Button>
          <Button size="sm" variant="ghost" disabled={busy} onClick={onManualFill}>
            Fill slots manually instead
          </Button>
        </Stack>

        <Stack gap={10} className="p-3">
          <Row justify="between" align="center" wrap gap={8}>
            <Text size="xs" weight="medium" className="uppercase tracking-widest text-muted">
              Kits · {combinations.length}
            </Text>
            {combinations.length > 3 ? (
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setKitView((v) => (v === "compare" ? "all" : "compare"))}
              >
                {kitView === "compare" ? `See all ${combinations.length}` : "Top 3 compare"}
              </Button>
            ) : null}
          </Row>

          {list.length === 0 ? (
            <Text size="sm" tone="muted">
              Run Find armor kits to propose full 5-piece combinations from inventory.
            </Text>
          ) : (
            <div
              className={
                kitView === "compare"
                  ? "grid gap-0 border border-line sm:grid-cols-3"
                  : "flex flex-col gap-2"
              }
            >
              {list.map((combo, i) => {
                const idx = kitView === "compare" ? i : combinations.indexOf(combo);
                const sel = idx === selectedIdx;
                return (
                  <div
                    key={idx}
                    className={
                      kitView === "compare"
                        ? `border-line p-2 sm:border-r sm:last:border-r-0 ${sel ? "bg-accent/10" : ""}`
                        : `border border-line p-2 ${sel ? "border-accent bg-accent/10" : ""}`
                    }
                  >
                    <button type="button" className="w-full text-left" onClick={() => setSelectedIdx(idx)}>
                      <Text size="xs" weight="medium">
                        #{idx + 1} · score {Math.round(combo.score)}
                        {combo.reusePieceCount ? ` · reuse ${combo.reusePieceCount}` : ""}
                      </Text>
                      <div className="mt-1 space-y-0.5 font-mono text-[11px] text-muted">
                        {ARMOR_STAT_NAMES.map((stat) => {
                          const v = combo.estimatedStats?.[stat];
                          const t = thresholds[stat];
                          const hit = t != null && v != null && v >= t;
                          return (
                            <div key={stat} className={hit ? "text-[var(--success,#6fc28b)]" : undefined}>
                              {stat.slice(0, 3)} {v ?? "—"}
                              {t != null ? ` / ${t}` : ""}
                            </div>
                          );
                        })}
                      </div>
                      <div className="mt-1 space-y-0.5 text-xs">
                        {combo.pieces.map((pc) => (
                          <div key={pc.slot}>
                            {pc.slot}{" "}
                            <span className="text-muted">{pc.itemName ?? pc.instanceId}</span>
                          </div>
                        ))}
                      </div>
                    </button>
                    <Button
                      className="mt-2"
                      size="sm"
                      variant={sel ? "accent" : "ghost"}
                      disabled={busy}
                      onClick={() => void applyKit(combo)}
                    >
                      Apply #{idx + 1}
                    </Button>
                  </div>
                );
              })}
            </div>
          )}

          {combinations.length > 0 ? (
            <div className="sticky bottom-0 border-t border-line bg-surface/95 p-2 backdrop-blur md:static md:border-0 md:bg-transparent md:p-0 md:backdrop-blur-none">
              <Button
                variant="accent"
                size="sm"
                className="w-full md:w-auto"
                disabled={busy || !combinations[selectedIdx]}
                onClick={() => {
                  const c = combinations[selectedIdx];
                  if (c) void applyKit(c);
                }}
              >
                Apply kit #{selectedIdx + 1} to set
              </Button>
            </div>
          ) : null}
        </Stack>
      </div>
    </Stack>
  );
}
