import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/equip/equip_format.dart';
import 'package:flutter_test/flutter_test.dart';

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
    });
  });

  group('step report', () {
    test('formats ok and fail lines + summary', () {
      const planStep = PlannedEquipStep(
        id: 'equip-primary',
        kind: EquipStepKind.equip,
        slot: 'primary',
        itemHash: 1,
        instanceId: 'i1',
      );
      final ok = const EquipStepResult(step: planStep, ok: true);
      final fail = const EquipStepResult(
        step: planStep,
        ok: false,
        error: 'boom',
      );
      expect(formatEquipStepReportLine(ok), startsWith('✓'));
      expect(formatEquipStepReportLine(fail), contains('boom'));
      final status = EquipStatus(steps: [ok, fail], completed: 1, failed: 1);
      expect(formatEquipStatusSummary(status), contains('Completed 1'));
      expect(formatEquipStatusSummary(status), contains('Failed 1'));
    });
  });

  group('character option', () {
    test('includes class and light', () {
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
}
