import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../unbroken_label.dart';
import 'sets_bonus_goals_editor.dart';
import 'sets_models.dart';
import 'sets_neon_chrome.dart';
import 'sets_optimize_dual_range.dart';

/// Optimizer confirm-only shell: DIM-style constraints + kit matrix + apply.
///
/// Dual-truth with mockup Optimize view (G-SET-027 / 036–037). Never writes on
/// open; apply only after confirm. Replace-all warning when [hasPins] is true.
class SetsOptimizeConfirmShell extends StatefulWidget {
  const SetsOptimizeConfirmShell({
    super.key,
    required this.kits,
    this.selectedKitId,
    this.onSelectKit,
    this.onConfirmApply,
    this.onCancel,
    this.onBack,
    this.onReoptimize,
    this.hasPins = false,
    this.classLabel,
    this.exoticLabel,
    this.bonusGoalsLabel,
    this.initialBonusGoals = const [],
    this.bonusFamilies = const [],
    this.bonusFamiliesLoading = false,
    this.onBonusGoalsChanged,
    this.isLegalBonusCombo,
    this.running = false,
    this.emptyMessage,
    /// Raw engine kit count before client exotic/stat filters (for honesty).
    this.engineKitCount,
    this.currentBoard,
    this.exoticOptions = const [
      SetsOptimizeExoticOption(id: 'any', label: 'Any'),
      SetsOptimizeExoticOption(id: 'none', label: 'No exotic'),
    ],
    this.initialExoticFilter = 'any',
    this.initialSort = SetsOptimizeSortMode.total,
    this.initialIncludeCurrent = true,
    this.initialStatMin = const {},
    this.initialStatMax = const {},
    this.onConstraintsChanged,
  });

  /// Proposal kits (not including current board row).
  final List<SetsOptimizeKitRowData> kits;
  final String? selectedKitId;
  final ValueChanged<String>? onSelectKit;
  final VoidCallback? onConfirmApply;
  final VoidCallback? onCancel;

  /// Optional ← Board (defaults to [onCancel]).
  final VoidCallback? onBack;

  /// Re-run find kits (host). Shown as **Re-optimize** in constraints.
  ///
  /// Passes current exotic + dual-range mins so the engine can lock exotic,
  /// require thresholds, and rank/prune by constrained stats.
  final void Function({
    required String exoticFilter,
    required Map<String, int> statMin,
    required Map<String, int> statMax,
  })? onReoptimize;
  final bool hasPins;
  final String? classLabel;
  final String? exoticLabel;

  /// Fallback seed label when [initialBonusGoals] is empty (legacy host).
  final String? bonusGoalsLabel;

  /// Editable hard goals (G-SET-013). Host persists + re-runs on change.
  final List<SetsBonusGoalData> initialBonusGoals;
  final List<SetsBonusFamilyOption> bonusFamilies;
  final bool bonusFamiliesLoading;
  final ValueChanged<List<SetsBonusGoalData>>? onBonusGoalsChanged;
  final bool Function(List<SetsBonusGoalData> next)? isLegalBonusCombo;

  final bool running;
  final String? emptyMessage;

  /// Engine result size (pre client-side exotic/stat filter). Defaults to [kits].
  final int? engineKitCount;

  /// Current board baseline row for “Show current” + green/red deltas.
  final SetsOptimizeKitRowData? currentBoard;

  final List<SetsOptimizeExoticOption> exoticOptions;
  final String initialExoticFilter;
  final SetsOptimizeSortMode initialSort;
  final bool initialIncludeCurrent;

  /// Optional seeded floors / caps (Widgetbook mins story + tests).
  final Map<String, int> initialStatMin;
  final Map<String, int> initialStatMax;

  /// Fires when exotic / sort / stat bands change (host may re-run findKits).
  final void Function({
    required String exoticFilter,
    required SetsOptimizeSortMode sort,
    required Map<String, int> statMin,
    required Map<String, int> statMax,
  })? onConstraintsChanged;

  @override
  State<SetsOptimizeConfirmShell> createState() =>
      _SetsOptimizeConfirmShellState();
}

class _SetsOptimizeConfirmShellState extends State<SetsOptimizeConfirmShell> {
  late String _exoticFilter;
  late SetsOptimizeSortMode _sort;
  late bool _includeCurrent;
  late Map<String, int> _statMin;
  late Map<String, int> _statMax;
  late List<SetsBonusGoalData> _bonusGoals;

  /// Constraints (exotic / sort / dual-ranges) collapse when the kit matrix
  /// scrolls down so results get vertical space (G-SET-036 density).
  bool _constraintsCollapsed = false;

  /// User tapped the collapsed bar to peek; next scroll-down re-collapses.
  bool _forceConstraintsExpanded = false;

  static const double _collapseScrollPx = 20;

  @override
  void initState() {
    super.initState();
    _exoticFilter = widget.initialExoticFilter;
    _sort = widget.initialSort;
    _includeCurrent = widget.initialIncludeCurrent && widget.hasPins;
    _bonusGoals = List<SetsBonusGoalData>.from(widget.initialBonusGoals);
    _statMin = {
      for (final s in kArmorBoardEofStatLabels)
        s: widget.initialStatMin[s] ?? 0,
    };
    _statMax = {
      for (final s in kArmorBoardEofStatLabels)
        s: widget.initialStatMax[s] ?? kSetsOptimizeStatSliderMax,
    };
  }

  @override
  void didUpdateWidget(covariant SetsOptimizeConfirmShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Host re-seeded goals after persist (e.g. external edit) — take when list
    // identity/content changes and we are not mid-dialog.
    if (!_bonusGoalsEqual(oldWidget.initialBonusGoals, widget.initialBonusGoals) &&
        _bonusGoalsEqual(_bonusGoals, oldWidget.initialBonusGoals)) {
      _bonusGoals = List<SetsBonusGoalData>.from(widget.initialBonusGoals);
    }
  }

  static bool _bonusGoalsEqual(
    List<SetsBonusGoalData> a,
    List<SetsBonusGoalData> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].familyKey != b[i].familyKey ||
          a[i].minPieces != b[i].minPieces) {
        return false;
      }
    }
    return true;
  }

  String get _bonusGoalsDisplay {
    if (_bonusGoals.isEmpty) {
      final legacy = widget.bonusGoalsLabel?.trim();
      if (legacy != null && legacy.isNotEmpty) return legacy;
      return 'None';
    }
    return _bonusGoals
        .map((g) => '${g.familyLabel ?? g.familyKey} ${g.minPieces}pc')
        .join(' · ');
  }

  void _onMatrixScrollPixels(double pixels) {
    final shouldCollapse = pixels > _collapseScrollPx;
    if (shouldCollapse) {
      if (_forceConstraintsExpanded || !_constraintsCollapsed) {
        setState(() {
          _forceConstraintsExpanded = false;
          _constraintsCollapsed = true;
        });
      }
    } else if (_constraintsCollapsed || _forceConstraintsExpanded) {
      setState(() {
        _constraintsCollapsed = false;
        _forceConstraintsExpanded = false;
      });
    }
  }

  bool _onMatrixScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _onMatrixScrollPixels(n.metrics.pixels);
    }
    return false;
  }

  String get _constraintsSummary {
    String exoLabel = _exoticFilter;
    for (final o in widget.exoticOptions) {
      if (o.id == _exoticFilter) {
        exoLabel = o.label;
        break;
      }
    }
    final activeStats = <String>[];
    for (final s in kArmorBoardEofStatLabels) {
      final mn = _statMin[s] ?? 0;
      final mx = _statMax[s] ?? kSetsOptimizeStatSliderMax;
      if (mn > 0 && mx < kSetsOptimizeStatSliderMax) {
        activeStats.add('$s $mn–$mx');
      } else if (mn > 0) {
        activeStats.add('$s ≥$mn');
      } else if (mx < kSetsOptimizeStatSliderMax) {
        activeStats.add('$s ≤$mx');
      }
    }
    final parts = <String>[
      exoLabel,
      _bonusGoalsDisplay,
      if (activeStats.isNotEmpty) activeStats.join(' · '),
    ];
    return parts.join(' · ');
  }

  bool get _anyStatLimit =>
      _activeStatMin.isNotEmpty || _activeStatMax.isNotEmpty;

  Future<void> _openBonusGoalsEditor() async {
    if (widget.onBonusGoalsChanged == null) return;
    var draft = List<SetsBonusGoalData>.from(_bonusGoals);
    final applied = await showDialog<List<SetsBonusGoalData>>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xB8020208),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final palette = FlapPalette.of(ctx);
            return Dialog(
              backgroundColor: palette.surfaceRaised,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 640,
                  maxHeight: 720,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Set bonus goals'.toUpperCase(),
                        key: const Key('sets_optimize_bonus_dialog_title'),
                        style: neonDisplay(
                          color: palette.accent,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'None · 1×2pc · 2×2pc · 1×4pc. Apply saves; '
                        'Re-optimize uses the new goals.',
                        style: neonBody(color: palette.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SetsBonusGoalsEditor(
                            key: const Key('sets_optimize_bonus_editor'),
                            goals: draft,
                            families: widget.bonusFamilies,
                            loading: widget.bonusFamiliesLoading,
                            isLegalCombo: widget.isLegalBonusCombo,
                            onChanged: (next) {
                              setLocal(() => draft = next);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            key: const Key('sets_optimize_bonus_cancel'),
                            style: setsNeonGhostStyle(palette),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'Cancel',
                              style: setsNeonBtnLabel(palette.muted),
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            key: const Key('sets_optimize_bonus_apply'),
                            style: setsNeonPrimaryStyle(palette),
                            onPressed: () => Navigator.of(ctx).pop(draft),
                            child: Text(
                              'APPLY GOALS'.toUpperCase(),
                              style: setsNeonBtnLabel(palette.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (applied == null || !mounted) return;
    setState(() {
      _bonusGoals = List<SetsBonusGoalData>.from(applied);
    });
    widget.onBonusGoalsChanged?.call(_bonusGoals);
  }

  void _emitConstraints() {
    widget.onConstraintsChanged?.call(
      exoticFilter: _exoticFilter,
      sort: _sort,
      statMin: Map<String, int>.from(_statMin),
      statMax: Map<String, int>.from(_statMax),
    );
  }

  void _clearStats() {
    setState(() {
      for (final s in kArmorBoardEofStatLabels) {
        _statMin[s] = 0;
        _statMax[s] = kSetsOptimizeStatSliderMax;
      }
    });
    _emitConstraints();
  }

  Map<String, int> get _activeStatMin => {
        for (final e in _statMin.entries)
          if (e.value > 0) e.key: e.value,
      };

  Map<String, int> get _activeStatMax => {
        for (final e in _statMax.entries)
          if (e.value < kSetsOptimizeStatSliderMax) e.key: e.value,
      };

  String get _exoticFilterLabel {
    for (final o in widget.exoticOptions) {
      if (o.id == _exoticFilter) return o.label;
    }
    return _exoticFilter;
  }

  /// Re-run search with **current** exotic + stat mins (do not clear filters).
  void _onReoptimizePressed() {
    widget.onReoptimize?.call(
      exoticFilter: _exoticFilter,
      statMin: Map<String, int>.from(_activeStatMin),
      statMax: Map<String, int>.from(_activeStatMax),
    );
  }

  List<SetsOptimizeKitRowData> get _filtered {
    return filterSortOptimizeKits(
      kits: widget.kits,
      exoticFilter: _exoticFilter,
      sort: _sort,
      statMin: _activeStatMin,
      statMax: _activeStatMax,
      baseline: widget.currentBoard,
    );
  }

  SetsOptimizeFilterBreakdown get _filterBreakdown {
    return breakdownOptimizeFilters(
      kits: widget.kits,
      exoticFilter: _exoticFilter,
      statMin: _activeStatMin,
      statMax: _activeStatMax,
      exoticFilterLabel: _exoticFilterLabel,
    );
  }

  SetsOptimizeKitRowData? get _selected {
    final id = widget.selectedKitId;
    if (id == null) return null;
    for (final k in _filtered) {
      if (k.id == id) return k;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final filtered = _filtered;
    final selected = _selected;
    final canApply =
        selected != null && widget.onConfirmApply != null && !widget.running;
    final baseline = widget.currentBoard;
    final engineN = widget.engineKitCount ?? widget.kits.length;
    final breakdown = _filterBreakdown;
    final matchLabel = widget.running
        ? 'Finding kits…'
        : filtered.isEmpty
            ? describeOptimizeFilterEmpty(
                b: SetsOptimizeFilterBreakdown(
                  engineCount: engineN,
                  afterExotic: breakdown.afterExotic,
                  afterAll: 0,
                  failedExotic: breakdown.failedExotic,
                  failedStatMin: breakdown.failedStatMin,
                  failedStatMax: breakdown.failedStatMax,
                  activeMinLabels: breakdown.activeMinLabels,
                  activeMaxLabels: breakdown.activeMaxLabels,
                  exoticFilterLabel: breakdown.exoticFilterLabel,
                ),
                engineEmptyMessage: widget.emptyMessage,
              )
            : (filtered.length == engineN
                ? '${filtered.length} kit${filtered.length == 1 ? '' : 's'} found'
                : '${filtered.length} of $engineN kits · filters applied');

    return Column(
      key: const Key('sets_optimize_confirm_shell'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              key: const Key('sets_optimize_back'),
              style: setsNeonGhostStyle(
                palette,
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: widget.onBack ?? widget.onCancel,
              child: Text(
                '← Board'.toUpperCase(),
                style: setsNeonBtnLabel(palette.muted, fontSize: 9),
              ),
            ),
            const Spacer(),
            if (widget.hasPins && widget.currentBoard != null)
              FilterChip(
                key: const Key('sets_optimize_include_current'),
                visualDensity: VisualDensity.compact,
                label: Text(
                  'cur',
                  style: neonBody(color: palette.foreground, fontSize: 11),
                ),
                selected: _includeCurrent,
                onSelected: (v) => setState(() => _includeCurrent = v),
              ),
            const SizedBox(width: 8),
            Text(
              matchLabel,
              key: const Key('sets_optimize_match_count'),
              style: neonMono(color: palette.muted, fontSize: 10),
            ),
          ],
        ),
        if (widget.hasPins) ...[
          const SizedBox(height: kSpace8),
          Container(
            key: const Key('sets_optimize_replace_all_warning'),
            padding: const EdgeInsets.all(kSpace8),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.08),
              border: Border.all(
                color: palette.warning.withValues(alpha: 0.35),
                width: kFlapRuleThickness,
              ),
            ),
            child: Text(
              'Applying a kit replaces all pins.',
              style: neonBody(
                color: palette.warning,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: kSpace8),
        // Body flexes: constraints can shrink/scroll; matrix keeps remaining space.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Constraints: full panel, or compact bar after matrix scroll-down.
              if (_constraintsCollapsed && !_forceConstraintsExpanded)
                _buildConstraintsCollapsedBar(palette)
              else
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: _buildConstraints(palette),
                  ),
                ),
              const SizedBox(height: kSpace8),
              Expanded(
                child: widget.running
                    ? const Center(
                        child: CircularProgressIndicator(
                          key: Key('sets_optimize_running'),
                        ),
                      )
                    : (filtered.isEmpty &&
                            !(_includeCurrent && baseline != null))
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.emptyMessage ??
                                  'No kits — adjust exotic / min / max and re-run',
                              key: const Key('sets_optimize_empty'),
                              style: neonBody(
                                color: palette.muted,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: _onMatrixScrollNotification,
                            child: _KitMatrix(
                              kits: filtered,
                              pinnedCurrent: (_includeCurrent &&
                                      baseline != null)
                                  ? baseline
                                  : null,
                              baseline: baseline,
                              selectedKitId: widget.selectedKitId,
                              statMin: _statMin,
                              statMax: _statMax,
                              sort: _sort,
                              onSort: (m) {
                                setState(() => _sort = m);
                                _emitConstraints();
                              },
                              onSelect: widget.onSelectKit,
                            ),
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpace8),
        Row(
          children: [
            TextButton(
              key: const Key('sets_optimize_cancel'),
              style: setsNeonGhostStyle(palette),
              onPressed: widget.onCancel,
              child: Text('Cancel', style: setsNeonBtnLabel(palette.muted)),
            ),
            const Spacer(),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Σ ${selected.total}',
                  style: neonMono(color: palette.muted, fontSize: 10),
                ),
              ),
            FilledButton(
              key: const Key('sets_optimize_confirm_apply'),
              style: setsNeonPrimaryStyle(palette),
              onPressed: canApply ? widget.onConfirmApply : null,
              child: Text(
                (widget.hasPins
                        ? 'Apply selected · replace all…'
                        : 'Apply selected…')
                    .toUpperCase(),
                style: setsNeonBtnLabel(
                  canApply
                      ? palette.accent
                      : palette.accent.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConstraintsCollapsedBar(FlapPalette palette) {
    return Material(
      color: palette.background,
      child: InkWell(
        key: const Key('sets_optimize_constraints_collapsed'),
        onTap: () {
          setState(() {
            _forceConstraintsExpanded = true;
            _constraintsCollapsed = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: palette.line, width: kFlapRuleThickness),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 14, color: palette.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _constraintsSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonMono(color: palette.foreground, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EXPAND',
                style: neonDisplay(
                  color: palette.accent,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.expand_more, size: 16, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConstraints(FlapPalette palette) {
    return Container(
      key: const Key('sets_optimize_constraints'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_forceConstraintsExpanded)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('sets_optimize_constraints_collapse'),
                style: setsNeonGhostStyle(
                  palette,
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  fontSize: 8,
                ),
                onPressed: () {
                  setState(() {
                    _forceConstraintsExpanded = false;
                    _constraintsCollapsed = true;
                  });
                },
                child: Text(
                  'COLLAPSE',
                  style: setsNeonBtnLabel(palette.muted, fontSize: 8),
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _exoticDropdown(palette),
              if (widget.onBonusGoalsChanged != null)
                _bonusGoalsConstraintControl(palette),
              if (_anyStatLimit)
                TextButton(
                  key: const Key('sets_optimize_clear_stats'),
                  style: setsNeonGhostStyle(
                    palette,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    fontSize: 8,
                  ),
                  onPressed: _clearStats,
                  child: Text(
                    'Clear limits'.toUpperCase(),
                    style: setsNeonBtnLabel(palette.muted, fontSize: 8),
                  ),
                ),
              if (widget.onReoptimize != null)
                TextButton.icon(
                  key: const Key('sets_optimize_rerun'),
                  style: setsNeonGhostStyle(
                    palette,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    fontSize: 8,
                  ),
                  onPressed: widget.running ? null : _onReoptimizePressed,
                  icon: Icon(
                    Icons.refresh,
                    size: 14,
                    color: widget.running
                        ? palette.accent.withValues(alpha: 0.35)
                        : palette.accent,
                  ),
                  label: Text(
                    (widget.running ? 'Finding…' : 'Re-optimize').toUpperCase(),
                    style: setsNeonBtnLabel(
                      widget.running
                          ? palette.accent.withValues(alpha: 0.35)
                          : palette.accent,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 900
                  ? 3
                  : w >= 560
                      ? 2
                      : 1;
              final cellW = (w - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final s in kArmorBoardEofStatLabels)
                    SizedBox(
                      width: cellW,
                      child: SetsOptimizeDualRange(
                        statLabel: s,
                        minValue: _statMin[s] ?? 0,
                        maxValue: _statMax[s] ?? kSetsOptimizeStatSliderMax,
                        onChanged: (mn, mx) {
                          setState(() {
                            _statMin[s] = mn;
                            _statMax[s] = mx;
                          });
                          _emitConstraints();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bonusGoalsConstraintControl(FlapPalette palette) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bonus goals'.toUpperCase(),
            style: neonDisplay(
              color: palette.muted,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            key: const Key('sets_optimize_bonus_open'),
            style: setsNeonGhostStyle(
              palette,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: widget.running ? null : _openBonusGoalsEditor,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _bonusGoalsDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: neonBody(color: palette.foreground, fontSize: 12),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 14, color: palette.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exoticDropdown(FlapPalette palette) {
    final options = widget.exoticOptions;
    final resolved =
        options.any((o) => o.id == _exoticFilter) ? _exoticFilter : 'any';
    SetsOptimizeExoticOption? selected;
    for (final o in options) {
      if (o.id == resolved) {
        selected = o;
        break;
      }
    }
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SetsFieldLabel('Exotic'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            key: const Key('sets_optimize_exotic'),
            // ignore: deprecated_member_use
            value: resolved,
            isDense: false,
            isExpanded: true,
            menuMaxHeight: 360,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              filled: true,
              fillColor: palette.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kFlapRadius),
                borderSide: BorderSide(color: palette.line),
              ),
            ),
            style: neonBody(color: palette.foreground, fontSize: 12),
            dropdownColor: palette.surfaceRaised,
            selectedItemBuilder: (context) {
              return [
                for (final o in options)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _exoticOptionRow(
                      o,
                      palette,
                      dense: true,
                      selected: o.id == resolved,
                    ),
                  ),
              ];
            },
            items: [
              for (final o in options)
                DropdownMenuItem<String>(
                  value: o.id,
                  child: _exoticOptionRow(o, palette, dense: false),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _exoticFilter = v);
              _emitConstraints();
            },
          ),
          if (selected != null &&
              selected.id != 'any' &&
              selected.id != 'none' &&
              (selected.subtitle?.isNotEmpty == true ||
                  selected.iconPath != null))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                selected.subtitle ?? selected.label,
                key: const Key('sets_optimize_exotic_detail'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: neonMono(color: palette.muted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _exoticOptionRow(
    SetsOptimizeExoticOption o,
    FlapPalette palette, {
    required bool dense,
    bool selected = false,
  }) {
    final isMeta = o.id == 'any' || o.id == 'none';
    final iconSize = dense ? 22.0 : 28.0;
    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            border: Border.all(
              color: isMeta
                  ? palette.line
                  : const Color(0xFFE5C35A).withValues(alpha: 0.65),
              width: kFlapRuleThickness,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: o.iconPath != null && o.iconPath!.trim().isNotEmpty
              ? BungieContentIcon(
                  pathOrUrl: o.iconPath,
                  size: iconSize,
                  fallback: Icon(
                    Icons.star_outline,
                    size: iconSize * 0.55,
                    color: palette.muted,
                  ),
                )
              : Icon(
                  isMeta ? Icons.filter_alt_outlined : Icons.star_outline,
                  size: iconSize * 0.55,
                  color: isMeta
                      ? palette.muted
                      : const Color(0xFFE5C35A),
                ),
        ),
        Expanded(
          child: dense
              ? Text(
                  o.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: neonBody(
                    color: selected
                        ? palette.accent
                        : palette.foreground,
                    fontSize: 12,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      o.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: neonBody(
                        color: isMeta
                            ? palette.foreground
                            : const Color(0xFFE5C35A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (o.subtitle != null && o.subtitle!.isNotEmpty)
                      Text(
                        o.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: neonMono(color: palette.muted, fontSize: 10),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

}

class _KitMatrix extends StatelessWidget {
  const _KitMatrix({
    required this.kits,
    required this.baseline,
    required this.selectedKitId,
    required this.statMin,
    required this.statMax,
    required this.sort,
    this.pinnedCurrent,
    this.onSelect,
    this.onSort,
  });

  /// Scrollable proposal kits (not including [pinnedCurrent]).
  final List<SetsOptimizeKitRowData> kits;

  /// Sticky current-board row — stays visible while proposals scroll.
  final SetsOptimizeKitRowData? pinnedCurrent;
  final SetsOptimizeKitRowData? baseline;
  final String? selectedKitId;
  final Map<String, int> statMin;
  final Map<String, int> statMax;
  final SetsOptimizeSortMode sort;
  final ValueChanged<String>? onSelect;
  final ValueChanged<SetsOptimizeSortMode>? onSort;

  static const double _minTableWidth = 1300;

  Map<int, TableColumnWidth> get _columnWidths {
    const stats = kArmorBoardEofStatLabels;
    const slots = kArmorBoardSlotWires;
    return {
      0: const FixedColumnWidth(40),
      1: const FixedColumnWidth(48),
      for (var i = 0; i < stats.length; i++) 2 + i: const FixedColumnWidth(72),
      for (var i = 0; i < slots.length; i++)
        2 + stats.length + i: const FixedColumnWidth(132),
      2 + stats.length + slots.length: const FixedColumnWidth(120),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    const stats = kArmorBoardEofStatLabels;
    const slotLabels = kArmorBoardSlotLabels;
    final widths = _columnWidths;

    Table headerTable() => Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: widths,
          children: [
            TableRow(
              decoration: BoxDecoration(color: palette.surfaceRaised),
              children: [
                _th('#', palette),
                _th(
                  'Σ',
                  palette,
                  num: true,
                  sortMode: SetsOptimizeSortMode.total,
                  headerKey: 'total',
                ),
                for (final s in stats)
                  _th(
                    s,
                    palette,
                    num: true,
                    sortMode: SetsOptimizeSortModeX.parse(s.toLowerCase()),
                    headerKey: s,
                    wash: _statWash(s, palette),
                    highlightKey: (statMin[s] ?? 0) > 0
                        ? 'sets_optimize_col_highlight_$s'
                        : null,
                  ),
                for (final l in slotLabels) _th(l, palette),
                _th(
                  'Goals',
                  palette,
                  sortMode: SetsOptimizeSortMode.goals,
                  headerKey: 'Goals',
                ),
              ],
            ),
          ],
        );

    Table rowTable(SetsOptimizeKitRowData kit, {required bool sticky}) => Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: widths,
          children: [_kitRow(kit, palette, sticky: sticky)],
        );

    return Container(
      key: const Key('sets_optimize_kit_matrix'),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line, width: kFlapRuleThickness),
        color: palette.surface,
      ),
      // One horizontal viewport for header + current + kits so columns stay
      // locked. Only the proposal list scrolls vertically.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            key: const Key('sets_optimize_kit_matrix_hscroll'),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _minTableWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerTable(),
                  if (pinnedCurrent != null) ...[
                    rowTable(pinnedCurrent!, sticky: true),
                    Container(
                      key: const Key('sets_optimize_current_pin_rule'),
                      height: 2,
                      color: palette.accent.withValues(alpha: 0.45),
                    ),
                  ],
                  Expanded(
                    child: _AttachedVerticalScrollbar(
                      builder: (context, controller) => Scrollbar(
                        controller: controller,
                        child: SingleChildScrollView(
                          controller: controller,
                          child: Table(
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: widths,
                            children: [
                              for (final kit in kits)
                                _kitRow(kit, palette, sticky: false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TableRow _kitRow(
    SetsOptimizeKitRowData kit,
    FlapPalette palette, {
    required bool sticky,
  }) {
    const stats = kArmorBoardEofStatLabels;
    const slots = kArmorBoardSlotWires;
    return TableRow(
      decoration: BoxDecoration(
        color: kit.isCurrent
            ? palette.accent.withValues(alpha: sticky ? 0.12 : 0.06)
            : kit.id == selectedKitId
                ? palette.accent.withValues(alpha: kFlapChannelWashAlpha)
                : (sticky ? palette.surfaceRaised : null),
        border: Border(
          left: kit.id == selectedKitId && !kit.isCurrent
              ? BorderSide(color: palette.accent, width: 3)
              : BorderSide.none,
          bottom: BorderSide(
            color: palette.line,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      children: [
        _tapCell(
          kit: kit,
          onSelect: onSelect,
          child: Text(
            kit.isCurrent
                ? 'cur'
                : (kit.rank > 0 ? '#${kit.rank}' : kit.id),
            key: ValueKey('sets_optimize_kit_${kit.id}'),
            style: neonDisplay(
              color: palette.accent,
              fontSize: 11,
            ),
          ),
        ),
        _numCell(
          kit.total,
          base: baseline?.total,
          forcedDelta: baseline == null && !kit.isCurrent
              ? kit.deltaVsCurrent
              : null,
          showDelta: !kit.isCurrent &&
              (baseline != null || kit.deltaVsCurrent != null),
          palette: palette,
          hi: true,
          deltaKey: kit.isCurrent
              ? null
              : Key('sets_optimize_delta_${kit.id}'),
          onTap: kit.isCurrent || onSelect == null
              ? null
              : () => onSelect!(kit.id),
        ),
        for (final s in stats)
          _numCell(
            kit.stats[s] ?? 0,
            base: baseline?.stats[s],
            showDelta: baseline != null && !kit.isCurrent,
            palette: palette,
            fail: _fail(s, kit.stats[s] ?? 0),
            wash: _statWash(s, palette),
            onTap: kit.isCurrent || onSelect == null
                ? null
                : () => onSelect!(kit.id),
          ),
        for (final w in slots) _pieceCell(kit, w, palette, onSelect),
        _tapCell(
          kit: kit,
          onSelect: onSelect,
          child: _goalBadge(kit, palette),
        ),
      ],
    );
  }

  Widget _tapCell({
    required SetsOptimizeKitRowData kit,
    required ValueChanged<String>? onSelect,
    required Widget child,
  }) {
    return InkWell(
      onTap: kit.isCurrent || onSelect == null ? null : () => onSelect(kit.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: child,
      ),
    );
  }

  bool _fail(String stat, int v) {
    final mn = statMin[stat] ?? 0;
    final mx = statMax[stat] ?? kSetsOptimizeStatSliderMax;
    if (mn > 0 && v < mn) return true;
    if (mx < kSetsOptimizeStatSliderMax && v > mx) return true;
    return false;
  }

  Color? _statWash(String stat, FlapPalette palette) {
    final mn = statMin[stat] ?? 0;
    final mx = statMax[stat] ?? kSetsOptimizeStatSliderMax;
    if (mn > 0) return palette.accent.withValues(alpha: 0.14);
    if (mx < kSetsOptimizeStatSliderMax) {
      return palette.muted.withValues(alpha: 0.08);
    }
    return null;
  }

  Widget _th(
    String t,
    FlapPalette palette, {
    bool num = false,
    SetsOptimizeSortMode? sortMode,
    String? headerKey,
    Color? wash,
    String? highlightKey,
  }) {
    final active = sortMode != null && sort == sortMode;
    final label = active ? '${t.toUpperCase()} ▼' : t.toUpperCase();
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: UnbrokenLabel(
        label,
        fit: true,
        textAlign: num ? TextAlign.right : TextAlign.left,
        style: neonDisplay(
          color: active
              ? palette.accent
              : palette.muted.withValues(alpha: 0.85),
          fontSize: 8,
          letterSpacing: 0.2,
        ),
      ),
    );
    final boxed = DecoratedBox(
      key: highlightKey != null ? Key(highlightKey) : null,
      decoration: BoxDecoration(color: wash),
      child: sortMode == null || onSort == null
          ? child
          : InkWell(
              key: Key('sets_optimize_th_$headerKey'),
              onTap: () => onSort!(sortMode),
              child: child,
            ),
    );
    return boxed;
  }

  Widget _numCell(
    int val, {
    int? base,
    int? forcedDelta,
    required bool showDelta,
    required FlapPalette palette,
    bool hi = false,
    bool fail = false,
    Color? wash,
    Key? deltaKey,
    VoidCallback? onTap,
  }) {
    final delta = forcedDelta ??
        (showDelta && base != null ? val - base : null);
    Color color = hi ? palette.accent : palette.foreground;
    if (fail) {
      color = palette.danger;
    } else if (delta != null) {
      if (delta > 0) color = palette.success;
      if (delta < 0) color = palette.danger;
      if (delta == 0) color = palette.muted;
    }
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(color: wash),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$val',
              style: neonMono(
                color: color,
                fontSize: 12,
                fontWeight: hi || fail ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (delta != null && delta != 0)
              Text(
                delta > 0 ? '+$delta' : '$delta',
                key: deltaKey,
                style: neonMono(
                  color: delta > 0 ? palette.success : palette.danger,
                  fontSize: 9,
                ),
              )
            else if (deltaKey != null)
              Text(
                '—',
                key: deltaKey,
                style: neonMono(color: palette.muted, fontSize: 9),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _pieceCell(
    SetsOptimizeKitRowData kit,
    String wire,
    FlapPalette palette,
    ValueChanged<String>? onSelect,
  ) {
    final piece = kit.slotPieces[wire];
    final name = kit.pieceName(wire);
    final exo = kit.pieceIsExotic(wire);
    final sub = piece?.subtitle ?? _pieceSubtitle(piece);
    final baseLine = piece?.baseStatsLine;
    final iconPath = piece?.iconPath;
    return InkWell(
      onTap: kit.isCurrent || onSelect == null ? null : () => onSelect(kit.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, top: 1),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                border: Border.all(
                  color: exo
                      ? const Color(0xFFE5C35A).withValues(alpha: 0.7)
                      : palette.line,
                  width: kFlapRuleThickness,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: iconPath != null && iconPath.trim().isNotEmpty
                  ? BungieContentIcon(
                      pathOrUrl: iconPath,
                      size: 28,
                      fallback: Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: palette.muted,
                      ),
                    )
                  : Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: palette.muted,
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: exo && !name.startsWith('★') ? '★ $name' : name,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Text(
                      exo && !name.startsWith('★') ? '★ $name' : name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: neonBody(
                        color: exo
                            ? const Color(0xFFE5C35A)
                            : palette.foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (sub != null && sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: neonMono(color: palette.muted, fontSize: 9),
                    ),
                  if (baseLine != null && baseLine.isNotEmpty)
                    Text(
                      baseLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: neonMono(
                        color: palette.muted.withValues(alpha: 0.85),
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _pieceSubtitle(SetsOptimizeSlotPiece? piece) {
    if (piece == null) return null;
    final parts = <String>[];
    if (piece.pieceTotal != null) parts.add('Σ ${piece.pieceTotal}');
    if (piece.power != null && piece.power! > 0) {
      parts.add('✧${piece.power}');
    }
    final fam = piece.familyKey?.trim();
    if (fam != null && fam.isNotEmpty) {
      parts.add(fam.split(RegExp(r'\s+')).first);
    }
    if (parts.isEmpty) return piece.subtitle;
    return parts.join(' · ');
  }

  Widget _goalBadge(SetsOptimizeKitRowData kit, FlapPalette palette) {
    final empty = kit.goalsLabel == '—' || kit.goalsLabel.isEmpty;
    final color = empty
        ? palette.muted
        : kit.goalsOk
            ? palette.success
            : palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: kFlapRuleThickness,
        ),
      ),
      child: Text(
        kit.goalsLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: neonMono(color: color, fontSize: 9),
      ),
    );
  }
}

/// Scrollbar + viewport share one [ScrollController] (PrimaryScrollController
/// is often detached on this nested matrix).
class _AttachedVerticalScrollbar extends StatefulWidget {
  const _AttachedVerticalScrollbar({required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<_AttachedVerticalScrollbar> createState() =>
      _AttachedVerticalScrollbarState();
}

class _AttachedVerticalScrollbarState extends State<_AttachedVerticalScrollbar> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
