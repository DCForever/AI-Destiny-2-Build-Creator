/// In-game loadouts controller for Jaspr (DART-055).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';

/// Phase for web In-Game Loadouts surface.
enum LoadoutsPhase {
  idle,
  loading,
  error,
}

/// Loads Bungie in-game loadouts (component 206) for the signed-in web user.
///
/// Soft never auto-applies. No CLIENT_SECRET.
class LoadoutsController extends ChangeNotifier {
  LoadoutsController({
    required WebOAuthSession session,
    required BungieProfileClient profileClient,
    LoadoutPresentationTables presentationTables =
        const LoadoutPresentationTables(),
  })  : _session = session,
        _profileClient = profileClient,
        _presentationTables = presentationTables;

  final WebOAuthSession _session;
  final BungieProfileClient _profileClient;
  final LoadoutPresentationTables _presentationTables;

  LoadoutsPhase _phase = LoadoutsPhase.idle;
  List<BungieInGameLoadout> _all = const [];
  String? _errorMessage;
  String? _hintMessage;
  String? _classFilter;
  bool _hideEmpty = true;
  bool _loadedOnce = false;

  LoadoutsPhase get phase => _phase;
  List<BungieInGameLoadout> get allLoadouts => _all;
  String? get errorMessage => _errorMessage;
  String? get hintMessage => _hintMessage;
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

  Future<void> refresh() async {
    if (!_session.isSignedIn || _session.tokens == null) {
      _all = const [];
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
        _phase = LoadoutsPhase.error;
        _errorMessage = 'No Destiny memberships found for this Bungie account';
        _loadedOnce = true;
        notifyListeners();
        return;
      }

      final membership = memberships.first;
      final profile = await _profileClient.getCharacterLoadoutsProfile(
        accessToken,
        membership,
      );
      final characters = parseCharactersResponse(profile);
      final resolvedCharacters = characters.isNotEmpty
          ? characters
          : await _profileClient.getCharacters(accessToken, membership);

      _all = parseCharacterLoadoutsResponse(
        profile,
        resolvedCharacters,
        tables: _presentationTables,
      );
      _phase = LoadoutsPhase.idle;
      if (_all.isEmpty) {
        _hintMessage =
            'No in-game loadouts returned. Equip a loadout in Destiny or turn '
            'off “Hiding empty”.';
      }
    } catch (e) {
      _phase = LoadoutsPhase.error;
      _errorMessage = e.toString();
      _hintMessage =
          'Could not load Bungie in-game loadouts. Manifest presentation tables '
          'are optional on web (fallback names).';
    } finally {
      _loadedOnce = true;
      notifyListeners();
    }
  }
}
