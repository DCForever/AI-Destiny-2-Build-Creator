import 'dart:math';

/// ISO-8601 UTC timestamp provider (injectable for tests).
typedef NowClock = String Function();

/// Opaque id generator (injectable for tests).
typedef IdGenerator = String Function();

/// Default wall-clock now as ISO-8601 UTC with milliseconds.
String defaultNow() => DateTime.now().toUtc().toIso8601String();

final _rng = Random();

/// Default opaque id (timestamp + random hex) — no uuid package dependency.
String defaultNewId() {
  final t = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(16);
  final r = List.generate(4, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  return '$t-$r';
}

/// Sequential id generator for deterministic tests.
IdGenerator sequentialIds([String prefix = 'id']) {
  var n = 0;
  return () => '$prefix-${++n}';
}

/// Fixed clock for tests.
NowClock fixedNow(String iso) => () => iso;
