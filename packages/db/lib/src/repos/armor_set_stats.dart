import 'instance_projection.dart';

/// One armor piece contribution for set board totals (DAC-NME-004 / BR-SET-011).
class ArmorStatPieceInput {
  const ArmorStatPieceInput({
    this.stats,
    this.statsIncomplete = false,
    this.instanceId,
  });

  /// Canonical EoF keys → values when known; null/empty = no rolls.
  final Map<String, int>? stats;

  final bool statsIncomplete;

  /// When set and stats missing, totals mark incomplete (pinned but unknown).
  final String? instanceId;

  factory ArmorStatPieceInput.fromBoard(
    ArmorBaseStatBoard? board, {
    String? instanceId,
  }) {
    if (board == null) {
      return ArmorStatPieceInput(instanceId: instanceId);
    }
    return ArmorStatPieceInput(
      stats: board.stats,
      statsIncomplete: board.incomplete,
      instanceId: instanceId,
    );
  }
}

/// Aggregated armor set EoF six-stat totals (product `sumArmorSetStats`).
class ArmorSetStatTotals {
  const ArmorSetStatTotals({
    required this.statValues,
    required this.grandTotal,
    required this.incomplete,
    required this.piecesWithStats,
  });

  /// Summed EoF keys present on at least one piece.
  final Map<String, int> statValues;

  /// Sum of known EoF values across pieces.
  final int grandTotal;

  /// True when any pinned instance lacks complete six-stat data.
  final bool incomplete;

  /// Count of pieces that contributed at least one EoF stat.
  final int piecesWithStats;

  bool get hasAny => piecesWithStats > 0 || statValues.isNotEmpty;
}

/// Sum EoF six armor stats across set pieces that have instance rolls.
///
/// Wishlist pieces (no [ArmorStatPieceInput.stats]) do not invent zeros.
/// Pinned instances without stats mark [ArmorSetStatTotals.incomplete].
ArmorSetStatTotals sumArmorSetStats(Iterable<ArmorStatPieceInput> items) {
  final statValues = <String, int>{};
  var piecesWithStats = 0;
  var incomplete = false;

  for (final item in items) {
    final vals = item.stats;
    if (vals == null || vals.isEmpty) {
      if (item.instanceId != null && item.instanceId!.isNotEmpty) {
        incomplete = true;
      }
      continue;
    }
    final hasAnyEof = armorBaseStatKeys.any((n) => vals[n] != null);
    if (!hasAnyEof) {
      if (item.instanceId != null && item.instanceId!.isNotEmpty) {
        incomplete = true;
      }
      continue;
    }
    piecesWithStats += 1;
    if (item.statsIncomplete) {
      incomplete = true;
    }
    for (final name in armorBaseStatKeys) {
      if (!vals.containsKey(name)) {
        incomplete = true;
        continue;
      }
      final v = vals[name]!;
      statValues[name] = (statValues[name] ?? 0) + v;
    }
  }

  var grandTotal = 0;
  for (final name in armorBaseStatKeys) {
    grandTotal += statValues[name] ?? 0;
  }

  return ArmorSetStatTotals(
    statValues: Map.unmodifiable(statValues),
    grandTotal: grandTotal,
    incomplete: incomplete,
    piecesWithStats: piecesWithStats,
  );
}
