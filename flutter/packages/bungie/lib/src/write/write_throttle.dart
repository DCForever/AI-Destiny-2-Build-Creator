import '../bungie_errors.dart';
import '../rate_limit.dart';

/// Max cooperative retries after throttle / 429 before surfacing the error.
const int kWriteThrottleMaxAttempts = 3;

/// Cap a single backoff wait (Bungie ThrottleSeconds can be large).
const int kWriteThrottleMaxWaitSeconds = 60;

/// Default sleeper (real wall clock). Tests inject a no-op / recorder.
typedef WriteDelay = Future<void> Function(Duration delay);

Future<void> defaultWriteDelay(Duration delay) => Future<void>.delayed(delay);

/// Runs [action] sequentially with backoff when Bungie signals throttle / 429.
///
/// Honors [BungiePlatformException.throttleSeconds] and
/// [BungieHttpException.throttleSeconds] before the next attempt. Caps each
/// wait at [kWriteThrottleMaxWaitSeconds]. ErrorCode 1672 with no positive
/// ThrottleSeconds does not retry. Does not parallelize.
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
      final wait = throttleWaitDuration(
        throttleSeconds: e.throttleSeconds > 0 ? e.throttleSeconds : null,
        signal: e.rateLimitSignal,
      );
      if (wait == null || attempt >= maxAttempts) rethrow;
      await delay(wait);
    } on BungieHttpException catch (e) {
      lastError = e;
      final wait = throttleWaitDuration(
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

/// Resolves cooperative wait for throttle / 429, or null when no retry wait.
Duration? throttleWaitDuration({
  int? throttleSeconds,
  RateLimitSignal? signal,
  int? httpStatus,
}) {
  int? seconds;
  if (throttleSeconds != null && throttleSeconds > 0) {
    seconds = throttleSeconds;
  } else if (signal != null) {
    final suggested = suggestedDelay(signal);
    if (suggested != null) {
      seconds = suggested.inSeconds;
    }
  } else if (httpStatus == 429) {
    seconds = 1;
  }
  if (seconds == null || seconds <= 0) return null;
  final capped = seconds > kWriteThrottleMaxWaitSeconds
      ? kWriteThrottleMaxWaitSeconds
      : seconds;
  return Duration(seconds: capped);
}
