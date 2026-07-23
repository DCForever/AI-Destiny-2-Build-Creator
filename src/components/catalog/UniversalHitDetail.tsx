"use client";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Badge,
  Button,
  Chip,
  Cluster,
  Heading,
  Panel,
  Row,
  Section,
  Stack,
  Text,
  WorkspaceMain,
} from "@/components/ui";
import { compositionKindLabel } from "@/lib/catalog/compositionKinds";
import type { CompositionSearchHit } from "@/lib/catalog/universalSearch";
import { CATALOG_BACK_TO_RESULTS_CLASSES } from "@/lib/ui/viewportLayout";

import { UniversalSetActions } from "./UniversalSetActions";
import { UniversalSynergyActions } from "./UniversalSynergyActions";

function metaEntries(meta: Record<string, unknown> | undefined): Array<[string, string]> {
  if (!meta) return [];
  const out: Array<[string, string]> = [];
  for (const [k, v] of Object.entries(meta)) {
    if (v == null || v === "") continue;
    if (typeof v === "string" || typeof v === "number" || typeof v === "boolean") {
      out.push([k, String(v)]);
    } else if (Array.isArray(v) && v.every((x) => typeof x === "string")) {
      out.push([k, v.join(", ")]);
    }
  }
  return out;
}

export function UniversalHitDetail({
  hit,
  onBack,
  onSuccess,
}: {
  hit: CompositionSearchHit;
  onBack: () => void;
  onSuccess: (message: string) => void;
}) {
  const meta = metaEntries(hit.meta);

  return (
    <WorkspaceMain>
      <div className={CATALOG_BACK_TO_RESULTS_CLASSES}>
        <Button size="sm" variant="ghost" onClick={onBack}>
          ← Results
        </Button>
      </div>
      <Panel tone="raised" className="w-full">
        <Stack gap={14}>
          <Row gap={14} align="start" wrap>
            <ItemIcon icon={hit.icon} name={hit.name} size={64} />
            <Stack gap={6} className="min-w-0 flex-1">
              <Heading level={1}>{hit.name}</Heading>
              <Cluster>
                <Chip accent>{compositionKindLabel(hit.kind)}</Chip>
                {hit.owned && hit.owned.count > 0 ? (
                  <Badge tone="verified" title="Owned copies">
                    Owned ×{hit.owned.count}
                  </Badge>
                ) : null}
                {hit.hash != null ? (
                  <Text size="xs" tone="muted" as="span">
                    #{hit.hash}
                  </Text>
                ) : null}
              </Cluster>
            </Stack>
          </Row>

          {hit.description ? (
            <Section label="Description">
              <Text size="sm" className="leading-relaxed whitespace-pre-wrap">
                {hit.description}
              </Text>
            </Section>
          ) : null}

          {meta.length > 0 ? (
            <Section label="Meta">
              <Cluster gap={4}>
                {meta.map(([k, v]) => (
                  <Chip key={k}>
                    {k}: {v}
                  </Chip>
                ))}
              </Cluster>
            </Section>
          ) : null}

          {hit.actions.set ? (
            <Section label="Set">
              <UniversalSetActions hit={hit} onSuccess={onSuccess} />
            </Section>
          ) : null}

          {hit.actions.synergy ? (
            <Section label="Synergy">
              <UniversalSynergyActions hit={hit} onSuccess={onSuccess} />
            </Section>
          ) : null}

          {!hit.actions.set && !hit.actions.synergy ? (
            <Text size="sm" tone="muted">
              This entity is visible in Universal search but cannot be attached to a Set or
              Synergy from Catalog in this release.
            </Text>
          ) : null}
        </Stack>
      </Panel>
    </WorkspaceMain>
  );
}
