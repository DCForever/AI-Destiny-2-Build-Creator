import 'package:flutter/foundation.dart';

import 'builds_mock_fixture.dart';
import 'builds_mock_logic.dart';
import 'builds_mock_models.dart';

enum BuildsMockTab { detail, pool, reoptimize }

/// In-memory UI state for the Builds mock-up (no IO).
class BuildsMockController extends ChangeNotifier {
  BuildsMockController({BuildsMockFixture? fixture})
      : _fixture = fixture ?? loadBuildsMockFixture() {
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

  String _query = '';
  String? _filterExoticArmor;
  String? _filterExoticWeapon;
  String? _filterSubclass;
  String? _filterSetId;
  MockReadiness? _filterReadiness;
  String? _selectedId;
  int _inventoryCap = kMockDefaultInventoryCap;
  BuildsMockTab _tab = BuildsMockTab.detail;
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
  String? get selectedId => _selectedId;

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
