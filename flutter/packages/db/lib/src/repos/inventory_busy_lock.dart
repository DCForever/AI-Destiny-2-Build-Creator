import 'dart:async';

/// In-process exclusive gate for inventory full-replace (DART-016 busy lock hook).
///
/// Mirrors product `syncLocks` / `SyncInProgressError` intent from
/// `src/lib/bungie/syncInventory.ts` without network. Per-isolate only — not a
/// durable SQLite lock table.

/// Thrown when an exclusive inventory replace is already in flight for a user.
class InventoryReplaceBusyException implements Exception {
  InventoryReplaceBusyException(this.userId);

  final int userId;

  @override
  String toString() =>
      'InventoryReplaceBusyException: inventory replace already in progress '
      'for user $userId';
}

/// Per-user exclusive lock for full-replace operations.
class InventoryBusyLock {
  final Map<int, Completer<void>> _inFlight = {};

  /// Whether [userId] currently holds an exclusive replace.
  bool isBusy(int userId) => _inFlight.containsKey(userId);

  /// Runs [body] exclusively for [userId].
  ///
  /// Throws [InventoryReplaceBusyException] if already busy for that user.
  Future<T> runExclusive<T>(
    int userId,
    Future<T> Function() body,
  ) async {
    if (_inFlight.containsKey(userId)) {
      throw InventoryReplaceBusyException(userId);
    }

    final gate = Completer<void>();
    _inFlight[userId] = gate;

    try {
      return await body();
    } finally {
      _inFlight.remove(userId);
      if (!gate.isCompleted) {
        gate.complete();
      }
    }
  }

  /// Test helper: drop all held locks.
  void clearForTests() {
    for (final c in _inFlight.values) {
      if (!c.isCompleted) {
        c.complete();
      }
    }
    _inFlight.clear();
  }
}

/// Default shared lock for hosts that do not inject their own instance.
final InventoryBusyLock defaultInventoryBusyLock = InventoryBusyLock();
