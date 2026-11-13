import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/settings/warlock_matrix_path_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/../../packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'warlock_matrix_min.json not found from ${Directory.current.path}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late StorageRoot root;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('warlock_matrix_path_ctrl_');
    root = StorageRoot(basePath: temp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  test('save round-trip persists under StorageRoot settings', () async {
    final controller = WarlockMatrixPathController(
      storageRoot: root,
      environment: const {},
    );
    addTearDown(controller.dispose);

    controller.setPathField(r'D:\matrix\round-trip.json');
    await controller.save();

    expect(controller.savedPath, r'D:\matrix\round-trip.json');
    final reloaded = WarlockMatrixPathController(
      storageRoot: root,
      environment: const {},
    );
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.savedPath, r'D:\matrix\round-trip.json');
    expect(reloaded.pathField, r'D:\matrix\round-trip.json');
  });

  test('resolvedPath prefers saved setting over env', () async {
    final controller = WarlockMatrixPathController(
      storageRoot: root,
      environment: {warlockMatrixPathEnv: r'D:\env.json'},
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.resolvedPath, r'D:\env.json');

    controller.setPathField(r'D:\saved.json');
    await controller.save();
    expect(controller.resolvedPath, r'D:\saved.json');
  });

  test('missing file status', () async {
    final missing = p.join(temp.path, 'missing-matrix.json');
    final controller = WarlockMatrixPathController(
      storageRoot: root,
      environment: const {},
    );
    addTearDown(controller.dispose);

    controller.setPathField(missing);
    await controller.save();

    expect(controller.displayStatus, 'File not found');
    expect(controller.buildCount, isNull);
  });

  test('invalid JSON status', () async {
    final bad = File(p.join(temp.path, 'bad.json'));
    await bad.writeAsString('not-json{', flush: true);

    final controller = WarlockMatrixPathController(
      storageRoot: root,
      environment: const {},
    );
    addTearDown(controller.dispose);

    controller.setPathField(bad.path);
    await controller.save();

    expect(controller.displayStatus.toLowerCase(), contains('not valid json'));
    expect(controller.phase, WarlockMatrixPathPhase.error);
  });

  test('valid fixture reports build count', () async {
    final source = File(_fixturePath());
    final copy = File(p.join(temp.path, 'matrix.json'));
    await copy.writeAsBytes(await source.readAsBytes(), flush: true);

    final controller = WarlockMatrixPathController(
      storageRoot: root,
      environment: const {},
    );
    addTearDown(controller.dispose);

    controller.setPathField(copy.path);
    await controller.save();

    expect(controller.displayStatus, startsWith('File found · '));
    expect(controller.buildCount, greaterThan(0));
    expect(await copy.readAsBytes(), await source.readAsBytes());
  });
}
