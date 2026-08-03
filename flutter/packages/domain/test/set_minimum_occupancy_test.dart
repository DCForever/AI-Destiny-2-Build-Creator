import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// DAC-DST-010 / DAC-DST-011 / DAC-SET-002 package minimum occupancy.
void main() {
  group('countWeaponOrArmorItems', () {
    test('counts unique weapon domain slots', () {
      expect(
        countWeaponOrArmorItems(SetType.weapon, const [
          SetOccupancyItem(slot: 'primary'),
          SetOccupancyItem(slot: 'heavy'),
          SetOccupancyItem(slot: 'primary'),
        ]),
        2,
      );
    });

    test('ignores soft-removed', () {
      expect(
        countWeaponOrArmorItems(SetType.armor, const [
          SetOccupancyItem(slot: 'helmet'),
          SetOccupancyItem(slot: 'arms', removedAt: '2026-01-01'),
        ]),
        1,
      );
    });
  });

  group('countModPieces', () {
    test('counts distinct armor pieces from mod keys', () {
      expect(
        countModPieces(const [
          SetOccupancyItem(slot: 'helmet:1'),
          SetOccupancyItem(slot: 'helmet:2'),
          SetOccupancyItem(slot: 'arms:3'),
        ]),
        2,
      );
    });

    test('treats legacy free-list as one piece', () {
      expect(
        countModPieces(const [
          SetOccupancyItem(slot: 'mod:10'),
          SetOccupancyItem(slot: 'mod:11'),
        ]),
        1,
      );
    });
  });

  group('evaluateSetMinimumOccupancy — DAC-DST-010 weapon/armor', () {
    test('rejects empty weapon scaffold with SET_MIN_ITEMS', () {
      final r = evaluateSetMinimumOccupancy(SetType.weapon, const []);
      expect(r.ok, isFalse);
      expect(r.empty, isTrue);
      expect(r.code, DomainFailureCodes.setMinItems);
      expect(r.count, 0);
      expect(r.required, 2);
    });

    test('rejects single-item weapon set', () {
      final r = evaluateSetMinimumOccupancy(SetType.weapon, const [
        SetOccupancyItem(slot: 'primary'),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.setMinItems);
      expect(r.count, 1);
      expect(r.required, 2);
      expect(r.message, contains('Weapon'));
    });

    test('accepts weapon set with two items', () {
      final r = evaluateSetMinimumOccupancy(SetType.weapon, const [
        SetOccupancyItem(slot: 'primary'),
        SetOccupancyItem(slot: 'special'),
      ]);
      expect(r.ok, isTrue);
      expect(r.empty, isFalse);
      expect(r.count, 2);
    });

    test('rejects armor set with one piece', () {
      final r = evaluateSetMinimumOccupancy(SetType.armor, const [
        SetOccupancyItem(slot: 'helmet'),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.setMinItems);
      expect(r.message, contains('Armor'));
    });

    test('accepts armor set with two pieces', () {
      final r = evaluateSetMinimumOccupancy(SetType.armor, const [
        SetOccupancyItem(slot: 'helmet'),
        SetOccupancyItem(slot: 'legs'),
      ]);
      expect(r.ok, isTrue);
    });
  });

  group('evaluateSetMinimumOccupancy — DAC-DST-011 mod multi-piece', () {
    test('rejects empty mod set with MOD_SET_MIN_SLOTS', () {
      final r = evaluateSetMinimumOccupancy(SetType.mod, const []);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.modSetMinSlots);
      expect(r.count, 0);
    });

    test('rejects mod set with one piece only (multiple plugs same piece)', () {
      final r = evaluateSetMinimumOccupancy(SetType.mod, const [
        SetOccupancyItem(slot: 'helmet:1'),
        SetOccupancyItem(slot: 'helmet:2'),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.modSetMinSlots);
      expect(r.count, 1);
    });

    test('accepts mod set with two pieces', () {
      final r = evaluateSetMinimumOccupancy(SetType.mod, const [
        SetOccupancyItem(slot: 'helmet:1'),
        SetOccupancyItem(slot: 'legs:2'),
      ]);
      expect(r.ok, isTrue);
      expect(r.count, 2);
    });
  });

  group('evaluateSetMinimumOccupancy — DAC-SET-002 pair complete', () {
    test('rejects incomplete pair (weapon only)', () {
      final r = evaluateSetMinimumOccupancy(SetType.pair, const [
        SetOccupancyItem(slot: 'exotic_weapon'),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.pairIncomplete);
      expect(r.count, 1);
    });

    test('rejects incomplete pair (armor only)', () {
      final r = evaluateSetMinimumOccupancy(SetType.pair, const [
        SetOccupancyItem(slot: 'exotic_armor'),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.pairIncomplete);
    });

    test('rejects empty pair', () {
      final r = evaluateSetMinimumOccupancy(SetType.pair, const []);
      expect(r.ok, isFalse);
      expect(r.code, DomainFailureCodes.pairIncomplete);
      expect(r.empty, isTrue);
    });

    test('accepts complete pair', () {
      final r = evaluateSetMinimumOccupancy(SetType.pair, const [
        SetOccupancyItem(slot: 'exotic_weapon'),
        SetOccupancyItem(slot: 'exotic_armor'),
      ]);
      expect(r.ok, isTrue);
      expect(r.count, 2);
    });
  });

  group('evaluateSetMinimumOccupancy — fashion exempt', () {
    test('always ok for fashion', () {
      expect(evaluateSetMinimumOccupancy(SetType.fashion, const []).ok, isTrue);
      expect(
        evaluateSetMinimumOccupancy(SetType.fashion, const [
          SetOccupancyItem(slot: 'ghost'),
        ]).ok,
        isTrue,
      );
    });
  });

  group('setWouldPassSaveRules', () {
    test('false under min, true at min, fashion always true', () {
      expect(
        setWouldPassSaveRules(SetType.weapon, const [
          SetOccupancyItem(slot: 'primary'),
        ]),
        isFalse,
      );
      expect(
        setWouldPassSaveRules(SetType.weapon, const [
          SetOccupancyItem(slot: 'primary'),
          SetOccupancyItem(slot: 'heavy'),
        ]),
        isTrue,
      );
      expect(setWouldPassSaveRules(SetType.fashion, const []), isTrue);
    });
  });

  group('formatSetOccupancyMessage', () {
    test('plain language for SET_MIN_ITEMS', () {
      final msg = formatSetOccupancyMessage(
        code: DomainFailureCodes.setMinItems,
        setType: SetType.weapon,
        count: 1,
        required: 2,
      );
      expect(msg, isNot(contains(RegExp(r'^[0-9a-f]{8,}$'))));
      expect(msg.toLowerCase(), contains('weapon'));
      expect(msg, contains('2'));
    });
  });
}
