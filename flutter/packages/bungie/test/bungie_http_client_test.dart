import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

String successBody([Object? response]) => jsonEncode({
      'ErrorCode': 1,
      'ErrorStatus': 'Success',
      'Message': 'Ok',
      'ThrottleSeconds': 0,
      'Response': response ?? {'ok': true},
    });

String platformErrorBody({
  int errorCode = 99,
  String message = 'Access Denied',
  int throttleSeconds = 0,
}) =>
    jsonEncode({
      'ErrorCode': errorCode,
      'ErrorStatus': 'Failure',
      'Message': message,
      'ThrottleSeconds': throttleSeconds,
      'Response': null,
    });

void main() {
  group('BungieHttpClient construction', () {
    test('rejects empty API key', () {
      expect(
        () => BungieHttpClient(apiKey: '', transport: _unusedTransport),
        throwsA(isA<BungieConfigException>()),
      );
    });
  });

  group('US1 API key GET/POST', () {
    test('GET sends X-API-Key and Bearer and unwraps Response', () async {
      BungieHttpRequest? seen;
      final client = BungieHttpClient(
        apiKey: 'test-public-key',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(
            statusCode: 200,
            body: successBody(<String, Object?>{'memberships': <Object>[]}),
          );
        },
      );

      final result = await client.getJson(
        '/User/GetMembershipsForCurrentUser/',
        accessToken: 'access-token-1',
      );

      expect(seen, isNotNull);
      expect(seen!.method, 'GET');
      expect(
        seen!.uri.toString(),
        'https://www.bungie.net/Platform/User/GetMembershipsForCurrentUser/',
      );
      expect(seen!.headers['X-API-Key'], 'test-public-key');
      expect(seen!.headers['Authorization'], 'Bearer access-token-1');
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map<String, dynamic>)['memberships'], isEmpty);
    });

    test('POST sends JSON body without Authorization when no token', () async {
      BungieHttpRequest? seen;
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody(0));
        },
      );

      final result = await client.postJson(
        '/Destiny2/Actions/Items/EquipItem/',
        body: {
          'itemId': '1',
          'characterId': '2',
          'membershipType': 3,
        },
      );

      expect(seen!.method, 'POST');
      expect(seen!.headers['X-API-Key'], 'k');
      expect(seen!.headers.containsKey('Authorization'), isFalse);
      expect(seen!.headers['Content-Type'], 'application/json');
      expect(jsonDecode(seen!.body!), {
        'itemId': '1',
        'characterId': '2',
        'membershipType': 3,
      });
      expect(result, 0);
    });

    test('uses defaultAccessToken when call omits token', () async {
      BungieHttpRequest? seen;
      final client = BungieHttpClient(
        apiKey: 'k',
        defaultAccessToken: 'default-tok',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody({}));
        },
      );

      await client.getJson('/User/GetMembershipsForCurrentUser/');
      expect(seen!.headers['Authorization'], 'Bearer default-tok');
    });

    test('absolute URL path is used as-is', () async {
      BungieHttpRequest? seen;
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(statusCode: 200, body: successBody(null));
        },
      );

      await client.getJson('https://example.test/Platform/foo');
      expect(seen!.uri.toString(), 'https://example.test/Platform/foo');
    });
  });

  group('US2 typed errors', () {
    test('HTTP non-2xx throws BungieHttpException', () async {
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async => const BungieHttpResponse(
          statusCode: 503,
          body: 'unavailable',
        ),
      );

      try {
        await client.getJson('/x');
        fail('expected exception');
      } on BungieHttpException catch (e) {
        expect(e.statusCode, 503);
        expect(e.bodySnippet, contains('unavailable'));
        expect(e, isNot(isA<BungiePlatformException>()));
      }
    });

    test('ErrorCode != 1 throws BungiePlatformException', () async {
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: platformErrorBody(errorCode: 99, message: 'Access Denied'),
        ),
      );

      try {
        await client.getJson('/x');
        fail('expected exception');
      } on BungiePlatformException catch (e) {
        expect(e.errorCode, 99);
        expect(e.message, contains('Access Denied'));
        expect(e.throttleSeconds, 0);
      }
    });

    test('invalid JSON throws BungieParseException', () async {
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async => const BungieHttpResponse(
          statusCode: 200,
          body: 'not-json',
        ),
      );

      expect(
        () => client.getJson('/x'),
        throwsA(isA<BungieParseException>()),
      );
    });

    test('non-object JSON throws BungieParseException', () async {
      final client = BungieHttpClient(
        apiKey: 'k',
        transport: (_) async => const BungieHttpResponse(
          statusCode: 200,
          body: '[]',
        ),
      );

      expect(
        () => client.getJson('/x'),
        throwsA(isA<BungieParseException>()),
      );
    });
  });

  group('US3 rate-limit hooks', () {
    test('hook fires on envelope ThrottleSeconds > 0 with platform error',
        () async {
      RateLimitSignal? signal;
      final client = BungieHttpClient(
        apiKey: 'k',
        onRateLimit: (s) => signal = s,
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: platformErrorBody(
            errorCode: 5,
            message: 'Throttled',
            throttleSeconds: 5,
          ),
        ),
      );

      try {
        await client.getJson('/Destiny2/1/Profile/2/');
        fail('expected exception');
      } on BungiePlatformException catch (e) {
        expect(e.throttleSeconds, 5);
        expect(e.rateLimitSignal, isNotNull);
      }

      expect(signal, isNotNull);
      expect(signal!.throttleSeconds, 5);
      expect(signal!.source, RateLimitSource.envelope);
      expect(signal!.path, '/Destiny2/1/Profile/2/');
      expect(suggestedDelay(signal!), const Duration(seconds: 5));
    });

    test('hook fires on HTTP 429 with Retry-After', () async {
      RateLimitSignal? signal;
      final client = BungieHttpClient(
        apiKey: 'k',
        onRateLimit: (s) => signal = s,
        transport: (_) async => const BungieHttpResponse(
          statusCode: 429,
          body: 'slow down',
          headers: {'retry-after': '12'},
        ),
      );

      try {
        await client.postJson('/Destiny2/Actions/Items/TransferItem/');
        fail('expected exception');
      } on BungieHttpException catch (e) {
        expect(e.statusCode, 429);
        expect(e.throttleSeconds, 12);
        expect(e.rateLimitSignal, isNotNull);
      }

      expect(signal, isNotNull);
      expect(signal!.httpStatus, 429);
      expect(signal!.throttleSeconds, 12);
      expect(signal!.source, RateLimitSource.http);
    });

    test('hook fires on throttle ErrorCode even if ThrottleSeconds is 0',
        () async {
      RateLimitSignal? signal;
      final client = BungieHttpClient(
        apiKey: 'k',
        onRateLimit: (s) => signal = s,
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: platformErrorBody(
            errorCode: kBungieThrottleErrorCode,
            message: 'Throttled by game server',
            throttleSeconds: 0,
          ),
        ),
      );

      await expectLater(
        client.getJson('/x'),
        throwsA(isA<BungiePlatformException>()),
      );
      expect(signal, isNotNull);
      expect(signal!.errorCode, kBungieThrottleErrorCode);
    });

    test('hook does not fire on clean success with ThrottleSeconds 0',
        () async {
      var hookCalls = 0;
      final client = BungieHttpClient(
        apiKey: 'k',
        onRateLimit: (_) => hookCalls++,
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: successBody({'a': 1}),
        ),
      );

      await client.getJson('/x');
      expect(hookCalls, 0);
    });
  });

  group('no secrets', () {
    test('public API has no clientSecret surface on client', () {
      final client = BungieHttpClient(
        apiKey: 'public-only',
        transport: _unusedTransport,
      );
      // Reflective sanity: only apiKey field for credentials.
      expect(client.apiKey, 'public-only');
      expect(client.defaultAccessToken, isNull);
    });
  });
}

Future<BungieHttpResponse> _unusedTransport(BungieHttpRequest request) async {
  fail('transport should not be called: ${request.uri}');
}
