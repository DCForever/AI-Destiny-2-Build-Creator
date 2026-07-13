"use client";

import { Suspense, useCallback, useMemo, useState } from "react";
import { BungieAuthControl } from "@/components/BungieAuthControl";
import { LoadoutDiscoveryOverlay } from "@/components/LoadoutDiscoveryOverlay";
import {
  LoadoutExoticFilterBar,
  type ExoticPickerOption,
} from "@/components/loadouts/LoadoutExoticFilterBar";
import { EditableBuildSheet } from "@/components/sheet/EditableBuildSheet";
import {
  Button,
  Callout,
  ClassFilterChip,
  ClassIcon,
  EmptyState,
  FilterChip,
  LoadoutColorBar,
  LoadoutIconPlate,
  PageFrame,
  PageFrameBody,
  PageFrameChrome,
  PageHeader,
  Panel,
  Row,
  Stack,
  Text,
} from "@/components/ui";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import type { SavedLoadout } from "@/lib/db/types";
import type { BungieInGameLoadout } from "@/lib/bungie/characterLoadouts";
import {
  CLASS_CSS_COLOR,
  isGuardianClass,
  loadoutAccentColor,
} from "@/lib/destiny/identityVisuals";
import { buildDiscoveryMatches, filterLoadoutRows } from "@/lib/loadouts/loadoutListApi";
import {
  loadoutMatchLabel,
  matchLoadoutToBuilds,
  type BuildMatchInput,
} from "@/lib/loadouts/matchLoadoutToBuilds";
import type { ExoticFilterCriteria, LoadoutListRow } from "@/lib/loadouts/types";

function formatDate(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

function collectPickerOptions(rows: LoadoutListRow[]): {
  armor: ExoticPickerOption[];
  weapon: ExoticPickerOption[];
} {
  const armor = new Map<string, ExoticPickerOption>();
  const weapon = new Map<string, ExoticPickerOption>();

  for (const row of rows) {
    const a = row.exoticSummary.exoticArmor;
    if (a?.name) {
      armor.set(a.name, { hash: a.hash, name: a.name });
    }
    const w = row.exoticSummary.exoticWeapon;
    if (w?.name) {
      weapon.set(w.name, { hash: w.hash, name: w.name });
    }
  }

  return {
    armor: [...armor.values()].sort((x, y) => x.name.localeCompare(y.name)),
    weapon: [...weapon.values()].sort((x, y) => x.name.localeCompare(y.name)),
  };
}

function exoticRowLabels(row: LoadoutListRow): string[] {
  const labels: string[] = [];
  const armor = row.exoticSummary.exoticArmor?.name;
  const weapon = row.exoticSummary.exoticWeapon?.name;
  if (armor) labels.push(`Armor: ${armor}`);
  if (weapon) labels.push(`Weapon: ${weapon}`);
  return labels;
}

export function LoadoutsPage() {
  const [signedIn, setSignedIn] = useState(false);
  const [bungieLoadouts, setBungieLoadouts] = useState<BungieInGameLoadout[]>(
    [],
  );
  const [localRows, setLocalRows] = useState<LoadoutListRow[]>([]);
  const [curatedBuilds, setCuratedBuilds] = useState<BuildMatchInput[]>([]);
  const [filterCriteria, setFilterCriteria] = useState<ExoticFilterCriteria>(
    {},
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [bungieHint, setBungieHint] = useState<string | null>(null);
  const [openId, setOpenId] = useState<string | null>(null);
  const [openLoadout, setOpenLoadout] = useState<SavedLoadout | null>(null);
  const [liveBuild, setLiveBuild] = useState<GeneratedBuild | null>(null);
  const [liveSheet, setLiveSheet] = useState<ResolvedBuildSheet | null>(null);
  const [staleBanner, setStaleBanner] = useState<string | null>(null);
  const [opening, setOpening] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [expandedBungieId, setExpandedBungieId] = useState<string | null>(null);
  const [discovery, setDiscovery] = useState<{
    open: boolean;
    title: string;
    matches: LoadoutListRow[];
  }>({ open: false, title: "", matches: [] });
  const [classFilter, setClassFilter] = useState<string | null>(null);
  const [hideEmpty, setHideEmpty] = useState(true);

  const pickerOptions = useMemo(
    () => collectPickerOptions(localRows),
    [localRows],
  );
  const displayLocalRows = useMemo(
    () => filterLoadoutRows(localRows, filterCriteria),
    [localRows, filterCriteria],
  );

  const displayBungie = useMemo(() => {
    return bungieLoadouts.filter((lo) => {
      if (hideEmpty && lo.empty) return false;
      if (classFilter && lo.className !== classFilter) return false;
      return true;
    });
  }, [bungieLoadouts, hideEmpty, classFilter]);

  const matchByLoadoutId = useMemo(() => {
    const map = new Map<string, ReturnType<typeof matchLoadoutToBuilds>>();
    for (const lo of localRows) {
      map.set(
        lo.id,
        matchLoadoutToBuilds(
          {
            className: lo.className,
            exoticArmorHash: lo.exoticSummary.exoticArmor?.hash ?? null,
            exoticWeaponHash: lo.exoticSummary.exoticWeapon?.hash ?? null,
          },
          curatedBuilds,
        ),
      );
    }
    for (const lo of bungieLoadouts) {
      map.set(
        lo.id,
        matchLoadoutToBuilds(
          {
            className: lo.className,
            exoticArmorHash: lo.exoticArmorHash ?? null,
            exoticWeaponHash: lo.exoticWeaponHash ?? null,
          },
          curatedBuilds,
        ),
      );
    }
    return map;
  }, [localRows, bungieLoadouts, curatedBuilds]);

  const fetchLoadouts = useCallback(async () => {
    setLoading(true);
    setError(null);
    setBungieHint(null);
    try {
      const [bungieRes, localRes, buildRes] = await Promise.all([
        fetch("/api/bungie/loadouts"),
        fetch("/api/user/loadouts"),
        fetch("/api/user/builds"),
      ]);

      if (bungieRes.status === 401 || localRes.status === 401) {
        setBungieLoadouts([]);
        setLocalRows([]);
        setCuratedBuilds([]);
        return;
      }

      if (bungieRes.ok) {
        const body = (await bungieRes.json()) as {
          loadouts?: BungieInGameLoadout[];
        };
        setBungieLoadouts(body.loadouts ?? []);
      } else {
        const body = (await bungieRes.json()) as {
          error?: string;
          detail?: string;
        };
        setBungieLoadouts([]);
        setBungieHint(
          body.error ??
            "Could not load Bungie in-game loadouts. Refresh the manifest from Settings if icons are missing.",
        );
      }

      if (localRes.ok) {
        const body = (await localRes.json()) as { loadouts: LoadoutListRow[] };
        setLocalRows(body.loadouts ?? []);
      } else {
        setLocalRows([]);
      }

      if (buildRes.ok) {
        const bBody = (await buildRes.json()) as {
          builds?: Array<{
            id: string;
            name: string;
            className: string;
            exoticArmorHash?: number | null;
            exoticWeaponHash?: number | null;
          }>;
        };
        setCuratedBuilds(
          (bBody.builds ?? []).map((b) => ({
            id: b.id,
            name: b.name,
            className: b.className,
            exoticArmorHash: b.exoticArmorHash ?? null,
            exoticWeaponHash: b.exoticWeaponHash ?? null,
          })),
        );
      } else {
        setCuratedBuilds([]);
      }
    } catch {
      setError("Failed to load loadouts");
    } finally {
      setLoading(false);
    }
  }, []);

  const handleAuthChange = useCallback(
    (auth: { signedIn: boolean }) => {
      setSignedIn(auth.signedIn);
      if (auth.signedIn) {
        void fetchLoadouts();
      } else {
        setBungieLoadouts([]);
        setLocalRows([]);
        setCuratedBuilds([]);
        setOpenId(null);
        setOpenLoadout(null);
        setLiveBuild(null);
        setLiveSheet(null);
        setStaleBanner(null);
        setFilterCriteria({});
        setExpandedBungieId(null);
        setDiscovery({ open: false, title: "", matches: [] });
        setLoading(false);
      }
    },
    [fetchLoadouts],
  );

  const openDiscovery = useCallback(
    (title: string, criteria: ExoticFilterCriteria) => {
      const matches = buildDiscoveryMatches(
        localRows,
        criteria,
        openId ?? undefined,
      );
      setDiscovery({ open: true, title, matches });
    },
    [localRows, openId],
  );

  const reResolveIfStale = async (
    loadout: SavedLoadout,
  ): Promise<{
    build: GeneratedBuild;
    sheet: ResolvedBuildSheet;
    banner: string | null;
  }> => {
    let manifestVersion: string | null = null;
    try {
      const statusRes = await fetch("/api/manifest");
      if (statusRes.ok) {
        const status = (await statusRes.json()) as {
          cachedVersion: string | null;
        };
        manifestVersion = status.cachedVersion;
      }
    } catch {
      return {
        build: loadout.generatedBuild,
        sheet: loadout.resolvedSheet,
        banner: null,
      };
    }

    if (!manifestVersion || loadout.manifestVersion === manifestVersion) {
      return {
        build: loadout.generatedBuild,
        sheet: loadout.resolvedSheet,
        banner: null,
      };
    }

    const activity =
      loadout.buildRequest?.activity ?? loadout.resolvedSheet.activity;
    const res = await fetch("/api/build/resolve-slot", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        build: loadout.generatedBuild,
        activity,
      }),
    });
    if (!res.ok) {
      return {
        build: loadout.generatedBuild,
        sheet: loadout.resolvedSheet,
        banner: "Manifest updated; re-resolve failed — showing cached sheet.",
      };
    }
    const body = (await res.json()) as { sheet: ResolvedBuildSheet };
    return {
      build: loadout.generatedBuild,
      sheet: body.sheet,
      banner: "Sheet re-resolved against the current manifest.",
    };
  };

  const handleOpenLocal = async (id: string) => {
    if (openId === id) {
      setOpenId(null);
      setOpenLoadout(null);
      setLiveBuild(null);
      setLiveSheet(null);
      setStaleBanner(null);
      return;
    }
    setOpening(true);
    setOpenId(id);
    setError(null);
    setExpandedBungieId(null);
    try {
      const res = await fetch(`/api/user/loadouts/${id}`);
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to open loadout");
        setOpenId(null);
        return;
      }
      const body = (await res.json()) as { loadout: SavedLoadout };
      const { build, sheet, banner } = await reResolveIfStale(body.loadout);
      setOpenLoadout(body.loadout);
      setLiveBuild(build);
      setLiveSheet(sheet);
      setStaleBanner(banner);
    } catch {
      setError("Failed to open loadout");
      setOpenId(null);
    } finally {
      setOpening(false);
    }
  };

  const handleDeleteLocal = async (id: string, name: string) => {
    if (!window.confirm(`Delete local snapshot “${name}”?`)) return;
    setDeletingId(id);
    setError(null);
    try {
      const res = await fetch(`/api/user/loadouts/${id}`, { method: "DELETE" });
      if (!res.ok && res.status !== 204) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to delete loadout");
        return;
      }
      if (openId === id) {
        setOpenId(null);
        setOpenLoadout(null);
        setLiveBuild(null);
        setLiveSheet(null);
        setStaleBanner(null);
      }
      setLocalRows((prev) => prev.filter((l) => l.id !== id));
    } catch {
      setError("Failed to delete loadout");
    } finally {
      setDeletingId(null);
    }
  };

  const activity =
    openLoadout?.buildRequest?.activity ??
    openLoadout?.resolvedSheet.activity ??
    "General PvE";

  const openRow = openId ? localRows.find((r) => r.id === openId) : undefined;

  return (
    <PageFrame>
      <LoadoutDiscoveryOverlay
        open={discovery.open}
        title={discovery.title}
        matches={discovery.matches}
        onClose={() => setDiscovery((d) => ({ ...d, open: false }))}
      />

      <PageFrameChrome>
        <Stack gap={12}>
          <PageHeader
            title="In-Game Loadouts"
            description="Bungie character loadouts with real icon and color (same source as DIM). Sign in to sync from your profile."
            actions={
              <Suspense
                fallback={
                  <Text size="xs" tone="muted">
                    Loading sign-in…
                  </Text>
                }
              >
                <BungieAuthControl compact onAuthChange={handleAuthChange} />
              </Suspense>
            }
          />
          {error ? <Callout tone="danger">{error}</Callout> : null}
          {bungieHint ? <Callout tone="warning">{bungieHint}</Callout> : null}
        </Stack>
      </PageFrameChrome>

      <PageFrameBody scroll>
        <Stack gap={16}>
        {!signedIn ? (
          <EmptyState description="Sign in with Bungie to view your in-game loadout slots and icons." />
        ) : null}

        {signedIn && loading ? (
          <Text size="sm" tone="muted">
            Loading Bungie loadouts…
          </Text>
        ) : null}

        {signedIn && !loading ? (
          <Stack gap={16}>
            <Panel tone="muted" pad="md">
              <Stack gap={10}>
                <Row justify="between" align="center" wrap gap={8}>
                  <Text size="xs" tone="muted" className="uppercase tracking-widest">
                    Bungie slots · {displayBungie.length}
                    {bungieLoadouts.length !== displayBungie.length
                      ? ` of ${bungieLoadouts.length}`
                      : ""}
                  </Text>
                  <Row gap={8} wrap>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => void fetchLoadouts()}
                    >
                      Refresh
                    </Button>
                    <Button
                      size="sm"
                      variant={hideEmpty ? "accent" : "outline"}
                      onClick={() => setHideEmpty((v) => !v)}
                    >
                      {hideEmpty ? "Hiding empty" : "Show empty"}
                    </Button>
                    {(["Titan", "Hunter", "Warlock"] as const).map((cls) => (
                      <ClassFilterChip
                        key={cls}
                        className={cls}
                        active={classFilter === cls}
                        onClick={() =>
                          setClassFilter((prev) => (prev === cls ? null : cls))
                        }
                        size="md"
                      />
                    ))}
                  </Row>
                </Row>

                {displayBungie.length === 0 ? (
                  <EmptyState description="No in-game loadouts to show. Equip a loadout in Destiny or turn off “Hiding empty”." />
                ) : (
                  <Stack gap={8}>
                    {displayBungie.map((lo) => {
                      const expanded = expandedBungieId === lo.id;
                      const cls = isGuardianClass(lo.className)
                        ? lo.className
                        : "Titan";
                      const fallbackAccent = loadoutAccentColor(
                        `${lo.id}:${lo.name}`,
                      );
                      const classColor = CLASS_CSS_COLOR[cls];
                      const match = matchByLoadoutId.get(lo.id);
                      const matchLabel = match
                        ? loadoutMatchLabel(match)
                        : "No linked build";

                      return (
                        <Panel
                          key={lo.id}
                          tone="default"
                          pad="none"
                          className="overflow-hidden"
                        >
                          <div className="flex flex-wrap items-center justify-between gap-3 p-3 sm:p-4">
                            <LoadoutColorBar
                              color={fallbackAccent}
                              colorImageUrl={lo.colorUrl}
                            >
                              <LoadoutIconPlate color={classColor}>
                                {lo.iconUrl ? (
                                  // eslint-disable-next-line @next/next/no-img-element
                                  <img
                                    src={lo.iconUrl}
                                    alt=""
                                    width={28}
                                    height={28}
                                    className="size-7 object-contain"
                                  />
                                ) : (
                                  <ClassIcon
                                    className={cls}
                                    color={classColor}
                                    size={18}
                                    title={cls}
                                  />
                                )}
                              </LoadoutIconPlate>
                              <Stack gap={4} className="min-w-0">
                                <Row gap={8} align="center" wrap>
                                  <Text
                                    size="sm"
                                    weight="medium"
                                    className="truncate"
                                  >
                                    {lo.name}
                                  </Text>
                                  {lo.colorUrl ? (
                                    // eslint-disable-next-line @next/next/no-img-element
                                    <img
                                      src={lo.colorUrl}
                                      alt=""
                                      className="h-3 w-10 object-cover border border-line"
                                      title="Loadout color"
                                    />
                                  ) : null}
                                </Row>
                                <Text size="xs" tone="muted">
                                  {lo.className} · Light {lo.characterLight} ·
                                  Slot {lo.index + 1}
                                  {lo.empty ? " · Empty" : ""}
                                  {!lo.empty
                                    ? ` · ${lo.itemInstanceIds.length} items`
                                    : ""}
                                </Text>
                                {lo.exoticArmorName || lo.exoticWeaponName ? (
                                  <Text size="xs" tone="accent">
                                    {[lo.exoticArmorName, lo.exoticWeaponName]
                                      .filter(Boolean)
                                      .join(" · ")}
                                  </Text>
                                ) : null}
                                <Text
                                  size="xs"
                                  tone={
                                    match?.kind === "none" || !match
                                      ? "muted"
                                      : "accent"
                                  }
                                >
                                  {matchLabel}
                                </Text>
                              </Stack>
                            </LoadoutColorBar>
                            <Button
                              size="sm"
                              onClick={() =>
                                setExpandedBungieId((id) =>
                                  id === lo.id ? null : lo.id,
                                )
                              }
                            >
                              {expanded ? "Hide" : "Details"}
                            </Button>
                          </div>
                          {expanded ? (
                            <div className="border-t border-line p-4">
                              <Stack gap={8}>
                                <Text size="xs" tone="muted">
                                  Character id {lo.characterId} · iconHash{" "}
                                  {lo.iconHash} · colorHash {lo.colorHash}
                                </Text>
                                {lo.iconUrl ? (
                                  <Row gap={8} align="center">
                                    {/* eslint-disable-next-line @next/next/no-img-element */}
                                    <img
                                      src={lo.iconUrl}
                                      alt=""
                                      className="size-12 object-contain border border-line bg-surface-raised"
                                    />
                                    <Text size="xs" tone="muted">
                                      Real Bungie loadout icon
                                    </Text>
                                  </Row>
                                ) : null}
                                {lo.empty ? (
                                  <Text size="sm" tone="muted">
                                    This slot is empty in Destiny.
                                  </Text>
                                ) : (
                                  <Text size="sm" tone="muted">
                                    {lo.itemInstanceIds.length} item
                                    instance(s) snapshot from Bungie. Equip /
                                    sheet import can be wired next.
                                  </Text>
                                )}
                              </Stack>
                            </div>
                          ) : null}
                        </Panel>
                      );
                    })}
                  </Stack>
                )}
              </Stack>
            </Panel>

            {/* Local app snapshots (generator / analyzer) — secondary */}
            <Stack gap={12}>
              <Text size="xs" tone="muted" className="uppercase tracking-widest">
                Local app snapshots · {displayLocalRows.length}
              </Text>
              <Text size="xs" tone="muted">
                Builds saved inside this app (not Bungie slots). Kept for generator
                / analyzer history.
              </Text>

              {localRows.length > 0 ? (
                <LoadoutExoticFilterBar
                  criteria={filterCriteria}
                  armorOptions={pickerOptions.armor}
                  weaponOptions={pickerOptions.weapon}
                  onChange={setFilterCriteria}
                  onClearAll={() => setFilterCriteria({})}
                />
              ) : null}

              {localRows.length === 0 ? (
                <Text size="sm" tone="muted">
                  No local snapshots yet.
                </Text>
              ) : displayLocalRows.length === 0 ? (
                <Text size="sm" tone="muted">
                  No local snapshots match the current exotic filters.
                </Text>
              ) : (
                <Stack gap={8}>
                  {displayLocalRows.map((loadout) => {
                    const isOpen = openId === loadout.id;
                    const isDeleting = deletingId === loadout.id;
                    const exoticLabels = exoticRowLabels(loadout);
                    const buildMatch = matchByLoadoutId.get(loadout.id) ?? {
                      kind: "none" as const,
                      builds: [],
                    };
                    const matchLabel = loadoutMatchLabel(buildMatch);
                    const cls = isGuardianClass(loadout.className ?? "")
                      ? loadout.className!
                      : "Titan";
                    const accent = loadoutAccentColor(
                      `${loadout.id}:${loadout.name}:${cls}`,
                    );
                    const classColor = CLASS_CSS_COLOR[cls];
                    return (
                      <Panel
                        key={loadout.id}
                        tone="default"
                        pad="none"
                        className="overflow-hidden"
                      >
                        <div className="flex flex-wrap items-center justify-between gap-3 p-3 sm:p-4">
                          <LoadoutColorBar color={accent}>
                            <LoadoutIconPlate color={accent}>
                              <ClassIcon
                                className={cls}
                                color={classColor}
                                size={18}
                                title={cls}
                              />
                            </LoadoutIconPlate>
                            <Stack gap={4} className="min-w-0">
                              <Text
                                size="sm"
                                weight="medium"
                                className="truncate"
                              >
                                {loadout.name}
                              </Text>
                              <Text size="xs" tone="muted">
                                {[
                                  loadout.className,
                                  loadout.source,
                                  formatDate(loadout.updatedAt),
                                ]
                                  .filter(Boolean)
                                  .join(" · ")}
                              </Text>
                              {exoticLabels.length > 0 ? (
                                <Text size="xs" tone="accent">
                                  {exoticLabels.join(" · ")}
                                </Text>
                              ) : null}
                              <Text
                                size="xs"
                                tone={
                                  buildMatch.kind === "none" ? "muted" : "accent"
                                }
                              >
                                {matchLabel}
                              </Text>
                            </Stack>
                          </LoadoutColorBar>
                          <Row gap={8} className="shrink-0">
                            <Button
                              size="sm"
                              disabled={opening && openId === loadout.id}
                              onClick={() => void handleOpenLocal(loadout.id)}
                            >
                              {isOpen ? "Close" : "Open"}
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              disabled={isDeleting}
                              onClick={() =>
                                void handleDeleteLocal(loadout.id, loadout.name)
                              }
                            >
                              {isDeleting ? "Deleting…" : "Delete"}
                            </Button>
                          </Row>
                        </div>

                        {isOpen && opening ? (
                          <div className="px-4 pb-4">
                            <Text size="xs" tone="muted">
                              Loading build…
                            </Text>
                          </div>
                        ) : null}

                        {isOpen &&
                        openLoadout?.id === loadout.id &&
                        liveBuild &&
                        liveSheet &&
                        !opening ? (
                          <div className="border-t border-line p-4">
                            <EditableBuildSheet
                              sheet={liveSheet}
                              build={liveBuild}
                              activity={activity}
                              className={
                                openLoadout.buildRequest?.className ?? "Titan"
                              }
                              staleBanner={staleBanner}
                              exoticSummary={openRow?.exoticSummary}
                              onDiscoverLoadouts={openDiscovery}
                              onUpdate={({ build, sheet }) => {
                                setLiveBuild(build);
                                setLiveSheet(sheet);
                                void fetch(`/api/user/loadouts/${loadout.id}`, {
                                  method: "PUT",
                                  headers: {
                                    "Content-Type": "application/json",
                                  },
                                  body: JSON.stringify({
                                    generatedBuild: build,
                                    resolvedSheet: sheet,
                                  }),
                                });
                              }}
                            />
                          </div>
                        ) : null}
                      </Panel>
                    );
                  })}
                </Stack>
              )}
            </Stack>
          </Stack>
        ) : null}
        </Stack>
      </PageFrameBody>
    </PageFrame>
  );
}
