"use client";

import { useMemo, useState } from "react";

import type { GuardianClass, BuildSummary } from "@/components/build/types";
import {
  Button,
  ClassFilterChip,
  ClassIcon,
  Cluster,
  ElementIcon,
  FilterChip,
  IconBadge,
  Panel,
  Row,
  SectionLabel,
  Stack,
  SuperIcon,
  Text,
} from "@/components/ui";
import {
  CLASS_CSS_COLOR,
  CLASS_TEXT_CLASS,
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
    <Panel as="aside" className="h-full min-h-0 flex flex-col overflow-hidden">
      <Stack gap={10} className="shrink-0">
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
                onClick={() => onClassFilter(classFilter === cls ? null : cls)}
                size="md"
              />
            ))}
          </Cluster>
        </Stack>

        {exoticOptions.length > 0 ? (
          <Stack gap={6}>
            <Text size="xs" tone="muted" className="uppercase tracking-widest">
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

        {hasFilters ? (
          <button
            type="button"
            className="text-[10px] tracking-widest uppercase text-muted hover:text-foreground self-start"
            onClick={clearFilters}
          >
            Clear filters
          </button>
        ) : null}
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
          <Stack gap={6}>
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

              return (
                <button
                  key={build.id}
                  type="button"
                  onClick={() => onSelect(build.id)}
                  className="text-left w-full"
                >
                  <Panel
                    tone={selected ? "accent" : "muted"}
                    pad="sm"
                    className={
                      selected
                        ? ""
                        : "hover:border-line-strong transition-colors"
                    }
                  >
                    <Stack gap={4}>
                      <Text size="sm" weight="medium" className="truncate">
                        {build.name}
                      </Text>
                      <Row gap={6} align="center" wrap>
                        <IconBadge label={cls}>
                          <ClassIcon className={cls} color={classColor} size={14} />
                        </IconBadge>
                        <Text
                          size="xs"
                          as="span"
                          className={CLASS_TEXT_CLASS[cls]}
                        >
                          {cls}
                        </Text>
                        {subclass ? (
                          <>
                            <IconBadge label={element}>
                              <ElementIcon
                                element={element}
                                color={elementColor}
                                size={12}
                                title={subclass}
                              />
                            </IconBadge>
                            <Text size="xs" tone="muted" as="span">
                              {subclass}
                            </Text>
                          </>
                        ) : null}
                        {superName ? (
                          <IconBadge label={superName}>
                            <SuperIcon
                              color={elementColor}
                              size={13}
                              title={superName}
                            />
                          </IconBadge>
                        ) : null}
                      </Row>
                      {build.exoticArmorName ? (
                        <Text size="xs" tone="muted" as="span">
                          {build.exoticArmorName}
                        </Text>
                      ) : null}
                      <BuildLoadoutBadges
                        match={loadoutMatchesByBuildId?.get(build.id)}
                      />
                    </Stack>
                  </Panel>
                </button>
              );
            })}
          </Stack>
        )}
      </div>
    </Panel>
  );
}

function BuildLoadoutBadges({
  match,
}: {
  match: BuildLoadoutMatch | undefined;
}) {
  if (!match || match.kind === "none" || match.loadouts.length === 0) {
    return null;
  }

  const label = buildLoadoutMatchLabel(match);
  const shown = match.loadouts.slice(0, 3);
  const extra = match.loadouts.length - shown.length;

  return (
    <Row gap={4} align="center" wrap>
      <span className="inline-flex items-center gap-1" title={label}>
        {shown.map((lo) => (
          <span
            key={lo.id}
            className="inline-flex size-5 shrink-0 items-center justify-center border border-line bg-surface-raised overflow-hidden"
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
              <span className="text-[8px] text-muted tracking-tight">LO</span>
            )}
          </span>
        ))}
      </span>
      {extra > 0 ? (
        <Text size="xs" tone="muted" as="span">
          +{extra}
        </Text>
      ) : null}
      <Text
        size="xs"
        tone={match.kind === "exact" ? "accent" : "muted"}
        as="span"
        className="truncate max-w-[140px]"
      >
        {match.kind === "exact" ? "In-game" : "Partial"}
        {match.loadouts.length === 1 ? ` · ${match.loadouts[0]!.name}` : ""}
      </Text>
    </Row>
  );
}
