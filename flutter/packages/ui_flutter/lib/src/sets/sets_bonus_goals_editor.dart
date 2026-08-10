import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// G-SET-013 bonus goals editor: none · 1×2pc · 2×2pc · 1×4pc.
///
/// [isLegalCombo] is provided by the host (domain pure helper).
class SetsBonusGoalsEditor extends StatelessWidget {
  const SetsBonusGoalsEditor({
    super.key,
    required this.goals,
    required this.availableFamilies,
    this.onChanged,
    this.isLegalCombo,
    this.enabled = true,
  });

  final List<SetsBonusGoalData> goals;
  final List<String> availableFamilies;
  final ValueChanged<List<SetsBonusGoalData>>? onChanged;

  /// Return false to reject illegal multi-goal combos.
  final bool Function(List<SetsBonusGoalData> next)? isLegalCombo;
  final bool enabled;

  void _emit(List<SetsBonusGoalData> next) {
    if (isLegalCombo != null && !isLegalCombo!(next)) {
      return;
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
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
        const SizedBox(height: kSpace8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('sets_bonus_goal_none'),
              label: const Text('None'),
              selected: goals.isEmpty,
              onSelected: !enabled
                  ? null
                  : (_) => _emit(const []),
            ),
            for (final family in availableFamilies) ...[
              ChoiceChip(
                key: Key('sets_bonus_goal_2pc_$family'),
                label: Text('$family 2pc'),
                selected: goals.length == 1 &&
                    goals.first.familyKey == family &&
                    goals.first.minPieces == 2,
                onSelected: !enabled
                    ? null
                    : (_) => _emit([
                          SetsBonusGoalData(
                            familyKey: family,
                            minPieces: 2,
                            familyLabel: family,
                          ),
                        ]),
              ),
              ChoiceChip(
                key: Key('sets_bonus_goal_4pc_$family'),
                label: Text('$family 4pc'),
                selected: goals.length == 1 &&
                    goals.first.familyKey == family &&
                    goals.first.minPieces == 4,
                onSelected: !enabled
                    ? null
                    : (_) => _emit([
                          SetsBonusGoalData(
                            familyKey: family,
                            minPieces: 4,
                            familyLabel: family,
                          ),
                        ]),
              ),
            ],
          ],
        ),
        if (availableFamilies.length >= 2) ...[
          const SizedBox(height: kSpace8),
          Text(
            'Or 2×2pc different families',
            style: neonBody(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: kSpace4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < availableFamilies.length; i++)
                for (var j = i + 1; j < availableFamilies.length; j++)
                  ActionChip(
                    key: Key(
                      'sets_bonus_goal_2x2_${availableFamilies[i]}_${availableFamilies[j]}',
                    ),
                    label: Text(
                      '${availableFamilies[i]}+${availableFamilies[j]} 2pc',
                    ),
                    onPressed: !enabled
                        ? null
                        : () => _emit([
                              SetsBonusGoalData(
                                familyKey: availableFamilies[i],
                                minPieces: 2,
                                familyLabel: availableFamilies[i],
                              ),
                              SetsBonusGoalData(
                                familyKey: availableFamilies[j],
                                minPieces: 2,
                                familyLabel: availableFamilies[j],
                              ),
                            ]),
                  ),
            ],
          ),
        ],
        if (goals.isNotEmpty) ...[
          const SizedBox(height: kSpace8),
          Wrap(
            spacing: 6,
            children: [
              for (final g in goals)
                Chip(
                  key: Key('sets_bonus_goal_active_${g.familyKey}_${g.minPieces}'),
                  label: Text(g.display),
                ),
            ],
          ),
        ],
        Text(
          'Illegal combos are rejected (same family twice, 2pc+4pc, >2 goals).',
          key: const Key('sets_bonus_goals_hint'),
          style: neonBody(color: palette.muted, fontSize: 11),
        ),
      ],
    );
  }
}
