// Anti-Champion 2.0 rule tables (Update 9.7.0).
// Port of `src/data/rules/championCounters.ts`.

enum ChampionType {
  barrier('Barrier'),
  overload('Overload'),
  unstoppable('Unstoppable');

  const ChampionType(this.wireName);
  final String wireName;
}

// Base mapping by weapon-type family (patch notes table 1).
const Map<String, ChampionType> baseFrameCounters = {
  'aggressive': ChampionType.unstoppable,
  'high-impact': ChampionType.unstoppable,
  'precision': ChampionType.barrier,
  'adaptive': ChampionType.barrier,
  'lightweight': ChampionType.overload,
  'rapid-fire': ChampionType.overload,
};

class FrameOverrideRule {
  const FrameOverrideRule({
    required this.frame,
    this.weaponType,
    required this.counters,
  });

  /// Normalized frame-name prefix as it appears in the manifest intrinsic.
  final String frame;

  /// Manifest weapon type display name; null = any weapon type.
  final String? weaponType;
  final ChampionType counters;
}

// Frame-specific overrides (patch notes table 2), checked before the base map.
const List<FrameOverrideRule> frameOverrides = [
  FrameOverrideRule(
    frame: 'support',
    weaponType: 'Auto Rifle',
    counters: ChampionType.overload,
  ),
  FrameOverrideRule(
    frame: 'adaptive burst',
    weaponType: 'Linear Fusion Rifle',
    counters: ChampionType.barrier,
  ),
  FrameOverrideRule(
    frame: 'area denial',
    weaponType: 'Grenade Launcher',
    counters: ChampionType.overload,
  ),
  FrameOverrideRule(
    frame: 'double fire',
    weaponType: 'Grenade Launcher',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'micro-missile',
    weaponType: 'Grenade Launcher',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'wave',
    weaponType: 'Grenade Launcher',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'compressed wave',
    weaponType: 'Grenade Launcher',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'heavy burst',
    weaponType: 'Hand Cannon',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'spread shot',
    weaponType: 'Hand Cannon',
    counters: ChampionType.overload,
  ),
  FrameOverrideRule(
    frame: 'aggressive burst',
    weaponType: 'Submachine Gun',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'aggressive burst',
    weaponType: 'Pulse Rifle',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'heavy burst',
    weaponType: 'Pulse Rifle',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'legacy pr-55',
    weaponType: 'Pulse Rifle',
    counters: ChampionType.barrier,
  ),
  FrameOverrideRule(
    frame: 'rocket-assisted',
    weaponType: 'Pulse Rifle',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'rocket-assisted',
    weaponType: 'Sidearm',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(
    frame: 'disruption',
    weaponType: 'Sniper Rifle',
    counters: ChampionType.barrier,
  ),
  FrameOverrideRule(
    frame: 'caster',
    weaponType: 'Sword',
    counters: ChampionType.barrier,
  ),
  FrameOverrideRule(
    frame: 'vortex',
    weaponType: 'Sword',
    counters: ChampionType.overload,
  ),
  FrameOverrideRule(
    frame: 'wave',
    weaponType: 'Sword',
    counters: ChampionType.unstoppable,
  ),
  FrameOverrideRule(frame: 'dynamic heat', counters: ChampionType.overload),
  FrameOverrideRule(frame: 'balanced heat', counters: ChampionType.overload),
];

// Subclass-verb champion counters on the 9.7.0 baseline.
const Map<String, ChampionType> subclassVerbCounters = {
  'blind': ChampionType.unstoppable,
  'suspend': ChampionType.unstoppable,
  'ignition': ChampionType.unstoppable,
  'shatter': ChampionType.unstoppable,
  'jolt': ChampionType.overload,
  'suppression': ChampionType.overload,
  'slow': ChampionType.overload,
};

// Status effects that buff champion damage instead of stunning (9.7.0).
const Map<String, int> championDamageBuffsPercent = {
  'radiant': 10,
  'volatile rounds': 10,
};

String _normalizeFrameName(String frame) {
  return frame
      .toLowerCase()
      .replaceFirst(RegExp(r'\s+frame\s*$'), '')
      .trim();
}

ChampionType? _matchOverride(String normalizedFrame, String weaponType) {
  for (final rule in frameOverrides) {
    final frameMatches = normalizedFrame.startsWith(rule.frame);
    final typeMatches =
        rule.weaponType == null || rule.weaponType == weaponType;
    if (frameMatches && typeMatches) return rule.counters;
  }
  return null;
}

// Resolves a weapon's intrinsic champion counter from frame + weapon type.
ChampionType? getChampionCounterForFrame(
  String frameName,
  String weaponTypeName,
) {
  if (frameName.isEmpty) return null;
  final normalized = _normalizeFrameName(frameName);
  final override = _matchOverride(normalized, weaponTypeName);
  if (override != null) return override;
  for (final family in baseFrameCounters.keys) {
    if (normalized.startsWith(family)) {
      return baseFrameCounters[family];
    }
  }
  return null;
}
