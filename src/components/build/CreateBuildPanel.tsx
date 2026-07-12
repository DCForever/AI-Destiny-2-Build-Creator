"use client";

import { useState } from "react";

import type { BuildSubclass, GuardianClass } from "@/components/build/types";
import { ExoticArmorLookup } from "@/components/debug/ExoticArmorLookup";
import { PinnedSuperLookup } from "@/components/debug/PinnedSuperLookup";
import {
  SynergyTypeMultiSelect,
  type SynergyTypeSelection,
} from "@/components/debug/SynergyTypeMultiSelect";
import {
  Button,
  Cluster,
  FilterChip,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  TextField,
  Heading,
} from "@/components/ui";
import { formatSubclassLabel } from "@/data/subclasses";
import {
  defaultSubclassForClass,
  pinnedSuperAfterSubclassChange,
  subclassAfterClassChange,
  subclassesForClass,
} from "@/lib/build/createBuildLookups";
import { createBuildPayload } from "@/lib/build/createBuildPayload";

const CLASSES: GuardianClass[] = ["Titan", "Hunter", "Warlock"];

const DEFAULT_SUBCLASS: BuildSubclass = {
  name: "Sunbreaker",
  super: "Hammer of Sol",
  classAbility: "Rally Barricade",
  movement: "Catapult Lift",
  melee: "Consecration",
  grenade: "Healing Grenade",
  aspects: ["Roaring Flames", "Sol Invictus"],
  fragments: ["Ember of Torches", "Ember of Ashes"],
  rationale: "Curated build",
};

export function CreateBuildPanel({
  busy,
  error,
  onCancel,
  onCreate,
}: {
  busy: boolean;
  error: string | null;
  onCancel: () => void;
  onCreate: (input: ReturnType<typeof createBuildPayload>) => void;
}) {
  const [name, setName] = useState("");
  const [className, setClassName] = useState<GuardianClass>("Titan");
  const [subclassName, setSubclassName] = useState(defaultSubclassForClass("Titan"));
  const [pinnedSuper, setPinnedSuper] = useState<string | null>(null);
  const [exotic, setExotic] = useState<{ hash: number; name: string } | null>(null);
  const [synergyTypes, setSynergyTypes] = useState<SynergyTypeSelection[]>([]);

  const canSubmit = synergyTypes.length > 0 && !busy;

  function handleClassChange(next: GuardianClass) {
    setClassName(next);
    setSubclassName((prev) => {
      const nextSubclass = subclassAfterClassChange(next, prev);
      setPinnedSuper((pin) => pinnedSuperAfterSubclassChange(prev, nextSubclass, pin));
      return nextSubclass;
    });
    setExotic(null);
  }

  function handleSubclassChange(next: string) {
    setSubclassName((prev) => {
      setPinnedSuper((pin) => pinnedSuperAfterSubclassChange(prev, next, pin));
      return next;
    });
  }

  return (
    <Panel tone="raised" pad="lg" as="form">
      <Stack gap={16}>
        <Row justify="between" align="center">
          <Heading level={2}>Create build</Heading>
          <Button variant="ghost" size="sm" onClick={onCancel}>
            Cancel
          </Button>
        </Row>

        <TextField
          label="Name (optional — auto-derived if empty)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Consecrated Pyre"
        />

        <Section label="Class">
          <Cluster>
            {CLASSES.map((cls) => (
              <FilterChip
                key={cls}
                label={cls}
                active={className === cls}
                onClick={() => handleClassChange(cls)}
              />
            ))}
          </Cluster>
        </Section>

        <Section label="Subclass">
          <select
            className="w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground"
            value={subclassName}
            onChange={(e) => handleSubclassChange(e.target.value)}
          >
            {subclassesForClass(className).map((s) => (
              <option key={s} value={s}>
                {formatSubclassLabel(s)}
              </option>
            ))}
          </select>
        </Section>

        <PinnedSuperLookup
          subclassName={subclassName}
          selected={pinnedSuper}
          onSelect={setPinnedSuper}
        />

        <ExoticArmorLookup className={className} selected={exotic} onSelect={setExotic} />

        <Section label="Synergy Types (required)">
          <Text size="xs" tone="muted" className="mb-2">
            Intent only — Type (+ sub-type). Library Synergies (Type + Object) are matched for
            coverage.
          </Text>
          <SynergyTypeMultiSelect selected={synergyTypes} onChange={setSynergyTypes} />
        </Section>

        {error ? (
          <Text size="xs" tone="danger">
            {error}
          </Text>
        ) : null}

        <Button
          variant="accent"
          disabled={!canSubmit}
          onClick={() =>
            onCreate(
              createBuildPayload({
                name,
                className,
                subclassName,
                pinnedSuper,
                exotic,
                synergyTypes,
                subclassDefaults: DEFAULT_SUBCLASS,
              }),
            )
          }
        >
          {busy ? "Creating…" : "Save build"}
        </Button>
      </Stack>
    </Panel>
  );
}
