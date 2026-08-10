import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_bonus_goals_editor.dart';
import 'sets_models.dart';

/// Create Armor: Type → Class lock → optional goals → name preview.
///
/// Piece / compare UI stays hidden until Type+Class locked ([typeClassLocked]).
class SetsCreateWizard extends StatelessWidget {
  const SetsCreateWizard({
    super.key,
    required this.setType,
    this.guardianClass,
    this.goals = const [],
    this.availableFamilies = const [],
    this.namePreview = '',
    this.nameController,
    this.onTypeChanged,
    this.onClassChanged,
    this.onGoalsChanged,
    this.onCreate,
    this.isLegalCombo,
    this.types = const ['armor', 'weapon', 'mod', 'pair', 'fashion'],
    this.classes = const ['Titan', 'Hunter', 'Warlock'],
  });

  final String setType;
  final String? guardianClass;
  final List<SetsBonusGoalData> goals;
  final List<String> availableFamilies;
  final String namePreview;
  final TextEditingController? nameController;
  final ValueChanged<String>? onTypeChanged;
  final ValueChanged<String>? onClassChanged;
  final ValueChanged<List<SetsBonusGoalData>>? onGoalsChanged;
  final VoidCallback? onCreate;
  final bool Function(List<SetsBonusGoalData>)? isLegalCombo;
  final List<String> types;
  final List<String> classes;

  bool get typeClassLocked {
    if (setType != 'armor') return setType.isNotEmpty;
    return setType == 'armor' &&
        guardianClass != null &&
        guardianClass!.isNotEmpty;
  }

  bool get showArmorExtras => setType == 'armor' && typeClassLocked;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return SingleChildScrollView(
      key: const Key('sets_create_wizard'),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create set',
          style: neonBody(
            color: palette.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: kSpace12),
        Text('Type', style: neonBody(color: palette.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          key: const Key('sets_create_type'),
          spacing: 8,
          children: [
            for (final t in types)
              ChoiceChip(
                key: Key('sets_create_type_$t'),
                label: Text(t),
                selected: setType == t,
                onSelected: onTypeChanged == null
                    ? null
                    : (_) => onTypeChanged!(t),
              ),
          ],
        ),
        if (setType == 'armor') ...[
          const SizedBox(height: kSpace12),
          Text('Class', style: neonBody(color: palette.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            key: const Key('sets_create_class'),
            spacing: 8,
            children: [
              for (final c in classes)
                ChoiceChip(
                  key: Key('sets_create_class_$c'),
                  label: Text(c),
                  selected: guardianClass == c,
                  onSelected: onClassChanged == null
                      ? null
                      : (_) => onClassChanged!(c),
                ),
            ],
          ),
        ],
        if (!typeClassLocked)
          Padding(
            padding: const EdgeInsets.only(top: kSpace16),
            child: Text(
              setType == 'armor'
                  ? 'Lock Type and Class to continue'
                  : 'Select a type to continue',
              key: const Key('sets_create_lock_hint'),
              style: neonBody(color: palette.muted, fontSize: 13),
            ),
          )
        else ...[
          // Piece UI deliberately absent until locked — proved by tests.
          if (showArmorExtras) ...[
            const SizedBox(height: kSpace16),
            SetsBonusGoalsEditor(
              goals: goals,
              availableFamilies: availableFamilies,
              onChanged: onGoalsChanged,
              isLegalCombo: isLegalCombo,
            ),
          ],
          const SizedBox(height: kSpace16),
          TextField(
            key: const Key('sets_create_name'),
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name (blank → auto)',
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
          const SizedBox(height: kSpace16),
          FilledButton(
            key: const Key('sets_create_button'),
            onPressed: onCreate,
            child: const Text('Create'),
          ),
        ],
        // Sentinel: piece/compare UI must not appear until locked.
        if (!typeClassLocked)
          const SizedBox.shrink(key: Key('sets_create_pieces_hidden')),
      ],
      ),
    );
  }
}
