import 'dart:convert';
import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StorageRoot root;
  late OptimizeBuildStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('optimize_store_');
    root = StorageRoot(basePath: tempDir.path);
    store = OptimizeBuildStore(root: root);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save + load optimized overlay', () async {
    await store.saveBuildRecord(
      const OptimizedBuildRecord(
        buildId: 'b1',
        isOptimized: true,
        resultIndexOneBased: 2,
        slots: [
          OptimizedArmorSlot(
            slotWire: 'helmet',
            pieceName: 'Helm A',
            setId: 'set_a',
            isExotic: false,
            instanceId: 'inst1',
            itemHash: 11,
            statTotal: 64,
          ),
        ],
        stats: [
          OptimizedStatTotal(idWire: 'health', value: 70),
        ],
        setBonuses: [
          OptimizedSetBonus(
            setId: 'set_a',
            setName: 'Set A',
            pieces: 4,
            tier: '4pc',
            text: '4pc Set A',
          ),
        ],
        exoticArmor: 'Solipsism',
      ),
    );
    final loaded = await store.loadForBuild('b1');
    expect(loaded, isNotNull);
    expect(loaded!.isOptimized, isTrue);
    expect(loaded.resultIndexOneBased, 2);
    expect(loaded.slots, hasLength(1));
    expect(loaded.slots.single.pieceName, 'Helm A');
    expect(loaded.stats.single.value, 70);
  });

  test('schema mismatch writes exclusive backup then migrates', () async {
    final path = root.optimizeByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    await File(path).writeAsString(
      jsonEncode({
        'schemaVersion': 0,
        'builds': {
          'old': {
            'isOptimized': true,
            'resultIndex': 1,
            'slots': <dynamic>[],
            'stats': <dynamic>[],
            'setBonuses': <dynamic>[],
          },
        },
      }),
    );
    const stamp = '20261114T000000';
    final migrating = OptimizeBuildStore(
      root: root,
      backupStampForTest: stamp,
    );
    await migrating.saveBuildRecord(
      const OptimizedBuildRecord(
        buildId: 'new',
        isOptimized: true,
        resultIndexOneBased: 1,
        slots: [],
        stats: [],
        setBonuses: [],
      ),
    );
    final backups = Directory(root.fillInCacheDir)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).contains('.bak-'))
        .toList();
    expect(backups, hasLength(1));
    expect(await backups.single.readAsString(), contains('"schemaVersion":0'));
    final decoded =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    expect(decoded['schemaVersion'], kOptimizeBuildSchemaVersion);
    final builds = decoded['builds'] as Map<String, dynamic>;
    expect(builds.containsKey('old'), isTrue);
    expect(builds.containsKey('new'), isTrue);
  });

  test('clearBuild removes one overlay only', () async {
    await store.saveBuildRecord(
      const OptimizedBuildRecord(
        buildId: 'a',
        isOptimized: true,
        resultIndexOneBased: 1,
        slots: [],
        stats: [],
        setBonuses: [],
      ),
    );
    await store.saveBuildRecord(
      const OptimizedBuildRecord(
        buildId: 'b',
        isOptimized: true,
        resultIndexOneBased: 1,
        slots: [],
        stats: [],
        setBonuses: [],
      ),
    );
    await store.clearBuild('a');
    final all = await store.loadAll();
    expect(all.containsKey('a'), isFalse);
    expect(all.containsKey('b'), isTrue);
  });

  test('corrupt JSON throws and save never overwrites', () async {
    final path = root.optimizeByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    const corrupt = '{not-json';
    await File(path).writeAsString(corrupt);

    await expectLater(
      store.loadAll(),
      throwsA(isA<OptimizeBuildStoreException>()),
    );

    await expectLater(
      store.saveBuildRecord(
        const OptimizedBuildRecord(
          buildId: 'x',
          isOptimized: true,
          resultIndexOneBased: 1,
          slots: [],
          stats: [],
          setBonuses: [],
        ),
      ),
      throwsA(isA<OptimizeBuildStoreException>()),
    );

    expect(await File(path).readAsString(), corrupt);
  });
}
