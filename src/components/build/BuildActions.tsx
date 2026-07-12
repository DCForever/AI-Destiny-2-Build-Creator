"use client";

import type { BungieCharacter, GuardianClass } from "@/components/build/types";
import {
  Button,
  Panel,
  Row,
  Section,
  SelectField,
  Stack,
  Text,
} from "@/components/ui";

export function BuildActions({
  className,
  characters,
  characterId,
  onCharacterId,
  equipReadyHint,
  busy,
  message,
  onEquip,
  onDimExport,
  onDimJson,
}: {
  className: GuardianClass;
  characters: BungieCharacter[];
  characterId: string;
  onCharacterId: (id: string) => void;
  equipReadyHint: string | null;
  busy: string | null;
  message: string | null;
  onEquip: () => void;
  onDimExport: () => void;
  onDimJson: () => void;
}) {
  const matching = characters.filter((c) => c.classType === className);

  return (
    <Panel>
      <Section label="Apply / export">
        <Stack gap={12}>
          <Row gap={12} wrap align="end">
            <SelectField
              label="Character"
              value={characterId}
              onChange={(e) => onCharacterId(e.target.value)}
            >
              <option value="">Select…</option>
              {matching.map((c) => (
                <option key={c.characterId} value={c.characterId}>
                  {c.classType}
                  {c.light != null ? ` · ${c.light}` : ""}
                </option>
              ))}
            </SelectField>

            <Button
              variant="accent"
              disabled={!characterId || Boolean(busy)}
              onClick={onEquip}
            >
              {busy === "equip" ? "Applying…" : "Apply to character"}
            </Button>
            <Button
              variant="outline"
              disabled={Boolean(busy)}
              onClick={onDimExport}
            >
              {busy === "dim" ? "Sharing…" : "DIM share"}
            </Button>
            <Button
              variant="ghost"
              disabled={Boolean(busy)}
              onClick={onDimJson}
            >
              DIM JSON
            </Button>
          </Row>

          {equipReadyHint ? (
            <Text size="xs" tone="warning">
              {equipReadyHint}
            </Text>
          ) : null}
          {message ? (
            <Text size="xs" tone="success">
              {message}
            </Text>
          ) : null}
          {matching.length === 0 && characters.length > 0 ? (
            <Text size="xs" tone="muted">
              No {className} characters on this account.
            </Text>
          ) : null}
        </Stack>
      </Section>
    </Panel>
  );
}
