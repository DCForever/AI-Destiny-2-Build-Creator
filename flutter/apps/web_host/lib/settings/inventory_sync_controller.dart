/// Inventory sync controller for Jaspr Settings (DART-056).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';

/// High-level phase for web Settings inventory sync UI.
enum InventorySyncPhase {
  idle,
  loadingStatus,
  syncing,
  error,
}

/// Orchestrates local user ensure + [syncUserInventory] for Jaspr Settings.
///
/// Tokens come from [WebOAuthSession] only — never written to SQLite.
/// Soft guidance never auto-applies. No CLIENT_SECRET.
///
/// **DART-056 / DART-050:** production hosts MUST inject
/// [equipmentBucketLookupBuilder] (and/or [equipmentBucketLookup]) so
/// vault/postmaster gear is stored. Empty lookup is test-only.
///
/// **DART-053:** retains [lastDiagnostics] from the last successful
/// [syncNow] for Settings diagnostics UI.
class InventorySyncController extends ChangeNotifier {
  InventorySyncController({
    required AppDatabase db,
    required WebOAuthSession session,
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
  final WebOAuthSession _session;
  final BungieProfileClient _profileClient;
  final InventoryBusyLock? _lock;
  final DateTime Function() _clock;

  /// Explicit itemHash → equipment bucketHash (tests / overrides).
  final Map<int, int>? equipmentBucketLookup;

  /// Production builder: catalog slots (web) and/or raw defs when available.
  final EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder;

  /// Explicit plugHash → perk display name (tests / overrides).
  final Map<int, String>? perkNameMap;

  /// Production builder: plug names (web residual often empty).
  final PerkNameMapBuilder? perkNameMapBuilder;

  /// Explicit itemHash → weapon frame/type meta (tests / overrides).
  final Map<int, RollTagWeaponMeta>? weaponRollMetaLookup;

  /// Production builder: weapon meta from OfflineCatalog.
  final WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder;

  /// Production builder: weapon socket context (web residual without raw).
  final WeaponSocketContextBuilder? weaponSocketContextBuilder;

  InventorySyncPhase _phase = InventorySyncPhase.idle;
  int? _itemCount;
  int? _syncVersion;
  String? _lastFullSyncAt;
  String? _errorMessage;
  int? _localUserId;
  InventoryParseDiagnostics? _lastDiagnostics;

  InventorySyncPhase get phase => _phase;
  int? get itemCount => _itemCount;
  int? get syncVersion => _syncVersion;
  String? get lastFullSyncAt => _lastFullSyncAt;
  String? get errorMessage => _errorMessage;
  int? get localUserId => _localUserId;

  /// Full parse/resolution diagnostics from last successful [syncNow].
  ///
  /// Session-ephemeral — not reloaded by [refreshStatus] from Drift.
  InventoryParseDiagnostics? get lastDiagnostics => _lastDiagnostics;

  int? get lastResolvedFromTransfer =>
      _lastDiagnostics?.resolution?.resolvedFromTransfer;
  int? get lastDroppedNonEquipment =>
      _lastDiagnostics?.resolution?.droppedNonEquipment;
  int? get lastStoredTotal => _lastDiagnostics?.resolution?.storedTotal;
  int? get lastRawTotal => _lastDiagnostics?.raw.total;
  int? get lastParsedTotal => _lastDiagnostics?.parsed.total;
  int? get lastDroppedTotal => _lastDiagnostics?.dropped.total;

  /// Human-readable multi-line diagnostics, or null when none retained.
  String? get lastDiagnosticsFormatted {
    final d = _lastDiagnostics;
    if (d == null) return null;
    return formatSyncDiagnostics(d);
  }

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
      _lastDiagnostics = null;
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

  /// Force full inventory replace via [syncUserInventory].
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
      _lastDiagnostics = result.diagnostics;
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
