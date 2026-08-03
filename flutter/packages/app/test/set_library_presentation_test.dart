import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('filledSlotCount / firstEmptyBoardSlot', () {
    test('counts exact slot matches', () {
      expect(
        filledSlotCount(
          boardSlots: const ['primary', 'special', 'heavy'],
          activeItemSlots: const ['primary', 'heavy'],
        ),
        2,
      );
      expect(
        firstEmptyBoardSlot(
          boardSlots: const ['primary', 'special', 'heavy'],
          activeItemSlots: const ['primary'],
        ),
        'special',
      );
    });
  });

  group('buildSetReadiness', () {
    test('weapon partial readiness under package min', () {
      final r = buildSetReadiness(
        setType: SetType.weapon,
        boardSlots: const ['primary', 'special', 'heavy'],
        activeItemSlots: const ['primary'],
      );
      expect(r.filled, 1);
      expect(r.capacity, 3);
      expect(r.emptySlots, 2);
      expect(r.nextEmptySlot, 'special');
      // Under DBR-CMP-008 floor → unresolved until ≥2 items.
      expect(r.meetsPackageMinimum, isFalse);
      expect(r.tone, 'unresolved');
      expect(r.badgeLabel, contains('1/3'));
    });

    test('weapon partial at package min is fuzzy when slots remain', () {
      final r = buildSetReadiness(
        setType: SetType.weapon,
        boardSlots: const ['primary', 'special', 'heavy'],
        activeItemSlots: const ['primary', 'special'],
      );
      expect(r.meetsPackageMinimum, isTrue);
      expect(r.tone, 'fuzzy');
      expect(r.badgeLabel, contains('2/3 filled'));
    });

    test('full board verified', () {
      final r = buildSetReadiness(
        setType: SetType.weapon,
        boardSlots: const ['primary', 'special', 'heavy'],
        activeItemSlots: const ['primary', 'special', 'heavy'],
      );
      expect(r.tone, 'verified');
      expect(r.nextEmptySlot, isNull);
    });

    test('mod set shows piece groups from pure helper', () {
      final r = buildSetReadiness(
        setType: SetType.mod,
        boardSlots: const ['helmet', 'arms', 'chest', 'legs', 'class_item'],
        activeItemSlots: const ['helmet:1', 'arms:2'],
      );
      expect(r.isMods, isTrue);
      expect(r.modCount, 2);
      expect(r.packageMinimumCount, 2);
      expect(r.meetsPackageMinimum, isTrue);
      expect(r.nextEmptySlot, isNull);
      expect(r.badgeLabel, contains('piece'));
    });

    test('meetsPackageMinimum false under SET_MIN_ITEMS', () {
      final r = buildSetReadiness(
        setType: SetType.weapon,
        boardSlots: const ['primary', 'special', 'heavy'],
        activeItemSlots: const ['primary'],
      );
      expect(r.meetsPackageMinimum, isFalse);
      expect(r.packageMinimumCode, DomainFailureCodes.setMinItems);
      expect(r.tone, 'unresolved');
      expect(r.packageMinimumMessage, isNotNull);
    });

    test('mod under one piece fails package minimum', () {
      final r = buildSetReadiness(
        setType: SetType.mod,
        boardSlots: const ['helmet', 'arms', 'chest', 'legs', 'class_item'],
        activeItemSlots: const ['helmet:1', 'helmet:2'],
      );
      expect(r.meetsPackageMinimum, isFalse);
      expect(r.packageMinimumCode, DomainFailureCodes.modSetMinSlots);
      expect(r.packageMinimumCount, 1);
    });
  });

  group('formatSetInUseMessage', () {
    test('includes build and variant ids', () {
      final msg = formatSetInUseMessage(
        buildIds: ['b1'],
        variantIds: ['v1', 'v2'],
      );
      expect(msg, contains('SET_IN_USE'));
      expect(msg, contains('b1'));
      expect(msg, contains('v1'));
    });
  });

  group('mapUsedByDisplays', () {
    test('prefers build name', () {
      final rows = mapUsedByDisplays([
        (buildId: 'b1', variantId: 'v1', buildName: 'Main'),
      ]);
      expect(rows.single.label, 'Main · v1');
    });
  });
}
