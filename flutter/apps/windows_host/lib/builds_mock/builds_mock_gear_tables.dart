import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../fill_in/fill_in_saved_plan_card.dart';
import 'builds_mock_models.dart';

/// Row status for armor / weapon tables.
enum BuildsMockSlotStatus { held, filled, proposed, missing, none }

String buildsMockSlotStatusLabel(BuildsMockSlotStatus status) {
  switch (status) {
    case BuildsMockSlotStatus.held:
      return 'Held';
    case BuildsMockSlotStatus.filled:
      return 'Filled in';
    case BuildsMockSlotStatus.proposed:
      return 'Proposed';
    case BuildsMockSlotStatus.missing:
      return 'Missing';
    case BuildsMockSlotStatus.none:
      return '';
  }
}

BuildsMockSlotStatus buildsMockSlotStatusFromWire(String? wire) {
  switch ((wire ?? '').trim().toLowerCase()) {
    case 'held':
      return BuildsMockSlotStatus.held;
    case 'filled':
      return BuildsMockSlotStatus.filled;
    case 'proposed':
      return BuildsMockSlotStatus.proposed;
    case 'missing':
      return BuildsMockSlotStatus.missing;
    default:
      return BuildsMockSlotStatus.none;
  }
}

class BuildsMockArmorRow {
  const BuildsMockArmorRow({
    required this.slotLabel,
    required this.itemName,
    required this.setName,
    required this.statTotal,
    required this.isExotic,
    required this.status,
    this.mods = const [],
  });

  final String slotLabel;
  final String itemName;
  final String setName;
  final int? statTotal;
  final bool isExotic;
  final BuildsMockSlotStatus status;
  final List<String> mods;
}

class BuildsMockWeaponRow {
  const BuildsMockWeaponRow({
    required this.slotLabel,
    required this.itemName,
    required this.note,
    required this.isExotic,
    required this.status,
  });

  final String slotLabel;
  final String itemName;
  final String note;
  final bool isExotic;
  final BuildsMockSlotStatus status;
}

/// Armor table: slot | item | set | stat | status (+ optional per-slot mods).
class BuildsMockArmorTable extends StatelessWidget {
  const BuildsMockArmorTable({
    super.key,
    required this.rows,
    this.showMods = false,
  });

  final List<BuildsMockArmorRow> rows;
  final bool showMods;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('builds_mock_armor_table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          _armorLine(context, palette, row),
          if (showMods && row.mods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final mod in row.mods)
                    _chip(palette, mod, key: Key('builds_mock_armor_mod_$mod')),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _armorLine(
    BuildContext context,
    FlapPalette palette,
    BuildsMockArmorRow row,
  ) {
    final itemColor = row.isExotic ? palette.warning : palette.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              row.slotLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: itemColor,
                fontWeight: row.isExotic ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.setName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: neonMono(color: palette.muted, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              row.statTotal?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 54,
            child: _status(palette, row.status),
          ),
        ],
      ),
    );
  }
}

/// Weapons table: Kinetic / Energy / Power.
class BuildsMockWeaponTable extends StatelessWidget {
  const BuildsMockWeaponTable({super.key, required this.rows});

  final List<BuildsMockWeaponRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('builds_mock_weapon_table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    row.slotLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: neonMono(color: palette.muted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: row.itemName == 'Not in DIM link'
                          ? palette.muted
                          : (row.isExotic
                              ? palette.warning
                              : palette.foreground),
                      fontWeight:
                          row.isExotic ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (row.note.isNotEmpty)
                  Text(
                    row.note,
                    style: neonMono(color: palette.muted, fontSize: 11),
                  ),
                SizedBox(
                  width: 54,
                  child: _status(palette, row.status),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BuildsMockStatsRow extends StatelessWidget {
  const BuildsMockStatsRow({super.key, required this.stats});

  final List<MockStatTotal> stats;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (stats.isEmpty) {
      return Text(
        'Stats unavailable',
        key: const Key('builds_mock_stats_unavailable'),
        style: neonMono(color: palette.muted, fontSize: 11),
      );
    }
    return Wrap(
      key: const Key('builds_mock_stats_row'),
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final s in stats)
          Tooltip(
            message: s.label,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle_outlined, size: 12, color: palette.muted),
                const SizedBox(width: 5),
                Text(
                  '${s.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BuildsMockSetBonusBoxes extends StatelessWidget {
  const BuildsMockSetBonusBoxes({super.key, required this.bonuses});

  final List<MockSetBonus> bonuses;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    if (bonuses.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('builds_mock_set_bonus_boxes'),
      children: [
        for (final b in bonuses)
          Container(
            key: Key('builds_mock_set_bonus_${b.setId}_${b.tier}'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              border: Border.all(color: palette.line, width: kFlapRuleThickness),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.grid_view_outlined, size: 16, color: palette.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.pieces >= 4
                            ? b.setName
                            : '${b.tier} ${b.setName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      for (final line in b.text.split('\n'))
                        if (line.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              line.trim(),
                              style: neonMono(
                                color: palette.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.line),
                    color: palette.surface,
                  ),
                  child: Text(
                    b.tier,
                    style: neonMono(fontSize: 10, color: palette.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Widget _status(FlapPalette palette, BuildsMockSlotStatus status) {
  final label = buildsMockSlotStatusLabel(status);
  if (label.isEmpty) return const SizedBox.shrink();
  final color = status == BuildsMockSlotStatus.missing
      ? palette.danger
      : palette.success;
  return Text(
    label,
    textAlign: TextAlign.right,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget _chip(FlapPalette palette, String label, {Key? key}) {
  return Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: palette.line),
      color: palette.surface,
    ),
    child: Text(label, style: neonMono(fontSize: 11)),
  );
}

/// Map saved-plan wire state through the shared label helper (tests / UI).
String buildsMockSavedStateLabel(String wire) =>
    fillInSavedRowStateLabel(wire);
