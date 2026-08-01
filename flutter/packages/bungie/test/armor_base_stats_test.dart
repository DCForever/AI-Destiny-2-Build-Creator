import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

/// Golden parity with TypeScript `armorBaseStats.test.ts`.
void main() {
  const grenade = 1735777505;
  const superStat = 144602215;
  const health = 392767087;
  const melee = 4244567218;

  group('computeArmorBaseStatsFromPlugs', () {
    test('sums armor_stats plugs and ignores mods/mw/tuning', () {
      final plugs = <int, PlugStatSource>{
        1: const PlugStatSource(
          plugCategoryIdentifier: 'armor_stats',
          investmentStats: [
            PlugInvestmentStat(statTypeHash: grenade, value: 30),
          ],
        ),
        2: const PlugStatSource(
          plugCategoryIdentifier: 'armor_stats',
          investmentStats: [
            PlugInvestmentStat(statTypeHash: superStat, value: 25),
          ],
        ),
        3: const PlugStatSource(
          plugCategoryIdentifier: 'armor_stats',
          investmentStats: [
            PlugInvestmentStat(statTypeHash: health, value: 20),
          ],
        ),
        4: const PlugStatSource(
          plugCategoryIdentifier: 'enhancements.v2_general',
          investmentStats: [
            PlugInvestmentStat(statTypeHash: grenade, value: 10),
          ],
        ),
        5: const PlugStatSource(
          plugCategoryIdentifier: 'v460.plugs.armor.masterworks',
          investmentStats: [
            PlugInvestmentStat(
              statTypeHash: melee,
              value: 5,
              isConditionallyActive: true,
            ),
          ],
        ),
        6: const PlugStatSource(
          plugCategoryIdentifier:
              'core.gear_systems.armor_tiering.plugs.tuning.mods',
          investmentStats: [
            PlugInvestmentStat(statTypeHash: grenade, value: 5),
            PlugInvestmentStat(statTypeHash: 1943323491, value: -5),
          ],
        ),
      };

      expect(
        computeArmorBaseStatsFromPlugs(
          [1, 2, 3, 4, 5, 6],
          plugStatResolverFromMap(plugs),
        ),
        {
          'Health': 20,
          'Melee': 0,
          'Grenade': 30,
          'Super': 25,
          'Class': 0,
          'Weapons': 0,
        },
      );
    });

    test('returns null when no armor_stats plugs are present', () {
      expect(
        computeArmorBaseStatsFromPlugs(
          [1],
          (_) => const PlugStatSource(
            plugCategoryIdentifier: 'enhancements.v2_general',
            investmentStats: [
              PlugInvestmentStat(statTypeHash: grenade, value: 10),
            ],
          ),
        ),
        isNull,
      );
    });

    test('plugStatSourceFromItemDef reads category + investments', () {
      final src = plugStatSourceFromItemDef({
        'plug': {'plugCategoryIdentifier': 'armor_stats.v2'},
        'investmentStats': [
          {'statTypeHash': health, 'value': 12},
          {'statTypeHash': melee, 'value': 0},
        ],
      });
      expect(src, isNotNull);
      expect(src!.plugCategoryIdentifier, 'armor_stats.v2');
      expect(src.investmentStats, hasLength(2));
      expect(src.investmentStats.first.statTypeHash, health);
      expect(src.investmentStats.first.value, 12);
    });
  });
}
