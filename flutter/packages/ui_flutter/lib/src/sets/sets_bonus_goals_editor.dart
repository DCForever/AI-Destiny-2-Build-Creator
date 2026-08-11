import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../catalog/entity_info_hotspot.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_bonus_family_info.dart';
import 'sets_models.dart';
import 'sets_neon_chrome.dart';

/// G-SET-013 bonus goals editor: none · 1×2pc · 2×2pc · 1×4pc.
///
/// Browse **all** families via search + per-family 2pc/4pc. Hover/focus the
/// name or selected chips for [EntityInfoHotspot] perk descriptions (same
/// Catalog entity-info popup stack).
class SetsBonusGoalsEditor extends StatefulWidget {
  const SetsBonusGoalsEditor({
    super.key,
    required this.goals,
    this.families = const [],
    @Deprecated('Use families (SetsBonusFamilyOption)') this.availableFamilies = const [],
    this.onChanged,
    this.isLegalCombo,
    this.enabled = true,
    this.loading = false,
    this.emptyMessage,
  });

  final List<SetsBonusGoalData> goals;

  /// Full catalog options (name + 2pc/4pc perk text). Preferred.
  final List<SetsBonusFamilyOption> families;

  /// Name-only fallback for tests / legacy call sites.
  final List<String> availableFamilies;

  final ValueChanged<List<SetsBonusGoalData>>? onChanged;
  final bool Function(List<SetsBonusGoalData> next)? isLegalCombo;
  final bool enabled;
  final bool loading;
  final String? emptyMessage;

  List<SetsBonusFamilyOption> get resolvedFamilies {
    if (families.isNotEmpty) return families;
    return [
      for (final n in availableFamilies) SetsBonusFamilyOption.nameOnly(n),
    ];
  }

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

  SetsBonusFamilyOption? _optionFor(String familyKey) {
    for (final f in widget.resolvedFamilies) {
      if (f.name == familyKey) return f;
    }
    return SetsBonusFamilyOption.nameOnly(familyKey);
  }

  void _selectNone() => _emit(const []);

  void _selectTier(String family, int tier) {
    final current = _tierFor(family);
    if (current == tier) {
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

  List<SetsBonusFamilyOption> get _filtered {
    final all = widget.resolvedFamilies;
    final q = _query.trim();
    if (q.isEmpty) return all;
    // Multi-token AND over name + perk titles + full descriptions.
    return [for (final f in all) if (f.matchesSearch(q)) f];
  }

  Widget _tierChip({
    required SetsBonusFamilyOption family,
    required int tier,
    required bool selected,
  }) {
    final label = tier == 2 ? '2pc' : '4pc';
    // Key on hotspot so tests/taps hit the interactive layer (not IgnorePointer chip).
    return EntityInfoHotspot(
      key: Key('sets_bonus_goal_${tier}pc_${family.name}'),
      data: entityInfoForSetBonusTier(family, tier),
      enabled: widget.enabled,
      onPrimary: !widget.enabled ? null : () => _selectTier(family.name, tier),
      child: IgnorePointer(
        child: FilterChip(
          key: Key('sets_bonus_info_${tier}pc_${family.name}'),
          label: Text(label),
          selected: selected,
          // Visual only — hotspot owns hover/info + primary select.
          onSelected: (_) {},
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final families = _filtered;
    final all = widget.resolvedFamilies;
    final emptyMsg = widget.emptyMessage ??
        'No set bonuses loaded. Refresh the Destiny manifest in Settings, then reopen Create.';

    return Column(
      key: const Key('sets_bonus_goals_editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetsFieldLabel('Armor set-bonus goals (optional)'),
        const SizedBox(height: kSpace4),
        Text(
          'None · one 2pc · two 2pc (different families) · one 4pc. '
          'Hover a name or chip for perk details (info popup).',
          style: neonBody(color: palette.muted, fontSize: 11),
        ),
        const SizedBox(height: kSpace8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Compact “None” choice — keeps catalog-editor residual vs mockup mode-seg.
            _NoneChoice(
              selected: widget.goals.isEmpty,
              enabled: widget.enabled,
              onTap: !widget.enabled ? null : _selectNone,
            ),
            if (widget.goals.isNotEmpty)
              for (final g in widget.goals)
                EntityInfoHotspot(
                  key: Key(
                    'sets_bonus_selected_info_${g.familyKey}_${g.minPieces}',
                  ),
                  data: entityInfoForSetBonusTier(
                    _optionFor(g.familyKey)!,
                    g.minPieces,
                  ),
                  enabled: true,
                  child: InputChip(
                    key: Key(
                      'sets_bonus_goal_active_${g.familyKey}_${g.minPieces}',
                    ),
                    label: Text(g.display),
                    avatar: const Icon(Icons.info_outline, size: 16),
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
            hintText: 'Search name or perk description…',
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
        else if (all.isEmpty)
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
            constraints: const BoxConstraints(maxHeight: 320),
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
                  final tier = _tierFor(family.name);
                  final familyInfo = entityInfoForSetBonusFamily(family);
                  final twoPreview = family.twoPcDescription.trim().isNotEmpty
                      ? family.twoPcDescription.trim()
                      : family.twoPcName.trim();
                  return ListTile(
                    key: Key('sets_bonus_family_row_${family.name}'),
                    dense: true,
                    isThreeLine: twoPreview.isNotEmpty,
                    title: EntityInfoHotspot(
                      key: Key('sets_bonus_family_info_${family.name}'),
                      data: familyInfo,
                      enabled: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              family.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: neonBody(
                                color: palette.foreground,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: palette.muted,
                          ),
                        ],
                      ),
                    ),
                    subtitle: twoPreview.isEmpty
                        ? null
                        : Text(
                            twoPreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: neonBody(
                              color: palette.muted,
                              fontSize: 11,
                            ),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tierChip(
                          family: family,
                          tier: 2,
                          selected: tier == 2,
                        ),
                        const SizedBox(width: 6),
                        _tierChip(
                          family: family,
                          tier: 4,
                          selected: tier == 4,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        if (_query.isNotEmpty && families.isEmpty && all.isNotEmpty)
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
          '${all.isEmpty ? '' : '${all.length} bonuses available. Hover for perk text.'}',
          key: const Key('sets_bonus_goals_hint'),
          style: neonBody(color: palette.muted, fontSize: 11),
        ),
      ],
    );
  }
}

/// Compact neon “None” control (replaces Material ChoiceChip).
class _NoneChoice extends StatelessWidget {
  const _NoneChoice({
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final borderColor = selected
        ? palette.accent.withValues(alpha: 0.45)
        : palette.line;
    final bg = selected
        ? palette.accent.withValues(alpha: kFlapChannelWashAlpha)
        : palette.background;
    final fg = selected ? palette.foreground : palette.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('sets_bonus_goal_none'),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: kFlapRuleThickness),
            borderRadius: BorderRadius.circular(kFlapRadius),
          ),
          child: Text(
            'None'.toUpperCase(),
            style: neonDisplay(
              color: fg,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
