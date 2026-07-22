"use client";

import { useMemo, useState } from "react";

import type { GuardianClass, BuildSummary } from "@/components/build/types";
import {
  Button,
  ClassFilterChip,
  ClassIcon,
  Cluster,
  CollapsibleFilterSection,
  ElementIcon,
  FilterChip,
  FlapBoard,
  FlapCell,
  FlapHeader,
  FlapRow,
  FlapSeal,
  Panel,
  Row,
  SectionLabel,
  Stack,
  SuperIcon,
  Text,
} from "@/components/ui";
import {
  CLASS_CSS_COLOR,
  ELEMENT_CSS_COLOR,
  elementFromSubclass,
  isGuardianClass,
} from "@/lib/destiny/identityVisuals";
import {
  collectExoticArmorOptions,
  filterBuilds,
  type ExoticArmorFilterKey,
} from "@/lib/builds/filterBuilds";
import type { BuildLoadoutMatch } from "@/lib/loadouts/matchLoadoutToBuilds";
import { buildLoadoutMatchLabel } from "@/lib/loadouts/matchLoadoutToBuilds";

const CLASSES: GuardianClass[] = ["Titan", "Hunter", "Warlock"];
const COLS = "minmax(0,1.35fr) 4.25rem 5.5rem minmax(0,0.9fr)";

export function BuildLibrary({
  builds,
  selectedId,
  classFilter,
  onClassFilter,
  onSelect,
  onNew,
  loading,
  loadoutMatchesByBuildId,
}: {
  builds: BuildSummary[];
  selectedId: string | null;
  classFilter: GuardianClass | null;
  onClassFilter: (next: GuardianClass | null) => void;
  onSelect: (id: string) => void;
  onNew: () => void;
  loading: boolean;
  /** In-game loadout matches keyed by build id (from Bungie slots). */
  loadoutMatchesByBuildId?: Map<string, BuildLoadoutMatch>;
}) {
  const [exoticKeys, setExoticKeys] = useState<ExoticArmorFilterKey[]>([]);
  const [filtersOpen, setFiltersOpen] = useState(false);

  /** Exotic chips scoped to current class filter (or full library). */
  const exoticOptions = useMemo(() => {
    const scope = classFilter
      ? builds.filter((b) => b.className === classFilter)
      : builds;
    return collectExoticArmorOptions(scope);
  }, [builds, classFilter]);

  // Drop exotic selections that vanished after class filter / library changes.
  const activeExoticKeys = useMemo(() => {
    if (exoticKeys.length === 0) return exoticKeys;
    const allowed = new Set(exoticOptions.map((o) => o.key));
    return exoticKeys.filter((k) => allowed.has(k));
  }, [exoticKeys, exoticOptions]);

  const filtered = useMemo(
    () =>
      filterBuilds(builds, {
        className: classFilter,
        exoticArmorKeys: activeExoticKeys,
      }),
    [builds, classFilter, activeExoticKeys],
  );

  const hasFilters = Boolean(classFilter) || activeExoticKeys.length > 0;

  function toggleExotic(key: ExoticArmorFilterKey) {
    setExoticKeys((prev) => {
      const next = prev.includes(key)
        ? prev.filter((k) => k !== key)
        : [...prev, key];
      return next;
    });
  }

  function clearFilters() {
    onClassFilter(null);
    setExoticKeys([]);
  }

  return (
    <Panel as="aside" pad="sm" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={6} className="shrink-0">
        <Row justify="between" align="center">
          <SectionLabel>
            Library
            {filtered.length !== builds.length
              ? ` · ${filtered.length}`
              : builds.length > 0
                ? ` · ${builds.length}`
                : ""}
          </SectionLabel>
          <Button variant="accent" size="sm" onClick={onNew}>
            New
          </Button>
        </Row>

        <CollapsibleFilterSection
          panel={false}
          open={filtersOpen}
          onOpenChange={setFiltersOpen}
          activeCount={(classFilter ? 1 : 0) + activeExoticKeys.length}
          onClear={clearFilters}
          summary={
            <Cluster gap={3}>
              {classFilter ? (
                <ClassFilterChip
                  className={classFilter}
                  active
                  onClick={() => onClassFilter(null)}
                  size="md"
                />
              ) : null}
              {activeExoticKeys.map((key) => {
                const opt = exoticOptions.find((o) => o.key === key);
                return (
                  <FilterChip
                    key={key}
                    size="xs"
                    label={opt?.label ?? key}
                    active
                    onClick={() => toggleExotic(key)}
                    title={opt?.label ?? key}
                  />
                );
              })}
            </Cluster>
          }
        >
          <Stack gap={8}>
            <Stack gap={6}>
              <Text size="xs" tone="muted" className="uppercase tracking-widest">
                Class
              </Text>
              <Cluster>
                {CLASSES.map((cls) => (
                  <ClassFilterChip
                    key={cls}
                    className={cls}
                    active={classFilter === cls}
                    onClick={() =>
                      onClassFilter(classFilter === cls ? null : cls)
                    }
                    size="md"
                  />
                ))}
              </Cluster>
            </Stack>

            {exoticOptions.length > 0 ? (
              <Stack gap={6}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest"
                >
                  Exotic armor
                </Text>
                <Cluster>
                  {exoticOptions.map((opt) => (
                    <FilterChip
                      key={opt.key}
                      label={opt.label}
                      active={activeExoticKeys.includes(opt.key)}
                      onClick={() => toggleExotic(opt.key)}
                      title={opt.label}
                    />
                  ))}
                </Cluster>
              </Stack>
            ) : null}
          </Stack>
        </CollapsibleFilterSection>
      </Stack>

      <div className="flex-1 min-h-0 overflow-y-auto mt-2">
        {loading ? (
          <Text size="sm" tone="muted">
            Loading builds…
          </Text>
        ) : filtered.length === 0 ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              {builds.length === 0
                ? "No curated builds yet."
                : "No builds match these filters."}
            </Text>
            {hasFilters ? (
              <Button variant="ghost" size="sm" onClick={clearFilters}>
                Clear filters
              </Button>
            ) : (
              <Button variant="ghost" size="sm" onClick={onNew}>
                Create build
              </Button>
            )}
          </Stack>
        ) : (
          <FlapBoard>
            <FlapHeader
              columns={COLS}
              cells={["Name", "Id", "Exotic", "Meta"]}
            />
            {filtered.map((build) => {
              const selected = build.id === selectedId;
              const cls = isGuardianClass(build.className)
                ? build.className
                : "Titan";
              const subclass = build.subclassName ?? null;
              const element = elementFromSubclass(subclass);
              const superName = build.pinnedSuper ?? build.superName ?? null;
              const elementColor = ELEMENT_CSS_COLOR[element];
              const classColor = CLASS_CSS_COLOR[cls];
              const match = loadoutMatchesByBuildId?.get(build.id);
              const ready =
                match?.kind === "exact" && (match.loadouts?.length ?? 0) > 0;

const hold = Boolean(match && match.kind !== "none" && !ready);
              const channel =
                element !== "Kinetic" ? elementColor : classColor;

              return (
                <FlapRow
                  key={build.id}
                  columns={COLS}
                  selected={selected}
                  channel={channel}
                  lamp={hold ? "warning" : "none"}
                  onClick={() => onSelect(build.id)}
                  aria-label={build.name}
                >
                  <FlapCell variant="name" title={build.name}>
                    {build.name}
                  </FlapCell>
                  <FlapCell
                    variant="channel"
                    className="gap-1"
                    title={`${cls}${subclass ? ` · ${subclass}` : ""}`}
                  >
                    <ClassIcon className={cls} color={classColor} size={14} />
                    {subclass ? (
                      <ElementIcon
                        element={element}
                        color={elementColor}
                        size={12}
                        title={subclass}
                      />
                    ) : null}
                    {superName ? (
                      <SuperIcon
                        color={elementColor}
                        size={12}
                        title={superName}
                      />
                    ) : null}
                  </FlapCell>
                  <FlapCell title={build.exoticArmorName ?? "No exotic"}>
                    {build.exoticArmorName ? (
                      <FlapSeal
                        kind="exotic"
                        label={build.exoticArmorName}
                        title={build.exoticArmorName}
                      />
                    ) : (
                      <span className="flap-cell-meta">—</span>
                    )}
                    {build.exoticWeaponName ? (
                      <FlapSeal
                        kind="exotic"
                        label={build.exoticWeaponName}
                        title={build.exoticWeaponName}
                      />
                    ) : null}
                  </FlapCell>
                  <FlapCell className="justify-end gap-2 min-w-0">
                    <BuildLoadoutBadges match={match} compact />
                    <span
                      className="flap-cell-tally"
                      data-ready={ready ? "true" : undefined}
                      data-hold={hold ? "true" : undefined}
                    >
                      {ready ? "READY" : hold ? "HOLD" : "—"}
                    </span>
                  </FlapCell>
                </FlapRow>
              );
            })}
          </FlapBoard>
        )}
      </div>
    </Panel>
  );
}

function BuildLoadoutBadges({
  match,
  compact = false,
}: {
  match: BuildLoadoutMatch | undefined;
  compact?: boolean;
}) {
  if (!match || match.kind === "none" || match.loadouts.length === 0) {
    return null;
  }

  const label = buildLoadoutMatchLabel(match);
  const shown = match.loadouts.slice(0, compact ? 2 : 3);
  const extra = match.loadouts.length - shown.length;

  return (
    <span className="inline-flex items-center gap-1 min-w-0" title={label}>
      {shown.map((lo) => (
<span
          key={lo.id}
          className="inline-flex size-5 shrink-0 items-center justify-center border overflow-hidden"
          style={{
            borderColor:
              match.kind === "exact"
                ? "color-mix(in srgb, var(--accent) 55%, transparent)"
                : "color-mix(in srgb, var(--warning) 45%, transparent)",
            background:
              match.kind === "exact"
                ? "color-mix(in srgb, var(--accent) 12%, var(--surface-raised))"
                : "color-mix(in srgb, var(--warning) 10%, var(--surface-raised))",
          }}
          title={
            match.kind === "exact"
              ? `In-game loadout: ${lo.name}`
              : `Partial match: ${lo.name}`
          }
        >
          {lo.iconUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={lo.iconUrl}
              alt=""
              width={16}
              height={16}
              className="size-4 object-contain"
            />
          ) : (
            <span className="text-[10px] text-muted tracking-tight">LO</span>
          )}
        </span>
      ))}
      {extra > 0 ? (
        <Text size="xs" tone="muted" as="span">
          +{extra}
        </Text>
      ) : null}
    </span>
  );
}

