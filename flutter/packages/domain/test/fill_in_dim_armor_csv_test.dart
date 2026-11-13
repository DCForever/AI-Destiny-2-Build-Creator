import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  const techsecSet = 555001;
  const setByHash = <int, int>{
    111001: techsecSet,
    111002: techsecSet,
    111003: techsecSet,
  };

  group('parseDimArmorCsv', () {
    test('parses a good synthetic DIM Armor CSV fixture', () {
      final result = parseDimArmorCsv(
        _fixtureText(),
        armorSetHashByItemHash: setByHash,
      );
      expect(result.isOk, isTrue, reason: result.error);
      final items = result.items!;
      expect(items, isNotEmpty);

      final warlockHelms = items.where(
        (i) =>
            i.guardianClass == GuardianClass.warlock &&
            i.slot == EquipmentSlot.helmet &&
            !i.isExotic,
      );
      expect(warlockHelms, hasLength(1));
      expect(warlockHelms.single.armorSetHash, techsecSet);
      expect(warlockHelms.single.instanceId, '1000000000000000001');

      final exotic = items.where((i) => i.itemHash == 9001);
      expect(exotic, hasLength(1));
      expect(exotic.single.isExotic, isTrue);
      expect(exotic.single.armorSetHash, isNull);
    });

    test('fails closed on malformed CSV', () {
      final result = parseDimArmorCsv('"unterminated');
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.items, isNull);
    });

    test('fails closed when a required column is missing', () {
      const csv = 'Name,Hash,Id,Equippable,Type\n'
          'X,1,"1",Warlock,Helmet\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, contains('missing required column "Rarity"'));
    });

    test('fails closed on unknown / incomplete header', () {
      const csv = 'Foo,Bar\n1,2\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('missing required column'));
    });

    test('fails closed on oversized file', () {
      final result = parseDimArmorCsv(
        _fixtureText(),
        maxBytes: 32,
      );
      expect(result.isOk, isFalse);
      expect(result.error, contains('size limit'));
    });

    test('duplicate instance id is kept once', () {
      final result = parseDimArmorCsv(
        _fixtureText(),
        armorSetHashByItemHash: setByHash,
      );
      final ids = result.items!.map((i) => i.instanceId).toList();
      expect(ids.toSet().length, ids.length);
      expect(
        result.items!.where((i) => i.instanceId == '1000000000000000004'),
        hasLength(1),
      );
    });

    test('wrong-class legendary does not fill a Warlock set need', () {
      final parsed = parseDimArmorCsv(
        _fixtureText(),
        armorSetHashByItemHash: setByHash,
      );
      final report = matchFillIn(
        inventory: parsed.items!,
        inventoryCap: 2,
        builds: const [
          FillInBuildRequirement(
            buildId: 'w',
            guardianClass: GuardianClass.warlock,
            subclassKey: 'prismatic',
            slots: [
              FillInSlotRequirement(
                slot: EquipmentSlot.helmet,
                isExotic: false,
                armorSetHash: techsecSet,
              ),
            ],
          ),
        ],
      );
      // Warlock Techsec helmet is held; Titan copy of same hash must not add
      // a second pool count for Warlock.
      expect(report.builds.single.slots.single.poolHeldCount, 1);
      expect(report.builds.single.slots.single.isHeld, isTrue);
    });

    test('optional: Titan exotic hash does not fill Warlock exotic need when '
        'hash differs', () {
      final parsed = parseDimArmorCsv(_fixtureText());
      final report = matchFillIn(
        inventory: parsed.items!,
        builds: const [
          FillInBuildRequirement(
            buildId: 'w',
            guardianClass: GuardianClass.warlock,
            subclassKey: 'prismatic',
            exoticArmorName: 'Solipsism',
            slots: [
              FillInSlotRequirement(
                slot: EquipmentSlot.classItem,
                isExotic: true,
                exoticItemHash: 9001,
              ),
            ],
          ),
        ],
      );
      expect(report.builds.single.slots.single.isHeld, isTrue);
      // Aeon Safe (9002, Titan) is present but must not satisfy Solipsism.
      expect(
        parsed.items!.any((i) => i.itemHash == 9002),
        isTrue,
      );
    });

    test('parseDimArmorCsvBytes rejects oversize before decode work matters',
        () {
      final bytes = utf8.encode(_fixtureText());
      final result = parseDimArmorCsvBytes(bytes, maxBytes: 8);
      expect(result.isOk, isFalse);
      expect(result.error, contains('size limit'));
    });

    test('fails closed on a short data row (width mismatch)', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          'Short,1\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('width'));
      expect(result.items, isNull);
    });

    test('fails closed on an empty Id', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          'X,1,"",Warlock,Helmet,Legendary\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('empty Id'));
      expect(result.items, isNull);
    });

    test('fails closed on an empty Id that is only quotes/whitespace', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          'X,1,"   ",Warlock,Helmet,Legendary\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, contains('empty Id'));
      expect(result.items, isNull);
    });

    test('fails closed on an unparseable Hash', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          'X,not-a-hash,"1",Warlock,Helmet,Legendary\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isFalse);
      expect(result.error, startsWith("Couldn't read file:"));
      expect(result.error, contains('unparseable Hash'));
      expect(result.items, isNull);
    });

    test('accepts a quoted comma inside a field', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          '"Helm, Techsec",111001,"1001",Warlock,Helmet,Legendary\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isTrue, reason: result.error);
      expect(result.items, hasLength(1));
      expect(result.items!.single.instanceId, '1001');
      expect(result.items!.single.itemHash, 111001);
    });

    test('accepts a quoted newline inside a field', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
          '"Helm\nTechsec",111001,"1002",Warlock,Helmet,Legendary\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isTrue, reason: result.error);
      expect(result.items, hasLength(1));
      expect(result.items!.single.instanceId, '1002');
    });

    test('accepts CRLF line endings', () {
      const csv = 'Name,Hash,Id,Equippable,Type,Rarity\r\n'
          'Helm,111001,"1003",Warlock,Helmet,Legendary\r\n';
      final result = parseDimArmorCsv(csv);
      expect(result.isOk, isTrue, reason: result.error);
      expect(result.items, hasLength(1));
      expect(result.items!.single.instanceId, '1003');
    });

    test(
      'parses one synthetic row on the exact measured DIM Armor header '
      '(48 cols; unused columns ignored; Equippable Warlock/Titan/Hunter)',
      () {
        // Measured from Daniel's export, Nov 12, 2026 — synthetic values only.
        expect(_kMeasuredArmorHeader.split(','), hasLength(48));
        expect(_kMeasuredArmorHeader.split(','), contains('Equippable'));

        final cells = List<String>.filled(48, '');
        void set(String name, String value) {
          final i = _kMeasuredArmorHeader.split(',').indexOf(name);
          expect(i, greaterThanOrEqualTo(0), reason: name);
          cells[i] = value;
        }

        set('Name', 'Synthetic Techsec Helm');
        set('Hash', '111001');
        set('Id', '"1000000000000000099"');
        set('Rarity', 'Legendary');
        set('Tier', '2');
        set('Type', 'Helmet');
        set('Equippable', 'Warlock');
        set('Power', '1800');
        set('Energy Capacity', '3');
        // Unused columns stay blank — must not fail when width matches.

        final csv = '$_kMeasuredArmorHeader\n${cells.join(',')}\n';
        final result = parseDimArmorCsv(
          csv,
          armorSetHashByItemHash: const {111001: 555001},
        );
        expect(result.isOk, isTrue, reason: result.error);
        expect(result.items, hasLength(1));
        final item = result.items!.single;
        expect(item.itemHash, 111001);
        expect(item.instanceId, '1000000000000000099');
        expect(item.isExotic, isFalse);
        expect(item.slot, EquipmentSlot.helmet);
        expect(item.guardianClass, GuardianClass.warlock);
        expect(item.armorSetHash, 555001);
      },
    );
  });
}

/// Exact Armor CSV header measured from Daniel's DIM export, Nov 12, 2026
/// (48 columns, 826 rows). Synthetic fixtures only.
const String _kMeasuredArmorHeader =
    'Name,Hash,Id,Tag,Rarity,Tier,Type,Source,Equippable,Power,'
    'Energy Capacity,Archetype,Tertiary Stat,Tuning Stat,Masterwork Tier,'
    'Owner,Locked,Equipped,Holofoil,Year,Season,Event,Weapons,Health,Class,'
    'Grenade,Super,Melee,Total,Weapons (Base),Health (Base),Class (Base),'
    'Grenade (Base),Super (Base),Melee (Base),Total (Base),Seasonal Mod,'
    'Loadouts,Notes,Perks 0,Perks 1,Perks 2,Perks 3,Perks 4,Perks 5,Perks 6,'
    'Perks 7,Perks 8';

String _fixtureText() => File(_fixturePath()).readAsStringSync();

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/test/fixtures/dim_armor_min.csv',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/packages/domain/test/fixtures/dim_armor_min.csv',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'dim_armor_min.csv not found from ${Directory.current.path}',
  );
}
