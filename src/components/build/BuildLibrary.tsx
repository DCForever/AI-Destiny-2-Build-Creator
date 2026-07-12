"use client";

import type { GuardianClass, BuildSummary } from "@/components/build/types";
import { CLASS_COLOR } from "@/components/build/types";
import {
  Button,
  Cluster,
  FilterChip,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";

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
    <Panel as="aside" className="flex flex-col min-h-[420px]">
      <Stack gap={12}>
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
          <Stack gap={8}>
            {filtered.map((build) => {
              const selected = build.id === selectedId;
              return (
                <button
                  key={build.id}
                  type="button"
                  onClick={() => onSelect(build.id)}
                  className="text-left"
                >
                  <Panel
                    tone={selected ? "accent" : "muted"}
                    pad="sm"
                    className={
                      selected ? "" : "hover:border-line-strong transition-colors"
                    }
                  >
                    <Stack gap={4}>
                      <Text size="sm" weight="medium">
                        {build.name}
                      </Text>
                      <Row gap={8} wrap>
                        <Text
                          size="xs"
                          as="span"
                          className={CLASS_COLOR[build.className]}
                        >
                          {build.className}
                        </Text>
                        {build.exoticArmorName ? (
                          <Text size="xs" tone="muted" as="span">
                            {build.exoticArmorName}
                          </Text>
                        ) : null}
                      </Row>
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
