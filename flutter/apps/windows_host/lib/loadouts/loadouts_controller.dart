import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';

/// Phase for Windows In-Game Loadouts surface (DART-055).
enum LoadoutsPhase {
  idle,
  loading,
  error,
}

/// Optional exotic enrichment inputs (inventory + catalog).
class LoadoutExoticEnrichment {
  const LoadoutExoticEnrichment({
    required this.instanceIdToHash,
    required this.catalog,
  });

  final Map<String, int> instanceIdToHash;
  final ExoticCatalogIndex catalog;
}

/// Loads Bungie in-game loadouts (component 206) for the signed-in user.
///
/// Soft guidance never auto-applies. Tokens come from [WindowsOAuthSession]
/// only — never written to SQLite. No CLIENT_SECRET.
class LoadoutsController extends ChangeNotifier {
  LoadoutsController({
    required WindowsOAuthSession session,
    required BungieProfileClient profileClient,
    LoadoutPresentationTables? presentationTables,
    Future<LoadoutPresentationTables> Function()? presentationTablesLoader,
    Future<LoadoutExoticEnrichment?> Function()? exoticEnrichment,
  })  : _session = session,
        _profileClient = profileClient,
        _presentationTables = presentationTables,
        _presentationTablesLoader = presentationTablesLoader,
        _exoticEnrichment = exoticEnrichment;

  final WindowsOAuthSession _session;
  final BungieProfileClient _profileClient;
  LoadoutPresentationTables? _presentationTables;
  final Future<LoadoutPresentationTables> Function()?
      _presentationTablesLoader;
  final Future<LoadoutExoticEnrichment?> Function()? _exoticEnrichment;

  LoadoutsPhase _phase = LoadoutsPhase.idle;
  List<BungieInGameLoadout> _all = const [];
  String? _errorMessage;
  String? _hintMessage;
  String? _membershipDisplayName;
  String? _classFilter;
  bool _hideEmpty = true;
  bool _loadedOnce = false;

  LoadoutsPhase get phase => _phase;
  List<BungieInGameLoadout> get allLoadouts => _all;
  String? get errorMessage => _errorMessage;
  String? get hintMessage => _hintMessage;
  String? get membershipDisplayName => _membershipDisplayName;
  String? get classFilter => _classFilter;
  bool get hideEmpty => _hideEmpty;
  bool get isLoading => _phase == LoadoutsPhase.loading;
  bool get isSignedIn => _session.isSignedIn;
  bool get hasLoadedOnce => _loadedOnce;

  List<BungieInGameLoadout> get displayLoadouts => filterInGameLoadouts(
        _all,
        classFilter: _classFilter,
        hideEmpty: _hideEmpty,
      );

  void setClassFilter(String? className) {
    if (_classFilter == className) return;
    _classFilter = className;
    notifyListeners();
  }

  void setHideEmpty(bool value) {
    if (_hideEmpty == value) return;
    _hideEmpty = value;
    notifyListeners();
  }

  /// Load (or reload) in-game loadouts from Bungie profile.
  Future<void> refresh() async {
    if (!_session.isSignedIn || _session.tokens == null) {
      _all = const [];
      _membershipDisplayName = null;
      _errorMessage = null;
      _hintMessage = 'Sign in with Bungie to view your in-game loadout slots.';
      _phase = LoadoutsPhase.idle;
      _loadedOnce = true;
      notifyListeners();
      return;
    }

    final accessToken = _session.tokens!.accessToken;
    if (accessToken.isEmpty) {
      _phase = LoadoutsPhase.error;
      _errorMessage = 'Missing access token';
      _loadedOnce = true;
      notifyListeners();
      return;
    }

    if (_phase == LoadoutsPhase.loading) return;

    _phase = LoadoutsPhase.loading;
    _errorMessage = null;
    _hintMessage = null;
    notifyListeners();

    try {
      final memberships = await _profileClient.getMemberships(accessToken);
      if (memberships.isEmpty) {
        _all = const [];
        _membershipDisplayName = null;
        _phase = LoadoutsPhase.error;
        _errorMessage = 'No Destiny memberships found for this Bungie account';
        _loadedOnce = true;
        notifyListeners();
        return;
      }

      final membership = memberships.first;
      _membershipDisplayName = membership.displayName;

      final profile = await _profileClient.getCharacterLoadoutsProfile(
        accessToken,
        membership,
      );
      final characters = parseCharactersResponse(profile);
      // Prefer characters from the same profile payload; fall back to dedicated call.
      final resolvedCharacters = characters.isNotEmpty
          ? characters
          : await _profileClient.getCharacters(accessToken, membership);

      final tables = await _resolvePresentationTables();
      var list = parseCharacterLoadoutsResponse(
        profile,
        resolvedCharacters,
        tables: tables,
      );

      // Soft best-effort exotic names (GAP-UI-LOADOUTS-02) — never blocks list.
      try {
        final enrich = await _exoticEnrichment?.call();
        if (enrich != null &&
            (enrich.instanceIdToHash.isNotEmpty ||
                enrich.catalog.armorHashes.isNotEmpty ||
                enrich.catalog.weaponHashes.isNotEmpty)) {
          list = enrichLoadoutsWithExotics(
            list,
            instanceIdToHash: enrich.instanceIdToHash,
            catalog: enrich.catalog,
          );
        }
      } catch (_) {
        // keep unenriched list
      }

      _all = list;
      _phase = LoadoutsPhase.idle;
      _errorMessage = null;
      if (_all.isEmpty) {
        _hintMessage =
            'No in-game loadouts returned. Equip a loadout in Destiny or check '
            'that character loadouts are available on this membership.';
      }
    } catch (e) {
      _phase = LoadoutsPhase.error;
      _errorMessage = _safeErrorMessage(e);
      _hintMessage =
          'Could not load Bungie in-game loadouts. Refresh the manifest from '
          'Settings if icons/names are missing.';
    } finally {
      _loadedOnce = true;
      notifyListeners();
    }
  }

  Future<LoadoutPresentationTables> _resolvePresentationTables() async {
    if (_presentationTables != null) return _presentationTables!;
    final loader = _presentationTablesLoader;
    if (loader != null) {
      try {
        final loaded = await loader();
        _presentationTables = loaded;
        return loaded;
      } catch (_) {
        return const LoadoutPresentationTables();
      }
    }
    return const LoadoutPresentationTables();
  }

  String _safeErrorMessage(Object e) {
    final s = e.toString();
    if (s.length > 240) return '${s.substring(0, 240)}…';
    return s;
  }

  /// Build enrichment from local inventory + offline catalog (production path).
  static Future<LoadoutExoticEnrichment?> buildExoticEnrichment({
    required AppDatabase db,
    required OfflineCatalog offlineCatalog,
    required InventorySyncController inventorySync,
  }) async {
    final userId = inventorySync.localUserId;
    Map<String, int> instanceMap = const {};
    if (userId != null) {
      final items = await listInventoryItems(db, userId);
      instanceMap = instanceHashMapFromInventory([
        for (final i in items) (instanceId: i.instanceId, itemHash: i.itemHash),
      ]);
    }

    final armor = <({int hash, String name})>[];
    final weapons = <({int hash, String name})>[];
    for (final item in offlineCatalog.baseItems) {
      if (!item.isExotic) continue;
      final store = item.sourceStore ?? '';
      if (store.contains('armor')) {
        armor.add((hash: item.hash, name: item.name));
      } else if (store.contains('weapon')) {
        weapons.add((hash: item.hash, name: item.name));
      } else {
        // Heuristic: armor slots vs weapon slots when store unknown.
        final slot = (item.slot ?? '').toLowerCase();
        if (slot.contains('helmet') ||
            slot.contains('gauntlet') ||
            slot.contains('chest') ||
            slot.contains('leg') ||
            slot.contains('class')) {
          armor.add((hash: item.hash, name: item.name));
        } else {
          weapons.add((hash: item.hash, name: item.name));
        }
      }
    }

    return LoadoutExoticEnrichment(
      instanceIdToHash: instanceMap,
      catalog: buildExoticCatalogIndex(
        exoticArmor: armor,
        exoticWeapons: weapons,
      ),
    );
  }
}
