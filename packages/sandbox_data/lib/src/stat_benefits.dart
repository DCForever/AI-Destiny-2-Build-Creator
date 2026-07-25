import 'armor_stat_name.dart';

/// Armor 3.0 stat benefit curves (0–200 scale), transcribed from Bungie's
/// Armor 3.0 documentation and the 9.7.0 patch notes. Port of
/// `src/data/rules/statBenefits.ts`.

const int statMax = 200;
const int enhancedThreshold = 100;

/// Template with `{v}` placeholder and max value at range end.
class ScalingBenefit {
  const ScalingBenefit({
    required this.template,
    required this.max,
    this.precision = 0,
  });

  /// e.g. "+{v}% grenade ability damage".
  final String template;

  /// Value reached at stat 100 (base) or 200 (enhanced).
  final num max;

  /// Decimal places when rendering the interpolated value.
  final int precision;
}

class StatBenefitDefinition {
  const StatBenefitDefinition({
    required this.stat,
    this.baseEffects = const [],
    this.baseScaling = const [],
    this.enhancedScaling = const [],
    this.enhancedNotes = const [],
  });

  final ArmorStatName stat;
  final List<String> baseEffects;
  final List<ScalingBenefit> baseScaling;
  final List<ScalingBenefit> enhancedScaling;
  final List<String> enhancedNotes;
}

final Map<ArmorStatName, StatBenefitDefinition> statBenefits = {
  ArmorStatName.health: const StatBenefitDefinition(
    stat: ArmorStatName.health,
    baseScaling: [
      ScalingBenefit(
        template: '+{v} HP healing when picking up an Orb of Power',
        max: 70,
      ),
      ScalingBenefit(template: '+{v}% flinch resistance', max: 10),
    ],
    enhancedScaling: [
      ScalingBenefit(template: '+{v} shield capacity vs combatants', max: 20),
      ScalingBenefit(template: 'shields start recharging {v}% sooner', max: 25),
      ScalingBenefit(
        template: '{v}% less time to fully recharge shields',
        max: 50,
      ),
    ],
  ),
  ArmorStatName.melee: const StatBenefitDefinition(
    stat: ArmorStatName.melee,
    baseEffects: [
      'Improves melee ability base cooldown',
      'Improves melee energy gained from external sources and regen scalars',
    ],
    enhancedScaling: [
      ScalingBenefit(template: '+{v}% melee ability damage', max: 30),
    ],
    enhancedNotes: ['Applies to powered, unpowered, and glaive melees'],
  ),
  ArmorStatName.grenade: const StatBenefitDefinition(
    stat: ArmorStatName.grenade,
    baseEffects: [
      'Improves grenade ability base cooldown',
      'Improves grenade energy gained from external sources and regen scalars',
    ],
    enhancedScaling: [
      ScalingBenefit(template: '+{v}% grenade ability damage', max: 65),
    ],
  ),
  ArmorStatName.superStat: const StatBenefitDefinition(
    stat: ArmorStatName.superStat,
    baseEffects: [
      'Improves Super energy gained from damaging targets (base cooldown unchanged)',
      'Improves Super energy gained from external sources and regen scalars',
    ],
    enhancedScaling: [
      ScalingBenefit(template: '+{v}% Super ability damage', max: 45),
    ],
  ),
  ArmorStatName.classStat: const StatBenefitDefinition(
    stat: ArmorStatName.classStat,
    baseEffects: [
      'Improves class ability base cooldown',
      'Improves class energy gained from external sources and regen scalars',
    ],
    enhancedScaling: [
      ScalingBenefit(
        template: '{v} HP overshield on casting your class ability (PvE)',
        max: 40,
      ),
      ScalingBenefit(template: '{v} HP overshield on cast in PvP', max: 10),
    ],
    enhancedNotes: [
      "Overshield duration is tied to the ability's cooldown length",
    ],
  ),
  ArmorStatName.weapons: const StatBenefitDefinition(
    stat: ArmorStatName.weapons,
    baseEffects: ['Improves weapon reload and handling speeds'],
    baseScaling: [
      ScalingBenefit(
        template:
            '+{v}% damage vs minor and major combatants (primary and special)',
        max: 15,
      ),
      ScalingBenefit(
        template: '+{v}% damage vs minor and major combatants (heavy)',
        max: 10,
      ),
    ],
    enhancedScaling: [
      ScalingBenefit(
        template: '+{v}% damage vs bosses (primary and special, PvE)',
        max: 15,
      ),
      ScalingBenefit(
        template: '+{v}% damage vs bosses (heavy, PvE)',
        max: 10,
      ),
      ScalingBenefit(
        template: '+{v}% weapon damage vs Guardians (PvP)',
        max: 6,
      ),
    ],
    enhancedNotes: [
      'Ammo bricks have a chance to contain more ammo than normal',
    ],
  ),
};

/// 9.7.0: damaging class abilities that additionally scale with Class above 100.
const List<String> classStatScalingAbilities = [
  'Shieldburst',
  'Ascension',
  "Threaded Specter",
  "Drengr's Lash",
];

const List<String> abilityEconomyNotes = [
  'Max passive ability-cooldown bonus from stats reduced by ~20% (9.7.0)',
  'Max active ability-cooldown bonus reduced from 190% to 125% (9.7.0)',
  'Super energy from boss damage reduced by 60% (9.7.0)',
  'Grenade/Melee stat boss-damage bonuses are additive, not multiplicative (9.7.0)',
];

double _interpolate(num value, num rangeStart, num max) {
  final clamped = (value - rangeStart).clamp(0, 100);
  return (clamped / 100) * max;
}

String _renderBenefit(ScalingBenefit benefit, num amount) {
  final rendered = amount.toStringAsFixed(benefit.precision);
  return benefit.template.replaceAll('{v}', rendered);
}

/// Human-readable benefit lines for a stat at [value] (0–200 scale).
/// Enhanced benefits are omitted at or below [enhancedThreshold].
List<String> computeBenefitsAt(ArmorStatName stat, num value) {
  final definition = statBenefits[stat]!;
  final lines = <String>[...definition.baseEffects];
  for (final benefit in definition.baseScaling) {
    lines.add(
      _renderBenefit(benefit, _interpolate(value, 0, benefit.max)),
    );
  }
  if (value <= enhancedThreshold) return lines;
  for (final benefit in definition.enhancedScaling) {
    lines.add(
      _renderBenefit(benefit, _interpolate(value, 100, benefit.max)),
    );
  }
  lines.addAll(definition.enhancedNotes);
  return lines;
}
