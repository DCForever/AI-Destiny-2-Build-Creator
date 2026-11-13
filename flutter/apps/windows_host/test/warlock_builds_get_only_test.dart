import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/warlock/warlock_builds_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matrix load wraps the real HttpClient and issues only GET', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final methods = <String>[];
    server.listen((request) async {
      methods.add(request.method);
      request.response.statusCode = 204;
      await request.response.close();
    });

    final bare = HttpClient();
    final guarded = GetOnlyHttpClient(HttpClient());
    addTearDown(() async {
      bare.close(force: true);
      guarded.close(force: true);
      await server.close(force: true);
    });

    expect(guarded.inner, isA<HttpClient>());
    final base = Uri.parse('http://127.0.0.1:${server.port}');
    final posted = await bare.openUrl('POST', base.replace(path: '/probe'));
    await (await posted.close()).drain<void>();
    await _until(() => methods.contains('POST'));
    methods.clear();

    final controller = WarlockBuildsController(
      http: guarded,
      initialPath: _fixturePath(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.error, isNull);
    expect(controller.builds, isNotEmpty);
    expect(methods.where((method) => method != 'GET'), isEmpty);

    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      expect(
        () => guarded.openUrl(method, base.replace(path: '/blocked')),
        throwsA(isA<GetOnlyHttpException>()),
      );
    }
    expect(methods, isEmpty);

    final got = await guarded.getUrl(base.replace(path: '/ok'));
    await (await got.close()).drain<void>();
    await _until(() => methods.contains('GET'));
    expect(methods, ['GET']);
  });

  test('matrix load over maxBytes surfaces a clear size-limit error', () async {
    final dir = await Directory.systemTemp.createTemp('warlock_matrix_cap_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/huge.json')
      ..writeAsBytesSync(List<int>.filled(64, 0x20));

    final controller = WarlockBuildsController(
      http: GetOnlyHttpClient(HttpClient()),
      initialPath: file.path,
      matrixMaxBytes: 8,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.builds, isEmpty);
    expect(controller.error, contains('file exceeds size limit'));
    expect(controller.error, contains('64 > 8'));
  });
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 50; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('timed out waiting for the local HTTP server');
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
