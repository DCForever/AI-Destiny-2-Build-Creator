import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('throttleWaitDuration', () {
    test('honors ThrottleSeconds', () {
      expect(
        throttleWaitDuration(throttleSeconds: 7),
        const Duration(seconds: 7),
      );
    });

    test('caps a single wait at 60s', () {
      expect(
        throttleWaitDuration(throttleSeconds: 120),
        const Duration(seconds: kWriteThrottleMaxWaitSeconds),
      );
      expect(kWriteThrottleMaxWaitSeconds, lessThanOrEqualTo(60));
    });

    test('plain 429 waits 1s', () {
      expect(
        throttleWaitDuration(httpStatus: 429),
        const Duration(seconds: 1),
      );
    });

    test('error 1672 without ThrottleSeconds does not wait', () {
      expect(
        throttleWaitDuration(
          throttleSeconds: null,
          signal: const RateLimitSignal(
            path: '/Destiny2/Actions/Items/TransferItem/',
            source: RateLimitSource.envelope,
            errorCode: kBungieThrottleErrorCode,
          ),
        ),
        isNull,
      );
    });
  });

  group('runWriteWithThrottleBackoff', () {
    test('honors ThrottleSeconds between attempts', () async {
      final waits = <Duration>[];
      var attempts = 0;
      try {
        await runWriteWithThrottleBackoff(
          () async {
            attempts += 1;
            throw const BungiePlatformException(
              'throttled',
              errorCode: kBungieThrottleErrorCode,
              throttleSeconds: 5,
            );
          },
          delay: (d) async => waits.add(d),
        );
        fail('expected throw');
      } on BungiePlatformException catch (e) {
        expect(e.throttleSeconds, 5);
      }
      expect(attempts, kWriteThrottleMaxAttempts);
      expect(waits, [
        const Duration(seconds: 5),
        const Duration(seconds: 5),
      ]);
    });

    test('plain 429 waits 1s and stops at 3 attempts', () async {
      final waits = <Duration>[];
      var attempts = 0;
      try {
        await runWriteWithThrottleBackoff(
          () async {
            attempts += 1;
            throw const BungieHttpException(
              'too many',
              statusCode: 429,
            );
          },
          delay: (d) async => waits.add(d),
        );
        fail('expected throw');
      } on BungieHttpException catch (e) {
        expect(e.statusCode, 429);
      }
      expect(attempts, 3);
      expect(waits, [
        const Duration(seconds: 1),
        const Duration(seconds: 1),
      ]);
    });

    test('error 1672 without ThrottleSeconds does not retry', () async {
      final waits = <Duration>[];
      var attempts = 0;
      try {
        await runWriteWithThrottleBackoff(
          () async {
            attempts += 1;
            throw const BungiePlatformException(
              'throttled',
              errorCode: kBungieThrottleErrorCode,
              throttleSeconds: 0,
              rateLimitSignal: RateLimitSignal(
                path: '/x',
                source: RateLimitSource.envelope,
                errorCode: kBungieThrottleErrorCode,
              ),
            );
          },
          delay: (d) async => waits.add(d),
        );
        fail('expected throw');
      } on BungiePlatformException catch (e) {
        expect(e.errorCode, kBungieThrottleErrorCode);
      }
      expect(attempts, 1);
      expect(waits, isEmpty);
    });

    test('caps wait from ThrottleSeconds above 60', () async {
      final waits = <Duration>[];
      var attempts = 0;
      try {
        await runWriteWithThrottleBackoff(
          () async {
            attempts += 1;
            throw const BungiePlatformException(
              'throttled',
              errorCode: kBungieThrottleErrorCode,
              throttleSeconds: 90,
            );
          },
          delay: (d) async => waits.add(d),
          maxAttempts: 2,
        );
        fail('expected throw');
      } on BungiePlatformException {
        // expected
      }
      expect(attempts, 2);
      expect(waits, [const Duration(seconds: 60)]);
    });
  });
}
