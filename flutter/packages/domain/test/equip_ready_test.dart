import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

ResolvedVariantEquipment resolved(
  Map<EquipmentSlot, SlotClaim> equipment,
) {
  return ResolvedVariantEquipment(equipment: equipment, conflicts: const []);
}

SlotClaim claim(
  EquipmentSlot slot,
  int itemHash, {
  String? instanceId,
  String itemName = 'Item',
}) {
  return SlotClaim(
    slot: slot,
    itemHash: itemHash,
    itemName: itemName,
    source: ClaimSource.set,
    instanceId: instanceId,
  );
}

void main() {
  group('computeEquipReady', () {
    test('marks slots without instanceId as wishlist and not equip-ready', () {
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(EquipmentSlot.primary, 1, itemName: 'Gun'),
        }),
        buildInventoryPinIndex(const []),
      );
      expect(result.equipReady, isFalse);
      expect(result.pinStatuses, [
        const PinStatus(
          slot: EquipmentSlot.primary,
          status: PinStatusKind.wishlist,
        ),
      ]);
    });

    test('is equip-ready when every applied combat slot is pinned', () {
      final inventory = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'a', itemHash: 1),
        InventoryPinItem(instanceId: 'b', itemHash: 2),
      ]);
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'a',
            itemName: 'Gun',
          ),
          EquipmentSlot.helmet: claim(
            EquipmentSlot.helmet,
            2,
            instanceId: 'b',
            itemName: 'Helm',
          ),
        }),
        inventory,
      );
      expect(result.equipReady, isTrue);
      expect(
        result.pinStatuses.every((s) => s.status == PinStatusKind.pinned),
        isTrue,
      );
    });

    test('ignores empty non-default gaps (only applied slots)', () {
      final inventory = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'a', itemHash: 1),
      ]);
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'a',
            itemName: 'Gun',
          ),
        }),
        inventory,
      );
      expect(result.equipReady, isTrue);
      expect(result.pinStatuses, hasLength(1));
    });

    test('marks missing inventory instance as stale', () {
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'gone',
            itemName: 'Gun',
          ),
        }),
        buildInventoryPinIndex(const []),
      );
      expect(result.equipReady, isFalse);
      expect(result.pinStatuses.single.status, PinStatusKind.stale);
      expect(result.pinStatuses.single.reason, PinStaleReason.instanceMissing);
      expect(result.pinStatuses.single.reason!.wireName, 'instance_missing');
      expect(result.pinStatuses.single.instanceId, 'gone');
    });

    test('marks hash mismatch as stale', () {
      final inventory = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'a', itemHash: 999),
      ]);
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'a',
            itemName: 'Gun',
          ),
        }),
        inventory,
      );
      expect(result.equipReady, isFalse);
      expect(result.pinStatuses.single, const PinStatus(
        slot: EquipmentSlot.primary,
        status: PinStatusKind.stale,
        instanceId: 'a',
        reason: PinStaleReason.hashMismatch,
      ));
      expect(
        result.pinStatuses.single.reason!.wireName,
        'hash_mismatch',
      );
    });

    test('empty equipment is never equip-ready', () {
      final result = computeEquipReady(
        const ResolvedVariantEquipment(),
        buildInventoryPinIndex(const []),
      );
      expect(result.equipReady, isFalse);
      expect(result.pinStatuses, isEmpty);
    });

    test('mixed wishlist and pinned is not equip-ready', () {
      final inventory = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'a', itemHash: 1),
      ]);
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'a',
            itemName: 'Gun',
          ),
          EquipmentSlot.helmet: claim(
            EquipmentSlot.helmet,
            2,
            itemName: 'Helm',
          ),
        }),
        inventory,
      );
      expect(result.equipReady, isFalse);
      expect(
        result.pinStatuses.map((s) => s.status).toList(),
        [PinStatusKind.pinned, PinStatusKind.wishlist],
      );
    });

    test('assertEquipReady throws NOT_EQUIP_READY when not ready', () {
      final result = computeEquipReady(
        resolved({
          EquipmentSlot.primary: claim(EquipmentSlot.primary, 1, itemName: 'Gun'),
        }),
        buildInventoryPinIndex(const []),
      );
      expect(
        () => assertEquipReady(result),
        throwsA(
          isA<EquipReadyException>()
              .having((e) => e.code, 'code', DomainFailureCodes.notEquipReady)
              .having((e) => e.code, 'code string', 'NOT_EQUIP_READY')
              .having((e) => e.details?['allowed'], 'allowed', false),
        ),
      );
    });

    test(
      'post-sync: pre-ready pins become not equip-ready when instance missing after refresh',
      () {
        final equipment = {
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'pin-a',
            itemName: 'Gun',
          ),
          EquipmentSlot.helmet: claim(
            EquipmentSlot.helmet,
            2,
            instanceId: 'pin-b',
            itemName: 'Helm',
          ),
        };

        final preSync = computeEquipReady(
          resolved(equipment),
          buildInventoryPinIndex(const [
            InventoryPinItem(instanceId: 'pin-a', itemHash: 1),
            InventoryPinItem(instanceId: 'pin-b', itemHash: 2),
          ]),
        );
        expect(preSync.equipReady, isTrue);

        // Post-sync inventory lost pin-b (sold/transferred out of account view).
        final postSync = computeEquipReady(
          resolved(equipment),
          buildInventoryPinIndex(const [
            InventoryPinItem(instanceId: 'pin-a', itemHash: 1),
          ]),
        );
        expect(postSync.equipReady, isFalse);
        expect(
          postSync.pinStatuses,
          contains(
            const PinStatus(
              slot: EquipmentSlot.helmet,
              status: PinStatusKind.stale,
              instanceId: 'pin-b',
              reason: PinStaleReason.instanceMissing,
            ),
          ),
        );
        expect(
          () => assertEquipReady(postSync),
          throwsA(
            isA<EquipReadyException>().having(
              (e) => e.code,
              'code',
              DomainFailureCodes.notEquipReady,
            ),
          ),
        );
      },
    );

    test(
      'post-sync happy path: all claimed instances still present remain equip-ready',
      () {
        final equipment = {
          EquipmentSlot.primary: claim(
            EquipmentSlot.primary,
            1,
            instanceId: 'pin-a',
            itemName: 'Gun',
          ),
          EquipmentSlot.special: claim(
            EquipmentSlot.special,
            3,
            instanceId: 'pin-c',
            itemName: 'Special',
          ),
          EquipmentSlot.helmet: claim(
            EquipmentSlot.helmet,
            2,
            instanceId: 'pin-b',
            itemName: 'Helm',
          ),
        };
        final postSync = computeEquipReady(
          resolved(equipment),
          buildInventoryPinIndex(const [
            InventoryPinItem(instanceId: 'pin-a', itemHash: 1),
            InventoryPinItem(instanceId: 'pin-b', itemHash: 2),
            InventoryPinItem(instanceId: 'pin-c', itemHash: 3),
          ]),
        );
        expect(postSync.equipReady, isTrue);
        expect(() => assertEquipReady(postSync), returnsNormally);
      },
    );

    test('buildInventoryPinIndex maps instanceId to itemHash', () {
      final index = buildInventoryPinIndex(const [
        InventoryPinItem(instanceId: 'x', itemHash: 10),
        InventoryPinItem(instanceId: 'y', itemHash: 20),
      ]);
      expect(index['x'], 10);
      expect(index['y'], 20);
      expect(index.containsKey('z'), isFalse);
    });
  });
}
