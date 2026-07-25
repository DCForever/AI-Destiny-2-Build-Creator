import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/foundation.dart';

import '../auth/windows_oauth_session.dart';

/// Phase for Windows In-Game Loadouts surface (DART-055).
enum LoadoutsPhase {
  idle,
  loading,
  error,
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
  })  : _session = session,
        _profileClient = profileClient,
        _presentationTables = presentationTables,
        _presentationTablesLoader = presentationTablesLoader;

  final WindowsOAuthSession _session;
  final BungieProfileClient _profileClient;
  LoadoutPresentationTables? _presentationTables;
  final Future<LoadoutPresentationTables> Function()?
      _presentationTablesLoader;

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
      _all = parseCharacterLoadoutsResponse(
        profile,
        resolvedCharacters,
        tables: tables,
      );
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
}
