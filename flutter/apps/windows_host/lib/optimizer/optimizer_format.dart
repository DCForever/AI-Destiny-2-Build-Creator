import 'package:destiny2_domain/destiny2_domain.dart';

/// Pure display helpers for Armor optimizer workspace UI (DART-036).
///
/// Suggestions are display-only until explicit user confirm. Soft goals never
/// encode hard-block semantics.

/// Advisory caption: suggest → confirm; never silent apply.
const String kOptimizerAdvisoryCaption =
    'Suggestions are not applied until you confirm. '
    'Find kits never writes sets. Soft thresholds never auto-apply kits.';

/// Default number of kits shown in the compact compare window.
const int kOptimizerTopCompareCount = 3;

/// Default maxResults for Find kits requests.
const int kOptimizerDefaultMaxResults = 25;

/// Human label for empty-reason codes.
String formatOptimizerEmptyReason(ArmorOptimizeEmptyReason reason) {
  final code = reason.code.wireName;
  final msg = reason.message.trim();
  if (msg.isEmpty) return code;
  return '$code — $msg';
}

/// Compact estimated stats: `Health:20 Melee:10 …` (non-zero preferred order).
String formatEstimatedStatsSummary(Map<ArmorStatName, int> stats) {
  if (stats.isEmpty) return '—';
  final parts = <String>[];
  for (final s in ArmorStatName.all) {
    final v = stats[s];
    if (v != null) parts.add('${s.wireName}:$v');
  }
  return parts.isEmpty ? '—' : parts.join(' ');
}

/// One-line piece list: `helmet·name, arms·…` (uses itemName or hash).
String formatCombinationPiecesSummary(ArmorCombination combo) {
  final parts = <String>[];
  for (final p in combo.pieces) {
    final label = (p.itemName != null && p.itemName!.trim().isNotEmpty)
        ? p.itemName!.trim()
        : '${p.itemHash}';
    final exotic = p.isExotic ? ' (exotic)' : '';
    parts.add('${p.slot.wireName}·$label$exotic');
  }
  return parts.join(', ');
}

/// Suggestion card title line: `#n · score S · reuse R`.
String formatSuggestionTitle({
  required int indexOneBased,
  required ArmorCombination combo,
}) {
  final soft = combo.meetsSoftThresholds ? '' : ' · below soft';
  return '#$indexOneBased · score ${combo.score} · reuse ${combo.reusePieceCount}$soft';
}

/// Window of combinations for the compact top-N compare (max [topN]).
List<ArmorCombination> topCompareWindow(
  List<ArmorCombination> all, {
  int topN = kOptimizerTopCompareCount,
}) {
  if (topN <= 0 || all.isEmpty) return const [];
  if (all.length <= topN) return List<ArmorCombination>.from(all);
  return all.sublist(0, topN);
}

/// Truncation note when response.truncated or list was capped.
String? formatTruncationNote({
  required bool truncated,
  required int shown,
  required int total,
}) {
  if (!truncated && shown >= total) return null;
  if (truncated) {
    return 'Results truncated — showing $shown of evaluated kits (cap applied).';
  }
  if (shown < total) {
    return 'Showing top $shown of $total suggestions. Expand to see all.';
  }
  return null;
}

/// NO_INVENTORY-oriented guidance copy.
String inventoryEmptyGuidance() =>
    'No armor candidates. Sync inventory in Settings, then try Find kits again.';

/// Confirm dialog body for apply-in-place.
String confirmApplyInPlaceBody(ArmorCombination combo) {
  return 'Apply this kit to the selected armor set?\n\n'
      '${formatCombinationPiecesSummary(combo)}\n\n'
      'This overwrites the five armor slots. Cancel leaves the set unchanged.';
}

/// Confirm dialog body for materialize.
String confirmMaterializeBody(ArmorCombination combo, String newName) {
  final name = newName.trim().isEmpty ? '(unnamed)' : newName.trim();
  return 'Create a new armor set "$name" from this kit?\n\n'
      '${formatCombinationPiecesSummary(combo)}\n\n'
      'The currently selected set is not modified.';
}
