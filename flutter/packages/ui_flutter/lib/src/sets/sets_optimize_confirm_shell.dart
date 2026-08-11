import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';
import 'sets_neon_chrome.dart';

/// Optimizer confirm-only shell: kit matrix + single apply (BR-OPT-004).
///
/// Never writes on open; apply only after confirm. Replace-all warning when
/// [hasPins] is true.
class SetsOptimizeConfirmShell extends StatelessWidget {
  const SetsOptimizeConfirmShell({
    super.key,
    required this.kits,
    this.selectedKitId,
    this.onSelectKit,
    this.onConfirmApply,
    this.onCancel,
    this.hasPins = false,
    this.classLabel,
    this.exoticLabel,
    this.bonusGoalsLabel,
    this.running = false,
    this.emptyMessage,
  });

  final List<SetsOptimizeKitRowData> kits;
  final String? selectedKitId;
  final ValueChanged<String>? onSelectKit;
  final VoidCallback? onConfirmApply;
  final VoidCallback? onCancel;
  final bool hasPins;
  final String? classLabel;
  final String? exoticLabel;
  final String? bonusGoalsLabel;
  final bool running;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final selected = kits.where((k) => k.id == selectedKitId).toList();
    final canApply = selected.isNotEmpty && onConfirmApply != null && !running;

    return Column(
      key: const Key('sets_optimize_confirm_shell'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Optimizer · DIM-style · confirm-only'.toUpperCase(),
          key: const Key('sets_optimize_title'),
          style: neonDisplay(
            color: palette.accent,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: kSpace8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (classLabel != null)
              Text(
                'Class: $classLabel',
                key: const Key('sets_optimize_seed_class'),
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
            if (exoticLabel != null)
              Text(
                'Exotic: $exoticLabel',
                key: const Key('sets_optimize_seed_exotic'),
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
            if (bonusGoalsLabel != null)
              Text(
                'Goals: $bonusGoalsLabel',
                key: const Key('sets_optimize_seed_bonus'),
                style: neonBody(color: palette.muted, fontSize: 12),
              ),
          ],
        ),
        if (hasPins) ...[
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
              'Applying a kit will replace all current pins.',
              style: neonBody(
                color: palette.warning,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: kSpace12),
        if (running)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                key: Key('sets_optimize_running'),
              ),
            ),
          )
        else if (kits.isEmpty)
          Text(
            emptyMessage ?? 'No kits — adjust constraints and re-run',
            key: const Key('sets_optimize_empty'),
            style: neonBody(color: palette.muted, fontSize: 13),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                key: const Key('sets_optimize_kit_matrix'),
                columnSpacing: 10,
                columns: const [
                  DataColumn(label: Text('Kit')),
                  DataColumn(label: Text('Σ'), numeric: true),
                  DataColumn(label: Text('Δ'), numeric: true),
                  DataColumn(label: Text('Goals')),
                  DataColumn(label: Text('Pieces')),
                ],
                rows: [
                  for (final kit in kits)
                    DataRow(
                      key: ValueKey('sets_optimize_kit_${kit.id}'),
                      selected: kit.id == selectedKitId,
                      onSelectChanged: onSelectKit == null
                          ? null
                          : (_) => onSelectKit!(kit.id),
                      cells: [
                        DataCell(Text(kit.id)),
                        DataCell(Text('${kit.total}')),
                        DataCell(
                          Text(
                            kit.deltaVsCurrent == null
                                ? '—'
                                : (kit.deltaVsCurrent! >= 0
                                    ? '+${kit.deltaVsCurrent}'
                                    : '${kit.deltaVsCurrent}'),
                            key: Key('sets_optimize_delta_${kit.id}'),
                            style: TextStyle(
                              color: kit.deltaVsCurrent == null
                                  ? null
                                  : kit.deltaVsCurrent! >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                        ),
                        DataCell(Text(kit.goalsLabel)),
                        DataCell(
                          Text(
                            kit.slotNames.values.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: kSpace12),
        Row(
          children: [
            TextButton(
              key: const Key('sets_optimize_cancel'),
              style: setsNeonGhostStyle(palette),
              onPressed: onCancel,
              child: Text('Cancel', style: setsNeonBtnLabel(palette.muted)),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('sets_optimize_confirm_apply'),
              style: setsNeonPrimaryStyle(palette),
              onPressed: canApply ? onConfirmApply : null,
              child: Text(
                (hasPins ? 'Replace all with kit' : 'Apply kit').toUpperCase(),
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
}
