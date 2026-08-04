import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../optimizer/optimizer_candidate_map.dart';

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
///
/// **DART-053:** retains [lastDiagnostics] from the last successful
/// [syncUserInventory] for Settings diagnostics UI (GAP-INV-04).
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
    this.perkIconMapBuilder,
    this.weaponRollMetaLookup,
    this.weaponRollMetaLookupBuilder,
    this.weaponSocketContextBuilder,
    this.listInventoryForSuggestions,
    this.improvementSuggestionsRunner,
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

  /// Production builder: plug hashes → Bungie icon paths (displayProperties.icon).
  final PerkNameMapBuilder? perkIconMapBuilder;

  /// Explicit itemHash → weapon frame/type meta (tests / overrides).
  final Map<int, RollTagWeaponMeta>? weaponRollMetaLookup;

  /// Production builder: weapon meta from OfflineCatalog (DART-051).
  final WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder;

  /// Production builder: weapon socket context for perk-grid plugs (DART-052).
  final WeaponSocketContextBuilder? weaponSocketContextBuilder;

  /// Optional inventory loader for post-sync suggestions (tests inject).
  final Future<List<InventoryItemRecord>> Function(int userId)?
      listInventoryForSuggestions;

  /// Optional suggestion runner (tests inject fixed list / no-op).
  final Future<List<ImprovementSuggestion>> Function({
    required AppDatabase db,
    required int userId,
    required List<CandidatePiece> candidates,
  })? improvementSuggestionsRunner;

  InventorySyncPhase _phase = InventorySyncPhase.idle;
  int? _itemCount;
  int? _syncVersion;
  String? _lastFullSyncAt;
  String? _errorMessage;
  int? _localUserId;
  InventoryParseDiagnostics? _lastDiagnostics;

  /// Soft post-sync better-kit suggestions (DART-067 / BR-OPT-004).
  /// Session-ephemeral — never auto-applied.
  List<ImprovementSuggestion> _postSyncSuggestions = const [];
  bool _loadingSuggestions = false;
  String? _suggestionError;

  InventorySyncPhase get phase => _phase;
  int? get itemCount => _itemCount;
  int? get syncVersion => _syncVersion;
  String? get lastFullSyncAt => _lastFullSyncAt;
  String? get errorMessage => _errorMessage;
  int? get localUserId => _localUserId;

  /// Full parse/resolution diagnostics from last successful [syncNow] (DART-053).
  ///
  /// Session-ephemeral — not reloaded by [refreshStatus] from Drift.
  InventoryParseDiagnostics? get lastDiagnostics => _lastDiagnostics;

  /// Soft better-kit suggestions after sync (DART-067). Empty until sync success.
  List<ImprovementSuggestion> get postSyncSuggestions =>
      List.unmodifiable(_postSyncSuggestions);
  bool get loadingPostSyncSuggestions => _loadingSuggestions;
  String? get postSyncSuggestionError => _suggestionError;

  /// From last successful sync diagnostics (DART-050 / DART-053 UI).
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
      _lastDiagnostics = result.diagnostics;
      _phase = InventorySyncPhase.idle;
      _errorMessage = null;
      notifyListeners();
      // Soft best-effort — never auto-applies kits (BR-OPT-004 / GAP-UI-SETTINGS-04).
      try {
        await fetchPostSyncSuggestions();
      } catch (_) {
        // Suggestions optional; inventory write already succeeded.
      }
      return;
    } on SyncInProgressError catch (e) {
      _phase = InventorySyncPhase.error;
      _errorMessage = e.message;
    } catch (e, st) {
      // Surface real failure without process kill when possible.
      debugPrint('InventorySyncController.syncNow failed: $e\n$st');
      _phase = InventorySyncPhase.error;
      _errorMessage = _safeErrorMessage(e);
    }
    notifyListeners();
  }

  /// Soft after-sync scan. **Never mutates** sets — Confirm applies separately.
  Future<void> fetchPostSyncSuggestions() async {
    final userId = _localUserId;
    if (userId == null) {
      _postSyncSuggestions = const [];
      notifyListeners();
      return;
    }
    _loadingSuggestions = true;
    _suggestionError = null;
    notifyListeners();
    try {
      final runner = improvementSuggestionsRunner;
      List<ImprovementSuggestion> suggestions;
      if (runner != null) {
        suggestions = await runner(
          db: _db,
          userId: userId,
          candidates: const [],
        );
      } else {
        final loader = listInventoryForSuggestions ??
            ((uid) => listInventoryItems(_db, uid));
        final items = await loader(userId);
        final candidates = candidatesFromInventory(items: items);
        suggestions = await buildImprovementSuggestions(
          _db,
          userId,
          candidates: candidates,
          afterSync: true,
          hasInventory: items.isNotEmpty,
        );
      }
      _postSyncSuggestions =
          suggestions.where((s) => s.hasImprovement).toList();
      _loadingSuggestions = false;
      _suggestionError = null;
    } catch (e) {
      // Soft suggestions are best-effort; leave banner empty on failure.
      _postSyncSuggestions = const [];
      _loadingSuggestions = false;
      _suggestionError = null;
    }
    notifyListeners();
  }

  /// Dismiss one suggestion without applying (local banner only).
  void dismissPostSyncSuggestion(String armorSetId) {
    _postSyncSuggestions = [
      for (final s in _postSyncSuggestions)
        if (s.armorSetId != armorSetId) s,
    ];
    notifyListeners();
  }

  /// Confirm apply-in-place for a soft suggestion. Explicit only — never auto.
  Future<String?> confirmPostSyncSuggestion(String armorSetId) async {
    final userId = _localUserId;
    if (userId == null) return 'Not signed in';
    ImprovementSuggestion? match;
    for (final s in _postSyncSuggestions) {
      if (s.armorSetId == armorSetId) {
        match = s;
        break;
      }
    }
    if (match == null) return 'Suggestion not found';
    final combo = match.betterCombination;
    if (combo == null) return 'No kit to apply';
    try {
      await applyArmorCombinationInPlace(
        _db,
        userId,
        ApplyArmorCombinationCommand(
          setId: armorSetId,
          pieces: [
            for (final p in combo.pieces)
              MaterializePiece(
                slot: p.slot,
                itemHash: p.itemHash,
                instanceId: p.instanceId,
                itemName: p.itemName,
              ),
          ],
        ),
      );
      dismissPostSyncSuggestion(armorSetId);
      return null;
    } on UseCaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
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
