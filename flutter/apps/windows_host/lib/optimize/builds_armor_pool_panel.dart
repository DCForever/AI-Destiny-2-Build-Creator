import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'builds_optimize_apply.dart';
import 'builds_optimize_controller.dart';

/// Read-only Armor pool tab: set coverage (2+ / 1 / 0) per slot from DIM CSV.
class BuildsArmorPoolPanel extends StatelessWidget {
  const BuildsArmorPoolPanel({
    super.key,
    required this.controller,
    required this.guardianClass,
  });

  final BuildsOptimizeController controller;
  final GuardianClass guardianClass;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final reason = controller.disabledReason;
    if (reason != null || controller.armorItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No DIM Armor CSV imported.\n'
          'Open Settings, import a DIM Armor CSV, then return here.\n'
          'Optimize stays disabled until a CSV is available.',
          key: const Key('builds_armor_pool_no_csv'),
          style: neonMono(color: palette.muted, fontSize: 12),
        ),
      );
    }

    final report = controller.coverageForClass(guardianClass);
    if (report == null) {
      return const SizedBox.shrink();
    }

    final imported = controller.csvImportedAt;
    final stamp = imported == null
        ? 'unknown time'
        : _formatLocalStamp(imported);
    final classLabel = _classLabel(guardianClass);
    final header =
        'From DIM armor CSV · imported $stamp · $classLabel · '
        '${report.slotGoalsMet} of ${report.slotGoalsTotal} slot goals met';

    return ListView(
      key: const Key('builds_armor_pool_panel'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          header,
          key: const Key('builds_armor_pool_header'),
          style: neonMono(color: palette.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text(
          'Set coverage (goal: 2 pieces per set per slot). '
          'Universe: ${report.setUniverseCount} sets '
          '(derived from data'
          '${report.setUniverseCount == 28 ? '' : '; not 28'}'
          ').',
          style: neonMono(color: palette.muted, fontSize: 10),
        ),
        const SizedBox(height: 12),
        Table(
          key: const Key('builds_armor_pool_table'),
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(2.2),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(1.4),
          },
          children: [
            TableRow(
              children: [
                _h('Slot'),
                _h(
                  'Sets with 2+ pieces '
                  '(goal: ${report.setUniverseCount} of ${report.setUniverseCount})',
                ),
                _h('Sets with 1 piece'),
                _h('Sets with none'),
              ],
            ),
            for (final row in report.slotRows)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_slotLabel(row.slot)),
                  ),
                  Text(
                    '${row.setsWithTwoPlus} of ${row.setUniverseCount}',
                    key: Key(
                      'builds_armor_pool_two_plus_${row.slot.wireName}',
                    ),
                  ),
                  Text(
                    '${row.setsWithOne}',
                    key: Key('builds_armor_pool_one_${row.slot.wireName}'),
                  ),
                  Text(
                    '${row.setsWithNone}',
                    key: Key('builds_armor_pool_none_${row.slot.wireName}'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

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

  String _classLabel(GuardianClass c) {
    switch (c) {
      case GuardianClass.warlock:
        return 'Warlock';
      case GuardianClass.titan:
        return 'Titan';
      case GuardianClass.hunter:
        return 'Hunter';
    }
  }

  String _formatLocalStamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

/// Whether Optimize should be enabled given CSV state.
bool buildsOptimizeEnabled(BuildsOptimizeController controller) =>
    controller.disabledReason == null && controller.armorItems.isNotEmpty;

/// Reason string for disabled Optimize (or null when enabled).
String? buildsOptimizeDisabledReason(BuildsOptimizeController controller) =>
    buildsOptimizeEnabled(controller)
        ? null
        : (controller.disabledReason ?? kBuildsOptimizeNoCsvReason);
