import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'builds_optimize_controller.dart';

/// Weapons Optimize results panel — same confirm / tabs shape as armor.
///
/// Shown after armor result is confirmed or applied. Reuses the Optimize
/// panel chrome (tabs, Use this result / Cancel).
class BuildsWeaponOptimizeResultsPanel extends StatelessWidget {
  const BuildsWeaponOptimizeResultsPanel({
    super.key,
    required this.controller,
    required this.onUseResult,
    required this.onCancel,
  });

  final BuildsOptimizeController controller;
  final Future<void> Function(int index) onUseResult;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final combos = controller.weaponCombinations;
    if (combos.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected =
        controller.weaponSelectedIndex.clamp(0, combos.length - 1);
    final combo = combos[selected];
    final topCount = combos.length < 3 ? combos.length : 3;

    return Card(
      key: const Key('builds_weapon_optimize_results_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              combo.isSubstitute
                  ? 'Weapons (substitute — ${combo.reason ?? kWeaponOptimizeNoCsvReason})'
                  : 'Weapons results',
              key: const Key('builds_weapon_optimize_caption'),
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const Key('builds_weapon_optimize_result_tabs'),
              segments: [
                for (var i = 0; i < topCount; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(i == 0 ? '#1 Best' : '#${i + 1}'),
                  ),
              ],
              selected: {selected < topCount ? selected : 0},
              onSelectionChanged: (s) =>
                  controller.selectWeaponResult(s.first),
            ),
            const SizedBox(height: 8),
            Wrap(
              key: Key('builds_weapon_optimize_metrics_${selected + 1}'),
              spacing: 16,
              runSpacing: 8,
              children: [
                _metric(
                  context,
                  palette,
                  'Score',
                  combo.isSubstitute ? '—' : '${combo.score}',
                ),
                _metric(
                  context,
                  palette,
                  'Source',
                  combo.isSubstitute
                      ? kWeaponOptimizeSubstituteLabel
                      : kWeaponOptimizeOptimizedLabel,
                ),
                if (combo.reason != null)
                  _metric(context, palette, 'Reason', combo.reason!),
              ],
            ),
            const SizedBox(height: 8),
            Text('Weapons', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Table(
              key: const Key('builds_weapon_optimize_table'),
              columnWidths: const {
                0: FlexColumnWidth(1.1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.4),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Slot',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'Item',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Source',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Note',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                for (final pick in combo.picks)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(_slotLabel(pick.slot)),
                      ),
                      Text(
                        [
                          pick.item.name ?? '${pick.item.itemHash}',
                          if (pick.item.isExotic) ' (exotic)',
                        ].join(),
                      ),
                      Text(pick.sourceLabel),
                      Text(pick.note ?? '—'),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  key: const Key('builds_weapon_optimize_use_result'),
                  onPressed: controller.applying
                      ? null
                      : () => onUseResult(selected),
                  child: const Text('Use this result'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('builds_weapon_optimize_cancel'),
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    FlapPalette palette,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: neonMono(color: palette.muted, fontSize: 10)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }

  String _slotLabel(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.primary:
        return 'Kinetic';
      case EquipmentSlot.special:
        return 'Energy';
      case EquipmentSlot.heavy:
        return 'Power';
      default:
        return slot.wireName;
    }
  }
}
