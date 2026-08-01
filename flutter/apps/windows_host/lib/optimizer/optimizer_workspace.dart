import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'optimizer_controller.dart';
import 'optimizer_format.dart';

/// Armor optimizer workspace (goals → Find kits → confirm apply) — DART-036.
class OptimizerWorkspace extends StatefulWidget {
  const OptimizerWorkspace({
    super.key,
    required this.controller,
    this.onApplied,
  });

  final OptimizerController controller;

  /// Called after successful confirm apply/materialize (host may refresh sets).
  final VoidCallback? onApplied;

  @override
  State<OptimizerWorkspace> createState() => _OptimizerWorkspaceState();
}

class _OptimizerWorkspaceState extends State<OptimizerWorkspace> {
  final _materializeNameController = TextEditingController();
  final Map<ArmorStatName, TextEditingController> _thresholdControllers = {
    for (final s in ArmorStatName.all) s: TextEditingController(),
  };
  final _lockedExoticController = TextEditingController();
  bool _boundGoals = false;

  OptimizerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onController);
    _syncGoalFieldsFromController();
  }

  @override
  void didUpdateWidget(covariant OptimizerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _boundGoals = false;
      _syncGoalFieldsFromController();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    _materializeNameController.dispose();
    _lockedExoticController.dispose();
    for (final c in _thresholdControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncGoalFieldsFromController() {
    if (_boundGoals) return;
    _boundGoals = true;
    _lockedExoticController.text = _c.lockedExoticText;
    for (final s in ArmorStatName.all) {
      _thresholdControllers[s]!.text = _c.thresholdFields[s] ?? '';
    }
  }

  void _onController() {
    if (_c.pending != null && mounted) {
      // Dialog is opened from explicit button handlers; status still refreshes.
    }
    if (mounted) setState(() {});
  }

  Future<void> _findKits() async {
    _c.setLockedExoticText(_lockedExoticController.text);
    for (final s in ArmorStatName.all) {
      _c.setThresholdField(s, _thresholdControllers[s]!.text);
    }
    await _c.findKits();
  }

  Future<void> _openApplyConfirm(int index) async {
    final err = _c.requestApplyInPlace(index);
    if (err != null) {
      return;
    }
    final pending = _c.pending;
    if (pending == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('optimizer_confirm_dialog'),
        title: const Text('Confirm apply kit'),
        content: SingleChildScrollView(
          child: Text(
            confirmApplyInPlaceBody(pending.combination),
            key: const Key('optimizer_confirm_body'),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('optimizer_confirm_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('optimizer_confirm_accept'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm apply'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      final applyErr = await _c.confirmPending();
      if (applyErr == null) {
        widget.onApplied?.call();
      }
    } else {
      _c.cancelPending();
    }
  }

  Future<void> _openMaterializeConfirm(int index) async {
    final name = _materializeNameController.text;
    final err = _c.requestMaterialize(index, name);
    if (err != null) {
      // Controller does not set error for validation on request — surface status.
      setState(() {});
      return;
    }
    final pending = _c.pending;
    if (pending == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('optimizer_materialize_dialog'),
        title: const Text('Confirm create set'),
        content: SingleChildScrollView(
          child: Text(
            confirmMaterializeBody(
              pending.combination,
              pending.materializeName ?? name,
            ),
            key: const Key('optimizer_materialize_body'),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('optimizer_materialize_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('optimizer_materialize_accept'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm create'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      final applyErr = await _c.confirmPending();
      if (applyErr == null) {
        widget.onApplied?.call();
      }
    } else {
      _c.cancelPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('optimizer_workspace'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: kFlapRuleThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Armor optimizer',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            kOptimizerAdvisoryCaption,
            key: const Key('optimizer_advisory'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 12),
          _buildGoals(context),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                key: const Key('optimizer_find_kits'),
                onPressed: _c.running || _c.confirming ? null : _findKits,
                child: _c.running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Find kits'),
              ),
              const SizedBox(width: 12),
              if (_c.running)
                Text(
                  'Running…',
                  key: const Key('optimizer_busy'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (_c.error != null || _c.status != null) ...[
            const SizedBox(height: 8),
            Text(
              _c.error ?? _c.status!,
              key: const Key('optimizer_status'),
              style: TextStyle(
                color: _c.error != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildSuggestions(context),
        ],
      ),
    );
  }

  Widget _buildGoals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Goals', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          key: const Key('optimizer_locked_exotic'),
          controller: _lockedExoticController,
          decoration: const InputDecoration(
            labelText: 'Locked exotic item hash (optional)',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _c.setLockedExoticText,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('optimizer_prefer_reuse'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Prefer reuse of pieces already in sets'),
          value: _c.preferReuse,
          onChanged: _c.setPreferReuse,
        ),
        SwitchListTile(
          key: const Key('optimizer_require_thresholds'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Require soft stat thresholds'),
          subtitle: const Text('Filters results only — never auto-applies kits'),
          value: _c.requireThresholds,
          onChanged: _c.setRequireThresholds,
        ),
        const SizedBox(height: 4),
        Text(
          'Soft stat thresholds (optional)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in ArmorStatName.all)
              SizedBox(
                width: 100,
                child: TextField(
                  key: Key('optimizer_threshold_${s.wireName}'),
                  controller: _thresholdControllers[s],
                  decoration: InputDecoration(
                    labelText: s.wireName,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _c.setThresholdField(s, v),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('optimizer_materialize_name'),
          controller: _materializeNameController,
          decoration: const InputDecoration(
            labelText: 'New set name (for Materialize)',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final combos = _c.combinations;
    if (combos.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = _c.visibleCombinations;
    final note = formatTruncationNote(
      truncated: _c.lastResponse?.truncated ?? false,
      shown: visible.length,
      total: combos.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            if (combos.length > kOptimizerTopCompareCount)
              TextButton(
                key: const Key('optimizer_toggle_see_all'),
                onPressed: () =>
                    _c.setShowAllSuggestions(!_c.showAllSuggestions),
                child: Text(
                  _c.showAllSuggestions
                      ? 'Show top $kOptimizerTopCompareCount'
                      : 'See all ${combos.length}',
                ),
              ),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              note,
              key: const Key('optimizer_truncation_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (var i = 0; i < visible.length; i++)
          _buildSuggestionCard(context, visible[i], _indexInAll(visible[i])),
      ],
    );
  }

  int _indexInAll(ArmorCombination combo) {
    final all = _c.combinations;
    final idx = all.indexOf(combo);
    return idx >= 0 ? idx : 0;
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    ArmorCombination combo,
    int index,
  ) {
    return Container(
      key: Key('optimizer_suggestion_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatSuggestionTitle(indexOneBased: index + 1, combo: combo),
            key: Key('optimizer_suggestion_title_$index'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            formatEstimatedStatsSummary(combo.estimatedStats),
            key: Key('optimizer_suggestion_stats_$index'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            formatCombinationPiecesSummary(combo),
            key: Key('optimizer_suggestion_pieces_$index'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonal(
                key: Key('optimizer_apply_$index'),
                onPressed: _c.running || _c.confirming
                    ? null
                    : () => _openApplyConfirm(index),
                child: const Text('Apply in place…'),
              ),
              OutlinedButton(
                key: Key('optimizer_materialize_$index'),
                onPressed: _c.running || _c.confirming
                    ? null
                    : () => _openMaterializeConfirm(index),
                child: const Text('Materialize new…'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
