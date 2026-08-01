/// Injectable backends for cross-tab writer election (DART-043).
library;

/// Cross-tab (or simulated) exclusive lock store.
///
/// Implementations must be safe for concurrent [tryAcquire] from multiple
/// logical tabs. Heartbeat expiry allows recovery after crash.
abstract class TabLockBackend {
  /// Attempts to claim exclusive ownership for [ownerId].
  ///
  /// Returns `true` if this owner holds the lock after the call (including
  /// refresh of an existing hold by the same owner).
  Future<bool> tryAcquire(String lockName, String ownerId);

  /// Releases if [ownerId] currently holds [lockName].
  Future<void> release(String lockName, String ownerId);

  /// Whether [ownerId] currently holds [lockName] (and is not expired).
  Future<bool> isHeldBy(String lockName, String ownerId);
}

/// In-memory lock for unit tests and single-isolate simulation of multi-tab.
class MemoryTabLockBackend implements TabLockBackend {
  MemoryTabLockBackend({
    this.ttl = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _clock;

  final Map<String, _LockEntry> _locks = {};

  @override
  Future<bool> tryAcquire(String lockName, String ownerId) async {
    final now = _clock();
    final existing = _locks[lockName];
    if (existing == null || existing.isExpired(now, ttl)) {
      _locks[lockName] = _LockEntry(ownerId, now);
      return true;
    }
    if (existing.ownerId == ownerId) {
      _locks[lockName] = _LockEntry(ownerId, now);
      return true;
    }
    return false;
  }

  @override
  Future<void> release(String lockName, String ownerId) async {
    final existing = _locks[lockName];
    if (existing != null && existing.ownerId == ownerId) {
      _locks.remove(lockName);
    }
  }

  @override
  Future<bool> isHeldBy(String lockName, String ownerId) async {
    final existing = _locks[lockName];
    if (existing == null) return false;
    if (existing.isExpired(_clock(), ttl)) {
      _locks.remove(lockName);
      return false;
    }
    return existing.ownerId == ownerId;
  }

  /// Test helper.
  void clear() => _locks.clear();
}

class _LockEntry {
  _LockEntry(this.ownerId, this.acquiredAt);

  final String ownerId;
  final DateTime acquiredAt;

  bool isExpired(DateTime now, Duration ttl) =>
      now.difference(acquiredAt) > ttl;
}
