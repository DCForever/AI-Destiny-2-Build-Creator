"use client";

import { useCallback, useEffect, useState, type ReactNode } from "react";
import { useRouter, useSearchParams } from "next/navigation";

import { BuildActions } from "@/components/build/BuildActions";
import { BuildEditPanel } from "@/components/build/BuildEditPanel";
import { BuildIdentity } from "@/components/build/BuildIdentity";
import { BuildLibrary } from "@/components/build/BuildLibrary";
import { CreateBuildPanel } from "@/components/build/CreateBuildPanel";
import { VariantCard } from "@/components/build/VariantCard";
import { VariantEditPanel } from "@/components/build/VariantEditPanel";
import type {
  BuildDetail,
  BuildSubclass,
  BuildSummary,
  BungieCharacter,
  GuardianClass,
} from "@/components/build/types";
import type { SynergyTypeSelection } from "@/components/build/SynergyTypeMultiSelect";
import {
  Callout,
  CardGrid,
  EmptyState,
  PageHeader,
  Stack,
  Workspace,
  WorkspaceMain,
} from "@/components/ui";
import {
  BUILD_QUERY_BUILD,
  BUILD_QUERY_VARIANT,
} from "@/lib/sets/buildDetailHref";
import { sortByName } from "@/lib/sortByName";

/**
 * Build screen composition.
 *
 * Layout slots (reorder freely):
 *   PageHeader
 *   Workspace
 *     rail  → BuildLibrary
 *     main  → WorkspaceMain
 *       CreateBuildPanel | BuildEditPanel | EmptyState |
 *       [BuildIdentity, VariantEditPanel | CardGrid + BuildActions]
 */
export function BuildPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const deepBuildId = searchParams.get(BUILD_QUERY_BUILD);
  const deepVariantName = searchParams.get(BUILD_QUERY_VARIANT);

  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [builds, setBuilds] = useState<BuildSummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<BuildDetail | null>(null);
  const [variantId, setVariantId] = useState<string | null>(null);
  const [classFilter, setClassFilter] = useState<GuardianClass | null>(null);
  const [creating, setCreating] = useState(false);
  const [editingBuild, setEditingBuild] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [createError, setCreateError] = useState<string | null>(null);
  const [createBusy, setCreateBusy] = useState(false);
  const [characters, setCharacters] = useState<BungieCharacter[]>([]);
  const [characterId, setCharacterId] = useState("");
  const [actionBusy, setActionBusy] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [editingVariantId, setEditingVariantId] = useState<string | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);

  const writeBuildQuery = useCallback(
    (buildId: string | null, variantName?: string | null) => {
      const params = new URLSearchParams(searchParams.toString());
      if (buildId) {
        params.set(BUILD_QUERY_BUILD, buildId);
        if (variantName) params.set(BUILD_QUERY_VARIANT, variantName);
        else params.delete(BUILD_QUERY_VARIANT);
      } else {
        params.delete(BUILD_QUERY_BUILD);
        params.delete(BUILD_QUERY_VARIANT);
      }
      const qs = params.toString();
      router.replace(qs ? `/build?${qs}` : "/build", { scroll: false });
    },
    [router, searchParams],
  );

  const loadBuilds = useCallback(async () => {
    const res = await fetch("/api/user/builds");
    if (res.status === 401) {
      setSignedIn(false);
      setBuilds([]);
      return false;
    }
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      setError(body.error ?? "Failed to load builds");
      return false;
    }
    setSignedIn(true);
    const body = (await res.json()) as {
      builds: Array<
        BuildSummary & {
          subclass?: BuildSubclass | string | null;
          pinnedSuper?: string | null;
        }
      >;
    };
    const mapped: BuildSummary[] = (body.builds ?? []).map((b) => {
      const sub =
        typeof b.subclass === "string"
          ? b.subclass
          : b.subclass && typeof b.subclass === "object"
            ? b.subclass.name
            : b.subclassName ?? null;
      const superName =
        b.pinnedSuper ??
        (typeof b.subclass === "object" && b.subclass
          ? b.subclass.super
          : null) ??
        b.superName ??
        null;
      return {
        id: b.id,
        name: b.name,
        className: b.className,
        exoticArmorHash: b.exoticArmorHash,
        exoticArmorName: b.exoticArmorName,
        exoticWeaponHash: b.exoticWeaponHash,
        exoticWeaponName: b.exoticWeaponName,
        pinnedSuper: b.pinnedSuper,
        subclassName: sub,
        superName,
      };
    });
    setBuilds(sortByName(mapped));
    return true;
  }, []);

  const loadCharacters = useCallback(async () => {
    const res = await fetch("/api/bungie/characters");
    if (!res.ok) {
      setCharacters([]);
      return;
    }
    const body = (await res.json()) as { characters: BungieCharacter[] };
    setCharacters(body.characters ?? []);
  }, []);

  const loadDetail = useCallback(
    async (id: string, preferredVariantName?: string | null) => {
      setError(null);
      const res = await fetch(`/api/user/builds/${id}`);
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to load build");
        setDetail(null);
        return;
      }
      const body = (await res.json()) as { build: BuildDetail };
      const build = body.build;
      setDetail(build);
      const byName = preferredVariantName
        ? build.variants.find((v) => v.name === preferredVariantName)
        : undefined;
      const preferred =
        byName ??
        build.variants.find((v) => v.isDefault) ??
        build.variants[0] ??
        null;
      setVariantId(preferred?.id ?? null);
    },
    [],
  );

  useEffect(() => {
    void (async () => {
      setLoading(true);
      const ok = await loadBuilds();
      if (ok) {
        await loadCharacters();
      }
      setLoading(false);
    })();
  }, [loadBuilds, loadCharacters]);

  // Deep link: /build?build=<id>&variant=<name>
  useEffect(() => {
    if (loading || signedIn !== true || !deepBuildId) return;
    if (selectedId === deepBuildId && detail?.id === deepBuildId) {
      if (deepVariantName && detail) {
        const match = detail.variants.find((v) => v.name === deepVariantName);
        if (match && variantId !== match.id) setVariantId(match.id);
      }
      return;
    }
    const exists = builds.some((b) => b.id === deepBuildId);
    if (!exists) {
      setError("Linked build was not found in your library.");
      return;
    }
    setCreating(false);
    setEditingBuild(false);
    setEditingVariantId(null);
    setSelectedId(deepBuildId);
    void loadDetail(deepBuildId, deepVariantName);
  }, [
    loading,
    signedIn,
    deepBuildId,
    deepVariantName,
    builds,
    selectedId,
    detail,
    variantId,
    loadDetail,
  ]);

  async function handleCreate(input: {
    name?: string;
    className: GuardianClass;
    subclass: BuildSubclass;
    synergyTypes: SynergyTypeSelection[];
    exoticArmorName: string | null;
    exoticArmorHash: number | null;
    pinnedSuper: string | null;
  }) {
    setCreateBusy(true);
    setCreateError(null);
    try {
      const payload = {
        name: input.name,
        className: input.className,
        subclass: input.subclass,
        synergyTypes: input.synergyTypes,
        pinnedSuper: input.pinnedSuper,
        exoticArmorName: input.exoticArmorName,
        exoticArmorHash: input.exoticArmorHash,
      };
      const res = await fetch("/api/user/builds", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const body = (await res.json()) as {
        build?: BuildDetail;
        error?: string;
      };
      if (!res.ok) {
        setCreateError(body.error ?? "Failed to create build");
        return;
      }
      await loadBuilds();
      if (body.build?.id) {
        setSelectedId(body.build.id);
        await loadDetail(body.build.id);
        writeBuildQuery(body.build.id);
        setCreating(false);
      }
    } catch {
      setCreateError("Failed to create build");
    } finally {
      setCreateBusy(false);
    }
  }

  async function runEquip() {
    if (!selectedId || !variantId || !characterId) return;
    setActionBusy("equip");
    setActionMessage(null);
    setError(null);
    try {
      const res = await fetch(
        `/api/user/builds/${selectedId}/variants/${variantId}/equip`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ characterId }),
        },
      );
      const body = (await res.json()) as { error?: string; message?: string };
      if (!res.ok) {
        setError(body.error ?? "Equip failed");
        return;
      }
      setActionMessage(body.message ?? "Applied to character.");
    } catch {
      setError("Equip failed");
    } finally {
      setActionBusy(null);
    }
  }

  async function runDim(jsonOnly: boolean) {
    if (!selectedId || !variantId) return;
    setActionBusy("dim");
    setActionMessage(null);
    setError(null);
    try {
      const res = await fetch(
        `/api/user/builds/${selectedId}/variants/${variantId}/dim-export`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ jsonOnly }),
        },
      );
      const body = (await res.json()) as {
        error?: string;
        shareUrl?: string;
        loadout?: unknown;
      };
      if (!res.ok) {
        setError(body.error ?? "DIM export failed");
        return;
      }
      if (body.shareUrl) {
        setActionMessage(`DIM share: ${body.shareUrl}`);
        window.open(body.shareUrl, "_blank", "noopener,noreferrer");
        return;
      }
      const blob = new Blob([JSON.stringify(body.loadout ?? body, null, 2)], {
        type: "application/json",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `dim-${selectedId}-${variantId}.json`;
      a.click();
      URL.revokeObjectURL(url);
      setActionMessage("Downloaded DIM loadout JSON.");
    } catch {
      setError("DIM export failed");
    } finally {
      setActionBusy(null);
    }
  }

  function applySavedBuild(next: BuildDetail) {
    setDetail(next);
    setSelectedId(next.id);
    setBuilds((prev) => {
      const exists = prev.some((b) => b.id === next.id);
      const mapped = exists
        ? prev.map((b) =>
            b.id === next.id
              ? {
                  ...b,
                  name: next.name,
                  exoticArmorName: next.exoticArmorName,
                  exoticWeaponName: next.exoticWeaponName,
                  pinnedSuper: next.pinnedSuper,
                }
              : b,
          )
        : [
            ...prev,
            {
              id: next.id,
              name: next.name,
              className: next.className,
              exoticArmorHash: next.exoticArmorHash,
              exoticArmorName: next.exoticArmorName,
              exoticWeaponHash: next.exoticWeaponHash,
              exoticWeaponName: next.exoticWeaponName,
              pinnedSuper: next.pinnedSuper,
              subclassName: next.subclass?.name ?? null,
              superName: next.pinnedSuper ?? next.subclass?.super ?? null,
            },
          ];
      return sortByName(mapped);
    });
  }

  async function handleDeleteBuild() {
    if (!detail) return;
    const confirmed = window.confirm(
      `Delete build “${detail.name}”? This cannot be undone.`,
    );
    if (!confirmed) return;
    setDeleteBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/builds/${detail.id}`, {
        method: "DELETE",
      });
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to delete build");
        return;
      }
      setBuilds((prev) => prev.filter((b) => b.id !== detail.id));
      setSelectedId(null);
      setDetail(null);
      setVariantId(null);
      setEditingBuild(false);
      setEditingVariantId(null);
      setActionMessage(null);
      writeBuildQuery(null);
    } catch {
      setError("Failed to delete build");
    } finally {
      setDeleteBusy(false);
    }
  }

  if (signedIn === false) {
    return (
      <div className="flex-1 max-w-3xl mx-auto px-4 sm:px-6 py-4 sm:py-6">
        <Stack gap={16}>
          <PageHeader
            title="Build"
            description="Sign in with Bungie to browse and apply your curated builds."
          />
        </Stack>
      </div>
    );
  }

  const selectedVariant =
    detail?.variants.find((v) => v.id === variantId) ??
    detail?.variants[0] ??
    null;
  const editingVariant =
    detail?.variants.find((v) => v.id === editingVariantId) ?? null;

  let main: ReactNode;
  if (creating) {
    main = (
      <CreateBuildPanel
        busy={createBusy}
        error={createError}
        onCancel={() => setCreating(false)}
        onCreate={(input) => void handleCreate(input)}
      />
    );
  } else if (!detail) {
    main = (
      <EmptyState
        description={
          loading
            ? "Loading…"
            : "Select a build from the library, or create a new one."
        }
      />
    );
  } else if (editingBuild) {
    main = (
      <WorkspaceMain>
        <BuildEditPanel
          key={detail.id}
          build={detail}
          onClose={() => setEditingBuild(false)}
          onSaved={(next) => {
            applySavedBuild(next);
            if (next.id !== detail.id) {
              setEditingBuild(false);
              void loadDetail(next.id);
            }
          }}
        />
      </WorkspaceMain>
    );
  } else if (editingVariant) {
    main = (
      <WorkspaceMain>
        <BuildIdentity
          build={detail}
          onEdit={() => {
            setEditingVariantId(null);
            setEditingBuild(true);
            setActionMessage(null);
          }}
          onDelete={() => void handleDeleteBuild()}
          deleteBusy={deleteBusy}
        />
        <VariantEditPanel
          key={editingVariant.id}
          build={detail}
          variant={editingVariant}
          onClose={() => setEditingVariantId(null)}
          onSaved={(next, preferredVariantId) => {
            applySavedBuild(next);
            if (preferredVariantId) {
              setVariantId(preferredVariantId);
              setEditingVariantId(preferredVariantId);
            }
          }}
        />
      </WorkspaceMain>
    );
  } else {
    main = (
      <WorkspaceMain>
        <BuildIdentity
          build={detail}
          onEdit={() => {
            setEditingVariantId(null);
            setEditingBuild(true);
            setActionMessage(null);
          }}
          onDelete={() => void handleDeleteBuild()}
          deleteBusy={deleteBusy}
        />
        <CardGrid>
          {detail.variants.map((variant) => (
            <VariantCard
              key={variant.id}
              build={detail}
              variant={variant}
              selected={selectedVariant?.id === variant.id}
              onSelect={() => {
                setVariantId(variant.id);
                setActionMessage(null);
                if (selectedId) writeBuildQuery(selectedId, variant.name);
              }}
              onEdit={() => {
                setEditingBuild(false);
                setVariantId(variant.id);
                setEditingVariantId(variant.id);
                setActionMessage(null);
                if (selectedId) writeBuildQuery(selectedId, variant.name);
              }}
            />
          ))}
        </CardGrid>
        {selectedVariant ? (
          <BuildActions
            className={detail.className}
            characters={characters}
            characterId={characterId}
            onCharacterId={setCharacterId}
            equipReadyHint={null}
            busy={actionBusy}
            message={actionMessage}
            onEquip={() => void runEquip()}
            onDimExport={() => void runDim(false)}
            onDimJson={() => void runDim(true)}
          />
        ) : null}
      </WorkspaceMain>
    );
  }

  return (
    <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6">
      <Stack gap={16}>
        <PageHeader
          title="Build"
          description="Curated library — create builds, edit variants (General · Sets · Artifact · Mods · Abilities · Aspects · Fragments), apply to a character or export to DIM."
        />

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <Workspace
          rail={
            <BuildLibrary
              builds={builds}
              selectedId={selectedId}
              classFilter={classFilter}
              onClassFilter={setClassFilter}
              onSelect={(id) => {
                setCreating(false);
                setEditingBuild(false);
                setEditingVariantId(null);
                setSelectedId(id);
                setActionMessage(null);
                writeBuildQuery(id);
                void loadDetail(id);
              }}
              onNew={() => {
                setCreating(true);
                setEditingBuild(false);
                setEditingVariantId(null);
                setSelectedId(null);
                setDetail(null);
                setVariantId(null);
                setCreateError(null);
                writeBuildQuery(null);
              }}
              loading={loading}
            />
          }
          main={main}
          /* railPosition="end" moves library to the right */
        />
      </Stack>
    </div>
  );
}
