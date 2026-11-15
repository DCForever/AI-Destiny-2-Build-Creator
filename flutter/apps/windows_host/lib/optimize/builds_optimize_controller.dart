import 'dart:math';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/foundation.dart';

import '../builds_mock/builds_mock_models.dart';
import '../builds_mock/builds_mock_proposed_sets.dart';
import '../optimizer/optimizer_controller.dart' show OptimizeRunner;
import '../optimizer/optimizer_format.dart';
import 'builds_optimize_apply.dart';
import 'builds_optimize_preferred_stats.dart';
import 'weapon_optimize_apply.dart';

/// How Optimize was invoked from Builds detail.
enum BuildsOptimizeMode {
  /// Show results panel; wait for Use this result.
  panel,

  /// Auto-apply combination #1 (Fill In shortcut).
  autoApplyFirst,
}

/// In-process Optimize runner for Builds detail (CSV pool → isolate → confirm).
class BuildsOptimizeController extends ChangeNotifier {
  BuildsOptimizeController({
    this.optimizeRunner,
    this.loadArmorItems,
    this.loadWeaponItems,
    this.optimizeStore,
    this.fillInStore,
    this.guardianClass = GuardianClass.warlock,
    this.setBonusKeyByItemHash = const <int, String>{},
    this.knownSetKeys = const <String>{},
    this.statTargets = const SoftStatTargets(),
  });

  /// Defaults to [optimizeArmorInIsolate].
  final OptimizeRunner? optimizeRunner;

  /// Load DIM armor CSV cache items (armor only). Null → no CSV.
  final Future<List<FillInInventoryItem>?> Function()? loadArmorItems;

  /// Load DIM weapons CSV cache items (weapons only). Null / empty → substitute.
  final Future<List<FillInInventoryItem>?> Function()? loadWeaponItems;

  final OptimizeBuildStore? optimizeStore;
  final FillInMissingListStore? fillInStore;

  GuardianClass guardianClass;
  Map<int, String> setBonusKeyByItemHash;
  Set<String> knownSetKeys;
  SoftStatTargets statTargets;

  bool _running = false;
  bool _applying = false;
  String? _error;
  String? _disabledReason;
  ArmorOptimizeResponse? _response;
  bool _showAll = false;
  int _selectedIndex = 0;
  bool _panelOpen = false;

  MockBuild? _undoBaseline;
  int? _appliedResultIndex;

  /// Prior Fill In plan for this build at apply time (null = absent).
  FillInSavedBuildPlan? _priorFillInPlan;
  bool _priorFillInCaptured = false;

  /// Prior Optimize overlay for this build at apply time (null = absent).
  OptimizedBuildRecord? _priorOptimizeRecord;
  bool _priorOptimizeCaptured = false;

  List<FillInInventoryItem> _armorItems = const [];
  DateTime? _csvImportedAt;

  List<FillInInventoryItem> _weaponItems = const [];
  bool _hasWeaponsCsv = false;
  String? _weaponsCsvReason;
  WeaponOptimizeResponse? _weaponResponse;
  bool _weaponPanelOpen = false;
  int _weaponSelectedIndex = 0;
  MockBuild? _armorAppliedBuild;
  FillInSavedBuildPlan? _planAfterArmor;

  bool get running => _running;
  bool get applying => _applying;
  String? get error => _error;
  String? get disabledReason => _disabledReason;
  bool get panelOpen => _panelOpen;
  bool get showAll => _showAll;
  int get selectedIndex => _selectedIndex;
  ArmorOptimizeResponse? get response => _response;
  List<FillInInventoryItem> get armorItems => _armorItems;
  DateTime? get csvImportedAt => _csvImportedAt;
  int? get appliedResultIndex => _appliedResultIndex;
  bool get canUndo => _undoBaseline != null;

  List<ArmorCombination> get combinations =>
      _response?.combinations ?? const [];

  bool get hasArmorCsv =>
      _disabledReason == null && _armorItems.isNotEmpty;

  List<FillInInventoryItem> get weaponItems => _weaponItems;
  bool get hasWeaponsCsv => _hasWeaponsCsv;
  String? get weaponsCsvReason => _weaponsCsvReason;
  bool get weaponPanelOpen => _weaponPanelOpen;
  int get weaponSelectedIndex => _weaponSelectedIndex;
  List<WeaponOptimizeCombination> get weaponCombinations =>
      _weaponResponse?.combinations ?? const [];
  MockBuild? get armorAppliedBuild => _armorAppliedBuild;

  ArmorPoolCoverageReport? coverageForClass(GuardianClass cls) {
    if (_armorItems.isEmpty) return null;
    return computeArmorPoolSetCoverage(
      items: _armorItems,
      guardianClass: cls,
      knownSetKeys: knownSetKeys,
      setKeyByItemHash: setBonusKeyByItemHash,
    );
  }

  Future<void> refreshArmorCsv() async {
    _error = null;
    final loader = loadArmorItems;
    if (loader == null) {
      _armorItems = const [];
      _disabledReason = kBuildsOptimizeNoCsvReason;
      _csvImportedAt = null;
      notifyListeners();
      return;
    }
    try {
      final items = await loader();
      if (items == null || items.isEmpty) {
        _armorItems = const [];
        _disabledReason = kBuildsOptimizeNoCsvReason;
        _csvImportedAt = null;
      } else {
        _armorItems = List<FillInInventoryItem>.unmodifiable(items);
        _disabledReason = null;
        _csvImportedAt = DateTime.now();
      }
    } catch (e) {
      _armorItems = const [];
      _disabledReason = kBuildsOptimizeNoCsvReason;
      _csvImportedAt = null;
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Refresh Weapons CSV cache (offline only). Empty → substitute path.
  Future<void> refreshWeaponsCsv() async {
    final loader = loadWeaponItems;
    if (loader == null) {
      _weaponItems = const [];
      _hasWeaponsCsv = false;
      _weaponsCsvReason = kWeaponOptimizeNoCsvReason;
      notifyListeners();
      return;
    }
    try {
      final items = await loader();
      if (items == null || items.isEmpty) {
        _weaponItems = const [];
        _hasWeaponsCsv = false;
        _weaponsCsvReason = kWeaponOptimizeNoCsvReason;
      } else {
        _weaponItems = List<FillInInventoryItem>.unmodifiable(items);
        _hasWeaponsCsv = true;
        _weaponsCsvReason = null;
      }
    } catch (e) {
      _weaponItems = const [];
      _hasWeaponsCsv = false;
      _weaponsCsvReason = kWeaponOptimizeNoCsvReason;
      _error = e.toString();
    }
    notifyListeners();
  }

  void setShowAll(bool value) {
    if (_showAll == value) return;
    _showAll = value;
    notifyListeners();
  }

  void selectResult(int index) {
    if (index < 0 || index >= combinations.length) return;
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void selectWeaponResult(int index) {
    if (index < 0 || index >= weaponCombinations.length) return;
    if (_weaponSelectedIndex == index) return;
    _weaponSelectedIndex = index;
    notifyListeners();
  }

  void closePanel() {
    if (!_panelOpen && _response == null) return;
    _panelOpen = false;
    _response = null;
    _selectedIndex = 0;
    _showAll = false;
    _error = null;
    notifyListeners();
  }

  void closeWeaponPanel() {
    if (!_weaponPanelOpen && _weaponResponse == null) return;
    _weaponPanelOpen = false;
    _weaponResponse = null;
    _weaponSelectedIndex = 0;
    _armorAppliedBuild = null;
    _planAfterArmor = null;
    notifyListeners();
  }

  /// Run optimizer for [build]. Panel mode shows results; auto mode applies #1.
  ///
  /// [fillInPlan] supplies Fill In `proposed`/`filled` armor rows when the
  /// build has no [MockBuild.setBonuses] yet (proposed-set goals).
  Future<MockBuild?> runOptimize({
    required MockBuild build,
    required BuildsOptimizeMode mode,
    FillInSavedBuildPlan? fillInPlan,
  }) async {
    if (_running || _applying) return null;
    if (_disabledReason != null || _armorItems.isEmpty) {
      _error = _disabledReason ?? kBuildsOptimizeNoCsvReason;
      notifyListeners();
      return null;
    }

    _running = true;
    _error = null;
    _response = null;
    _panelOpen = mode == BuildsOptimizeMode.panel;
    notifyListeners();

    try {
      final candidates = candidatesFromDimArmorItems(
        items: _armorItems,
        guardianClass: guardianClass,
        setBonusKeyByItemHash: setBonusKeyByItemHash,
      );
      // Proposed sets (4pc or 2+2) → hard KitConstraints.setBonusGoals.
      final setGoals = proposedSetBonusGoalsFor(
        build: build,
        plan: fillInPlan,
        armorItems: _armorItems,
        setBonusKeyByItemHash: setBonusKeyByItemHash,
      );
      // Preferred / inferred stats from the build detail row (soft closeness).
      // Controller [statTargets] remain a manual override when non-empty.
      final preferred = statTargets.values.isNotEmpty
          ? BuildsOptimizePreferredStats(
              targets: {
                for (final e in statTargets.values.entries)
                  if (e.value > 0) e.key: e.value,
              },
              priorities: [
                for (final e in statTargets.values.entries)
                  if (e.value > 0) e.key,
              ],
            )
          : preferredStatTargetsFromBuild(build);
      final request = ArmorOptimizeRequest(
        candidates: candidates,
        constraints: KitConstraints(
          setBonusGoals: setGoals.isEmpty ? null : setGoals,
        ),
        statPriorities: preferred.priorities,
        // Soft guidance only — closeness re-rank below; never hard-filter.
        statThresholds: preferred.targets.isEmpty ? null : preferred.targets,
        requireThresholds: false,
        preferReuse: true,
        maxResults: kOptimizerDefaultMaxResults,
        classType: guardianClass.wireName,
        hasInventory: candidates.isNotEmpty,
      );
      final runner = optimizeRunner ?? optimizeArmorInIsolate;
      var response = await runner(request);
      // Existing domain order: setBonusGoals already constrained kits; then
      // lexicographic maximize on priorities. Re-rank by distance to preferred
      // targets so high/good prefs win without pushing low/very-low stats up.
      if (preferred.targets.isNotEmpty && response.combinations.length > 1) {
        final ranked = rankCombinationsByPreferredStatCloseness(
          combinations: response.combinations,
          targets: preferred.targets,
        );
        response = ArmorOptimizeResponse(
          combinations: ranked,
          truncated: response.truncated,
          evaluatedCount: response.evaluatedCount,
          emptyReason: response.emptyReason,
          seed: response.seed,
        );
      }
      _response = response;
      _running = false;

      if (response.combinations.isEmpty) {
        _error = response.emptyReason != null
            ? formatOptimizerEmptyReason(response.emptyReason!)
            : 'No kits found';
        notifyListeners();
        return null;
      }

      _selectedIndex = 0;
      notifyListeners();

      if (mode == BuildsOptimizeMode.autoApplyFirst) {
        return applySelectedResult(build: build, index: 0);
      }
      return null;
    } catch (e) {
      _running = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Confirm Use this result / auto-apply. Returns updated build or null.
  Future<MockBuild?> applySelectedResult({
    required MockBuild build,
    int? index,
  }) async {
    final i = index ?? _selectedIndex;
    final combos = combinations;
    if (i < 0 || i >= combos.length) {
      _error = 'Invalid suggestion index';
      notifyListeners();
      return null;
    }
    if (_applying) return null;
    _applying = true;
    _error = null;
    notifyListeners();

    try {
      final combo = combos[i];
      final next = applyOptimizeCombinationToBuild(
        build: build,
        combination: combo,
        resultIndexOneBased: i + 1,
      );

      final optStore = optimizeStore;
      final fiStore = fillInStore;

      // Snapshot prior file records BEFORE any write (Undo restores files).
      // Load both into locals first: if the second load fails, an earlier
      // undoable apply's priors + baseline stay intact (never half-updated).
      // Assign all four fields + baseline + applied index together only after
      // both loads succeed — a failed apply must not highlight the result.
      final loadedFillIn =
          fiStore == null ? null : await fiStore.loadForBuild(build.id);
      final loadedOptimize =
          optStore == null ? null : await optStore.loadForBuild(build.id);
      _priorFillInPlan = loadedFillIn;
      _priorFillInCaptured = fiStore != null;
      _priorOptimizeRecord = loadedOptimize;
      _priorOptimizeCaptured = optStore != null;
      _undoBaseline = snapshotMockBuild(build);
      _appliedResultIndex = i + 1;

      if (optStore != null) {
        await optStore.saveBuildRecord(
          optimizedRecordFromBuild(
            build: next,
            resultIndexOneBased: i + 1,
          ),
        );
      }
      final mergedPlan = fillInPlanFromCombination(
        buildId: build.id,
        combination: combo,
        existing: _priorFillInPlan,
      );
      if (fiStore != null) {
        await fiStore.saveBuildPlan(mergedPlan);
      }

      _applying = false;
      _panelOpen = false;
      _armorAppliedBuild = next;
      _planAfterArmor = mergedPlan;
      notifyListeners();
      return next;
    } catch (e) {
      _applying = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Rank weapons after armor confirm/apply. Opens the weapons results panel.
  ///
  /// When Weapons CSV is missing, returns a single substitute combination
  /// (never labeled optimized) from [cachedInventory] when provided.
  Future<WeaponOptimizeResponse?> prepareWeaponResults({
    required MockBuild build,
    FillInSavedBuildPlan? existingPlan,
    List<FillInInventoryItem>? cachedInventory,
    Random? random,
    bool openPanel = true,
  }) async {
    if (_weaponItems.isEmpty && loadWeaponItems != null) {
      await refreshWeaponsCsv();
    }
    var inventory = List<FillInInventoryItem>.from(_weaponItems);
    final hasCsv = _hasWeaponsCsv && inventory.isNotEmpty;
    if (!hasCsv && cachedInventory != null) {
      // No Weapons CSV import — substitute from offline cached inventory only.
      inventory = [
        for (final item in cachedInventory)
          if (item.slot == EquipmentSlot.primary ||
              item.slot == EquipmentSlot.special ||
              item.slot == EquipmentSlot.heavy)
            item,
      ];
    }
    final plan = existingPlan ?? _planAfterArmor;
    final response = runWeaponOptimizeForBuild(
      build: build,
      weaponInventory: inventory,
      hasWeaponsCsv: hasCsv,
      plan: plan,
      random: random,
    );
    _weaponResponse = response;
    _weaponSelectedIndex = 0;
    _armorAppliedBuild = build;
    _planAfterArmor = plan;
    if (response.combinations.isEmpty && !hasCsv) {
      // Never leave blank weapon slots silently when the substitute pool is empty.
      _weaponsCsvReason = kWeaponOptimizeEmptySubstitutePoolReason;
      _error = kWeaponOptimizeEmptySubstitutePoolReason;
    }
    _weaponPanelOpen =
        openPanel && response.combinations.isNotEmpty;
    notifyListeners();
    return response;
  }

  /// Apply the selected weapons result (same Undo baseline as armor).
  ///
  /// Substitute kits persist as Fill In proposed pins — never as optimized.
  Future<MockBuild?> applySelectedWeaponResult({
    required MockBuild build,
    int? index,
    FillInSavedBuildPlan? existingPlan,
  }) async {
    final i = index ?? _weaponSelectedIndex;
    final combos = weaponCombinations;
    if (i < 0 || i >= combos.length) {
      _error = 'Invalid weapon suggestion index';
      notifyListeners();
      return null;
    }
    if (_applying) return null;
    _applying = true;
    _error = null;
    notifyListeners();

    try {
      final combo = combos[i];
      // Never persist a substitute as optimized.
      if (combo.isSubstitute && combo.isOptimized) {
        _applying = false;
        _error = 'Substitute kit cannot be marked optimized';
        notifyListeners();
        return null;
      }
      final merged = applyWeaponOptimizeCombination(
        build: build,
        combination: combo,
        existingPlan: existingPlan ?? _planAfterArmor,
      );
      final persistOk = await persistMergedFillInPlan(merged.plan);
      if (!persistOk) {
        _applying = false;
        notifyListeners();
        return null;
      }
      _weaponPanelOpen = false;
      _weaponResponse = null;
      _weaponSelectedIndex = 0;
      _applying = false;
      notifyListeners();
      return merged.build;
    } catch (e) {
      _applying = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Persist a Fill In plan merged after weapon Fill In (same Undo snapshot).
  ///
  /// Does not refresh the Undo baseline — Undo still restores the pre-Optimize
  /// Fill In + optimize file snapshots captured in [applySelectedResult].
  ///
  /// Returns false when save fails; sets [error] so the host can show a toast
  /// instead of an uncaught async error.
  Future<bool> persistMergedFillInPlan(FillInSavedBuildPlan plan) async {
    final fiStore = fillInStore;
    if (fiStore == null) return true;
    try {
      await fiStore.saveBuildPlan(plan);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Undo last Optimize apply. Restores memory + both store files.
  Future<MockBuild?> undoLastApply() async {
    final baseline = _undoBaseline;
    if (baseline == null) return null;
    if (_applying) return null;
    _applying = true;
    notifyListeners();
    try {
      final restored = undoOptimizeOnBuild(baseline);

      final optStore = optimizeStore;
      if (optStore != null && _priorOptimizeCaptured) {
        final prior = _priorOptimizeRecord;
        if (prior != null) {
          // Restore earlier Optimize record — never clear it away.
          await optStore.saveBuildRecord(prior);
        } else {
          await optStore.clearBuild(baseline.id);
        }
      }

      final fiStore = fillInStore;
      if (fiStore != null && _priorFillInCaptured) {
        final prior = _priorFillInPlan;
        if (prior != null) {
          await fiStore.saveBuildPlan(prior);
        } else {
          await fiStore.clearBuild(baseline.id);
        }
      }

      _undoBaseline = null;
      _appliedResultIndex = null;
      _priorFillInPlan = null;
      _priorFillInCaptured = false;
      _priorOptimizeRecord = null;
      _priorOptimizeCaptured = false;
      _weaponPanelOpen = false;
      _weaponResponse = null;
      _weaponSelectedIndex = 0;
      _armorAppliedBuild = null;
      _planAfterArmor = null;
      _applying = false;
      notifyListeners();
      return restored;
    } catch (e) {
      _applying = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
