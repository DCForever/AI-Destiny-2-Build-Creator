"use client";

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
  const filtered = classFilter
    ? builds.filter((b) => b.className === classFilter)
    : builds;

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

        {loading ? (
          <Text size="sm" tone="muted">
            Loading builds…
          </Text>
        ) : filtered.length === 0 ? (
          <Stack gap={8}>
            <Text size="sm" tone="muted">
              {builds.length === 0
                ? "No curated builds yet."
                : "No builds match this class filter."}
            </Text>
            <Button variant="ghost" size="sm" onClick={onNew}>
              Create build
            </Button>
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
