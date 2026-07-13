"use client";

import { useMemo, useState } from "react";

import type { GuardianClass, BuildSummary } from "@/components/build/types";
import {
  Button,
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

const CLASSES: GuardianClass[] = ["Titan", "Hunter", "Warlock"];

export function BuildLibrary({
  builds,
  selectedId,
  classFilter,
  onClassFilter,
  onSelect,
  onNew,
  loading,
}: {
  builds: BuildSummary[];
  selectedId: string | null;
  classFilter: GuardianClass | null;
  onClassFilter: (next: GuardianClass | null) => void;
  onSelect: (id: string) => void;
  onNew: () => void;
  loading: boolean;
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
    <Panel as="aside" className="flex flex-col min-h-[min(420px,70vh)] lg:min-h-[420px]">
      <Stack gap={10}>
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
              <FilterChip
                key={cls}
                label={cls}
                active={classFilter === cls}
                onClick={() => onClassFilter(classFilter === cls ? null : cls)}
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
                    </Stack>
                  </Panel>
                </button>
              );
            })}
          </Stack>
        )}
      </Stack>
    </Panel>
  );
}
