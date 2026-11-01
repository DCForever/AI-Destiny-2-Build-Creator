import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  test('GET-only wrapper uses a real HttpClient and rejects other methods',
      () async {
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

    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      expect(
        () => guarded.openUrl(method, base.replace(path: '/blocked')),
        throwsA(isA<GetOnlyHttpException>()),
      );
    }
    expect(methods, ['POST']);

    final got = await guarded.getUrl(base.replace(path: '/ok'));
    await (await got.close()).drain<void>();
    await _until(() => methods.contains('GET'));
    expect(methods, ['POST', 'GET']);
  });
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 50; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('timed out waiting for the local HTTP server');
}
