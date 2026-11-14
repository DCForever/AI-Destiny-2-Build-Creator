import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

/// When a saved/applied plan already names substitutes, keep those picks
/// instead of the fresh random roll from [planFillInSubstitutes].
///
/// Shared by the Fill In dialog and the headless weapon pass after Optimize
/// so existing weapon pins stay stable unless missing.
List<FillInSlotDiff> stabilizeFillInDiffsFromPlan({
  required List<FillInSlotDiff> diffs,
  required FillInSavedBuildPlan? plan,
  required List<FillInInventoryItem> inventory,
}) {
  if (plan == null) return diffs;
  final byWire = <String, ({String label, String? instanceId, int? itemHash})>{};
  for (final row in plan.rows) {
    if (row.state != 'proposed' && row.state != 'filled') continue;
    final name = row.itemName.trim();
    if (name.isEmpty) continue;
    byWire[row.slotWire] = (label: name, instanceId: null, itemHash: null);
  }
  for (final applied in plan.applied) {
    final name = applied.label.trim();
    if (name.isEmpty &&
        (applied.instanceId == null || applied.instanceId!.trim().isEmpty)) {
      continue;
    }
    byWire[applied.slotWire] = (
      label: name.isNotEmpty
          ? name
          : (byWire[applied.slotWire]?.label ?? ''),
      instanceId: applied.instanceId,
      itemHash: applied.itemHash,
    );
  }
  if (byWire.isEmpty) return diffs;

  final out = <FillInSlotDiff>[];
  for (final diff in diffs) {
    final saved = byWire[diff.slot.wireName];
    if (diff.isHeld || saved == null) {
      out.add(diff);
      continue;
    }
    final label = saved.label.trim().isNotEmpty
        ? saved.label.trim()
        : (diff.substituteLabel ?? '');
    if (label.isEmpty && saved.instanceId == null) {
      out.add(diff);
      continue;
    }
    FillInInventoryItem? invMatch;
    final savedId = saved.instanceId?.trim() ?? '';
    if (savedId.isNotEmpty) {
      for (final item in inventory) {
        if (item.instanceId == savedId) {
          invMatch = item;
          break;
        }
      }
    }
    if (invMatch == null && label.isNotEmpty) {
      final want = label.toLowerCase();
      for (final item in inventory) {
        if (item.slot != diff.slot) continue;
        if ((item.name ?? '').trim().toLowerCase() == want) {
          invMatch = item;
          break;
        }
      }
    }
    out.add(
      FillInSlotDiff(
        slot: diff.slot,
        currentLabel: diff.currentLabel,
        isHeld: false,
        isExotic: diff.isExotic || (invMatch?.isExotic ?? false),
        substituteLabel: label.isNotEmpty ? label : invMatch?.name,
        substituteInstanceId: saved.instanceId ?? invMatch?.instanceId,
        substituteItemHash: saved.itemHash ?? invMatch?.itemHash,
        note: diff.note,
      ),
    );
  }
  return List<FillInSlotDiff>.unmodifiable(out);
}
