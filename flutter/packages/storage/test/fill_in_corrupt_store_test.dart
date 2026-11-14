import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late StorageRoot root;
  late FillInMissingListStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fill_in_corrupt_');
    root = StorageRoot(basePath: temp.path);
    await root.ensureLayout();
    store = FillInMissingListStore(root: root);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  test('corrupt JSON throws and save never overwrites', () async {
    final path = root.fillInMissingByBuildPath;
    await Directory(root.fillInCacheDir).create(recursive: true);
    const corrupt = '{not-json';
    await File(path).writeAsString(corrupt);

    await expectLater(
      store.loadAll(),
      throwsA(isA<FillInMissingListStoreException>()),
    );

    await expectLater(
      store.saveBuildPlan(
        const FillInSavedBuildPlan(
          buildId: 'x',
          missing: <String>['Helmet'],
        ),
      ),
      throwsA(isA<FillInMissingListStoreException>()),
    );

    expect(await File(path).readAsString(), corrupt);
  });
}
