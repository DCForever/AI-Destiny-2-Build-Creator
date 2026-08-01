// Fallback cooldown/duration hints for subclass abilities.
// Port of `src/data/rules/abilityTimings.ts`.

class AbilityTiming {
  const AbilityTiming({
    this.cooldownSeconds,
    this.durationSeconds,
    this.charges,
  });

  final num? cooldownSeconds;
  final num? durationSeconds;
  final int? charges;

  bool get isEmpty =>
      cooldownSeconds == null && durationSeconds == null && charges == null;
}

// Normalized ability display name → timing fallback.
const Map<String, AbilityTiming> abilityTimingFallbacks = {
  'Stormtrance': AbilityTiming(cooldownSeconds: 300, durationSeconds: 22),
  'Healing Rift': AbilityTiming(cooldownSeconds: 38, durationSeconds: 12),
  'Burst Glide': AbilityTiming(cooldownSeconds: 4),
  'Ball Lightning': AbilityTiming(cooldownSeconds: 32),
  'Shackle Grenade': AbilityTiming(cooldownSeconds: 105),
  'Hammer of Sol': AbilityTiming(cooldownSeconds: 300, durationSeconds: 20),
  'Sentinel Shield': AbilityTiming(cooldownSeconds: 300, durationSeconds: 15),
  'Glacial Quake': AbilityTiming(cooldownSeconds: 300, durationSeconds: 10),
  'Fist of Havoc': AbilityTiming(cooldownSeconds: 300),
  'Blade Barrage': AbilityTiming(cooldownSeconds: 300),
  'Golden Gun': AbilityTiming(cooldownSeconds: 300, charges: 2),
  'Arc Staff': AbilityTiming(cooldownSeconds: 300, durationSeconds: 25),
  'Silence and Squall':
      AbilityTiming(cooldownSeconds: 300, durationSeconds: 18),
  'Shadowshot': AbilityTiming(cooldownSeconds: 300),
  'Silkstrike': AbilityTiming(cooldownSeconds: 300, durationSeconds: 20),
  'Daybreak': AbilityTiming(cooldownSeconds: 300, durationSeconds: 25),
  'Chaos Reach': AbilityTiming(cooldownSeconds: 300, durationSeconds: 5),
  "Winter's Wrath": AbilityTiming(cooldownSeconds: 300, durationSeconds: 10),
  'Nova Bomb': AbilityTiming(cooldownSeconds: 300),
  'Needlestorm': AbilityTiming(cooldownSeconds: 300, durationSeconds: 18),
};

final _cooldownPattern =
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:s|sec(?:ond)?s?)\s+cooldown', caseSensitive: false);
final _durationPattern =
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:s|sec(?:ond)?s?)\s+duration', caseSensitive: false);
final _chargePattern = RegExp(r'(\d+)\s+charge', caseSensitive: false);

AbilityTiming parseAbilityTiming(String description, [String? abilityName]) {
  num? cooldown;
  num? duration;
  int? charges;

  final cooldownMatch = _cooldownPattern.firstMatch(description);
  final durationMatch = _durationPattern.firstMatch(description);
  final chargeMatch = _chargePattern.firstMatch(description);
  if (cooldownMatch != null) {
    cooldown = num.parse(cooldownMatch.group(1)!);
  }
  if (durationMatch != null) {
    duration = num.parse(durationMatch.group(1)!);
  }
  if (chargeMatch != null) {
    charges = int.parse(chargeMatch.group(1)!);
  }

  final parsedEmpty = cooldown == null && duration == null && charges == null;
  if (abilityName != null && parsedEmpty) {
    return abilityTimingFallbacks[abilityName] ?? const AbilityTiming();
  }
  if (abilityName != null) {
    final fallback = abilityTimingFallbacks[abilityName];
    return AbilityTiming(
      cooldownSeconds: cooldown ?? fallback?.cooldownSeconds,
      durationSeconds: duration ?? fallback?.durationSeconds,
      charges: charges ?? fallback?.charges,
    );
  }
  return AbilityTiming(
    cooldownSeconds: cooldown,
    durationSeconds: duration,
    charges: charges,
  );
}

String? formatAbilityTiming(AbilityTiming timing) {
  final parts = <String>[];
  if (timing.cooldownSeconds != null) {
    parts.add('${timing.cooldownSeconds}s cooldown');
  }
  if (timing.durationSeconds != null) {
    parts.add('${timing.durationSeconds}s duration');
  }
  if (timing.charges != null) {
    parts.add('${timing.charges} charges');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
