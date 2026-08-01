import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

SlotClaim claim({
  required EquipmentSlot slot,
  required int itemHash,
  required String instanceId,
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

EquipInventoryItem inv({
  required String instanceId,
  required int itemHash,
  required String location,
  String? characterId,
}) {
  return EquipInventoryItem(
    instanceId: instanceId,
    itemHash: itemHash,
    location: location,
    characterId: characterId,
  );
}

void main() {
  group('planEquipSteps (US1)', () {
    test('orders transfer → equip → artifact → fashion', () {
      final plan = planEquipSteps(
        EquipPlanInput(
          characterId: 'char-a',
          equipment: {
            EquipmentSlot.helmet: claim(
              slot: EquipmentSlot.helmet,
              itemHash: 10,
              instanceId: 'i-helm',
              itemName: 'Helm',
            ),
          },
          artifact: const EquipPlanArtifact(
            hash: 99,
            name: 'Artifact',
            config: [1, 2],
          ),
          fashion: const EquipPlanFashion(
            setId: 'f1',
            slots: {
              'ghost': EquipPlanFashionPiece(itemHash: 50, itemName: 'Ghost'),
            },
          ),
          inventory: [
            inv(instanceId: 'i-helm', itemHash: 10, location: 'vault'),
            inv(instanceId: 'i-ghost', itemHash: 50, location: 'vault'),
          ],
        ),
      );

      expect(
        plan.map((s) => s.kind).toList(),
        [
          EquipStepKind.transfer,
          EquipStepKind.equip,
          EquipStepKind.artifact,
          EquipStepKind.fashion,
        ],
      );
      expect(plan[0].id, 'transfer-helmet');
      expect(plan[0].transferToVault, isFalse);
      expect(plan[1].id, 'equip-helmet');
      expect(plan[2].id, 'artifact');
      expect(plan[3].id, 'fashion-ghost');
      expect(plan[3].instanceId, 'i-ghost');
    });

    test('vault-hops when item is on another character', () {
      final plan = planEquipSteps(
        EquipPlanInput(
          characterId: 'char-a',
          equipment: {
            EquipmentSlot.primary: claim(
              slot: EquipmentSlot.primary,
              itemHash: 1,
              instanceId: 'i-gun',
              itemName: 'Gun',
            ),
          },
          inventory: [
            inv(
              instanceId: 'i-gun',
              itemHash: 1,
              location: 'equipped',
              characterId: 'char-b',
            ),
          ],
        ),
      );

      expect(
        plan.map((s) => s.id).toList(),
        [
          'transfer-primary-to-vault',
          'transfer-primary-from-vault',
          'equip-primary',
        ],
      );
      expect(plan[0].transferToVault, isTrue);
      expect(plan[1].transferToVault, isFalse);
    });

    test('skips transfer when already on target character', () {
      final plan = planEquipSteps(
        EquipPlanInput(
          characterId: 'char-a',
          equipment: {
            EquipmentSlot.arms: claim(
              slot: EquipmentSlot.arms,
              itemHash: 2,
              instanceId: 'i-arms',
              itemName: 'Arms',
            ),
          },
          inventory: [
            inv(
              instanceId: 'i-arms',
              itemHash: 2,
              location: 'character',
              characterId: 'char-a',
            ),
          ],
        ),
      );

      expect(plan.map((s) => s.kind).toList(), [EquipStepKind.equip]);
    });

    test('omits empty fashion slots and missing artifact', () {
      final plan = planEquipSteps(
        const EquipPlanInput(
          characterId: 'char-a',
          equipment: {},
          fashion: EquipPlanFashion(setId: 'f1'),
          inventory: [],
        ),
      );
      expect(plan, isEmpty);
    });

    test(
      'throws NOT_EQUIP_READY when combat instanceId is missing from inventory',
      () {
        expect(
          () => planEquipSteps(
            EquipPlanInput(
              characterId: 'char-a',
              equipment: {
                EquipmentSlot.helmet: claim(
                  slot: EquipmentSlot.helmet,
                  itemHash: 10,
                  instanceId: 'missing-helm',
                  itemName: 'Helm',
                ),
              },
              inventory: const [],
            ),
          ),
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

    test('plans equip steps for all pinned combat slots on happy path', () {
      final plan = planEquipSteps(
        EquipPlanInput(
          characterId: 'char-a',
          equipment: {
            EquipmentSlot.primary: claim(
              slot: EquipmentSlot.primary,
              itemHash: 1,
              instanceId: 'i-primary',
            ),
            EquipmentSlot.helmet: claim(
              slot: EquipmentSlot.helmet,
              itemHash: 10,
              instanceId: 'i-helm',
            ),
            EquipmentSlot.arms: claim(
              slot: EquipmentSlot.arms,
              itemHash: 11,
              instanceId: 'i-arms',
            ),
          },
          inventory: [
            inv(
              instanceId: 'i-primary',
              itemHash: 1,
              location: 'character',
              characterId: 'char-a',
            ),
            inv(
              instanceId: 'i-helm',
              itemHash: 10,
              location: 'character',
              characterId: 'char-a',
            ),
            inv(
              instanceId: 'i-arms',
              itemHash: 11,
              location: 'character',
              characterId: 'char-a',
            ),
          ],
        ),
      );

      expect(
        plan
            .where((s) => s.kind == EquipStepKind.equip)
            .map((s) => s.id)
            .toList(),
        ['equip-primary', 'equip-helmet', 'equip-arms'],
      );
    });

    test('skips combat claims without instanceId (wishlist)', () {
      final plan = planEquipSteps(
        EquipPlanInput(
          characterId: 'char-a',
          equipment: {
            EquipmentSlot.primary: const SlotClaim(
              slot: EquipmentSlot.primary,
              itemHash: 1,
              itemName: 'Gun',
              source: ClaimSource.set,
            ),
          },
          inventory: const [],
        ),
      );
      expect(plan, isEmpty);
    });
  });
}
