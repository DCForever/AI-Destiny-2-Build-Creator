import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';

/// Detail-card block for a saved Fill In plan (Armor / Weapons subsections).
///
/// Placed under Fill In / Optimize / Apply buttons and above DIM link details.
class FillInSavedPlanCard extends StatelessWidget {
  const FillInSavedPlanCard({super.key, required this.plan});

  final FillInSavedBuildPlan plan;

  @override
  Widget build(BuildContext context) {
    final title = fillInSavedPlanTitle(plan);
    final armorRows = [
      for (final r in plan.rows)
        if (r.isArmor) r,
    ];
    final weaponRows = [
      for (final r in plan.rows)
        if (r.isWeapon) r,
    ];
    final hasStructured = armorRows.isNotEmpty || weaponRows.isNotEmpty;

    return Card(
      key: Key('fill_in_saved_plan_${plan.buildId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              key: const Key('fill_in_saved_title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (hasStructured) ...[
              if (armorRows.isNotEmpty) ...[
                Text(
                  'Armor',
                  key: const Key('fill_in_saved_section_armor'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final row in armorRows) _rowLine(context, row),
                const SizedBox(height: 8),
              ],
              if (weaponRows.isNotEmpty) ...[
                Text(
                  'Weapons',
                  key: const Key('fill_in_saved_section_weapons'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final row in weaponRows) _rowLine(context, row),
              ],
            ] else ...[
              // Legacy flat missing list (blanks already dropped on read).
              if (plan.missing.isEmpty)
                const Text('None', key: Key('fill_in_saved_missing_empty'))
              else
                Text(
                  plan.missing.join('\n'),
                  key: const Key('fill_in_saved_missing_list'),
                ),
              if (plan.similarWeaponName != null &&
                  plan.similarWeaponName!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Similar: ${plan.similarWeaponName}'
                  '${plan.similarForName == null || plan.similarForName!.trim().isEmpty ? '' : ' (for ${plan.similarForName})'}',
                  key: const Key('fill_in_saved_similar'),
                ),
              ],
              if (plan.hasAppliedSubstitutes) ...[
                const SizedBox(height: 8),
                Text(
                  'Filled in: ${[
                    for (final a in plan.applied)
                      if (a.label.trim().isNotEmpty) a.label.trim(),
                  ].join(', ')}',
                  key: const Key('fill_in_saved_applied'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowLine(BuildContext context, FillInSavedSlotRow row) {
    final name = row.itemName.trim();
    final text = name.isEmpty
        ? '${row.slotLabel} · ${row.state}'
        : '${row.slotLabel} · $name · ${row.state}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        key: Key('fill_in_saved_row_${row.slotWire}'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Title: `Saved Fill In · saved <local date time>` when [plan.updatedAt] parses.
String fillInSavedPlanTitle(FillInSavedBuildPlan plan) {
  final stamp = plan.updatedAt?.trim();
  if (stamp == null || stamp.isEmpty) {
    return 'Saved Fill In';
  }
  final parsed = DateTime.tryParse(stamp);
  if (parsed == null) {
    return 'Saved Fill In · saved $stamp';
  }
  final local = parsed.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return 'Saved Fill In · saved $y-$m-$d $hh:$mm';
}
