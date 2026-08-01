/// Single-tab writer coordinator (DART-043).
library;

import 'tab_lock_backend.dart';
import 'web_db_status.dart';

/// Default lock name for the product app database writer.
const String kWebAppDbWriterLockName = 'destiny2.web.app_db.writer';

/// Coordinates exclusive writer role across logical browser tabs.
class TabWriterCoordinator {
  TabWriterCoordinator({
    required this.backend,
    required this.tabId,
    this.lockName = kWebAppDbWriterLockName,
  });

  final TabLockBackend backend;
  final String tabId;
  final String lockName;

  WebDbRole? _role;

  WebDbRole? get role => _role;

  /// Tries to become writer. Returns the resolved role.
  Future<WebDbRole> acquire() async {
    final ok = await backend.tryAcquire(lockName, tabId);
    _role = ok ? WebDbRole.writer : WebDbRole.blocked;
    return _role!;
  }

  /// Heartbeat / re-assert hold when already writer.
  Future<WebDbRole> refresh() async {
    if (_role == WebDbRole.writer) {
      final ok = await backend.tryAcquire(lockName, tabId);
      if (!ok) {
        _role = WebDbRole.blocked;
      }
      return _role!;
    }
    return acquire();
  }

  /// Releases writer ownership if held.
  Future<void> release() async {
    await backend.release(lockName, tabId);
    _role = null;
  }
}

/// Simple tab id generator (non-crypto; uniqueness per process is enough).
String generateTabId([DateTime Function()? clock]) {
  final now = (clock ?? DateTime.now)().microsecondsSinceEpoch;
  return 'tab-$now';
}
