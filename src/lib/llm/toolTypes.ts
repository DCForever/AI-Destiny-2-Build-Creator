/**
 * Contracts for the Phase A research-loop tools. Tool implementations read
 * the compact entity stores (never raw tables) and the SearXNG client;
 * the tool loop dispatches by name and enforces the call cap.
 */

import type { StoreName } from "@/lib/manifest/types/stores";

export const TOOL_NAMES = [
  "search_items",
  "get_weapon_perks",
  "get_exotic_details",
  "get_artifact_perks",
  "web_search",
] as const;

export type ToolName = (typeof TOOL_NAMES)[number];

/** JSON-schema-ish tool definition sent to the LLM `tools` parameter. */
export interface ToolDefinition {
  type: "function";
  function: {
    name: ToolName;
    description: string;
    parameters: Record<string, unknown>;
  };
}

export interface SearchItemsArgs {
  query: string;
  /** Which store to search; defaults to a sensible multi-store search. */
  category?: Extract<
    StoreName,
    "weapons" | "exotic-armor" | "exotic-weapons" | "aspects" | "fragments" | "mods"
  >;
}

export interface GetWeaponPerksArgs {
  weaponName: string;
}

export interface GetExoticDetailsArgs {
  name: string;
}

export interface GetArtifactPerksArgs {
  artifactName: string;
}

export interface WebSearchArgs {
  query: string;
}

/**
 * Every tool returns a compact, model-readable plain object. Errors and
 * misses are returned as `{ error: string }` results, never thrown, so the
 * loop keeps going and the model can adjust.
 */
export type ToolResult = Record<string, unknown>;

export interface ToolExecutor {
  execute(name: ToolName, args: Record<string, unknown>): Promise<ToolResult>;
}

/** Hard cap on Phase A tool calls (research loop). */
export const MAX_TOOL_CALLS = 8;
