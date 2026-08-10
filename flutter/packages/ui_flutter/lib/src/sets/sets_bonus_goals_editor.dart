import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// G-SET-013 bonus goals editor: none · 1×2pc · 2×2pc · 1×4pc.
///
/// Browse **all** [availableFamilies] via search + per-family 2pc/4pc controls.
/// [isLegalCombo] is provided by the host (domain pure helper).
class SetsBonusGoalsEditor extends StatefulWidget {
  const SetsBonusGoalsEditor({
    super.key,
    required this.goals,
    required this.availableFamilies,
    this.onChanged,
    this.isLegalCombo,
    this.enabled = true,
    this.loading = false,
    this.emptyMessage,
  });

  final List<SetsBonusGoalData> goals;
  final List<String> availableFamilies;
  final ValueChanged<List<SetsBonusGoalData>>? onChanged;

  /// Return false to reject illegal multi-goal combos.
  final bool Function(List<SetsBonusGoalData> next)? isLegalCombo;
  final bool enabled;
  final bool loading;

  /// Shown when [availableFamilies] is empty and not [loading].
  final String? emptyMessage;

  @override
  State<SetsBonusGoalsEditor> createState() => _SetsBonusGoalsEditorState();
}

class _SetsBonusGoalsEditorState extends State<SetsBonusGoalsEditor> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _emit(List<SetsBonusGoalData> next) {
    if (widget.isLegalCombo != null && !widget.isLegalCombo!(next)) {
      return;
    }
    widget.onChanged?.call(next);
  }

  int? _tierFor(String family) {
    for (final g in widget.goals) {
      if (g.familyKey == family) return g.minPieces;
    }
    return null;
  }

  void _selectNone() => _emit(const []);

  void _selectTier(String family, int tier) {
    final current = _tierFor(family);
    if (current == tier) {
      // Toggle off this family.
      final next = [
        for (final g in widget.goals)
          if (g.familyKey != family) g,
      ];
      _emit(next);
      return;
    }

    if (tier == 4) {
      _emit([
        SetsBonusGoalData(
          familyKey: family,
          minPieces: 4,
          familyLabel: family,
        ),
      ]);
      return;
    }

    // 2pc selection.
    final others = [
      for (final g in widget.goals)
        if (g.familyKey != family) g,
    ];
    final onlyOtherTwo = others.length == 1 && others.first.minPieces == 2;
    if (onlyOtherTwo) {
      _emit([
        others.first,
        SetsBonusGoalData(
          familyKey: family,
          minPieces: 2,
          familyLabel: family,
        ),
      ]);
      return;
    }
    _emit([
      SetsBonusGoalData(
        familyKey: family,
        minPieces: 2,
        familyLabel: family,
      ),
    ]);
  }

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.availableFamilies;
    return [
      for (final f in widget.availableFamilies)
        if (f.toLowerCase().contains(q)) f,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final families = _filtered;
    final emptyMsg = widget.emptyMessage ??
        'No set bonuses loaded. Refresh the Destiny manifest in Settings, then reopen Create.';

    return Column(
      key: const Key('sets_bonus_goals_editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set-bonus goals (optional)',
          style: neonBody(
            color: palette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: kSpace4),
        Text(
          'None · one 2pc · two 2pc (different families) · one 4pc. Search the full catalog.',
          style: neonBody(color: palette.muted, fontSize: 11),
        ),
        const SizedBox(height: kSpace8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('sets_bonus_goal_none'),
              label: const Text('None'),
              selected: widget.goals.isEmpty,
              onSelected: !widget.enabled ? null : (_) => _selectNone(),
            ),
            if (widget.goals.isNotEmpty)
              for (final g in widget.goals)
                Chip(
                  key: Key('sets_bonus_goal_active_${g.familyKey}_${g.minPieces}'),
                  label: Text(g.display),
                  onDeleted: !widget.enabled
                      ? null
                      : () {
                          final next = [
                            for (final x in widget.goals)
                              if (!(x.familyKey == g.familyKey &&
                                  x.minPieces == g.minPieces))
                                x,
                          ];
                          _emit(next);
                        },
                ),
          ],
        ),
        const SizedBox(height: kSpace8),
        TextField(
          key: const Key('sets_bonus_goals_search'),
          controller: _search,
          enabled: widget.enabled && !widget.loading,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Search set bonuses…',
            prefixIcon: Icon(Icons.search, size: 18),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: kSpace8),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(kSpace16),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('sets_bonus_goals_loading'),
              ),
            ),
          )
        else if (widget.availableFamilies.isEmpty)
          Padding(
            padding: const EdgeInsets.all(kSpace12),
            child: Text(
              emptyMsg,
              key: const Key('sets_bonus_goals_empty'),
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: palette.line),
                borderRadius: BorderRadius.circular(kRadiusMax),
              ),
              child: ListView.separated(
                key: const Key('sets_bonus_goals_list'),
                shrinkWrap: true,
                itemCount: families.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: palette.line,
                ),
                itemBuilder: (context, i) {
                  final family = families[i];
                  final tier = _tierFor(family);
                  return ListTile(
                    key: Key('sets_bonus_family_row_$family'),
                    dense: true,
                    title: Text(
                      family,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: neonBody(
                        color: palette.foreground,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                          key: Key('sets_bonus_goal_2pc_$family'),
                          label: const Text('2pc'),
                          selected: tier == 2,
                          onSelected: !widget.enabled
                              ? null
                              : (_) => _selectTier(family, 2),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          key: Key('sets_bonus_goal_4pc_$family'),
                          label: const Text('4pc'),
                          selected: tier == 4,
                          onSelected: !widget.enabled
                              ? null
                              : (_) => _selectTier(family, 4),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        if (_query.isNotEmpty &&
            families.isEmpty &&
            widget.availableFamilies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: kSpace8),
            child: Text(
              'No set bonuses match “$_query”.',
              key: const Key('sets_bonus_goals_no_match'),
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: kSpace8),
        Text(
          'Illegal combos are rejected (same family twice, 2pc+4pc, >2 goals). '
          '${widget.availableFamilies.isEmpty ? '' : '${widget.availableFamilies.length} bonuses available.'}',
          key: const Key('sets_bonus_goals_hint'),
          style: neonBody(color: palette.muted, fontSize: 11),
        ),
      ],
    );
  }
}
