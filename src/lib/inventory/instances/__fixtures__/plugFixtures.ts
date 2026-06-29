/** The Ringing Nail — quickstart fixture (specs/004-full-plug-resolution/quickstart.md) */
export const RINGING_NAIL_ITEM_HASH = 4206550094;

/** Previously unresolved weapon socket plugs resolved via manifest fallback */
export const ringingNailManifestPlugs = {
  1636108362: "Precision Frame",
  4248210736: "Default Shader",
  3634656993: "Synergy",
  882794620: "Reload Speed",
  2034764268: "Forge's Kin",
  905869860: "Kill Tracker",
} as const;

/** Roll perks resolved via entity stores in 003 */
export const ringingNailRollPlugs = {
  1001: "Fluted Barrel",
  2001: "High-Caliber Rounds",
  3001: "Heal Clip",
  4001: "Burning Ambition",
} as const;

export const ringingNailAllPlugHashes = [
  ...Object.keys(ringingNailManifestPlugs).map(Number),
  ...Object.keys(ringingNailRollPlugs).map(Number),
];

/** Armor mod + masterwork hashes for US2 validation */
export const armorManifestPlugs = {
  6001: "Harmonic Resonance",
  6002: "Recovery Mod",
  882794621: "Intellect Masterwork",
} as const;

export function buildHybridPlugMap(
  entityEntries: Record<number, string>,
  manifestEntries: Record<number, string>,
): Map<number, string> {
  const map = new Map<number, string>();
  for (const [hash, name] of Object.entries(entityEntries)) {
    map.set(Number(hash), name);
  }
  for (const [hash, name] of Object.entries(manifestEntries)) {
    const n = Number(hash);
    if (!map.has(n)) map.set(n, name);
  }
  return map;
}

export const ringingNailHybridPlugMap = buildHybridPlugMap(
  ringingNailRollPlugs,
  ringingNailManifestPlugs,
);

export const armorHybridPlugMap = buildHybridPlugMap(
  { 5001: "Solar Mod" },
  armorManifestPlugs,
);
