import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('parseDimWeaponsCsv', () {
    test('parses a good synthetic DIM Weapons CSV fixture', () {
      final result = parseDimWeaponsCsv(_fixtureText());
      expect(result.isOk, isTrue, reason: result.error);
      final items = result.items!;
      expect(items, isNotEmpty);

      final sunshot = items.where((i) => i.itemHash == 3118677280);
      expect(sunshot, hasLength(1));
      expect(sunshot.single.isExotic, isTrue);
      expect(sunshot.single.slot, EquipmentSlot.special);
      expect(sunshot.single.guardianClass, isNull);
      expect(sunshot.single.instanceId, '2000000000000000001');

      final kinetic = items.where((i) => i.itemHash == 111);
      expect(kinetic, hasLength(1));
      expect(kinetic.single.isExotic, isFalse);
      expect(kinetic.single.slot, EquipmentSlot.primary);
      expect(kinetic.single.guardianClass, isNull);
    });

    test('fails closed on malformed CSV', () {
      final result = parseDimWeaponsCsv('"unterminated');
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.items, isNull);
    });

    test('fails closed when a required column is missing', () {
      const csv = 'Name,Hash,Id,Type,Rarity\n'
          'X,1,"1",Hand Cannon,Exotic\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, contains('missing required column "Category"'));
    });

    test('fails closed on unknown / incomplete header', () {
      const csv = 'Foo,Bar\n1,2\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('missing required column'));
    });

    test('fails closed on oversized file', () {
      final result = parseDimWeaponsCsv(_fixtureText(), maxBytes: 32);
      expect(result.isOk, isFalse);
      expect(result.error, contains('size limit'));
    });

    test('duplicate instance id is kept once', () {
      final result = parseDimWeaponsCsv(_fixtureText());
      final ids = result.items!.map((i) => i.instanceId).toList();
      expect(ids.toSet().length, ids.length);
      expect(
        result.items!.where((i) => i.instanceId == '2000000000000000001'),
        hasLength(1),
      );
    });

    test('exotic weapon held counts toward build exotic weapon need by hash',
        () {
      final parsed = parseDimWeaponsCsv(_fixtureText());
      final report = matchFillIn(
        inventory: parsed.items!,
        builds: const [
          FillInBuildRequirement(
            buildId: 'w',
            guardianClass: GuardianClass.warlock,
            subclassKey: 'solar',
            exoticArmorName: 'Sunbracers',
            slots: [
              FillInSlotRequirement(
                slot: EquipmentSlot.special,
                isExotic: true,
                exoticItemHash: 3118677280,
              ),
            ],
          ),
        ],
      );
      expect(report.builds.single.slots.single.isHeld, isTrue);
      expect(report.builds.single.slots.single.poolHeldCount, 1);
    });

    test('parseDimWeaponsCsvBytes rejects oversize before decode work matters',
        () {
      final bytes = utf8.encode(_fixtureText());
      final result = parseDimWeaponsCsvBytes(bytes, maxBytes: 8);
      expect(result.isOk, isFalse);
      expect(result.error, contains('size limit'));
    });

    test('fails closed on a short data row (width mismatch)', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          'Short,1\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('width'));
      expect(result.items, isNull);
    });

    test('fails closed on an empty Id', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          'X,1,"",Hand Cannon,Exotic,Energy\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('empty Id'));
      expect(result.items, isNull);
    });

    test('fails closed on an empty Id that is only quotes/whitespace', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          'X,1,"   ",Hand Cannon,Exotic,Energy\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, contains('empty Id'));
    });

    test('fails closed on an unparseable Hash', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          'X,not-a-hash,"1",Hand Cannon,Exotic,Energy\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('unparseable Hash'));
      expect(result.items, isNull);
    });

    test('fails closed when Type cell is blank (missing needed field)', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          'X,1,"1",,Exotic,Energy\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, contains('missing a needed field'));
    });

    test('accepts a quoted comma inside a field', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\n'
          '"Gun, Named",3118677280,"2001",Hand Cannon,Exotic,Energy\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isTrue, reason: result.error);
      expect(result.items, hasLength(1));
      expect(result.items!.single.instanceId, '2001');
      expect(result.items!.single.itemHash, 3118677280);
    });

    test('accepts CRLF line endings', () {
      const csv = 'Name,Hash,Id,Type,Rarity,Category\r\n'
          'Sunshot,3118677280,"2003",Hand Cannon,Exotic,Energy\r\n';
      final result = parseDimWeaponsCsv(csv);
      expect(result.isOk, isTrue, reason: result.error);
      expect(result.items, hasLength(1));
      expect(result.items!.single.instanceId, '2003');
    });

    test(
      'parses one synthetic row on the exact measured DIM Weapons header '
      '(72 cols; unused columns ignored; no Equippable)',
      () {
        // Measured from Daniel's export, Nov 12, 2026 — synthetic values only.
        expect(_kMeasuredWeaponsHeader.split(','), hasLength(72));
        expect(_kMeasuredWeaponsHeader.split(','), isNot(contains('Equippable')));

        final cells = List<String>.filled(72, '');
        void set(String name, String value) {
          final i = _kMeasuredWeaponsHeader.split(',').indexOf(name);
          expect(i, greaterThanOrEqualTo(0), reason: name);
          cells[i] = value;
        }

        set('Name', 'Synthetic Sunshot');
        set('Hash', '3118677280');
        set('Id', '"2000000000000000099"');
        set('Rarity', 'Exotic');
        set('Tier', '5');
        set('Type', 'Hand Cannon');
        set('Category', 'Energy');
        set('Element', 'Solar');
        set('Ammo', 'Primary');
        set('Power', '1800');
        // Unused columns stay blank — must not fail when width matches.

        final csv = '$_kMeasuredWeaponsHeader\n${cells.join(',')}\n';
        final result = parseDimWeaponsCsv(csv);
        expect(result.isOk, isTrue, reason: result.error);
        expect(result.items, hasLength(1));
        final item = result.items!.single;
        expect(item.itemHash, 3118677280);
        expect(item.instanceId, '2000000000000000099');
        expect(item.isExotic, isTrue);
        expect(item.slot, EquipmentSlot.special);
        expect(item.guardianClass, isNull);
      },
    );
  });
}

/// Exact Weapons CSV header measured from Daniel's DIM export, Nov 12, 2026
/// (72 columns, 552 rows, no width mismatches). Synthetic fixtures only.
const String _kMeasuredWeaponsHeader =
    'Name,Hash,Id,Tag,Rarity,Tier,Type,Source,Category,Element,Ammo,Power,'
    'Archetype,Masterwork Type,Masterwork Tier,Owner,Locked,Equipped,Holofoil,'
    'Year,Season,Event,Recoil,AA,Impact,Range,Zoom,Blast Radius,Velocity,'
    'Persistence,Stability,ROF,Reload,Mag,Handling,Charge Time,Draw Time,'
    'Accuracy,Charge Rate,Guard Resistance,Guard Endurance,Swing Speed,'
    'Shield Duration,Airborne Effectiveness,Ammo Generation,Heat Generated,'
    'Cooling Efficiency,Crafted,Crafted Level,Kill Tracker,Foundry,Loadouts,'
    'Notes,Perks 0,Perks 1,Perks 2,Perks 3,Perks 4,Perks 5,Perks 6,Perks 7,'
    'Perks 8,Perks 9,Perks 10,Perks 11,Perks 12,Perks 13,Perks 14,Perks 15,'
    'Perks 16,Perks 17,Perks 18';

String _fixtureText() => File(_fixturePath()).readAsStringSync();

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/test/fixtures/dim_weapons_min.csv',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/packages/domain/test/fixtures/dim_weapons_min.csv',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'dim_weapons_min.csv not found from ${Directory.current.path}',
  );
}
