/**
 * Server-side composition root. Lazily builds the service graph bound to the
 * manifest version currently on disk, and rebuilds it after a manifest
 * refresh. All API routes get their dependencies from here.
 */

import { resolveBuild } from "@/lib/build/resolveBuild";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import { buildLoParams, renderLoParamsText } from "@/lib/dim/loParams";
import { buildWishlist } from "@/lib/dim/wishlist";
import { analyzeLoadout } from "@/lib/llm/analyzeLoadout";
import type { AnalyzeRequest, LoadoutAnalysis } from "@/lib/llm/analyzeSchema";
import type { BuildRequest, GeneratedBuild } from "@/lib/llm/buildSchema";
import { generateBuild } from "@/lib/llm/generateBuild";
import { createOllamaClient, type OllamaClient } from "@/lib/llm/ollamaClient";
import { createToolExecutor } from "@/lib/llm/tools";
import { createEntityCache } from "@/lib/manifest/entityCache";
import { createItemResolver } from "@/lib/manifest/itemResolver";
import { createManifestService } from "@/lib/manifest/manifestService";
import { createPerkValidator } from "@/lib/manifest/perkValidator";
import type {
  EntityCache,
  ItemResolver,
  ManifestService,
  ManifestStatus,
  PerkValidator,
} from "@/lib/manifest/types/services";
import { createSearxngClient, type SearxngClient } from "@/lib/search/searxng";

export interface Services {
  manifest: ManifestService;
  entityCache: EntityCache;
  resolver: ItemResolver;
  validator: PerkValidator;
  ollama: OllamaClient;
  searxng: SearxngClient;
}

let services: Services | null = null;
let boundVersion: string | null = null;

function buildServices(manifest: ManifestService, version: string | null): Services {
  const entityCache = createEntityCache({
    version,
    loadRawTable: (table) => {
      if (!version) {
        return Promise.reject(
          new Error("No manifest on disk. Refresh the manifest from Settings first."),
        );
      }
      return manifest.loadRawTable(version, table);
    },
  });
  return {
    manifest,
    entityCache,
    resolver: createItemResolver(entityCache),
    validator: createPerkValidator(entityCache),
    ollama: createOllamaClient(),
    searxng: createSearxngClient(),
  };
}

/** Returns the service graph, rebuilding it if the cached version changed. */
export async function getServices(): Promise<Services> {
  const manifest = services?.manifest ?? createManifestService();
  const status = await manifest.getStatus();
  if (!services || boundVersion !== status.cachedVersion) {
    services = buildServices(manifest, status.cachedVersion);
    boundVersion = status.cachedVersion;
  }
  return services;
}

export async function getManifestStatus(): Promise<ManifestStatus> {
  const { manifest } = await getServices();
  return manifest.getStatus();
}

/** Downloads the latest manifest tables and rebuilds the entity stores. */
export async function refreshManifest(): Promise<ManifestStatus> {
  const { manifest } = await getServices();
  const version = await manifest.ensureCurrent();
  const fresh = buildServices(manifest, version);
  await fresh.entityCache.rebuild(version);
  services = fresh;
  boundVersion = version;
  return manifest.getStatus();
}

export interface BuildExports {
  wishlistText: string;
  loParamsText: string;
  skipped: string[];
}

export interface BuildGenerationOutcome {
  build: GeneratedBuild;
  sheet: ResolvedBuildSheet;
  toolCallCount: number;
  researchSummary: string;
  exports: BuildExports;
}

function renderExports(sheet: ResolvedBuildSheet): BuildExports {
  const wishlist = buildWishlist(sheet);
  return {
    wishlistText: wishlist.text,
    loParamsText: renderLoParamsText(buildLoParams(sheet)),
    skipped: wishlist.skipped,
  };
}

/** Full pipeline: research loop -> composition -> manifest resolution. */
export async function runBuildGeneration(
  request: BuildRequest,
): Promise<BuildGenerationOutcome> {
  const { entityCache, resolver, validator, ollama, searxng } = await getServices();
  const meta = await entityCache.getMeta();
  if (!meta) {
    throw new ManifestNotReadyError();
  }

  const executor = createToolExecutor({ resolver, cache: entityCache, searcher: searxng });
  const generated = await generateBuild(request, { client: ollama, executor });
  const sheet = await resolveBuild(generated.build, request.activity, {
    resolver,
    validator,
    cache: entityCache,
  });
  return {
    build: generated.build,
    sheet,
    toolCallCount: generated.toolCallCount,
    researchSummary: generated.researchSummary,
    exports: renderExports(sheet),
  };
}

export interface LoadoutAnalysisOutcome {
  analysis: LoadoutAnalysis;
  /** The optimized build resolved against the manifest, same as the generator. */
  sheet: ResolvedBuildSheet;
  toolCallCount: number;
  researchSummary: string;
  exports: BuildExports;
}

/** Analyzer pipeline: research loop -> composition -> manifest resolution. */
export async function runLoadoutAnalysis(
  request: AnalyzeRequest,
): Promise<LoadoutAnalysisOutcome> {
  const { entityCache, resolver, validator, ollama, searxng } = await getServices();
  const meta = await entityCache.getMeta();
  if (!meta) {
    throw new ManifestNotReadyError();
  }

  const executor = createToolExecutor({ resolver, cache: entityCache, searcher: searxng });
  const result = await analyzeLoadout(request, { client: ollama, executor });
  const sheet = await resolveBuild(result.analysis.optimizedBuild, request.activity, {
    resolver,
    validator,
    cache: entityCache,
  });
  return {
    analysis: result.analysis,
    sheet,
    toolCallCount: result.toolCallCount,
    researchSummary: result.researchSummary,
    exports: renderExports(sheet),
  };
}

export class ManifestNotReadyError extends Error {
  constructor() {
    super(
      "Manifest entity stores are not built yet. Open Settings and refresh the manifest first.",
    );
    this.name = "ManifestNotReadyError";
  }
}
