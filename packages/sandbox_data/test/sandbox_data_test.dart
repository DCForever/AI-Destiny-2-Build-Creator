import 'package:destiny2_sandbox_data/destiny2_sandbox_data.dart';
import 'package:test/test.dart';

void main() {
  group('computeBenefitsAt', () {
    test('interpolates enhanced benefits linearly from 101 to 200', () {
      final at200 = computeBenefitsAt(ArmorStatName.melee, 200);
      expect(at200, contains('+30% melee ability damage'));

      final at150 = computeBenefitsAt(ArmorStatName.grenade, 150);
      expect(at150, contains('+33% grenade ability damage'));

      final at120 = computeBenefitsAt(ArmorStatName.classStat, 120);
      expect(
        at120,
        contains('8 HP overshield on casting your class ability (PvE)'),
      );
    });

    test('omits enhanced benefits at or below 100', () {
      final at100 = computeBenefitsAt(ArmorStatName.superStat, 100);
      expect(at100.join(' '), isNot(contains('Super ability damage')));

      final at60 = computeBenefitsAt(ArmorStatName.grenade, 60);
      expect(at60.join(' '), isNot(contains('grenade ability damage')));
    });

    test('scales base benefits across 0-100', () {
      final at50 = computeBenefitsAt(ArmorStatName.health, 50);
      expect(
        at50,
        contains('+35 HP healing when picking up an Orb of Power'),
      );
      expect(at50, contains('+5% flinch resistance'));
    });

    test('includes weapons boss-damage split at 200', () {
      final at200 = computeBenefitsAt(ArmorStatName.weapons, 200);
      expect(
        at200,
        contains('+15% damage vs bosses (primary and special, PvE)'),
      );
      expect(at200, contains('+10% damage vs bosses (heavy, PvE)'));
      expect(at200, contains('+6% weapon damage vs Guardians (PvP)'));
    });
  });

  group('synergy verbs', () {
    test('maps Ionic Trace and other Arc verbs to Arc', () {
      expect(impliedElementForVerb('Ionic Trace'), 'Arc');
      expect(impliedElementForVerb('Jolt'), 'Arc');
      expect(impliedElementForVerb('Bolt Charge'), 'Arc');
    });

    test('maps Solar / Void / Stasis / Strand verbs', () {
      expect(impliedElementForVerb('Scorch'), 'Solar');
      expect(impliedElementForVerb('Volatile'), 'Void');
      expect(impliedElementForVerb('Freeze'), 'Stasis');
      expect(impliedElementForVerb('Sever'), 'Strand');
    });

    test('accepts aliases and plurals', () {
      expect(impliedElementForVerb('Suppress'), 'Void');
      expect(impliedElementForVerb('Stasis Shards'), 'Stasis');
      expect(impliedElementForVerb('Arc Ionic Traces'), 'Arc');
    });

    test('returns null for agnostic keywords', () {
      expect(impliedElementForVerb('Armor Charge'), isNull);
      expect(impliedElementForVerb('Exhaust'), isNull);
      expect(impliedElementForVerb('Sliding'), isNull);
    });

    test('every curated verb has defined element field and resolves', () {
      for (final v in synergyVerbs) {
        if (v.element != null) {
          expect(impliedElementForVerb(v.name), v.element);
        } else {
          expect(impliedElementForVerb(v.name), isNull);
        }
        expect(resolveVerbSubType(v.name), v.name);
      }
    });
  });

  group('lookupExoticAbilityRequirements', () {
    test('returns null for unknown exotic', () {
      expect(
        lookupExoticAbilityRequirements(name: 'Not A Real Exotic'),
        isNull,
      );
    });

    test('finds curated rows by hash when present', () {
      final withHash = exoticAbilityRequirements.where((r) => r.hash != null);
      if (withHash.isEmpty) {
        expect(true, isTrue);
        return;
      }
      final hit = lookupExoticAbilityRequirements(hash: withHash.first.hash);
      expect(hit, isNotNull);
    });

    test('hasAbilityRequirements', () {
      expect(hasAbilityRequirements(null), isFalse);
      expect(hasAbilityRequirements(const AbilityRequirementFields()), isFalse);
      expect(
        hasAbilityRequirements(
          const AbilityRequirementFields(superAbility: 'X'),
        ),
        isTrue,
      );
    });
  });

  group('getChampionCounterForFrame', () {
    test('maps base weapon-type families', () {
      expect(
        getChampionCounterForFrame('Adaptive Frame', 'Scout Rifle'),
        ChampionType.barrier,
      );
      expect(
        getChampionCounterForFrame('Aggressive Frame', 'Shotgun'),
        ChampionType.unstoppable,
      );
      expect(
        getChampionCounterForFrame('Lightweight Frame', 'Bow'),
        ChampionType.overload,
      );
      expect(
        getChampionCounterForFrame('High-Impact Frame', 'Pulse Rifle'),
        ChampionType.unstoppable,
      );
      expect(
        getChampionCounterForFrame('Rapid-Fire Frame', 'Sniper Rifle'),
        ChampionType.overload,
      );
      expect(
        getChampionCounterForFrame('Precision Frame', 'Hand Cannon'),
        ChampionType.barrier,
      );
    });

    test('applies frame-specific overrides before the base map', () {
      expect(
        getChampionCounterForFrame('Wave Frame', 'Grenade Launcher'),
        ChampionType.unstoppable,
      );
      expect(
        getChampionCounterForFrame('Caster Frame', 'Sword'),
        ChampionType.barrier,
      );
      expect(
        getChampionCounterForFrame('Support Frame', 'Auto Rifle'),
        ChampionType.overload,
      );
      expect(
        getChampionCounterForFrame('Adaptive Burst', 'Linear Fusion Rifle'),
        ChampionType.barrier,
      );
      expect(
        getChampionCounterForFrame('Heavy Burst', 'Hand Cannon'),
        ChampionType.unstoppable,
      );
      expect(
        getChampionCounterForFrame('Spread Shot Frame', 'Hand Cannon'),
        ChampionType.overload,
      );
    });

    test('returns null for unknown frames and blank input', () {
      expect(
        getChampionCounterForFrame('Märchen Frame', 'Auto Rifle'),
        isNull,
      );
      expect(getChampionCounterForFrame('', 'Auto Rifle'), isNull);
    });

    test('encodes the 9.7.0 verb corrections', () {
      expect(subclassVerbCounters['shatter'], ChampionType.unstoppable);
      expect(subclassVerbCounters['jolt'], ChampionType.overload);
      expect(subclassVerbCounters.containsKey('radiant'), isFalse);
      expect(subclassVerbCounters.containsKey('volatile rounds'), isFalse);
      expect(championDamageBuffsPercent['radiant'], 10);
    });
  });

  group('armor archetypes', () {
    test('has all 12 archetypes, six of them new in 9.7.0', () {
      expect(armorArchetypes, hasLength(12));
      expect(armorArchetypes.where((a) => a.addedIn970), hasLength(6));
    });

    test('finds archetypes by name case-insensitively', () {
      expect(findArchetypeByName('powerhouse')?.primary, ArmorStatName.weapons);
      expect(findArchetypeByName('Nonexistent'), isNull);
      expect(findArchetypeByName(' '), isNull);
    });

    test('finds archetypes serving a stat', () {
      final grenadeOptions =
          findArchetypesForStat(ArmorStatName.grenade).map((a) => a.name);
      expect(
        grenadeOptions,
        containsAll([
          'Grenadier',
          'Gunner',
          'Siegebreaker',
          'Demolitionist',
        ]),
      );
    });
  });

  group('isArtifactAllowed', () {
    test('disables artifacts in Trials and Competitive only', () {
      expect(isArtifactAllowed('Trials of Osiris'), isFalse);
      expect(isArtifactAllowed('competitive crucible'), isFalse);
      expect(isArtifactAllowed('Grandmaster Nightfall'), isTrue);
      expect(isArtifactAllowed('Raid: The Desert Perpetual'), isTrue);
    });
  });

  group('abilityTimings', () {
    test('parses cooldown and duration from manifest text', () {
      final timing = parseAbilityTiming(
        '15 second cooldown. 8s duration while active.',
      );
      expect(formatAbilityTiming(timing), '15s cooldown · 8s duration');
    });

    test('falls back to table when description lacks timing', () {
      final timing =
          parseAbilityTiming('Call lightning down on foes.', 'Stormtrance');
      expect(formatAbilityTiming(timing), contains('300s cooldown'));
    });
  });

  group('weapon types and concept tags', () {
    test('filters and toggles known weapon types', () {
      expect(isKnownWeaponType('Hand Cannon'), isTrue);
      expect(isKnownWeaponType('Not A Gun'), isFalse);
      expect(
        filterKnownWeaponTypes([' Hand Cannon ', 'Bow', 'Bow', 'Nope']),
        ['Hand Cannon', 'Bow'],
      );
      expect(
        toggleWeaponType(['Bow'], 'Hand Cannon'),
        ['Bow', 'Hand Cannon'],
      );
      expect(toggleWeaponType(['Bow', 'Hand Cannon'], 'Bow'), ['Hand Cannon']);
    });

    test('concept tag vocabulary', () {
      expect(isConceptTagId('pve'), isTrue);
      expect(isConceptTagId('nope'), isFalse);
      expect(getConceptTagLabel('crowd_control'), 'Crowd Control');
      expect(getConceptTag('solar')?.facet, 'element');
    });
  });

  group('subclasses', () {
    test('lists six subclasses per class including Prismatic', () {
      expect(subclassesFor(GuardianClass.titan), hasLength(6));
      expect(subclassesFor(GuardianClass.hunter), contains('Gunslinger'));
      expect(
        subclassesFor(GuardianClass.warlock),
        contains('Prismatic Warlock'),
      );
    });
  });
}
