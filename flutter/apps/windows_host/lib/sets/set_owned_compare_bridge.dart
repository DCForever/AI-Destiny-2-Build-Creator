import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import 'sets_library_controller.dart' show SetSlotPickResult;

/// Host bridge: owned-only compare pick (replaces Catalog page embed for fill).
///
/// Returns null when cancelled. Never invents unowned armor.
Future<SetSlotPickResult?> showOwnedComparePicker({
  required BuildContext context,
  required String targetSlot,
  required List<OwnedArmorCompareRow> ownedRows,
  required bool signedOut,
  bool excludeExotic = false,
  Iterable<({String slot, bool isExotic, String? name})> otherOccupied =
      const [],
}) async {
  final filtered = filterOwnedWithInstanceIdentity(ownedRows);
  final ranked = rankOwnedArmorCompare(filtered);
  final viewRows = [
    for (final r in ranked)
      SetsOwnedCompareRowData(
        instanceId: r.instanceId,
        itemHash: r.itemHash,
        itemName: r.itemName,
        isExotic: r.isExotic,
        power: r.power,
        total: r.totalStats,
        stats: {
          for (final s in ArmorStatName.all) s.wireName: r.statOf(s),
        },
        bonusFit: r.bonusFit,
        setBonusKey: r.setBonusKey,
        exoticBlocked: excludeExotic && r.isExotic ||
            wouldBlockSecondExotic(
              candidateIsExotic: r.isExotic,
              otherOccupied: otherOccupied,
            ),
      ),
  ];

  return showDialog<SetSlotPickResult>(
    context: context,
    builder: (ctx) {
      return Dialog(
        key: const Key('sets_owned_compare_dialog'),
        child: SizedBox(
          width: 900,
          height: 560,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pick owned · $targetSlot',
                  key: const Key('sets_fill_slot_title'),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SetsOwnedCompareTable(
                      rows: viewRows,
                      signedOut: signedOut,
                      onSelect: (row) {
                        if (row.exoticBlocked) return;
                        Navigator.of(ctx).pop(
                          SetSlotPickResult(
                            itemHash: row.itemHash,
                            itemName: row.itemName,
                            instanceId: row.instanceId,
                            isExotic: row.isExotic,
                            catalogKind: 'armor',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('sets_owned_compare_cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
