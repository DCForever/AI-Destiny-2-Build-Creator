import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

void main() {
  test('loading the matrix file leaves it byte-for-byte unchanged', () async {
    final original = await File(_fixturePath()).readAsBytes();
    final dir = await Directory.systemTemp.createTemp('warlock-matrix-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/warlock-matrix.json');
    await file.writeAsBytes(original, flush: true);

    final before = sha256.convert(await file.readAsBytes());
    final loaded = await readOnlyFileBytes(file.path);
    final after = sha256.convert(await file.readAsBytes());

    expect(after.toString(), before.toString());
    expect(loaded, original);
    expect(await file.readAsBytes(), original);
  });

  test('blank path is rejected and a missing file is not created', () async {
    expect(() => readOnlyFileBytes('   '), throwsArgumentError);
    final dir = await Directory.systemTemp.createTemp('warlock-matrix-missing-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/missing-warlock-matrix.json');
    expect(await file.exists(), isFalse);
    expect(
      () => readOnlyFileBytes(file.path),
      throwsA(isA<ReadOnlyFileException>()),
    );
    expect(await file.exists(), isFalse);
  });

  test('matrix path is read from WARLOCK_MATRIX_PATH', () {
    expect(
      warlockMatrixPathFromEnvironment({
        warlockMatrixPathEnv: '  /tmp/matrix.json  ',
      }),
      '/tmp/matrix.json',
    );
    expect(warlockMatrixPathFromEnvironment(const {}), isNull);
    expect(
      warlockMatrixPathFromEnvironment({warlockMatrixPathEnv: '   '}),
      isNull,
    );
  });
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'warlock matrix fixture not found from ${Directory.current.path}',
  );
}
