import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late StorageRoot root;
  late FillInMissingListStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fill_in_missing_');
    root = StorageRoot(basePath: temp.path);
    await root.ensureLayout();
    store = FillInMissingListStore(root: root);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  test('save upserts one build without deleting another', () async {
    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'b01',
        missing: <String>['Helmet'],
      ),
    );
    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'b02',
        missing: <String>['Gauntlets', 'Sunshot'],
        similarWeaponName: 'Zaouli\'s Bane',
        similarForName: 'Sunshot',
      ),
    );
    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'b01',
        missing: <String>['Helmet', 'Legs'],
      ),
    );

    final b01 = await store.loadForBuild('b01');
    final b02 = await store.loadForBuild('b02');
    expect(b01!.missing, <String>['Helmet', 'Legs']);
    expect(b02!.missing, <String>['Gauntlets', 'Sunshot']);
    expect(b02.similarWeaponName, "Zaouli's Bane");
    expect(File(store.storePath).existsSync(), isTrue);
    expect(File('${store.storePath}.tmp').existsSync(), isFalse);
  });

  test('schema bump backs up prior file with exclusive-create', () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    await File(path).writeAsString(
      jsonEncode(<String, dynamic>{
        'schemaVersion': 0,
        'builds': <String, dynamic>{
          'old': <String, dynamic>{
            'missing': <String>['Chest'],
          },
        },
      }),
    );

    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'new',
        missing: <String>['Arms'],
      ),
    );

    final backups = Directory(root.fillInCacheDir)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('missing_by_build.json.bak-'))
        .toList();
    expect(backups, hasLength(1));
    final bakText = await backups.single.readAsString();
    expect(bakText, contains('"schemaVersion":0'));
    expect(bakText, contains('"old"'));

    final all = await store.loadAll();
    expect(all.keys, containsAll(<String>['old', 'new']));
    final decoded = jsonDecode(await File(path).readAsString())
        as Map<String, dynamic>;
    expect(decoded['schemaVersion'], kFillInMissingListSchemaVersion);
  });

  test('missing schemaVersion is treated as unknown and backed up before save',
      () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    final prior = jsonEncode(<String, dynamic>{
      'builds': <String, dynamic>{
        'legacy': <String, dynamic>{
          'missing': <String>['Helmet'],
        },
      },
    });
    await File(path).writeAsString(prior);

    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'fresh',
        missing: <String>['Arms'],
      ),
    );

    final backups = Directory(root.fillInCacheDir)
        .listSync()
        .whereType<File>()
        .where(
          (f) => p.basename(f.path).startsWith(
                'missing_by_build.json.bak-vunknown-',
              ),
        )
        .toList();
    expect(backups, hasLength(1));
    expect(await backups.single.readAsString(), prior);

    final decoded = jsonDecode(await File(path).readAsString())
        as Map<String, dynamic>;
    expect(decoded['schemaVersion'], kFillInMissingListSchemaVersion);
    final builds = decoded['builds'] as Map<String, dynamic>;
    expect(builds.keys, containsAll(<String>['legacy', 'fresh']));
  });

  test('oversize file is rejected before parse and never overwritten', () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    final prior = List<int>.filled(64, 0x41);
    await File(path).writeAsBytes(prior, flush: true);
    final beforeHash = sha256.convert(prior);

    final capped = FillInMissingListStore(root: root, maxBytes: 8);
    await expectLater(
      capped.loadAll(),
      throwsA(
        isA<FillInMissingListStoreException>().having(
          (e) => e.message,
          'message',
          allOf(contains('size limit'), contains('64 > 8')),
        ),
      ),
    );
    await expectLater(
      capped.saveBuildPlan(
        const FillInSavedBuildPlan(
          buildId: 'b01',
          missing: <String>['Helmet'],
        ),
      ),
      throwsA(isA<FillInMissingListStoreException>()),
    );

    final after = await File(path).readAsBytes();
    expect(sha256.convert(after).toString(), beforeHash.toString());
    expect(File('$path.tmp').existsSync(), isFalse);
    expect(
      Directory(root.fillInCacheDir)
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).contains('.bak-'))
          .toList(),
      isEmpty,
    );
  });

  test('non-object builds entries are preserved on save', () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    await File(path).writeAsString(
      jsonEncode(<String, dynamic>{
        'schemaVersion': kFillInMissingListSchemaVersion,
        'builds': <String, dynamic>{
          'ok': <String, dynamic>{
            'missing': <String>['Helmet'],
          },
          'odd': <String>['not', 'an', 'object'],
          'num': 42,
        },
      }),
    );

    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'new',
        missing: <String>['Arms'],
      ),
    );

    final decoded = jsonDecode(await File(path).readAsString())
        as Map<String, dynamic>;
    final builds = decoded['builds'] as Map<String, dynamic>;
    expect(builds['odd'], <String>['not', 'an', 'object']);
    expect(builds['num'], 42);
    expect(
      (builds['ok'] as Map<String, dynamic>)['missing'],
      <String>['Helmet'],
    );
    expect(
      (builds['new'] as Map<String, dynamic>)['missing'],
      <String>['Arms'],
    );
  });

  test('exclusive backup create fails when bak path already exists', () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    final prior = jsonEncode(<String, dynamic>{
      'schemaVersion': 0,
      'builds': <String, dynamic>{
        'old': <String, dynamic>{
          'missing': <String>['Chest'],
        },
      },
    });
    await File(path).writeAsString(prior);
    final beforeHash = sha256.convert(utf8.encode(prior));

    const stamp = 'fixedstamp';
    final taken = File('$path.bak-v0-$stamp');
    await taken.writeAsString('already taken', flush: true);

    final storeFixed = FillInMissingListStore(
      root: root,
      backupStampForTest: stamp,
    );
    await expectLater(
      storeFixed.saveBuildPlan(
        const FillInSavedBuildPlan(
          buildId: 'new',
          missing: <String>['Arms'],
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );

    final after = await File(path).readAsBytes();
    expect(sha256.convert(after).toString(), beforeHash.toString());
    expect(await taken.readAsString(), 'already taken');
    expect(File('$path.tmp').existsSync(), isFalse);
  });

  test('failed rename cleans up .tmp and leaves the original intact', () async {
    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'b01',
        missing: <String>['Helmet'],
      ),
    );
    final path = store.storePath;
    final before = await File(path).readAsBytes();
    final beforeHash = sha256.convert(before);

    final failing = FillInMissingListStore(
      root: root,
      beforeRename: () async {
        throw StateError('simulated rename failure');
      },
    );
    await expectLater(
      failing.saveBuildPlan(
        const FillInSavedBuildPlan(
          buildId: 'b02',
          missing: <String>['Arms'],
        ),
      ),
      throwsA(isA<StateError>()),
    );

    final after = await File(path).readAsBytes();
    expect(sha256.convert(after).toString(), beforeHash.toString());
    expect(File('$path.tmp').existsSync(), isFalse);
    expect(await store.loadForBuild('b02'), isNull);
    expect((await store.loadForBuild('b01'))!.missing, <String>['Helmet']);
  });

  test('loadForBuild returns null when store missing', () async {
    expect(await store.loadForBuild('missing'), isNull);
  });

  test('save/load preserves applied substitutes and clears on undo copy',
      () async {
    await store.saveBuildPlan(
      const FillInSavedBuildPlan(
        buildId: 'b01',
        missing: <String>['Helmet'],
        applied: <FillInAppliedSlot>[
          FillInAppliedSlot(
            slotWire: 'arms',
            label: 'Spare Arms',
            originalLabel: 'Needed Arms',
            instanceId: 'i-arms',
            itemHash: 42,
          ),
        ],
      ),
    );
    final loaded = await store.loadForBuild('b01');
    expect(loaded!.hasAppliedSubstitutes, isTrue);
    expect(loaded.applied.single.label, 'Spare Arms');
    expect(loaded.applied.single.originalLabel, 'Needed Arms');
    expect(loaded.missing, <String>['Helmet']);

    await store.saveBuildPlan(loaded.copyWith(clearApplied: true));
    final undone = await store.loadForBuild('b01');
    expect(undone!.hasAppliedSubstitutes, isFalse);
    expect(undone.missing, <String>['Helmet']);

    final decoded = jsonDecode(await File(store.storePath).readAsString())
        as Map<String, dynamic>;
    expect(decoded['schemaVersion'], kFillInMissingListSchemaVersion);
  });
}
