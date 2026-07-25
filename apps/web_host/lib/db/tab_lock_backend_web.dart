/// Browser [TabLockBackend] using localStorage heartbeat (DART-043).
///
/// Pure-JS interop via `dart:html` legacy API is avoided; we use `package:web`
/// + `dart:js_interop` when available. This file is only imported from the
/// client entrypoint (not from VM unit tests that use [MemoryTabLockBackend]).
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'tab_lock_backend.dart';

/// localStorage-backed exclusive lock with TTL heartbeat.
class WebLocalStorageTabLockBackend implements TabLockBackend {
  WebLocalStorageTabLockBackend({
    this.ttl = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _clock;

  String _key(String lockName) => 'destiny2.lock.$lockName';

  @override
  Future<bool> tryAcquire(String lockName, String ownerId) async {
    final storage = web.window.localStorage;
    final key = _key(lockName);
    final now = _clock();
    final raw = storage.getItem(key);

    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final existingOwner = map['ownerId'] as String?;
        final acquiredMs = map['acquiredAtMs'] as int?;
        if (existingOwner != null && acquiredMs != null) {
          final acquiredAt =
              DateTime.fromMillisecondsSinceEpoch(acquiredMs, isUtc: true);
          final expired = now.toUtc().difference(acquiredAt) > ttl;
          if (!expired && existingOwner != ownerId) {
            return false;
          }
        }
      } catch (_) {
        // Corrupt entry — take over.
      }
    }

    final payload = jsonEncode({
      'ownerId': ownerId,
      'acquiredAtMs': now.toUtc().millisecondsSinceEpoch,
    });
    storage.setItem(key, payload);
    return true;
  }

  @override
  Future<void> release(String lockName, String ownerId) async {
    final storage = web.window.localStorage;
    final key = _key(lockName);
    final raw = storage.getItem(key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['ownerId'] == ownerId) {
        storage.removeItem(key);
      }
    } catch (_) {
      storage.removeItem(key);
    }
  }

  @override
  Future<bool> isHeldBy(String lockName, String ownerId) async {
    final storage = web.window.localStorage;
    final key = _key(lockName);
    final raw = storage.getItem(key);
    if (raw == null) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final existingOwner = map['ownerId'] as String?;
      final acquiredMs = map['acquiredAtMs'] as int?;
      if (existingOwner == null || acquiredMs == null) return false;
      final acquiredAt =
          DateTime.fromMillisecondsSinceEpoch(acquiredMs, isUtc: true);
      if (_clock().toUtc().difference(acquiredAt) > ttl) {
        return false;
      }
      return existingOwner == ownerId;
    } catch (_) {
      return false;
    }
  }
}

/// Registers `beforeunload` to best-effort release the writer lock.
void registerWriterLockUnloadHook({
  required TabLockBackend backend,
  required String lockName,
  required String ownerId,
}) {
  web.window.addEventListener(
    'beforeunload',
    ((web.Event _) {
      // Fire-and-forget; browser may kill the tab quickly.
      backend.release(lockName, ownerId);
    }).toJS,
  );
}
