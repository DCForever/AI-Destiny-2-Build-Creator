import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import '../optimizer/optimizer_format.dart';
import 'builds_optimize_apply.dart';
import 'builds_optimize_controller.dart';

/// Optimize results panel: top-3 tabs + Show all, Use this result / Cancel.
class BuildsOptimizeResultsPanel extends StatelessWidget {
  const BuildsOptimizeResultsPanel({
    super.key,
    required this.controller,
    required this.statTargets,
    required this.onUseResult,
    required this.onCancel,
  });

  final BuildsOptimizeController controller;
  final SoftStatTargets statTargets;
  final Future<void> Function(int index) onUseResult;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final combos = controller.combinations;
    if (combos.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = controller.selectedIndex.clamp(0, combos.length - 1);
    final combo = combos[selected];
    final topCount = combos.length < kOptimizerTopCompareCount
        ? combos.length
        : kOptimizerTopCompareCount;

    return Card(
      key: const Key('builds_optimize_results_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kBuildsOptimizeAdvisoryCaption,
              key: const Key('builds_optimize_advisory'),
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const Key('builds_optimize_result_tabs'),
              segments: [
                for (var i = 0; i < topCount; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(i == 0 ? '#1 Best' : '#${i + 1}'),
                  ),
              ],
              selected: {selected < topCount ? selected : 0},
              onSelectionChanged: (s) => controller.selectResult(s.first),
            ),
            if (combos.length > kOptimizerTopCompareCount) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('builds_optimize_show_all'),
                  onPressed: () =>
                      controller.setShowAll(!controller.showAll),
                  child: Text(
                    controller.showAll
                        ? 'Hide full list'
                        : 'Show all ${combos.length}',
                  ),
                ),
              ),
            ],
            if (controller.showAll) ...[
              const SizedBox(height: 4),
              SizedBox(
                key: const Key('builds_optimize_all_list'),
                height: 120,
                child: ListView.builder(
                  itemCount: combos.length,
                  itemBuilder: (context, i) {
                    final c = combos[i];
                    return ListTile(
                      dense: true,
                      selected: i == selected,
                      title: Text(
                        formatSuggestionTitle(
                          indexOneBased: i + 1,
                          combo: c,
                        ),
                      ),
                      onTap: () => controller.selectResult(i),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            _MetricsRow(
              combo: combo,
              selectedOneBased: selected + 1,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final armor = _ArmorTable(
                  combo: combo,
                  items: controller.armorItems,
                );
                final stats = _StatsTable(
                  combo: combo,
                  targets: statTargets,
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: armor),
                      const SizedBox(width: 12),
                      Expanded(child: stats),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    armor,
                    const SizedBox(height: 8),
                    stats,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  key: const Key('builds_optimize_use_result'),
                  onPressed: controller.applying
                      ? null
                      : () => onUseResult(selected),
                  child: const Text('Use this result'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('builds_optimize_cancel'),
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
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.combo,
    required this.selectedOneBased,
  });

  final ArmorCombination combo;
  final int selectedOneBased;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final setBox = formatCombinationSetBonusBox(combo);
    return Wrap(
      key: Key('builds_optimize_metrics_$selectedOneBased'),
      spacing: 16,
      runSpacing: 8,
      children: [
        _metric(context, palette, 'Score', '${combo.score}'),
        _metric(
          context,
          palette,
          'Pieces reused from other builds',
          '${combo.reusePieceCount} of 5',
        ),
        _metric(context, palette, 'Set bonus', setBox),
        _metric(
          context,
          palette,
          'Stat targets',
          combo.meetsSoftThresholds ? 'All met' : 'Some below',
        ),
      ],
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
}

class _ArmorTable extends StatelessWidget {
  const _ArmorTable({required this.combo, required this.items});

  final ArmorCombination combo;
  final List<FillInInventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Armor', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Table(
          key: const Key('builds_optimize_armor_table'),
          columnWidths: const {
            0: FlexColumnWidth(1.1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(1.4),
          },
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('Slot', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('Item', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Set', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Where it is', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            for (final p in combo.pieces)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(_slotLabel(p.slot)),
                  ),
                  Text(
                    [
                      if (p.itemName != null && p.itemName!.trim().isNotEmpty)
                        p.itemName!.trim()
                      else
                        '${p.itemHash}',
                      if (p.isExotic) ' (exotic)',
                    ].join(),
                  ),
                  Text(
                    p.isExotic
                        ? 'Exotic'
                        : (p.setBonusKey?.trim().isNotEmpty == true
                            ? p.setBonusKey!.trim()
                            : '—'),
                  ),
                  Text(
                    formatArmorLocationLabel(
                      locationForInstanceId(
                        items: items,
                        instanceId: p.instanceId,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  String _slotLabel(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return 'Helmet';
      case EquipmentSlot.arms:
        return 'Arms';
      case EquipmentSlot.chest:
        return 'Chest';
      case EquipmentSlot.legs:
        return 'Legs';
      case EquipmentSlot.classItem:
        return 'Class item';
      default:
        return slot.wireName;
    }
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.combo, required this.targets});

  final ArmorCombination combo;
  final SoftStatTargets targets;

  static const _order = ArmorStatName.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Stats', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Table(
          key: const Key('builds_optimize_stats_table'),
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('Stat', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Target', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(''),
              ],
            ),
            for (final s in _order)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(s.wireName),
                  ),
                  Text('${combo.estimatedStats[s] ?? 0}'),
                  Text('${targets[s] ?? 'none'}'),
                  _pill(
                    context,
                    total: combo.estimatedStats[s] ?? 0,
                    target: targets[s],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _pill(BuildContext context, {required int total, int? target}) {
    final below = target != null && total < target;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key(below ? 'builds_optimize_stat_below' : 'builds_optimize_stat_ok'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: below
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          below ? 'Below' : 'OK',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
