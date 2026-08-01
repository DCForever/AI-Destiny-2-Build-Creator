import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { getServices } from "@/lib/services";
import type { ArtifactRecord } from "@/lib/manifest/types/records";

export type ArtifactSelection = {
  artifactHash: number | null;
  artifactName: string | null;
  artifactConfig: number[];
};

export async function resolveArtifactSelection(input: {
  artifactHash?: number | null;
  artifactName?: string | null;
  artifactConfig?: number[];
  previous?: ArtifactSelection;
}): Promise<Partial<ArtifactSelection> | null> {
  if (
    input.artifactHash === undefined &&
    input.artifactName === undefined &&
    input.artifactConfig === undefined
  ) {
    return null;
  }

  if (input.artifactHash === null) {
    return { artifactHash: null, artifactName: null, artifactConfig: [] };
  }

  const nextHash =
    input.artifactHash !== undefined ? input.artifactHash : (input.previous?.artifactHash ?? null);

  if (nextHash == null) {
    if (input.artifactConfig !== undefined || input.artifactName !== undefined) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_ITEM,
        "artifactConfig/artifactName require artifactHash",
      );
    }
    return null;
  }

  const artifact = await loadArtifact(nextHash);
  if (!artifact) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, `Unknown artifact hash ${nextHash}`);
  }

  const hashChanged =
    input.artifactHash !== undefined && input.artifactHash !== input.previous?.artifactHash;

  const config =
    input.artifactConfig !== undefined
      ? input.artifactConfig
      : hashChanged
        ? []
        : (input.previous?.artifactConfig ?? []);

  const allowed = new Set(artifact.perks.map((p) => p.hash));
  const invalid = config.filter((h) => !allowed.has(h));
  if (invalid.length) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Artifact config contains unknown perk hashes", {
      invalid,
    });
  }

  return {
    artifactHash: nextHash,
    artifactName:
      input.artifactName !== undefined && input.artifactName !== null
        ? input.artifactName
        : artifact.name,
    artifactConfig: config,
  };
}

async function loadArtifact(hash: number): Promise<ArtifactRecord | null> {
  try {
    const { entityCache } = await getServices();
    const artifacts = await entityCache.getStore("artifacts");
    return artifacts.find((a) => a.hash === hash) ?? null;
  } catch {
    return null;
  }
}
