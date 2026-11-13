import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart';
import 'builds_mock_fixture.dart';
import 'builds_mock_logic.dart';
import 'builds_mock_matrix.dart';
import 'builds_mock_models.dart';

enum BuildsMockTab { detail, pool, reoptimize }

/// In-memory UI state for the Builds page (no writes).
///
/// Defaults to the synthetic [loadBuildsMockFixture] for tests / previews.
/// Production loads the Warlock matrix via [adoptFixture] after a read-only
/// file parse (never the sample fixture).
class BuildsMockController extends ChangeNotifier {
  BuildsMockController({
    BuildsMockFixture? fixture,
    DimLoadoutsPanelStatus dimStatus = DimLoadoutsPanelStatus.notLoaded,
    List<CachedDimLoadout> dimLoadouts = const [],
    bool showMockBanner = true,
  })  : _fixture = fixture ?? loadBuildsMockFixture(),
        _dimStatus = dimStatus,
        _dimLoadouts = List<CachedDimLoadout>.unmodifiable(dimLoadouts),
        _showMockBanner = showMockBanner {
    _readiness = computeAllReadiness(_fixture);
    if (_fixture.builds.isNotEmpty) {
      _selectedId = _fixture.builds.first.id;
    }
    for (final s in _fixture.swaps) {
      _swapDecisions[s.id] = MockSwapDecision.pending;
    }
  }

  /// Production starting point: empty list until matrix load finishes.
  factory BuildsMockController.forMatrixLoad() {
    return BuildsMockController(
      fixture: emptyBuildsMockFixture(),
      showMockBanner: false,
    );
  }

  BuildsMockFixture _fixture;
  late List<MockSetReadiness> _readiness;
  DimLoadoutsPanelStatus _dimStatus;
  List<CachedDimLoadout> _dimLoadouts;
  bool _showMockBanner;

  String _query = '';
  String? _filterExoticArmor;
  String? _filterExoticWeapon;
  String? _filterSubclass;
  String? _filterSetId;
  MockReadiness? _filterReadiness;
  String? _selectedId;
  int _inventoryCap = kMockDefaultInventoryCap;
  BuildsMockTab _tab = BuildsMockTab.detail;
  BuildsMockCardLayout _cardLayout = BuildsMockCardLayout.grid;
  bool _showingBuildDetail = false;
  final Map<String, MockSwapDecision> _swapDecisions = {};

  String? _matrixError;
  bool _matrixLoading = false;

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
  bool get showingBuildDetail => _showingBuildDetail;
  String? get selectedId => _selectedId;
  DimLoadoutsPanelStatus get dimStatus => _dimStatus;
  bool get showMockBanner => _showMockBanner;
  String? get matrixError => _matrixError;
  bool get matrixLoading => _matrixLoading;

  /// Total loaded builds (Y in "Showing X of Y").
  int get totalBuildCount => _fixture.builds.length;

  /// Visible after search/filters (X in "Showing X of Y").
  int get visibleBuildCount => visibleBuilds.length;

  /// Replace the build list after a read-only matrix parse (display only).
  void adoptFixture(
    BuildsMockFixture fixture, {
    bool showMockBanner = false,
  }) {
    _fixture = fixture;
    _showMockBanner = showMockBanner;
    _matrixError = null;
    _matrixLoading = false;
    _readiness = computeAllReadiness(_fixture);
    _swapDecisions.clear();
    for (final s in _fixture.swaps) {
      _swapDecisions[s.id] = MockSwapDecision.pending;
    }
    if (_fixture.builds.isEmpty) {
      _selectedId = null;
    } else if (_selectedId == null ||
        _fixture.builds.every((b) => b.id != _selectedId)) {
      _selectedId = _fixture.builds.first.id;
    }
    _pruneFilters();
    notifyListeners();
  }

  void beginMatrixLoad() {
    _matrixLoading = true;
    _matrixError = null;
    notifyListeners();
  }

  void failMatrixLoad(String message) {
    _fixture = emptyBuildsMockFixture();
    _showMockBanner = false;
    _matrixLoading = false;
    _matrixError = message;
    _readiness = const [];
    _selectedId = null;
    _swapDecisions.clear();
    _pruneFilters();
    notifyListeners();
  }

  /// Adopt a read-only compiled DIM catalog snapshot (display only; no writes).
  void adoptDimLoadouts({
    required DimLoadoutsPanelStatus status,
    List<CachedDimLoadout> loadouts = const [],
  }) {
    _dimStatus = status;
    _dimLoadouts = List<CachedDimLoadout>.unmodifiable(loadouts);
    notifyListeners();
  }

  /// Resolve DIM link details for a card (shareId → exact name → never exotic).
  DimLoadoutCardBinding dimBindingFor(MockBuild build) {
    if (_dimStatus == DimLoadoutsPanelStatus.unreadable) {
      return const DimLoadoutCardBinding.unreadable();
    }
    if (_dimStatus != DimLoadoutsPanelStatus.loaded) {
      return const DimLoadoutCardBinding.notLoaded();
    }
    final match = matchCachedDimLoadout(
      loadouts: _dimLoadouts,
      dimLink: build.dimLink,
      buildName: build.name,
      exoticName: build.exoticArmor.isNotEmpty
          ? build.exoticArmor
          : build.exoticWeapon,
    );
    switch (match.kind) {
      case CachedDimLoadoutMatchKind.matched:
        return DimLoadoutCardBinding.matched(match.loadout!);
      case CachedDimLoadoutMatchKind.ambiguous:
        return DimLoadoutCardBinding.ambiguous(match.ambiguousCount);
      case CachedDimLoadoutMatchKind.none:
        return const DimLoadoutCardBinding.notLoaded();
    }
  }

  /// Prefer [dimBindingFor]; kept for call sites that only need a matched row.
  CachedDimLoadout? dimLoadoutFor(MockBuild build) {
    return dimBindingFor(build).loadout;
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
        [
          for (final b in _fixture.builds)
            if (b.exoticArmor.isNotEmpty) b.exoticArmor,
        ],
      );

  List<String> get exoticWeaponOptions => _unique(
        [
          for (final b in _fixture.builds)
            if (b.exoticWeapon.isNotEmpty) b.exoticWeapon,
        ],
      );

  List<String> get subclassOptions => _unique(
        [
          for (final b in _fixture.builds)
            if (b.subclass.isNotEmpty) b.subclass,
        ],
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
    notifyListeners();
  }

  /// Open the per-build detail screen (DIM panel + scoped pool / re-optimize).
  void openBuildDetail(String id) {
    _selectedId = id;
    _showingBuildDetail = true;
    _tab = BuildsMockTab.detail;
    notifyListeners();
  }

  void closeBuildDetail() {
    _showingBuildDetail = false;
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
    if (layout == _cardLayout) return;
    _cardLayout = layout;
    notifyListeners();
  }

  /// Top stat priorities for browse cards (DIM ranking when matched, else fixture).
  List<BuildsMockStatPriority> statPrioritiesFor(MockBuild build) {
    final binding = dimBindingFor(build);
    final loadout = binding.loadout;
    if (binding.status == DimLoadoutsPanelStatus.loaded && loadout != null) {
      final ranking = rankDimLoadoutStats(loadout);
      if (ranking.entries.isNotEmpty) {
        return [
          for (final e in ranking.entries.take(3))
            BuildsMockStatPriority(
              label: e.stat.wireName,
              inferred: e.source == DimStatRankingSource.inferred,
            ),
        ];
      }
    }
    if (build.stats.isEmpty) return const [];
    final sorted = [...build.stats]
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final s in sorted.take(3))
        BuildsMockStatPriority(label: s.label),
    ];
  }

  void acceptSwap(String id) {
    _swapDecisions[id] = MockSwapDecision.accepted;
    notifyListeners();
  }

  void rejectSwap(String id) {
    _swapDecisions[id] = MockSwapDecision.rejected;
    notifyListeners();
  }

  void _pruneFilters() {
    if (_filterExoticArmor != null &&
        !exoticArmorOptions.contains(_filterExoticArmor)) {
      _filterExoticArmor = null;
    }
    if (_filterExoticWeapon != null &&
        !exoticWeaponOptions.contains(_filterExoticWeapon)) {
      _filterExoticWeapon = null;
    }
    if (_filterSubclass != null &&
        !subclassOptions.contains(_filterSubclass)) {
      _filterSubclass = null;
    }
    if (_filterSetId != null &&
        _fixture.sets.every((s) => s.id != _filterSetId)) {
      _filterSetId = null;
    }
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
