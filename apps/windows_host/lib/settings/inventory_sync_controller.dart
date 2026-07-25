import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';

/// High-level phase for Settings inventory sync UI (DART-025).
enum InventorySyncPhase {
  idle,
  loadingStatus,
  syncing,
  error,
}

/// Orchestrates local user ensure + DART-024 [syncUserInventory] for Settings.
///
/// Tokens come from [WindowsOAuthSession] only — never written to SQLite.
/// Soft guidance never auto-applies.
///
/// **DART-050:** production hosts MUST inject [equipmentBucketLookupBuilder]
/// (and/or [equipmentBucketLookup]) so vault/postmaster gear is stored. Empty
/// lookup is test-only.
///
/// **DART-051:** inject [perkNameMapBuilder] + [weaponRollMetaLookupBuilder]
/// (and/or explicit maps) so roll tags match Next `computeRollTags` when data
/// is available. Soft metadata only — never auto-applies.
///
/// **DART-052:** inject [weaponSocketContextBuilder] so stored weapon plugs
/// include `columnKind`/`columnLabel` (Next `buildStoredSocketPlugs` parity).
class InventorySyncController extends ChangeNotifier {
  InventorySyncController({
    required AppDatabase db,
    required WindowsOAuthSession session,
    required BungieProfileClient profileClient,
    InventoryBusyLock? lock,
    DateTime Function()? clock,
    this.equipmentBucketLookup,
    this.equipmentBucketLookupBuilder,
    this.perkNameMap,
    this.perkNameMapBuilder,
    this.weaponRollMetaLookup,
    this.weaponRollMetaLookupBuilder,
    this.weaponSocketContextBuilder,
  })  : _db = db,
        _session = session,
        _profileClient = profileClient,
        _lock = lock,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final WindowsOAuthSession _session;
  final BungieProfileClient _profileClient;
  final InventoryBusyLock? _lock;
  final DateTime Function() _clock;

  /// Explicit itemHash → equipment bucketHash (tests / overrides).
  final Map<int, int>? equipmentBucketLookup;

  /// Production builder: raw DestinyInventoryItemDefinition and/or catalog slots.
  final EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder;

  /// Explicit plugHash → perk display name (tests / overrides).
  final Map<int, String>? perkNameMap;

  /// Production builder: plug names from raw item defs (DART-051).
  final PerkNameMapBuilder? perkNameMapBuilder;

  /// Explicit itemHash → weapon frame/type meta (tests / overrides).
  final Map<int, RollTagWeaponMeta>? weaponRollMetaLookup;

  /// Production builder: weapon meta from OfflineCatalog (DART-051).
  final WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder;

  /// Production builder: weapon socket context for perk-grid plugs (DART-052).
  final WeaponSocketContextBuilder? weaponSocketContextBuilder;

  InventorySyncPhase _phase = InventorySyncPhase.idle;
  int? _itemCount;
  int? _syncVersion;
  String? _lastFullSyncAt;
  String? _errorMessage;
  int? _localUserId;
  int? _lastResolvedFromTransfer;
  int? _lastDroppedNonEquipment;

  InventorySyncPhase get phase => _phase;
  int? get itemCount => _itemCount;
  int? get syncVersion => _syncVersion;
  String? get lastFullSyncAt => _lastFullSyncAt;
  String? get errorMessage => _errorMessage;
  int? get localUserId => _localUserId;

  /// From last successful sync diagnostics (DART-050 / future DART-053 UI).
  int? get lastResolvedFromTransfer => _lastResolvedFromTransfer;
  int? get lastDroppedNonEquipment => _lastDroppedNonEquipment;

  bool get isSyncing => _phase == InventorySyncPhase.syncing;
  bool get isLoadingStatus => _phase == InventorySyncPhase.loadingStatus;
  bool get isSignedIn => _session.isSignedIn;
  bool get canSync => isSignedIn && !isSyncing;

  /// Whether [lastFullSyncAt] is within the 60s equip freshness window.
  bool get isFresh {
    final nowMs = _clock().toUtc().millisecondsSinceEpoch;
    return isInventoryFresh(_lastFullSyncAt, nowMs: nowMs);
  }

  /// Load inventory sync meta for the signed-in user (no network).
  Future<void> refreshStatus() async {
    if (!_session.isSignedIn || _session.tokens == null) {
      _localUserId = null;
      _itemCount = null;
      _syncVersion = null;
      _lastFullSyncAt = null;
      _errorMessage = null;
      _phase = InventorySyncPhase.idle;
      notifyListeners();
      return;
    }

    _phase = InventorySyncPhase.loadingStatus;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _ensureLocalUser();
      _localUserId = user.id;
      final status = await getInventoryStatus(_db, user.id);
      _applyStatus(status);
      _phase = InventorySyncPhase.idle;
    } catch (e) {
      _phase = InventorySyncPhase.error;
      _errorMessage = _safeErrorMessage(e);
    }
    notifyListeners();
  }

  /// Force full inventory replace via DART-024 [syncUserInventory].
  Future<void> syncNow() async {
    if (!_session.isSignedIn || _session.tokens == null) {
      _phase = InventorySyncPhase.error;
      _errorMessage = 'Sign in to sync inventory';
      notifyListeners();
      return;
    }
    if (_phase == InventorySyncPhase.syncing) {
      return;
    }

    final accessToken = _session.tokens!.accessToken;
    if (accessToken.isEmpty) {
      _phase = InventorySyncPhase.error;
      _errorMessage = 'Missing access token';
      notifyListeners();
      return;
    }

    _phase = InventorySyncPhase.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _ensureLocalUser();
      _localUserId = user.id;

      final result = await syncUserInventory(
        db: _db,
        userId: user.id,
        accessToken: accessToken,
        profileClient: _profileClient,
        equipmentBucketLookup: equipmentBucketLookup,
        equipmentBucketLookupBuilder: equipmentBucketLookupBuilder,
        perkNameMap: perkNameMap,
        perkNameMapBuilder: perkNameMapBuilder,
        weaponRollMetaLookup: weaponRollMetaLookup,
        weaponRollMetaLookupBuilder: weaponRollMetaLookupBuilder,
        weaponSocketContextBuilder: weaponSocketContextBuilder,
        lock: _lock,
      );

      _itemCount = result.itemCount;
      _syncVersion = result.syncVersion;
      _lastFullSyncAt = result.lastFullSyncAt;
      _lastResolvedFromTransfer =
          result.diagnostics.resolution?.resolvedFromTransfer;
      _lastDroppedNonEquipment =
          result.diagnostics.resolution?.droppedNonEquipment;
      _phase = InventorySyncPhase.idle;
      _errorMessage = null;
    } on SyncInProgressError catch (e) {
      _phase = InventorySyncPhase.error;
      _errorMessage = e.message;
    } catch (e) {
      _phase = InventorySyncPhase.error;
      _errorMessage = _safeErrorMessage(e);
    }
    notifyListeners();
  }

  Future<User> _ensureLocalUser() async {
    final tokens = _session.tokens;
    if (tokens == null) {
      throw StateError('Not signed in');
    }
    // Product requireUser: ensure by Bungie.net membership id; membership
    // type/display filled/updated during profile sync.
    return ensureUser(
      _db,
      bungieMembershipId: tokens.bungieMembershipId,
      membershipType: 0,
      displayName: '',
    );
  }

  void _applyStatus(InventorySyncStatus? status) {
    if (status == null) {
      _itemCount = null;
      _syncVersion = null;
      _lastFullSyncAt = null;
      return;
    }
    _itemCount = status.itemCount;
    _syncVersion = status.syncVersion;
    _lastFullSyncAt = status.lastFullSyncAt;
  }

  static String _safeErrorMessage(Object e) {
    final text = e.toString();
    if (text.length > 240) {
      return '${text.substring(0, 240)}…';
    }
    return text;
  }
}
