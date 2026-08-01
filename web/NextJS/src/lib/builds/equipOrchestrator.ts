import type { BungieWriteClient, WriteClientContext } from "@/lib/bungie/writeClient";
import type { PlannedEquipStep } from "@/lib/builds/equipPlan";

export type EquipStepResult = PlannedEquipStep & {
  ok: boolean;
  error?: string;
};

export type EquipStatus = {
  steps: EquipStepResult[];
  completed: number;
  failed: number;
};

function summarize(steps: EquipStepResult[]): EquipStatus {
  let completed = 0;
  let failed = 0;
  for (const step of steps) {
    if (step.ok) completed += 1;
    else failed += 1;
  }
  return { steps, completed, failed };
}

async function runStep(
  client: BungieWriteClient,
  ctx: WriteClientContext,
  characterId: string,
  step: PlannedEquipStep,
): Promise<EquipStepResult> {
  try {
    if (step.kind === "transfer") {
      if (!step.instanceId || step.itemHash == null || step.transferToVault == null) {
        throw new Error("Transfer step missing instanceId, itemHash, or transferToVault");
      }
      await client.transferItem(ctx, {
        itemHash: step.itemHash,
        instanceId: step.instanceId,
        characterId,
        transferToVault: step.transferToVault,
      });
    } else if (step.kind === "equip") {
      if (!step.instanceId || step.itemHash == null) {
        throw new Error("Equip step missing instanceId or itemHash");
      }
      await client.equipItem(ctx, {
        itemHash: step.itemHash,
        instanceId: step.instanceId,
        characterId,
      });
    } else if (step.kind === "artifact") {
      if (step.itemHash == null) throw new Error("Artifact step missing hash");
      await client.applyArtifactConfig(ctx, {
        characterId,
        artifactHash: step.itemHash,
        config: step.artifactConfig ?? [],
      });
    } else if (step.kind === "fashion") {
      if (step.itemHash == null || !step.slot) throw new Error("Fashion step missing slot or hash");
      await client.applyFashionSlot(ctx, {
        characterId,
        slot: step.slot,
        itemHash: step.itemHash,
        instanceId: step.instanceId,
      });
    }
    return { ...step, ok: true };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Equip step failed";
    return { ...step, ok: false, error: message };
  }
}

/** Best-effort: run plan in order; never roll back prior ok steps. */
export async function executeEquipPlan(
  client: BungieWriteClient,
  ctx: WriteClientContext,
  characterId: string,
  plan: PlannedEquipStep[],
): Promise<EquipStatus> {
  const results: EquipStepResult[] = [];
  for (const step of plan) {
    results.push(await runStep(client, ctx, characterId, step));
  }
  return summarize(results);
}
