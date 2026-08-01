import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

import 'fixtures/raw_tables.dart';

void main() {
  late Directory tmp;
  late FileEntityCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dart-017-adapters-');
    final root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
    cache = FileEntityCache(storageRoot: root);
    await cache.rebuild(
      version: 'adapters-1',
      loadRawTable: loadFixtureRawTable,
      builtAt: DateTime.utc(2026, 7, 24),
    );
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('evaluateSubclassKitFromEntityCache', () {
    test('hard-blocks too many fragments vs aspect capacity', () async {
      final result = await evaluateSubclassKitFromEntityCache(
        cache: cache,
        aspectNames: ['Touch of Thunder', 'Consecration'], // cap 4+2=6
        fragmentNames: List.generate(7, (i) => 'Fragment $i'),
      );
      expect(result.fragmentCapacity, 6);
      expect(result.evaluation.isHardBlocked, isTrue);
      expect(
        result.evaluation.hardBlocks.first.code,
        DomainFailureCodes.illegalSubclassKit,
      );
    });

    test('legal kit within capacity has no hard blocks', () async {
      final result = await evaluateSubclassKitFromEntityCache(
        cache: cache,
        aspectNames: ['Touch of Thunder'], // cap 4
        fragmentNames: ['Spark of Brilliance', 'Echo of Undermining'],
      );
      expect(result.fragmentCapacity, 4);
      expect(result.evaluation.hardBlocks, isEmpty);
    });

    test('unknown aspect leaves capacityResolved false path soft on capacity',
        () async {
      final result = await evaluateSubclassKitFromEntityCache(
        cache: cache,
        aspectNames: ['Not A Real Aspect'],
        fragmentNames: ['A', 'B', 'C'],
      );
      // resolvedCount 0 of 1 → capacityResolved false → no fragment hard block
      expect(result.fragmentCapacity, 0);
      expect(
        result.evaluation.hardBlocks
            .where((b) => b.message.contains('fragments')),
        isEmpty,
      );
    });
  });

  group('evaluateModEnergyFromEntityCache', () {
    test('hard-blocks when energy exceeds capacity', () async {
      // Major Melee cost 3 — stack many on one piece
      final result = await evaluateModEnergyFromEntityCache(
        cache: cache,
        configs: const [
          ModEnergyConfig(
            slot: 'helmet',
            modHashes: [1030, 1030, 1030, 1030], // 12 energy > 10
          ),
        ],
      );
      expect(result.evaluation.isHardBlocked, isTrue);
      expect(
        result.evaluation.hardBlocks.first.code,
        DomainFailureCodes.modEnergyExceeded,
      );
    });

    test('legal mod energy empty hard blocks', () async {
      final result = await evaluateModEnergyFromEntityCache(
        cache: cache,
        configs: const [
          ModEnergyConfig(
            slot: 'helmet',
            modHashes: [1023], // Charged Up cost 1
          ),
        ],
      );
      expect(result.evaluation.hardBlocks, isEmpty);
      expect(result.illegalModMessages, isEmpty);
    });

    test('illegal slot category reported', () async {
      // Minor Health is chest-only; put on helmet
      final result = await evaluateModEnergyFromEntityCache(
        cache: cache,
        configs: const [
          ModEnergyConfig(
            slot: 'helmet',
            modHashes: [1031],
          ),
        ],
      );
      expect(result.hasHardBlocks, isTrue);
      expect(result.illegalModMessages, isNotEmpty);
    });
  });
}
