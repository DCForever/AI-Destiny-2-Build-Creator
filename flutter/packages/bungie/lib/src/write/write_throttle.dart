import '../bungie_errors.dart';
import '../rate_limit.dart';

/// Max cooperative retries after throttle / 429 before surfacing the error.
const int kWriteThrottleMaxAttempts = 3;

/// Default sleeper (real wall clock). Tests inject a no-op / recorder.
typedef WriteDelay = Future<void> Function(Duration delay);

Future<void> defaultWriteDelay(Duration delay) => Future<void>.delayed(delay);

/// Runs [action] sequentially with backoff when Bungie signals throttle / 429.
///
/// Honors [BungiePlatformException.throttleSeconds] and
/// [BungieHttpException.throttleSeconds] before the next attempt. Does not
/// parallelize; callers keep Transfer/Equip ordered.
Future<T> runWriteWithThrottleBackoff<T>(
  Future<T> Function() action, {
  WriteDelay delay = defaultWriteDelay,
  int maxAttempts = kWriteThrottleMaxAttempts,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } on BungiePlatformException catch (e) {
      lastError = e;
      final wait = _throttleWait(
        throttleSeconds: e.throttleSeconds > 0 ? e.throttleSeconds : null,
        signal: e.rateLimitSignal,
      );
      if (wait == null || attempt >= maxAttempts) rethrow;
      await delay(wait);
    } on BungieHttpException catch (e) {
      lastError = e;
      final wait = _throttleWait(
        throttleSeconds: e.throttleSeconds,
        signal: e.rateLimitSignal,
        httpStatus: e.statusCode,
      );
      if (wait == null || attempt >= maxAttempts) rethrow;
      await delay(wait);
    }
  }
  throw lastError ?? StateError('write throttle retry exhausted');
}

Duration? _throttleWait({
  int? throttleSeconds,
  RateLimitSignal? signal,
  int? httpStatus,
}) {
  if (throttleSeconds != null && throttleSeconds > 0) {
    return Duration(seconds: throttleSeconds);
  }
  if (signal != null) {
    final suggested = suggestedDelay(signal);
    if (suggested != null) return suggested;
  }
  if (httpStatus == 429) {
    return const Duration(seconds: 1);
  }
  return null;
}
