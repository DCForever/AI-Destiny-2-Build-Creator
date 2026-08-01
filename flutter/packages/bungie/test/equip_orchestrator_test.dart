import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  const ctx = WriteClientContext(accessToken: 't', membershipType: 3);

  group('executeEquipPlan (US2/US3)', () {
    test('executes steps via write client in plan order', () async {
      final calls = <String>[];
      final client = createMockWriteClient(
        transferItem: (c, a) async => calls.add('transfer'),
        equipItem: (c, a) async => calls.add('equip'),
        applyArtifactConfig: (c, a) async => calls.add('artifact'),
        applyFashionSlot: (c, a) async => calls.add('fashion'),
      );

      final status = await executeEquipPlan(client, ctx, 'char-a', const [
        PlannedEquipStep(
          id: 'transfer-helmet',
          kind: EquipStepKind.transfer,
          itemHash: 10,
          instanceId: 'i1',
          transferToVault: false,
        ),
        PlannedEquipStep(
          id: 'equip-helmet',
          kind: EquipStepKind.equip,
          itemHash: 10,
          instanceId: 'i1',
        ),
        PlannedEquipStep(
          id: 'artifact',
          kind: EquipStepKind.artifact,
          itemHash: 99,
          artifactConfig: [1],
        ),
        PlannedEquipStep(
          id: 'fashion-ghost',
          kind: EquipStepKind.fashion,
          slot: 'ghost',
          itemHash: 50,
        ),
      ]);

      expect(calls, ['transfer', 'equip', 'artifact', 'fashion']);
      expect(status.completed, 4);
      expect(status.failed, 0);
      expect(status.steps.every((s) => s.ok), isTrue);
    });

    test(
      'keeps prior ok steps when a later step fails (partial status)',
      () async {
        final client = createMockWriteClient(
          equipItem: (c, args) async {
            if (args.instanceId == 'fail') {
              throw Exception('bungie denied');
            }
          },
        );

        final status = await executeEquipPlan(client, ctx, 'char-a', const [
          PlannedEquipStep(
            id: 'transfer-helmet',
            kind: EquipStepKind.transfer,
            itemHash: 10,
            instanceId: 'ok',
            transferToVault: false,
          ),
          PlannedEquipStep(
            id: 'equip-helmet',
            kind: EquipStepKind.equip,
            itemHash: 10,
            instanceId: 'fail',
          ),
          PlannedEquipStep(
            id: 'equip-arms',
            kind: EquipStepKind.equip,
            itemHash: 11,
            instanceId: 'ok2',
          ),
        ]);

        expect(status.steps[0].ok, isTrue);
        expect(status.steps[1].ok, isFalse);
        expect(status.steps[1].error, contains('bungie denied'));
        expect(status.steps[2].ok, isTrue);
        expect(status.completed, 2);
        expect(status.failed, 1);
        // No compensating reverse transfer — only the three planned steps.
        expect(status.steps.length, 3);
      },
    );

    test('continues after missing transfer fields fail a step', () async {
      final client = createMockWriteClient();
      final status = await executeEquipPlan(client, ctx, 'char-a', const [
        PlannedEquipStep(
          id: 'bad-transfer',
          kind: EquipStepKind.transfer,
          // missing instanceId / itemHash / transferToVault
        ),
        PlannedEquipStep(
          id: 'equip-arms',
          kind: EquipStepKind.equip,
          itemHash: 11,
          instanceId: 'ok2',
        ),
      ]);

      expect(status.steps[0].ok, isFalse);
      expect(status.steps[1].ok, isTrue);
      expect(status.completed, 1);
      expect(status.failed, 1);
    });
  });
}
