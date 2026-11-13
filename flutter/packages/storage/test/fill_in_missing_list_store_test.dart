import 'dart:convert';
import 'dart:io';

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

  test('loadForBuild returns null when store missing', () async {
    expect(await store.loadForBuild('missing'), isNull);
  });
}
