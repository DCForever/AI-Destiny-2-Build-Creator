import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_bonus_goals_editor.dart';
import 'sets_models.dart';
import 'sets_tag_multi_select.dart';

/// Armor create path: Type → Class → Bonus → Name.
const kSetsCreateArmorStepLabels = ['type', 'class', 'bonus', 'name'];

/// Non-Armor create path: Type → thin Name (skips Class/Bonus).
const kSetsCreateNonArmorStepLabels = ['type', 'name'];

/// Resolve step labels for the active type path.
List<String> setsCreateStepLabelsForType(String setType) =>
    setType == 'armor'
        ? kSetsCreateArmorStepLabels
        : kSetsCreateNonArmorStepLabels;

/// Max step index (inclusive) for [setType].
int setsCreateMaxStep(String setType) =>
    setsCreateStepLabelsForType(setType).length - 1;

/// Crumb text: `New set · type|class|bonus|name`.
String setsCreateCrumb({required String setType, required int step}) {
  final labels = setsCreateStepLabelsForType(setType);
  final i = step.clamp(0, labels.length - 1);
  return 'New set · ${labels[i]}';
}

/// Create set wizard body: **one step visible at a time** with step dots.
///
/// Piece / compare UI never mounts during create ([sets_create_pieces_hidden]).
/// Footer Back / Continue / Create lives on [SetsCreateWizardFooter] (modal).
class SetsCreateWizard extends StatelessWidget {
  const SetsCreateWizard({
    super.key,
    required this.setType,
    this.step = 0,
    this.guardianClass,
    this.goals = const [],
    this.families = const [],
    this.availableFamilies = const [],
    this.namePreview = '',
    this.nameController,
    this.tags = const [],
    this.onTypeChanged,
    this.onClassChanged,
    this.onGoalsChanged,
    this.onNameChanged,
    this.onTagsChanged,
    this.onCreate,
    this.isLegalCombo,
    this.isTagBlocked,
    this.types = const ['armor', 'weapon', 'mod', 'pair', 'fashion'],
    this.classes = const ['Titan', 'Hunter', 'Warlock'],
    this.showEmbeddedFooter = false,
    this.onBack,
    this.onContinue,
    this.onCancel,
    this.canContinue = true,
    this.createLabel = 'Create',
  });

  final String setType;

  /// Active step index (0-based). Armor: 0–3; non-Armor: 0–1.
  final int step;
  final String? guardianClass;
  final List<SetsBonusGoalData> goals;

  /// Full set-bonus catalog (name + perk descriptions) for goals editor.
  final List<SetsBonusFamilyOption> families;

  /// Name-only fallback when [families] is empty (tests).
  final List<String> availableFamilies;
  final String namePreview;
  final TextEditingController? nameController;
  final List<SetsTagData> tags;
  final ValueChanged<String>? onTypeChanged;
  final ValueChanged<String>? onClassChanged;
  final ValueChanged<List<SetsBonusGoalData>>? onGoalsChanged;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<List<SetsTagData>>? onTagsChanged;
  final VoidCallback? onCreate;
  final bool Function(List<SetsBonusGoalData>)? isLegalCombo;
  final bool Function(String label)? isTagBlocked;
  final List<String> types;
  final List<String> classes;

  /// When true, render [SetsCreateWizardFooter] under the step body (tests).
  final bool showEmbeddedFooter;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;
  final bool canContinue;
  final String createLabel;

  bool get isArmor => setType == 'armor';

  int get maxStep => setsCreateMaxStep(setType);

  bool get isFinalStep => step >= maxStep;

  List<String> get stepLabels => setsCreateStepLabelsForType(setType);

  String get crumb => setsCreateCrumb(setType: setType, step: step);

  /// Piece/compare UI is never shown during create.
  bool get piecesHidden => true;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final safeStep = step.clamp(0, maxStep);
    return LayoutBuilder(
      key: const Key('sets_create_wizard'),
      builder: (context, constraints) {
        final body = SingleChildScrollView(
          child: _buildStepBody(context, palette, safeStep),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              crumb,
              key: const Key('sets_create_crumb'),
              style: neonBody(
                color: palette.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kSpace12),
            _StepDots(
              key: const Key('sets_create_step_dots'),
              labels: stepLabels,
              active: safeStep,
            ),
            const SizedBox(height: kSpace16),
            if (constraints.hasBoundedHeight && constraints.maxHeight.isFinite)
              Expanded(child: body)
            else
              body,
            // Sentinel: piece/compare UI must not appear during any create step.
            const SizedBox.shrink(key: Key('sets_create_pieces_hidden')),
            if (showEmbeddedFooter)
              Padding(
                padding: const EdgeInsets.only(top: kSpace12),
                child: SetsCreateWizardFooter(
                  step: safeStep,
                  isFinalStep: safeStep >= maxStep,
                  canContinue: canContinue,
                  onBack: onBack,
                  onContinue: onContinue,
                  onCancel: onCancel,
                  onCreate: onCreate,
                  createLabel: createLabel,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStepBody(
    BuildContext context,
    FlapPalette palette,
    int safeStep,
  ) {
    if (!isArmor) {
      if (safeStep == 0) return _buildTypeStep(palette);
      return _buildNameStep(palette, thinShell: true);
    }
    switch (safeStep) {
      case 0:
        return _buildTypeStep(palette);
      case 1:
        return _buildClassStep(palette);
      case 2:
        return _buildBonusStep();
      default:
        return _buildNameStep(palette, thinShell: false);
    }
  }

  Widget _buildTypeStep(FlapPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set type (locked after create)',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('sets_create_type'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in types)
              ChoiceChip(
                key: Key('sets_create_type_$t'),
                label: Text(_titleCase(t)),
                selected: setType == t,
                onSelected: onTypeChanged == null ? null : (_) => onTypeChanged!(t),
              ),
          ],
        ),
        const SizedBox(height: kSpace12),
        Text(
          'Armor-first: full board for Armor only. Other types open a thin detail shell.',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClassStep(FlapPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Class (locked before any piece pick)',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('sets_create_class'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in classes)
              ChoiceChip(
                key: Key('sets_create_class_$c'),
                label: Text(c),
                selected: guardianClass == c,
                onSelected:
                    onClassChanged == null ? null : (_) => onClassChanged!(c),
              ),
          ],
        ),
        const SizedBox(height: kSpace12),
        Text(
          'G-SET-004 · Type and Class locked before pieces are shown or chosen.',
          style: neonBody(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBonusStep() {
    return SetsBonusGoalsEditor(
      goals: goals,
      families: families,
      availableFamilies: availableFamilies,
      onChanged: onGoalsChanged,
      isLegalCombo: isLegalCombo,
    );
  }

  Widget _buildNameStep(FlapPalette palette, {required bool thinShell}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (thinShell) ...[
          Text(
            'Non-Armor type selected. Class lock applies to Armor only. '
            'You get a thin detail shell (no full board).',
            key: const Key('sets_create_thin_shell_hint'),
            style: neonBody(color: palette.muted, fontSize: 13),
          ),
          const SizedBox(height: kSpace16),
        ],
        TextField(
          key: const Key('sets_create_name'),
          controller: nameController,
          onChanged: onNameChanged,
          decoration: InputDecoration(
            labelText: thinShell ? 'Optional name' : 'Name (blank → auto)',
            helperText: namePreview.isEmpty ? null : 'Preview: $namePreview',
            helperMaxLines: 2,
          ),
        ),
        if (namePreview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: kSpace4),
            child: Text(
              namePreview,
              key: const Key('sets_create_name_preview'),
              style: neonBody(color: palette.muted, fontSize: 12),
            ),
          ),
        if (!thinShell && (onTagsChanged != null || tags.isNotEmpty)) ...[
          const SizedBox(height: kSpace16),
          SetsTagMultiSelect(
            key: const Key('sets_create_tags'),
            selected: tags,
            isBlocked: isTagBlocked,
            onChanged: onTagsChanged,
          ),
        ],
      ],
    );
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

/// Modal footer: Back · Cancel · Continue | Create (final only).
class SetsCreateWizardFooter extends StatelessWidget {
  const SetsCreateWizardFooter({
    super.key,
    required this.step,
    required this.isFinalStep,
    this.canContinue = true,
    this.onBack,
    this.onContinue,
    this.onCancel,
    this.onCreate,
    this.createLabel = 'Create',
  });

  final int step;
  final bool isFinalStep;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;
  final VoidCallback? onCreate;
  final String createLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('sets_create_footer'),
      children: [
        if (step > 0)
          TextButton(
            key: const Key('sets_create_back'),
            onPressed: onBack,
            child: const Text('Back'),
          )
        else
          const SizedBox(width: 8, key: Key('sets_create_back_hidden')),
        const Spacer(),
        TextButton(
          key: const Key('sets_create_cancel'),
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        if (isFinalStep)
          FilledButton(
            key: const Key('sets_create_button'),
            onPressed: onCreate,
            child: Text(createLabel),
          )
        else
          FilledButton(
            key: const Key('sets_create_continue'),
            onPressed: canContinue ? onContinue : null,
            child: const Text('Continue'),
          ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    super.key,
    required this.labels,
    required this.active,
  });

  final List<String> labels;
  final int active;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: Key('sets_create_step_dot_$i'),
              height: 3,
              decoration: BoxDecoration(
                color: i == active
                    ? palette.accent
                    : i < active
                        ? palette.accent.withValues(alpha: 0.45)
                        : palette.line,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
