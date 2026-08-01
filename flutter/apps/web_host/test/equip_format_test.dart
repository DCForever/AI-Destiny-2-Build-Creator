import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/equip/equip_format.dart';
import 'package:test/test.dart';

void main() {
  group('formatPinStatusLabel', () {
    test('wishlist / pinned / stale', () {
      expect(
        formatPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.primary,
            status: PinStatusKind.wishlist,
          ),
        ),
        contains('wishlist'),
      );
      expect(
        formatPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.helmet,
            status: PinStatusKind.pinned,
            instanceId: 'i1',
          ),
        ),
        contains('owned pin'),
      );
      expect(
        formatPinStatusLabel(
          const PinStatus(
            slot: EquipmentSlot.arms,
            status: PinStatusKind.stale,
            instanceId: 'i2',
            reason: PinStaleReason.instanceMissing,
          ),
        ),
        contains('stale'),
      );
    });
  });

  group('formatEquipReadySummary', () {
    test('ready and not ready', () {
      expect(
        formatEquipReadySummary(
          const EquipReadyResult(equipReady: true, pinStatuses: [
            PinStatus(
              slot: EquipmentSlot.primary,
              status: PinStatusKind.pinned,
              instanceId: 'a',
            ),
          ]),
        ),
        'Equip-ready',
      );
      expect(
        formatEquipReadySummary(
          const EquipReadyResult(equipReady: false, pinStatuses: [
            PinStatus(
              slot: EquipmentSlot.primary,
              status: PinStatusKind.wishlist,
            ),
          ]),
        ),
        contains('Not equip-ready'),
      );
    });
  });

  group('emptyCombatSlotWires', () {
    test('lists missing combat slots', () {
      final empty = emptyCombatSlotWires({
        EquipmentSlot.primary: const SlotClaim(
          slot: EquipmentSlot.primary,
          itemHash: 1,
          itemName: 'P',
          source: ClaimSource.set,
          instanceId: 'x',
        ),
      });
      expect(empty, isNot(contains('primary')));
      expect(empty, contains('helmet'));
      expect(empty.length, EquipmentSlot.combatSlots.length - 1);
    });
  });

  group('canEnableEquipCta', () {
    test('requires signed in, ready, character, idle', () {
      expect(
        canEnableEquipCta(
          signedIn: true,
          equipReady: true,
          characterId: 'c1',
          equipping: false,
          loading: false,
        ),
        isTrue,
      );
      expect(
        canEnableEquipCta(
          signedIn: false,
          equipReady: true,
          characterId: 'c1',
          equipping: false,
          loading: false,
        ),
        isFalse,
      );
      expect(
        canEnableEquipCta(
          signedIn: true,
          equipReady: false,
          characterId: 'c1',
          equipping: false,
          loading: false,
        ),
        isFalse,
      );
      expect(
        canEnableEquipCta(
          signedIn: true,
          equipReady: true,
          characterId: null,
          equipping: false,
          loading: false,
        ),
        isFalse,
      );
      expect(
        canEnableEquipCta(
          signedIn: true,
          equipReady: true,
          characterId: 'c1',
          equipping: false,
          loading: false,
          finishComplete: false,
        ),
        isFalse,
      );
      expect(
        canEnableEquipCta(
          signedIn: true,
          equipReady: true,
          characterId: 'c1',
          equipping: false,
          loading: false,
          finishComplete: true,
        ),
        isTrue,
      );
    });
  });

  group('formatCharacterOptionLabel', () {
    test('class and light', () {
      expect(
        formatCharacterOptionLabel(
          const CharacterSummary(
            characterId: 'c',
            classType: 'Hunter',
            light: 1810,
          ),
        ),
        'Hunter · 1810',
      );
    });
  });

  group('formatEquipStatusSummary', () {
    test('counts', () {
      const status = EquipStatus(
        steps: [],
        completed: 2,
        failed: 1,
      );
      expect(formatEquipStatusSummary(status), contains('Completed 2'));
      expect(formatEquipStatusSummary(status), contains('Failed 1'));
    });
  });
}
