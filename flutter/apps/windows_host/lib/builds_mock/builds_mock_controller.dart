import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart';
import 'builds_mock_fixture.dart';
import 'builds_mock_logic.dart';
import 'builds_mock_models.dart';

enum BuildsMockTab { detail, pool, reoptimize }

/// In-memory UI state for the Builds mock-up (no IO).
class BuildsMockController extends ChangeNotifier {
  BuildsMockController({
    BuildsMockFixture? fixture,
    DimLoadoutsPanelStatus dimStatus = DimLoadoutsPanelStatus.notLoaded,
    List<CachedDimLoadout> dimLoadouts = const [],
  })  : _fixture = fixture ?? loadBuildsMockFixture(),
        _dimStatus = dimStatus,
        _dimLoadouts = List<CachedDimLoadout>.unmodifiable(dimLoadouts) {
    _readiness = computeAllReadiness(_fixture);
    if (_fixture.builds.isNotEmpty) {
      _selectedId = _fixture.builds.first.id;
    }
    for (final s in _fixture.swaps) {
      _swapDecisions[s.id] = MockSwapDecision.pending;
    }
  }

  final BuildsMockFixture _fixture;
  late List<MockSetReadiness> _readiness;
  DimLoadoutsPanelStatus _dimStatus;
  List<CachedDimLoadout> _dimLoadouts;

  String _query = '';
  String? _filterExoticArmor;
  String? _filterExoticWeapon;
  String? _filterSubclass;
  String? _filterSetId;
  MockReadiness? _filterReadiness;
  String? _selectedId;
  int _inventoryCap = kMockDefaultInventoryCap;
  BuildsMockTab _tab = BuildsMockTab.detail;
  BuildsMockCardLayout _cardLayout = BuildsMockCardLayout.detail;
  final Map<String, MockSwapDecision> _swapDecisions = {};

  BuildsMockFixture get fixture => _fixture;
  List<MockSetReadiness> get readiness => _readiness;
  String get query => _query;
  String? get filterExoticArmor => _filterExoticArmor;
  String? get filterExoticWeapon => _filterExoticWeapon;
  String? get filterSubclass => _filterSubclass;
  String? get filterSetId => _filterSetId;
  MockReadiness? get filterReadiness => _filterReadiness;
  int get inventoryCap => _inventoryCap;
  BuildsMockTab get tab => _tab;
  BuildsMockCardLayout get cardLayout => _cardLayout;
  String? get selectedId => _selectedId;
  DimLoadoutsPanelStatus get dimStatus => _dimStatus;

  /// Adopt a read-only compiled DIM catalog snapshot (display only; no writes).
  void adoptDimLoadouts({
    required DimLoadoutsPanelStatus status,
    List<CachedDimLoadout> loadouts = const [],
  }) {
    _dimStatus = status;
    _dimLoadouts = List<CachedDimLoadout>.unmodifiable(loadouts);
    notifyListeners();
  }

  /// Match a mock card to a compiled loadout by exotic armor name (casefold).
  CachedDimLoadout? dimLoadoutFor(MockBuild build) {
    if (_dimStatus != DimLoadoutsPanelStatus.loaded) return null;
    final needle = build.exoticArmor.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final row in _dimLoadouts) {
      final exotic = row.exotic?.name.trim().toLowerCase() ?? '';
      if (exotic == needle) return row;
    }
    for (final row in _dimLoadouts) {
      if (row.name.trim().toLowerCase() == build.name.trim().toLowerCase()) {
        return row;
      }
    }
    return null;
  }

  List<MockBuild> get visibleBuilds => filterMockBuilds(
        builds: _fixture.builds,
        query: _query,
        exoticArmor: _filterExoticArmor,
        exoticWeapon: _filterExoticWeapon,
        subclass: _filterSubclass,
        setId: _filterSetId,
        readiness: _filterReadiness,
        readinessRows: _readiness,
      );

  MockBuild? get selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final b in _fixture.builds) {
      if (b.id == id) return b;
    }
    return null;
  }

  MockSwapDecision swapDecision(String id) =>
      _swapDecisions[id] ?? MockSwapDecision.pending;

  List<String> get exoticArmorOptions => _unique(
        [for (final b in _fixture.builds) b.exoticArmor],
      );

  List<String> get exoticWeaponOptions => _unique(
        [for (final b in _fixture.builds) b.exoticWeapon],
      );

  List<String> get subclassOptions => _unique(
        [for (final b in _fixture.builds) b.subclass],
      );

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilterExoticArmor(String? value) {
    _filterExoticArmor = _emptyToNull(value);
    notifyListeners();
  }

  void setFilterExoticWeapon(String? value) {
    _filterExoticWeapon = _emptyToNull(value);
    notifyListeners();
  }

  void setFilterSubclass(String? value) {
    _filterSubclass = _emptyToNull(value);
    notifyListeners();
  }

  void setFilterSetId(String? value) {
    _filterSetId = _emptyToNull(value);
    notifyListeners();
  }

  void setFilterReadiness(MockReadiness? value) {
    _filterReadiness = value;
    notifyListeners();
  }

  void selectBuild(String id) {
    _selectedId = id;
    _tab = BuildsMockTab.detail;
    notifyListeners();
  }

  void setInventoryCap(int value) {
    _inventoryCap = clampInventoryCap(value);
    notifyListeners();
  }

  void setTab(BuildsMockTab tab) {
    _tab = tab;
    notifyListeners();
  }

  void setCardLayout(BuildsMockCardLayout layout) {
    _cardLayout = layout;
    notifyListeners();
  }

  void acceptSwap(String id) {
    _swapDecisions[id] = MockSwapDecision.accepted;
    notifyListeners();
  }

  void rejectSwap(String id) {
    _swapDecisions[id] = MockSwapDecision.rejected;
    notifyListeners();
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  List<String> _unique(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final v in raw) {
      if (seen.add(v)) out.add(v);
    }
    out.sort();
    return out;
  }
}
