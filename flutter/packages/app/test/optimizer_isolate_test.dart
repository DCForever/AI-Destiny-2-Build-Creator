import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

CandidatePiece piece({
  required EquipmentSlot slot,
  required int itemHash,
  required String instanceId,
  Map<ArmorStatName, int>? stats,
}) {
  return CandidatePiece(
    slot: slot,
    itemHash: itemHash,
    instanceId: instanceId,
    isExotic: false,
    statValues: stats ??
        const {
          ArmorStatName.health: 10,
          ArmorStatName.melee: 10,
          ArmorStatName.grenade: 10,
          ArmorStatName.superStat: 10,
          ArmorStatName.classStat: 10,
          ArmorStatName.weapons: 10,
        },
  );
}

ArmorOptimizeRequest sampleRequest() {
  return ArmorOptimizeRequest(
    candidates: [
      piece(slot: EquipmentSlot.helmet, itemHash: 1, instanceId: 'h1'),
      piece(slot: EquipmentSlot.helmet, itemHash: 11, instanceId: 'h2'),
      piece(slot: EquipmentSlot.arms, itemHash: 2, instanceId: 'a1'),
      piece(slot: EquipmentSlot.chest, itemHash: 3, instanceId: 'c1'),
      piece(slot: EquipmentSlot.legs, itemHash: 4, instanceId: 'l1'),
      piece(slot: EquipmentSlot.classItem, itemHash: 5, instanceId: 'ci1'),
    ],
    maxResults: 10,
    classType: 'Warlock',
  );
}

void main() {
  group('US2 optimizer isolate', () {
    test('local runner matches pure core', () {
      final request = sampleRequest();
      final local = optimizeArmorLocal(request);
      final core = optimizeArmorCore(request);
      expect(local.combinations.length, core.combinations.length);
      expect(local.evaluatedCount, core.evaluatedCount);
      expect(local.truncated, core.truncated);
      expect(
        local.combinations.map((c) => c.score).toList(),
        core.combinations.map((c) => c.score).toList(),
      );
    });

    test('isolate runner matches local', () async {
      final request = sampleRequest();
      final local = optimizeArmorLocal(request);
      final remote = await optimizeArmorInIsolate(request);
      expect(remote.combinations.length, local.combinations.length);
      expect(remote.evaluatedCount, local.evaluatedCount);
      expect(remote.truncated, local.truncated);
      expect(
        remote.combinations.map((c) => c.score).toList(),
        local.combinations.map((c) => c.score).toList(),
      );
      expect(
        remote.combinations.first.pieces.map((p) => p.instanceId).toSet(),
        local.combinations.first.pieces.map((p) => p.instanceId).toSet(),
      );
    });

    test('request encode/decode round-trip', () {
      final request = sampleRequest();
      final again = decodeArmorOptimizeRequest(
        encodeArmorOptimizeRequest(request),
      );
      expect(again.candidates.length, request.candidates.length);
      expect(again.maxResults, request.maxResults);
      expect(again.classType, 'Warlock');
    });
  });
}
