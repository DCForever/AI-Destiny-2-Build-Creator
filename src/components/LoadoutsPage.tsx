"use client";

import { Suspense, useCallback, useState } from "react";
import { BungieAuthControl } from "@/components/BungieAuthControl";
import { EditableBuildSheet } from "@/components/sheet/EditableBuildSheet";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import type { SavedLoadout } from "@/lib/db/types";

interface LoadoutSummary {
  id: string;
  name: string;
  source: string;
  className?: string;
  createdAt: string;
  updatedAt: string;
  manifestVersion: string;
}

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

export function LoadoutsPage() {
  const [signedIn, setSignedIn] = useState(false);
  const [loadouts, setLoadouts] = useState<LoadoutSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [openId, setOpenId] = useState<string | null>(null);
  const [openLoadout, setOpenLoadout] = useState<SavedLoadout | null>(null);
  const [liveBuild, setLiveBuild] = useState<GeneratedBuild | null>(null);
  const [liveSheet, setLiveSheet] = useState<ResolvedBuildSheet | null>(null);
  const [staleBanner, setStaleBanner] = useState<string | null>(null);
  const [opening, setOpening] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const fetchLoadouts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/user/loadouts");
      if (res.status === 401) {
        setLoadouts([]);
        return;
      }
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setError(body.error ?? "Failed to load loadouts");
        return;
      }
      const body = await res.json() as { loadouts: LoadoutSummary[] };
      setLoadouts(body.loadouts);
    } catch {
      setError("Failed to load loadouts");
    } finally {
      setLoading(false);
    }
  }, []);

  const handleAuthChange = useCallback((auth: { signedIn: boolean }) => {
    setSignedIn(auth.signedIn);
    if (auth.signedIn) {
      void fetchLoadouts();
    } else {
      setLoadouts([]);
      setOpenId(null);
      setOpenLoadout(null);
      setLiveBuild(null);
      setLiveSheet(null);
      setStaleBanner(null);
      setLoading(false);
    }
  }, [fetchLoadouts]);

  const reResolveIfStale = async (
    loadout: SavedLoadout,
  ): Promise<{ build: GeneratedBuild; sheet: ResolvedBuildSheet; banner: string | null }> => {
    let manifestVersion: string | null = null;
    try {
      const statusRes = await fetch("/api/manifest");
      if (statusRes.ok) {
        const status = await statusRes.json() as { cachedVersion: string | null };
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

    const body = await res.json() as {
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
        const body = await res.json() as { error?: string };
        setError(body.error ?? "Failed to open loadout");
        setOpenId(null);
        return;
      }
      const body = await res.json() as { loadout: SavedLoadout };
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
        const body = await res.json() as { error?: string };
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
      setLoadouts((prev) => prev.filter((l) => l.id !== id));
    } catch {
      setError("Failed to delete loadout");
    } finally {
      setDeletingId(null);
    }
  };

  const activity =
    openLoadout?.buildRequest?.activity ?? openLoadout?.resolvedSheet.activity ?? "General PvE";

  return (
    <div className="flex-1 max-w-4xl mx-auto p-6 space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-lg text-foreground mb-2">Saved Loadouts</h1>
          <p className="text-sm text-muted leading-relaxed">
            Builds you save from the Generator appear here. Sign in with Bungie to sync across sessions.
          </p>
        </div>
        <Suspense fallback={<p className="text-xs text-muted">Loading sign-in…</p>}>
          <BungieAuthControl compact onAuthChange={handleAuthChange} />
        </Suspense>
      </div>

      {error && <p className="text-xs text-danger">{error}</p>}

      {!signedIn && (
        <div className="panel-notch p-6 text-center">
          <p className="text-sm text-muted">Sign in with Bungie to view and manage saved loadouts.</p>
        </div>
      )}

      {signedIn && loading && (
        <p className="text-xs text-muted">Loading loadouts…</p>
      )}

      {signedIn && !loading && loadouts.length === 0 && (
        <div className="panel-notch p-6 text-center">
          <p className="text-sm text-muted">
            No saved loadouts yet. Generate a build and click <span className="text-accent">Save Loadout</span>.
          </p>
        </div>
      )}

      {signedIn && loadouts.length > 0 && (
        <ul className="space-y-2" role="list">
          {loadouts.map((loadout) => {
            const isOpen = openId === loadout.id;
            const isDeleting = deletingId === loadout.id;
            return (
              <li key={loadout.id} className="panel-notch overflow-hidden">
                <div className="flex flex-wrap items-center justify-between gap-3 p-4">
                  <div className="min-w-0">
                    <div className="text-sm text-foreground truncate">{loadout.name}</div>
                    <div className="text-xs text-muted mt-0.5">
                      {[loadout.className, loadout.source, formatDate(loadout.updatedAt)]
                        .filter(Boolean)
                        .join(" · ")}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => void handleOpen(loadout.id)}
                      disabled={opening && openId === loadout.id}
                      className="text-xs border border-line px-3 py-1 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent disabled:opacity-50"
                    >
                      {isOpen ? "Close" : "Open"}
                    </button>
                    <button
                      type="button"
                      onClick={() => void handleDelete(loadout.id, loadout.name)}
                      disabled={isDeleting}
                      className="text-xs border border-line px-3 py-1 text-muted hover:text-danger hover:border-danger/40 transition-colors focus-visible:outline-accent disabled:opacity-50"
                    >
                      {isDeleting ? "Deleting…" : "Delete"}
                    </button>
                  </div>
                </div>

                {isOpen && opening && (
                  <div className="px-4 pb-4 text-xs text-muted">Loading build…</div>
                )}

                {isOpen && openLoadout?.id === loadout.id && liveBuild && liveSheet && !opening && (
                  <div className="border-t border-line p-4">
                    <EditableBuildSheet
                      sheet={liveSheet}
                      build={liveBuild}
                      activity={activity}
                      className={openLoadout.buildRequest?.className ?? "Titan"}
                      staleBanner={staleBanner}
                      onUpdate={({ build, sheet }) => {
                        setLiveBuild(build);
                        setLiveSheet(sheet);
                        void fetch(`/api/user/loadouts/${loadout.id}`, {
                          method: "PUT",
                          headers: { "Content-Type": "application/json" },
                          body: JSON.stringify({ generatedBuild: build, resolvedSheet: sheet }),
                        });
                      }}
                    />
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
