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
  ClassIcon,
  EmptyState,
  LoadoutColorBar,
  LoadoutIconPlate,
  PageHeader,
  Panel,
  Row,
  Stack,
  Text,
} from "@/components/ui";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import type { SavedLoadout } from "@/lib/db/types";
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
  const [rows, setRows] = useState<LoadoutListRow[]>([]);
  const [curatedBuilds, setCuratedBuilds] = useState<BuildMatchInput[]>([]);
  const [filterCriteria, setFilterCriteria] = useState<ExoticFilterCriteria>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [openId, setOpenId] = useState<string | null>(null);
  const [openLoadout, setOpenLoadout] = useState<SavedLoadout | null>(null);
  const [liveBuild, setLiveBuild] = useState<GeneratedBuild | null>(null);
  const [liveSheet, setLiveSheet] = useState<ResolvedBuildSheet | null>(null);
  const [staleBanner, setStaleBanner] = useState<string | null>(null);
  const [opening, setOpening] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [discovery, setDiscovery] = useState<{
    open: boolean;
    title: string;
    matches: LoadoutListRow[];
  }>({ open: false, title: "", matches: [] });

  const pickerOptions = useMemo(() => collectPickerOptions(rows), [rows]);
  const displayRows = useMemo(
    () => filterLoadoutRows(rows, filterCriteria),
    [rows, filterCriteria],
  );

  const matchByLoadoutId = useMemo(() => {
    const map = new Map<string, ReturnType<typeof matchLoadoutToBuilds>>();
    for (const lo of rows) {
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
    return map;
  }, [rows, curatedBuilds]);

  const fetchLoadouts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [loRes, buildRes] = await Promise.all([
        fetch("/api/user/loadouts"),
        fetch("/api/user/builds"),
      ]);
      if (loRes.status === 401) {
        setRows([]);
        setCuratedBuilds([]);
        return;
      }
      if (!loRes.ok) {
        const body = (await loRes.json()) as { error?: string };
        setError(body.error ?? "Failed to load loadouts");
        return;
      }
      const body = (await loRes.json()) as { loadouts: LoadoutListRow[] };
      setRows(body.loadouts);

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
        setRows([]);
        setCuratedBuilds([]);
        setOpenId(null);
        setOpenLoadout(null);
        setLiveBuild(null);
        setLiveSheet(null);
        setStaleBanner(null);
        setFilterCriteria({});
        setDiscovery({ open: false, title: "", matches: [] });
        setLoading(false);
      }
    },
    [fetchLoadouts],
  );

  const openDiscovery = useCallback(
    (title: string, criteria: ExoticFilterCriteria) => {
      const matches = buildDiscoveryMatches(rows, criteria, openId ?? undefined);
      setDiscovery({ open: true, title, matches });
    },
    [rows, openId],
  );

  const reResolveIfStale = async (
    loadout: SavedLoadout,
  ): Promise<{ build: GeneratedBuild; sheet: ResolvedBuildSheet; banner: string | null }> => {
    let manifestVersion: string | null = null;
    try {
      const statusRes = await fetch("/api/manifest");
      if (statusRes.ok) {
        const status = (await statusRes.json()) as { cachedVersion: string | null };
        manifestVersion = status.cachedVersion;
      }
    } catch {
      return { build: loadout.generatedBuild, sheet: loadout.resolvedSheet, banner: null };
    }

    if (!manifestVersion || loadout.manifestVersion === manifestVersion) {
      return { build: loadout.generatedBuild, sheet: loadout.resolvedSheet, banner: null };
    }

    const activity = loadout.buildRequest?.activity ?? loadout.resolvedSheet.activity;
    const res = await fetch("/api/build/resolve-slot", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "full",
        build: loadout.generatedBuild,
        activity,
      }),
    });

    if (!res.ok) {
      return {
        build: loadout.generatedBuild,
        sheet: loadout.resolvedSheet,
        banner: "Could not re-validate against the current manifest.",
      };
    }

    const body = (await res.json()) as {
      build: GeneratedBuild;
      sheet: ResolvedBuildSheet;
      manifestVersion: string;
    };

    void fetch(`/api/user/loadouts/${loadout.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        generatedBuild: body.build,
        resolvedSheet: body.sheet,
        manifestVersion: body.manifestVersion,
      }),
    });

    return {
      build: body.build,
      sheet: body.sheet,
      banner: "Re-validated against current manifest.",
    };
  };

  const handleOpen = async (id: string) => {
    if (openId === id) {
      setOpenId(null);
      setOpenLoadout(null);
      setLiveBuild(null);
      setLiveSheet(null);
      setStaleBanner(null);
      return;
    }

    setOpenId(id);
    setOpening(true);
    setError(null);
    setStaleBanner(null);
    try {
      const res = await fetch(`/api/user/loadouts/${id}`);
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to open loadout");
        setOpenId(null);
        return;
      }
      const body = (await res.json()) as { loadout: SavedLoadout };
      setOpenLoadout(body.loadout);

      const resolved = await reResolveIfStale(body.loadout);
      setLiveBuild(resolved.build);
      setLiveSheet(resolved.sheet);
      setStaleBanner(resolved.banner);
    } catch {
      setError("Failed to open loadout");
      setOpenId(null);
    } finally {
      setOpening(false);
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (!window.confirm(`Delete "${name}"? This cannot be undone.`)) return;

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
      setRows((prev) => prev.filter((l) => l.id !== id));
    } catch {
      setError("Failed to delete loadout");
    } finally {
      setDeletingId(null);
    }
  };

  const activity =
    openLoadout?.buildRequest?.activity ?? openLoadout?.resolvedSheet.activity ?? "General PvE";

  const openRow = openId ? rows.find((r) => r.id === openId) : undefined;

  return (
    <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6">
      <Stack gap={16}>
        <LoadoutDiscoveryOverlay
          open={discovery.open}
          title={discovery.title}
          matches={discovery.matches}
          onClose={() => setDiscovery((d) => ({ ...d, open: false }))}
        />

        <PageHeader
          title="In-Game Loadouts"
          description="Saved loadouts and gear snapshots. Sign in with Bungie to sync across sessions."
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

        {!signedIn ? (
          <EmptyState description="Sign in with Bungie to view and manage saved loadouts." />
        ) : null}

        {signedIn && loading ? (
          <Text size="sm" tone="muted">
            Loading loadouts…
          </Text>
        ) : null}

        {signedIn && !loading && rows.length === 0 ? (
          <EmptyState description="No saved loadouts yet. Apply or save a loadout from Build to see it here." />
        ) : null}

        {signedIn && rows.length > 0 ? (
          <Stack gap={12}>
            <LoadoutExoticFilterBar
              criteria={filterCriteria}
              armorOptions={pickerOptions.armor}
              weaponOptions={pickerOptions.weapon}
              onChange={setFilterCriteria}
              onClearAll={() => setFilterCriteria({})}
            />

            {displayRows.length === 0 ? (
              <Text size="sm" tone="muted">
                No loadouts match the current exotic filters.
              </Text>
            ) : null}

            <Stack gap={8}>
              {displayRows.map((loadout) => {
                const isOpen = openId === loadout.id;
                const isDeleting = deletingId === loadout.id;
                const exoticLabels = exoticRowLabels(loadout);
                const buildMatch =
                  matchByLoadoutId.get(loadout.id) ?? {
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
                  <Panel key={loadout.id} tone="default" pad="none" className="overflow-hidden">
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
                          <Text size="sm" weight="medium" className="truncate">
                            {loadout.name}
                          </Text>
                          <Text size="xs" tone="muted">
                            {[loadout.className, loadout.source, formatDate(loadout.updatedAt)]
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
                            tone={buildMatch.kind === "none" ? "muted" : "accent"}
                          >
                            {matchLabel}
                          </Text>
                        </Stack>
                      </LoadoutColorBar>
                      <Row gap={8} className="shrink-0">
                        <Button
                          size="sm"
                          disabled={opening && openId === loadout.id}
                          onClick={() => void handleOpen(loadout.id)}
                        >
                          {isOpen ? "Close" : "Open"}
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          disabled={isDeleting}
                          onClick={() => void handleDelete(loadout.id, loadout.name)}
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
                          className={openLoadout.buildRequest?.className ?? "Titan"}
                          staleBanner={staleBanner}
                          exoticSummary={openRow?.exoticSummary}
                          onDiscoverLoadouts={openDiscovery}
                          onUpdate={({ build, sheet }) => {
                            setLiveBuild(build);
                            setLiveSheet(sheet);
                            void fetch(`/api/user/loadouts/${loadout.id}`, {
                              method: "PUT",
                              headers: { "Content-Type": "application/json" },
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
          </Stack>
        ) : null}
      </Stack>
    </div>
  );
}
