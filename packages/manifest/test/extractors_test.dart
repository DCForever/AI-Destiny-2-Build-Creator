import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

import 'fixtures/raw_tables.dart';

void main() {
  group('exoticArmorExtractor', () {
    test('projects Celestial Nighthawk', () async {
      final records = await ExoticArmorExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(1));
      final rec = records.single as ExoticArmorRecord;
      expect(rec.hash, 1001);
      expect(rec.name, 'Celestial Nighthawk');
      expect(rec.searchName, 'celestial nighthawk');
      expect(rec.classType, DestinyClassName.hunter);
      expect(rec.slot, ArmorSlotName.helmet);
      expect(rec.icon, '/nighthawk.png');
      expect(rec.intrinsic.name, 'Hawkeye Hack');
      expect(rec.intrinsic.description, contains('Golden Gun'));
      expect(rec.archetype, 'Celestial Archetype');
    });
  });

  group('weaponsExtractor', () {
    test('projects Chattering Bone with perk columns', () async {
      final records = await WeaponsExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(1));
      final rec = records.single as WeaponRecord;
      expect(rec.hash, 1007);
      expect(rec.name, 'Chattering Bone');
      expect(rec.slot, WeaponSlotName.kinetic);
      expect(rec.element, ElementName.stasis);
      expect(rec.ammo, AmmoTypeName.primary);
      expect(rec.frame, 'Precision Frame');
      expect(rec.itemTypeName, 'Pulse Rifle');
      expect(rec.perkColumns, isNotEmpty);
      final allPerks = [
        for (final c in rec.perkColumns) ...c.curated,
        for (final c in rec.perkColumns) ...c.randomized,
      ];
      expect(allPerks, contains(1012)); // Kill Clip
    });
  });

  group('exoticWeaponsExtractor', () {
    test('projects Gjallarhorn (GAP-UI-CATALOG-04)', () async {
      final records = await ExoticWeaponsExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(1));
      final rec = records.single as ExoticWeaponRecord;
      expect(rec.hash, 1004);
      expect(rec.name, 'Gjallarhorn');
      expect(rec.slot, WeaponSlotName.power);
      expect(rec.element, ElementName.solar);
      expect(rec.ammo, AmmoTypeName.heavy);
      expect(rec.frame, 'Wolfpack Rounds');
      expect(rec.intrinsic.name, 'Wolfpack Rounds');
      expect(rec.catalyst?.name, 'Gjallarhorn Catalyst');
      expect(rec.itemTypeName, 'Rocket Launcher');
    });
  });

  group('legendaryArmorExtractor', () {
    test('projects Arms of Optimacy (GAP-UI-CATALOG-05)', () async {
      final records =
          await LegendaryArmorExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(1));
      final rec = records.single as LegendaryArmorRecord;
      expect(rec.hash, 1090);
      expect(rec.name, 'Arms of Optimacy');
      expect(rec.classType, DestinyClassName.titan);
      expect(rec.slot, ArmorSlotName.gauntlets);
      expect(rec.archetype, 'Brawler');
    });
  });

  group('aspectsExtractor', () {
    test('extracts fragment capacities', () async {
      final records = await AspectsExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(2));
      final byName = {
        for (final r in records.cast<AspectRecord>()) r.name: r,
      };
      expect(byName['Touch of Thunder']!.fragmentCapacity, 4);
      expect(byName['Consecration']!.fragmentCapacity, 2);
    });
  });

  group('fragmentsExtractor', () {
    test('extracts two fragments', () async {
      final records = await FragmentsExtractor().extract(loadFixtureRawTable);
      expect(records, hasLength(2));
      final echo = records.cast<FragmentRecord>().firstWhere(
            (r) => r.name == 'Echo of Undermining',
          );
      expect(echo.statModifiers['Strength'], -10);
    });
  });

  group('abilitiesExtractor', () {
    test('extracts ability kinds', () async {
      final records = await AbilitiesExtractor().extract(loadFixtureRawTable);
      expect(records.length, greaterThanOrEqualTo(5));
      final kinds = records.cast<AbilityRecord>().map((r) => r.kind).toSet();
      expect(kinds, contains(AbilityKind.superAbility));
      expect(kinds, contains(AbilityKind.grenade));
      expect(kinds, contains(AbilityKind.melee));
    });
  });

  group('modsExtractor', () {
    test('extracts mods with energy and dedupes Focusing Strike', () async {
      final records = await ModsExtractor().extract(loadFixtureRawTable);
      expect(records, isNotEmpty);
      final mods = records.cast<ModRecord>();
      final focusing =
          mods.where((m) => m.name == 'Focusing Strike').toList();
      expect(focusing, hasLength(1));
      expect(focusing.single.energyCost, 2); // higher cost kept
      final major = mods.firstWhere((m) => m.name == 'Major Melee');
      expect(major.energyCost, 3);
      expect(major.slotCategory, ModSlotCategory.general);
    });
  });
}
