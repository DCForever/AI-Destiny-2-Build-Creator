/// Presentation models for Sets Armor lifecycle UI (no domain/app deps).
///
/// Hosts map app/domain DTOs → these view models.
library;

/// Honesty empty reasons for Sets library / fill surfaces.
enum SetsHonestyKind {
  signedOut,
  needSync,
  noMatches,
  loading,
  generic,
}

/// One Armor library flap row: Name · class · pieces · coverage · used-by.
class SetsArmorLibraryRowData {
  const SetsArmorLibraryRowData({
    required this.id,
    required this.name,
    required this.classLabel,
    required this.pieceCount,
    this.capacity = 5,
    this.coverageLabel = '—',
    this.usedByLabel = '—',
    this.selected = false,
  });

  final String id;
  final String name;
  final String classLabel;
  final int pieceCount;
  final int capacity;
  final String coverageLabel;
  final String usedByLabel;
  final bool selected;

  String get piecesLabel => '$pieceCount/$capacity';
}

/// One free tag chip.
class SetsTagData {
  const SetsTagData({
    required this.id,
    required this.label,
    this.blocked = false,
  });

  final String id;
  final String label;
  final bool blocked;
}

/// Hard bonus goal chip for editor / board.
class SetsBonusGoalData {
  const SetsBonusGoalData({
    required this.familyKey,
    required this.minPieces,
    this.familyLabel,
  });

  final String familyKey;
  final int minPieces;
  final String? familyLabel;

  String get display =>
      '${familyLabel ?? familyKey} · ${minPieces}pc';
}

/// One board slot row (layout A).
class SetsArmorSlotData {
  const SetsArmorSlotData({
    required this.slotWire,
    required this.slotLabel,
    this.itemName,
    this.instanceId,
    this.isExotic = false,
    this.stats = const {},
    this.setBonusKey,
    this.energyLabel,
    this.modsLabel,
  });

  final String slotWire;
  final String slotLabel;
  final String? itemName;
  final String? instanceId;
  final bool isExotic;

  /// Base six stats keyed by EoF label (Health, Melee, …).
  final Map<String, int> stats;
  final String? setBonusKey;

  /// Null/empty → hide energy chrome.
  final String? energyLabel;

  /// Null/empty → hide mods chrome.
  final String? modsLabel;

  bool get isFilled =>
      (itemName != null && itemName!.trim().isNotEmpty) ||
      (instanceId != null && instanceId!.trim().isNotEmpty);

  int get total {
    var s = 0;
    for (final v in stats.values) {
      s += v;
    }
    return s;
  }
}

/// Totals row above pieces (layout A).
class SetsArmorBoardTotals {
  const SetsArmorBoardTotals({
    this.stats = const {},
    this.incomplete = false,
  });

  final Map<String, int> stats;
  final bool incomplete;

  int get sigma {
    var s = 0;
    for (final v in stats.values) {
      s += v;
    }
    return s;
  }

  static SetsArmorBoardTotals fromSlots(List<SetsArmorSlotData> slots) {
    final out = <String, int>{};
    var any = false;
    for (final slot in slots) {
      if (!slot.isFilled) continue;
      any = true;
      for (final e in slot.stats.entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }
    return SetsArmorBoardTotals(stats: out, incomplete: !any);
  }
}

/// Hard / soft coverage band state.
class SetsCoverageBandData {
  const SetsCoverageBandData({
    this.hardGoals = const [],
    this.hardMet = true,
    this.softTwoPiece = const [],
    this.softFourPiece = const [],
  });

  final List<SetsBonusGoalData> hardGoals;
  final bool hardMet;
  final List<String> softTwoPiece;
  final List<String> softFourPiece;
}

/// Owned compare table row (instance identity required).
class SetsOwnedCompareRowData {
  const SetsOwnedCompareRowData({
    required this.instanceId,
    required this.itemHash,
    required this.itemName,
    this.isExotic = false,
    this.power,
    this.total = 0,
    this.stats = const {},
    this.bonusFit = false,
    this.setBonusKey,
    this.exoticBlocked = false,
  });

  final String instanceId;
  final int itemHash;
  final String itemName;
  final bool isExotic;
  final int? power;
  final int total;
  final Map<String, int> stats;
  final bool bonusFit;
  final String? setBonusKey;
  final bool exoticBlocked;
}

/// One optimizer kit matrix row (confirm-only apply target).
class SetsOptimizeKitRowData {
  const SetsOptimizeKitRowData({
    required this.id,
    required this.total,
    this.stats = const {},
    this.slotNames = const {},
    this.goalsLabel = '—',
    this.deltaVsCurrent,
    this.selected = false,
  });

  final String id;
  final int total;
  final Map<String, int> stats;

  /// Helm–Class display names keyed by slot wire.
  final Map<String, String> slotNames;
  final String goalsLabel;
  final int? deltaVsCurrent;
  final bool selected;
}

/// Non-Armor thin detail shell.
class SetsNonArmorThinData {
  const SetsNonArmorThinData({
    required this.id,
    required this.name,
    required this.typeLabel,
    this.pieceSummary = '—',
    this.tags = const [],
  });

  final String id;
  final String name;
  final String typeLabel;
  final String pieceSummary;
  final List<String> tags;
}

/// Used-by attachment for delete / rail.
class SetsUsedByData {
  const SetsUsedByData({
    required this.buildId,
    required this.variantId,
    this.buildName,
  });

  final String buildId;
  final String variantId;
  final String? buildName;

  String get label {
    final n = buildName?.trim();
    if (n != null && n.isNotEmpty) return '$n · $variantId';
    return 'build $buildId · $variantId';
  }
}
