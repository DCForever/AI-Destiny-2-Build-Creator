import type { ToolDefinition, ToolName } from "./toolTypes";

function toolDef(
  name: ToolName,
  description: string,
  properties: Record<string, unknown>,
  required: string[],
): ToolDefinition {
  return {
    type: "function",
    function: { name, description, parameters: { type: "object", properties, required } },
  };
}

/** Static tool schemas — safe to import from client components (no Node/fs deps). */
export function buildToolDefinitions(): ToolDefinition[] {
  return [
    toolDef("search_items", "Fuzzy-search Destiny items by name.", {
      query: { type: "string", description: "Item name or fragment" },
      category: {
        type: "string",
        enum: ["weapons", "exotic-armor", "exotic-weapons", "aspects", "fragments", "mods"],
        description: "Optional store; default searches armor and weapons",
      },
      slot: {
        type: "string",
        enum: ["Kinetic", "Energy", "Power"],
        description: "Optional slot filter when searching weapons",
      },
    }, ["query"]),
    toolDef("get_weapon_perks", "Legendary perk columns or exotic intrinsics for a weapon.", {
      weaponName: { type: "string", description: "Weapon name" },
    }, ["weaponName"]),
    toolDef("search_weapon_perks", "Search the weapon perk catalog; returns column metadata per perk.", {
      query: { type: "string", description: "Perk name fragment" },
      limit: { type: "number", description: "Max matches (default 5)" },
    }, ["query"]),
    toolDef("find_weapons_with_perk", "Find weapons that can roll a perk in a required slot.", {
      perkName: { type: "string", description: "Exact or fuzzy perk name" },
      slot: {
        type: "string",
        enum: ["Kinetic", "Energy", "Power"],
        description: "Required weapon slot",
      },
      itemTypeName: { type: "string", description: "Optional weapon type filter (e.g. Hand Cannon)" },
      ownedOnly: { type: "boolean", description: "When true, return only weapons the user owns with this perk" },
    }, ["perkName", "slot"]),
    toolDef("get_exotic_details", "Exotic armor or weapon intrinsic and slot details.", {
      name: { type: "string", description: "Exotic name" },
    }, ["name"]),
    toolDef("get_artifact_perks", "Perks for a permanent Artifacts 2.0 artifact.", {
      artifactName: { type: "string", description: "Artifact name" },
    }, ["artifactName"]),
    toolDef("web_search", "Web search for current meta; prefer manifest tools first.", {
      query: { type: "string", description: "Search query" },
    }, ["query"]),
  ];
}
