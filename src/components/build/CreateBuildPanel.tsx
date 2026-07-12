"use client";

import { useState } from "react";

import type { BuildSubclass, GuardianClass } from "@/components/build/types";
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
  onCreate: (input: {
    name: string;
    className: GuardianClass;
    subclass: BuildSubclass;
    synergyTypes: SynergyTypeSelection[];
    exoticArmorName: string;
    pinnedSuper: string;
  }) => void;
}) {
  const [name, setName] = useState("");
  const [className, setClassName] = useState<GuardianClass>("Titan");
  const [subclassName, setSubclassName] = useState(DEFAULT_SUBCLASS.name);
  const [pinnedSuper, setPinnedSuper] = useState(DEFAULT_SUBCLASS.super);
  const [exoticArmorName, setExoticArmorName] = useState("");
  const [synergyTypes, setSynergyTypes] = useState<SynergyTypeSelection[]>([]);

  const canSubmit = synergyTypes.length > 0 && !busy;

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
                onClick={() => setClassName(cls)}
              />
            ))}
          </Cluster>
        </Section>

        <div className="grid gap-3 sm:grid-cols-2">
          <TextField
            label="Subclass"
            value={subclassName}
            onChange={(e) => setSubclassName(e.target.value)}
          />
          <TextField
            label="Pinned super"
            value={pinnedSuper}
            onChange={(e) => setPinnedSuper(e.target.value)}
          />
        </div>

        <TextField
          label="Exotic armor name (optional)"
          value={exoticArmorName}
          onChange={(e) => setExoticArmorName(e.target.value)}
          placeholder="Synthoceps"
        />

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
            onCreate({
              name: name.trim(),
              className,
              subclass: {
                ...DEFAULT_SUBCLASS,
                name: subclassName.trim() || DEFAULT_SUBCLASS.name,
                super: pinnedSuper.trim() || DEFAULT_SUBCLASS.super,
              },
              synergyTypes,
              exoticArmorName: exoticArmorName.trim(),
              pinnedSuper: pinnedSuper.trim(),
            })
          }
        >
          {busy ? "Creating…" : "Save build"}
        </Button>
      </Stack>
    </Panel>
  );
}
