import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import 'sets_models.dart';

/// Owned-only compare table with instance identity (not Catalog embed).
class SetsOwnedCompareTable extends StatelessWidget {
  const SetsOwnedCompareTable({
    super.key,
    required this.rows,
    this.onSelect,
    this.emptyMessage = 'No owned armor for this slot',
    this.signedOut = false,
  });

  final List<SetsOwnedCompareRowData> rows;
  final ValueChanged<SetsOwnedCompareRowData>? onSelect;
  final String emptyMessage;
  final bool signedOut;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final labels = kArmorBoardEofStatLabels;

    if (signedOut) {
      return Text(
        'Sign in and sync to compare owned armor',
        key: const Key('sets_owned_compare_signed_out'),
        style: neonBody(color: palette.muted, fontSize: 13),
      );
    }

    if (rows.isEmpty) {
      return Text(
        emptyMessage,
        key: const Key('sets_owned_compare_empty'),
        style: neonBody(color: palette.muted, fontSize: 13),
      );
    }

    return Column(
      key: const Key('sets_owned_compare_table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ensure Catalog page chrome keys are absent (fill is not Catalog embed).
        Text(
          'Owned compare',
          key: const Key('sets_fill_owned_compare'),
          style: neonBody(
            color: palette.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: kSpace8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            headingRowHeight: 32,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 48,
            columns: [
              const DataColumn(label: Text('Name')),
              const DataColumn(label: Text('Σ'), numeric: true),
              for (final l in labels) DataColumn(label: Text(l), numeric: true),
              const DataColumn(label: Text('Power'), numeric: true),
              const DataColumn(label: Text('Bonus')),
              const DataColumn(label: Text('Id')),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  key: ValueKey('sets_owned_row_${r.instanceId}'),
                  onSelectChanged: r.exoticBlocked || onSelect == null
                      ? null
                      : (_) => onSelect!(r),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          if (r.isExotic)
                            const Text('★ ', key: Key('sets_owned_exotic_mark')),
                          Flexible(child: Text(r.itemName)),
                          if (r.exoticBlocked)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                'exotic blocked',
                                key: Key(
                                  'sets_owned_exotic_block_${r.instanceId}',
                                ),
                                style: neonBody(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text('${r.total}')),
                    for (final l in labels)
                      DataCell(Text('${r.stats[l] ?? 0}')),
                    DataCell(Text('${r.power ?? '—'}')),
                    DataCell(
                      Text(
                        r.bonusFit ? 'fit' : '—',
                        key: Key('sets_owned_bonus_${r.instanceId}'),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.instanceId,
                        key: Key('sets_owned_instance_${r.instanceId}'),
                        style: neonMono(fontSize: 10),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
