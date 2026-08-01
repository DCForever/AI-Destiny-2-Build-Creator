import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/foundation.dart';

import 'optimizer_candidate_map.dart';
import 'optimizer_format.dart';

/// Kind of pending confirm action after a suggestion is chosen.
enum OptimizerConfirmKind {
  applyInPlace,
  materializeNew,
}

/// Pending confirm payload (never executed until [OptimizerController.confirmPending]).
class OptimizerPendingConfirm {
  const OptimizerPendingConfirm({
    required this.kind,
    required this.combination,
    required this.combinationIndex,
    this.materializeName,
  });

  final OptimizerConfirmKind kind;
  final ArmorCombination combination;
  final int combinationIndex;
  final String? materializeName;
}

/// Injectable optimize runner (isolate or local).
typedef OptimizeRunner = Future<ArmorOptimizeResponse> Function(
  ArmorOptimizeRequest request,
);

/// In-process orchestration for Armor optimizer workspace (DART-036).
///
/// **Confirm-only**: [findKits] never writes. Materialize/apply run only via
/// [confirmPending] after [requestApplyInPlace] / [requestMaterialize].
class OptimizerController extends ChangeNotifier {
  OptimizerController({
    required this.db,
    required this.resolveUserId,
    this.optimizeRunner,
    this.listInventory,
    List<CandidatePiece>? initialCandidates,
    bool? initialHasInventory,
  })  : _injectedCandidates = initialCandidates,
        _injectedHasInventory = initialHasInventory;

  final AppDatabase db;
  final Future<int> Function() resolveUserId;

  /// Defaults to [optimizeArmorInIsolate].
  final OptimizeRunner? optimizeRunner;

  /// Optional inventory loader for default candidate board.
  final Future<List<InventoryItemRecord>> Function(int userId)? listInventory;

  List<CandidatePiece>? _injectedCandidates;
  bool? _injectedHasInventory;

  String? _targetSetId;
  String? _targetSetName;

  // Goals draft
  String _lockedExoticText = '';
  bool _preferReuse = false;
  bool _requireThresholds = false;
  final Map<ArmorStatName, String> _thresholdFields = {
    for (final s in ArmorStatName.all) s: '',
  };
  int _maxResults = kOptimizerDefaultMaxResults;

  bool _running = false;
  bool _confirming = false;
  String? _error;
  String? _status;
  ArmorOptimizeResponse? _lastResponse;
  bool _showAllSuggestions = false;
  OptimizerPendingConfirm? _pending;

  // --- Goals getters ---

  String get lockedExoticText => _lockedExoticText;
  bool get preferReuse => _preferReuse;
  bool get requireThresholds => _requireThresholds;
  Map<ArmorStatName, String> get thresholdFields =>
      Map<ArmorStatName, String>.unmodifiable(_thresholdFields);
  int get maxResults => _maxResults;

  bool get running => _running;
  bool get confirming => _confirming;
  String? get error => _error;
  String? get status => _status;
  ArmorOptimizeResponse? get lastResponse => _lastResponse;
  bool get showAllSuggestions => _showAllSuggestions;
  OptimizerPendingConfirm? get pending => _pending;
  String? get targetSetId => _targetSetId;
  String? get targetSetName => _targetSetName;

  List<ArmorCombination> get combinations =>
      _lastResponse?.combinations ?? const [];

  List<ArmorCombination> get visibleCombinations {
    final all = combinations;
    if (_showAllSuggestions) return all;
    return topCompareWindow(all);
  }

  /// Bind workspace to a selected armor set (apply-in-place target).
  void bindTargetSet({required String setId, required String setName}) {
    if (_targetSetId == setId && _targetSetName == setName) return;
    _targetSetId = setId;
    _targetSetName = setName;
    // Clear pending confirm when target changes; keep last suggestions.
    _pending = null;
    notifyListeners();
  }

  void clearTargetSet() {
    _targetSetId = null;
    _targetSetName = null;
    _pending = null;
    notifyListeners();
  }

  /// Inject candidates (tests / host precompute). Null clears injection.
  void setInjectedCandidates(
    List<CandidatePiece>? candidates, {
    bool? hasInventory,
  }) {
    _injectedCandidates = candidates;
    _injectedHasInventory = hasInventory;
  }

  void setLockedExoticText(String value) {
    if (_lockedExoticText == value) return;
    _lockedExoticText = value;
    notifyListeners();
  }

  void setPreferReuse(bool value) {
    if (_preferReuse == value) return;
    _preferReuse = value;
    notifyListeners();
  }

  void setRequireThresholds(bool value) {
    if (_requireThresholds == value) return;
    _requireThresholds = value;
    notifyListeners();
  }

  void setThresholdField(ArmorStatName stat, String value) {
    if (_thresholdFields[stat] == value) return;
    _thresholdFields[stat] = value;
    notifyListeners();
  }

  void setMaxResults(int value) {
    final clamped = value.clamp(1, 50);
    if (_maxResults == clamped) return;
    _maxResults = clamped;
    notifyListeners();
  }

  void setShowAllSuggestions(bool value) {
    if (_showAllSuggestions == value) return;
    _showAllSuggestions = value;
    notifyListeners();
  }

  ArmorOptimizeRequest? _buildRequest(List<CandidatePiece> candidates, bool hasInventory) {
    int? lockedHash;
    final exoticRaw = _lockedExoticText.trim();
    if (exoticRaw.isNotEmpty) {
      lockedHash = int.tryParse(exoticRaw);
      if (lockedHash == null) {
        _error = 'Locked exotic item hash must be an integer';
        return null;
      }
    }

    final thresholds = <ArmorStatName, int>{};
    for (final s in ArmorStatName.all) {
      final raw = _thresholdFields[s]?.trim() ?? '';
      if (raw.isEmpty) continue;
      final n = int.tryParse(raw);
      if (n == null) {
        _error = '${s.wireName} threshold must be an integer';
        return null;
      }
      thresholds[s] = n;
    }

    return ArmorOptimizeRequest(
      candidates: candidates,
      constraints: KitConstraints(
        lockedExoticItemHash: lockedHash,
      ),
      statPriorities: const [],
      statThresholds: thresholds.isEmpty ? null : thresholds,
      requireThresholds: _requireThresholds,
      preferReuse: _preferReuse,
      maxResults: _maxResults,
      hasInventory: hasInventory,
    );
  }

  Future<({List<CandidatePiece> candidates, bool hasInventory})>
      _resolveCandidates(int userId) async {
    if (_injectedCandidates != null) {
      return (
        candidates: List<CandidatePiece>.from(_injectedCandidates!),
        hasInventory: _injectedHasInventory ?? _injectedCandidates!.isNotEmpty,
      );
    }
    final loader = listInventory ??
        ((uid) => listInventoryItems(db, uid));
    final items = await loader(userId);
    final candidates = candidatesFromInventory(items: items);
    final hasArmor = inventoryHasArmorCandidates(items);
    return (candidates: candidates, hasInventory: hasArmor || items.isNotEmpty);
  }

  /// Run optimize. **Never writes** sets/attachments.
  Future<void> findKits() async {
    if (_running) return;
    _running = true;
    _error = null;
    _status = 'Finding kits…';
    _pending = null;
    notifyListeners();

    try {
      final userId = await resolveUserId();
      final board = await _resolveCandidates(userId);
      final request = _buildRequest(board.candidates, board.hasInventory);
      if (request == null) {
        _running = false;
        _status = null;
        notifyListeners();
        return;
      }

      final runner = optimizeRunner ?? optimizeArmorInIsolate;
      final response = await runner(request);
      _lastResponse = response;
      _running = false;

      if (response.combinations.isEmpty) {
        final er = response.emptyReason;
        _status = er != null
            ? formatOptimizerEmptyReason(er)
            : 'No kits found';
        if (er?.code == ArmorOptimizeEmptyReasonCode.noInventory) {
          _status = '${_status!} — ${inventoryEmptyGuidance()}';
        }
      } else {
        final n = response.combinations.length;
        final trunc = response.truncated ? ' (truncated)' : '';
        _status =
            'Found $n kit${n == 1 ? '' : 's'}$trunc. Confirm a kit to apply — nothing written yet.';
      }
      notifyListeners();
    } catch (e) {
      _running = false;
      _error = e.toString();
      _status = null;
      notifyListeners();
    }
  }

  /// Stage apply-in-place for confirm (no write yet).
  String? requestApplyInPlace(int combinationIndex) {
    if (_targetSetId == null) {
      _error = 'Select an armor set to apply in place';
      notifyListeners();
      return _error;
    }
    final combos = combinations;
    if (combinationIndex < 0 || combinationIndex >= combos.length) {
      _error = 'Invalid suggestion index';
      notifyListeners();
      return _error;
    }
    _pending = OptimizerPendingConfirm(
      kind: OptimizerConfirmKind.applyInPlace,
      combination: combos[combinationIndex],
      combinationIndex: combinationIndex,
    );
    _error = null;
    notifyListeners();
    return null;
  }

  /// Stage materialize for confirm (no write yet).
  String? requestMaterialize(int combinationIndex, String newSetName) {
    final combos = combinations;
    if (combinationIndex < 0 || combinationIndex >= combos.length) {
      _error = 'Invalid suggestion index';
      notifyListeners();
      return _error;
    }
    final name = newSetName.trim();
    if (name.isEmpty) {
      _error = 'New set name is required to materialize';
      notifyListeners();
      return _error;
    }
    _pending = OptimizerPendingConfirm(
      kind: OptimizerConfirmKind.materializeNew,
      combination: combos[combinationIndex],
      combinationIndex: combinationIndex,
      materializeName: name,
    );
    _error = null;
    notifyListeners();
    return null;
  }

  /// Cancel pending confirm — no write.
  void cancelPending() {
    if (_pending == null) return;
    _pending = null;
    _status = 'Apply cancelled — set unchanged';
    notifyListeners();
  }

  List<MaterializePiece> _piecesFromCombo(ArmorCombination combo) {
    return [
      for (final p in combo.pieces)
        MaterializePiece(
          slot: p.slot,
          itemHash: p.itemHash,
          instanceId: p.instanceId,
          itemName: p.itemName,
        ),
    ];
  }

  /// Execute pending confirm (only write path).
  Future<String?> confirmPending() async {
    final pending = _pending;
    if (pending == null) return 'Nothing to confirm';
    if (_confirming) return 'Already confirming';

    _confirming = true;
    _error = null;
    _status = 'Applying…';
    notifyListeners();

    try {
      final userId = await resolveUserId();
      final pieces = _piecesFromCombo(pending.combination);

      if (pending.kind == OptimizerConfirmKind.applyInPlace) {
        final setId = _targetSetId;
        if (setId == null) {
          _confirming = false;
          _error = 'No target armor set';
          notifyListeners();
          return _error;
        }
        await applyArmorCombinationInPlace(
          db,
          userId,
          ApplyArmorCombinationCommand(setId: setId, pieces: pieces),
        );
        _pending = null;
        _confirming = false;
        _status = 'Applied kit to ${_targetSetName ?? setId}';
        notifyListeners();
        return null;
      }

      final name = pending.materializeName ?? 'Optimized kit';
      final result = await materializeArmorCombination(
        db,
        userId,
        MaterializeArmorCommand(
          pieces: pieces,
          armorSetName: name,
        ),
      );
      _pending = null;
      _confirming = false;
      _status = 'Created armor set ${result.armorSet.set.name}';
      notifyListeners();
      return null;
    } on UseCaseException catch (e) {
      _confirming = false;
      _error = e.message;
      _status = null;
      notifyListeners();
      return e.message;
    } catch (e) {
      _confirming = false;
      _error = e.toString();
      _status = null;
      notifyListeners();
      return _error;
    }
  }
}
