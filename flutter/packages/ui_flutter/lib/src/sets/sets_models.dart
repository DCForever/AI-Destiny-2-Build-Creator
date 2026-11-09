/// Presentation models for Sets Armor lifecycle UI (no domain/app deps).
///
/// Hosts map app/domain DTOs → these view models.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

import '../catalog/entity_info_hotspot.dart';

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
    this.entityInfo,
  });

  final String familyKey;
  final int minPieces;
  final String? familyLabel;

  /// Optional hover/long-press info popup (set-bonus perk body).
  final EntityInfoData? entityInfo;

  String get display =>
      '${familyLabel ?? familyKey} · ${minPieces}pc';
}

/// One catalog set-bonus family for the goals picker (name + 2pc/4pc perk text).
///
/// Host maps [SetBonusCatalogRecord] / raw extract. Description fields may be
/// empty when data is missing — UI uses honest empty (never invent).
class SetsBonusFamilyOption {
  const SetsBonusFamilyOption({
    required this.name,
    this.hash,
    this.iconPath,
    this.twoPcName = '',
    this.twoPcDescription = '',
    this.fourPcName = '',
    this.fourPcDescription = '',
    this.extraSearchText = '',
  });

  /// Name-only fixture (tests / offline) — no perk body.
  factory SetsBonusFamilyOption.nameOnly(String name) =>
      SetsBonusFamilyOption(name: name);

  final String name;
  final int? hash;
  final String? iconPath;
  final String twoPcName;
  final String twoPcDescription;
  final String fourPcName;
  final String fourPcDescription;

  /// Additional searchable catalog text (other tier perks, combined blob).
  final String extraSearchText;

  bool get hasAnyDescription =>
      twoPcDescription.trim().isNotEmpty ||
      fourPcDescription.trim().isNotEmpty ||
      twoPcName.trim().isNotEmpty ||
      fourPcName.trim().isNotEmpty;

  /// Lowercased haystack for name + perk titles + descriptions (search).
  String get searchHaystack {
    final parts = <String>[
      name,
      twoPcName,
      twoPcDescription,
      fourPcName,
      fourPcDescription,
      extraSearchText,
    ];
    return parts
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .join(' ');
  }

  /// True when every whitespace-separated query token appears in [searchHaystack].
  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = searchHaystack;
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      if (!hay.contains(t)) return false;
    }
    return true;
  }
}

/// One board slot row (layout A).
class SetsArmorSlotData {
  const SetsArmorSlotData({
    required this.slotWire,
    required this.slotLabel,
    this.itemName,
    this.instanceId,
    this.itemHash,
    this.iconPath,
    this.isExotic = false,
    this.stats = const {},
    this.setBonusKey,
    this.energyLabel,
    this.modsLabel,
    this.entityInfo,
  });

  final String slotWire;
  final String slotLabel;
  final String? itemName;
  final String? instanceId;
  final int? itemHash;

  /// Bungie content path/URL for armor icon.
  final String? iconPath;
  final bool isExotic;

  /// Base six stats keyed by EoF label (Health, Melee, …).
  final Map<String, int> stats;
  final String? setBonusKey;

  /// Null/empty → hide energy chrome.
  final String? energyLabel;

  /// Null/empty → hide mods chrome.
  final String? modsLabel;

  /// Optional hover/long-press info popup for the piece.
  final EntityInfoData? entityInfo;

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
    this.softEntityInfoByFamily = const {},
  });

  final List<SetsBonusGoalData> hardGoals;
  final bool hardMet;
  final List<String> softTwoPiece;
  final List<String> softFourPiece;

  /// Optional family-name → info popup for soft ≥2pc / ≥4pc chips.
  final Map<String, EntityInfoData> softEntityInfoByFamily;
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

/// One piece cell in the optimizer kit matrix (DIM LO column).
///
/// Mockup: name · Σ · power · family · base six line; optional armor icon.
class SetsOptimizeSlotPiece {
  const SetsOptimizeSlotPiece({
    required this.name,
    this.isExotic = false,
    this.subtitle,
    this.iconPath,
    this.power,
    this.pieceTotal,
    this.familyKey,
    this.baseStatsLine,
  });

  final String name;
  final bool isExotic;

  /// Compact second line when [baseStatsLine] is null (host-built).
  final String? subtitle;

  /// Bungie content path or URL for [BungieContentIcon].
  final String? iconPath;
  final int? power;
  final int? pieceTotal;
  final String? familyKey;

  /// EoF base six as `H/M/G/S/C/W` style values (mockup `base.join('/')`).
  final String? baseStatsLine;
}

/// Exotic filter option for optimizer constraints (G-SET-036).
///
/// Prefer stable [itemHash]-based [id] for concrete exotics (`'12345'`), with
/// display [label] + optional icon / slot / power / copy count for the dropdown.
class SetsOptimizeExoticOption {
  const SetsOptimizeExoticOption({
    required this.id,
    required this.label,
    this.iconPath,
    this.subtitle,
    this.itemHash,
    this.slotLabel,
    this.power,
    this.copyCount,
  });

  /// `any` · `none` · exotic itemHash as decimal string.
  final String id;
  final String label;

  /// Bungie icon path/URL for concrete exotic options.
  final String? iconPath;

  /// Secondary line (e.g. `Helmet · ✧2000 · ×3`).
  final String? subtitle;
  final int? itemHash;
  final String? slotLabel;
  final int? power;
  final int? copyCount;
}

/// Sort modes for kit results (G-SET-027).
enum SetsOptimizeSortMode {
  total,
  health,
  melee,
  grenade,
  superStat,
  classStat,
  weapons,
  goals,
}

extension SetsOptimizeSortModeX on SetsOptimizeSortMode {
  String get wireName => switch (this) {
        SetsOptimizeSortMode.total => 'total',
        SetsOptimizeSortMode.health => 'health',
        SetsOptimizeSortMode.melee => 'melee',
        SetsOptimizeSortMode.grenade => 'grenade',
        SetsOptimizeSortMode.superStat => 'super',
        SetsOptimizeSortMode.classStat => 'class',
        SetsOptimizeSortMode.weapons => 'weapons',
        SetsOptimizeSortMode.goals => 'goals',
      };

  String get label => switch (this) {
        SetsOptimizeSortMode.total => 'Σ base',
        SetsOptimizeSortMode.health => 'Health total',
        SetsOptimizeSortMode.melee => 'Melee total',
        SetsOptimizeSortMode.grenade => 'Grenade total',
        SetsOptimizeSortMode.superStat => 'Super total',
        SetsOptimizeSortMode.classStat => 'Class total',
        SetsOptimizeSortMode.weapons => 'Weapons total',
        SetsOptimizeSortMode.goals => 'Bonus goal fit',
      };

  /// EoF display label for stat sorts; null for total/goals.
  String? get statLabel => switch (this) {
        SetsOptimizeSortMode.health => 'Health',
        SetsOptimizeSortMode.melee => 'Melee',
        SetsOptimizeSortMode.grenade => 'Grenade',
        SetsOptimizeSortMode.superStat => 'Super',
        SetsOptimizeSortMode.classStat => 'Class',
        SetsOptimizeSortMode.weapons => 'Weapons',
        _ => null,
      };

  static SetsOptimizeSortMode parse(String raw) {
    switch (raw.toLowerCase()) {
      case 'health':
        return SetsOptimizeSortMode.health;
      case 'melee':
        return SetsOptimizeSortMode.melee;
      case 'grenade':
        return SetsOptimizeSortMode.grenade;
      case 'super':
        return SetsOptimizeSortMode.superStat;
      case 'class':
        return SetsOptimizeSortMode.classStat;
      case 'weapons':
        return SetsOptimizeSortMode.weapons;
      case 'goals':
        return SetsOptimizeSortMode.goals;
      default:
        return SetsOptimizeSortMode.total;
    }
  }
}

/// Kit stat dual-range domain (mockup dual-range · product kit totals).
///
/// 200 covers full five-piece EoF kit bands with headroom (was 100; too tight).
const int kSetsOptimizeStatSliderMax = 200;

/// One optimizer kit matrix row (confirm-only apply target).
class SetsOptimizeKitRowData {
  const SetsOptimizeKitRowData({
    required this.id,
    required this.total,
    this.stats = const {},
    this.slotNames = const {},
    this.slotPieces = const {},
    this.goalsLabel = '—',
    this.goalsOk = true,
    this.deltaVsCurrent,
    this.selected = false,
    this.isCurrent = false,
    this.rank = 0,
    this.exoticName,
    this.exoticItemHash,
    this.label,
  });

  final String id;
  final int total;

  /// Base six stats keyed by EoF label (Health, Melee, …).
  final Map<String, int> stats;

  /// Helm–Class display names keyed by slot wire (legacy compact).
  final Map<String, String> slotNames;

  /// Rich piece cells keyed by slot wire (preferred over [slotNames]).
  final Map<String, SetsOptimizeSlotPiece> slotPieces;

  final String goalsLabel;
  final bool goalsOk;

  /// Σ delta vs current board when pins exist; null when no baseline.
  final int? deltaVsCurrent;
  final bool selected;

  /// Current-board baseline row (not selectable as apply target).
  final bool isCurrent;
  final int rank;

  /// Display name of exotic in this kit, if any (for exotic filter).
  final String? exoticName;

  /// Item hash of the exotic piece when present (preferred filter key).
  final int? exoticItemHash;

  /// Human label for footer (defaults to id / rank).
  final String? label;

  String get displayLabel =>
      label ?? (isCurrent ? 'Current board' : (rank > 0 ? '#$rank' : id));

  String pieceName(String slotWire) {
    final p = slotPieces[slotWire];
    if (p != null && p.name.isNotEmpty) return p.name;
    return slotNames[slotWire] ?? '—';
  }

  bool pieceIsExotic(String slotWire) =>
      slotPieces[slotWire]?.isExotic ?? false;

  SetsOptimizeKitRowData copyWith({
    String? id,
    int? total,
    Map<String, int>? stats,
    Map<String, String>? slotNames,
    Map<String, SetsOptimizeSlotPiece>? slotPieces,
    String? goalsLabel,
    bool? goalsOk,
    int? deltaVsCurrent,
    bool clearDelta = false,
    bool? selected,
    bool? isCurrent,
    int? rank,
    String? exoticName,
    int? exoticItemHash,
    String? label,
  }) {
    return SetsOptimizeKitRowData(
      id: id ?? this.id,
      total: total ?? this.total,
      stats: stats ?? this.stats,
      slotNames: slotNames ?? this.slotNames,
      slotPieces: slotPieces ?? this.slotPieces,
      goalsLabel: goalsLabel ?? this.goalsLabel,
      goalsOk: goalsOk ?? this.goalsOk,
      deltaVsCurrent: clearDelta ? null : (deltaVsCurrent ?? this.deltaVsCurrent),
      selected: selected ?? this.selected,
      isCurrent: isCurrent ?? this.isCurrent,
      rank: rank ?? this.rank,
      exoticName: exoticName ?? this.exoticName,
      exoticItemHash: exoticItemHash ?? this.exoticItemHash,
      label: label ?? this.label,
    );
  }
}

/// Why a kit failed client-side exotic / min / max filter.
enum SetsOptimizeKitReject {
  exotic,
  statMin,
  statMax,
}

/// Counts for honest empty / match labels (G-SET-036).
class SetsOptimizeFilterBreakdown {
  const SetsOptimizeFilterBreakdown({
    required this.engineCount,
    required this.afterExotic,
    required this.afterAll,
    this.failedExotic = 0,
    this.failedStatMin = 0,
    this.failedStatMax = 0,
    this.activeMinLabels = const [],
    this.activeMaxLabels = const [],
    this.exoticFilterLabel = 'any',
  });

  final int engineCount;
  final int afterExotic;
  final int afterAll;
  final int failedExotic;
  final int failedStatMin;
  final int failedStatMax;
  final List<String> activeMinLabels;
  final List<String> activeMaxLabels;
  final String exoticFilterLabel;

  bool get hasClientFilters =>
      exoticFilterLabel != 'any' ||
      activeMinLabels.isNotEmpty ||
      activeMaxLabels.isNotEmpty;
}

bool _kitPassesExotic(SetsOptimizeKitRowData k, String exoticFilter) {
  final hasExotic = (k.exoticItemHash != null) ||
      (k.exoticName != null && k.exoticName!.trim().isNotEmpty);
  if (exoticFilter == 'none') return !hasExotic;
  if (exoticFilter == 'any' || exoticFilter.isEmpty) return true;
  final want = exoticFilter.trim();
  final wantHash = int.tryParse(want);
  if (wantHash != null) {
    return k.exoticItemHash == wantHash;
  }
  final wantL = want.toLowerCase();
  final have = (k.exoticName ?? '').trim().toLowerCase();
  if (have.isEmpty) return false;
  return have == wantL || have.contains(wantL) || wantL.contains(have);
}

SetsOptimizeKitReject? _kitRejectReason(
  SetsOptimizeKitRowData k, {
  required String exoticFilter,
  required Map<String, int?> statMin,
  required Map<String, int?> statMax,
}) {
  if (!_kitPassesExotic(k, exoticFilter)) {
    return SetsOptimizeKitReject.exotic;
  }
  for (final label in kArmorBoardEofStatLabels) {
    final v = k.stats[label] ?? 0;
    final mn = statMin[label];
    final mx = statMax[label];
    if (mn != null && mn > 0 && v < mn) {
      return SetsOptimizeKitReject.statMin;
    }
    if (mx != null && mx < kSetsOptimizeStatSliderMax && v > mx) {
      return SetsOptimizeKitReject.statMax;
    }
  }
  return null;
}

/// Explain empty matrix when engine returned kits but client filters wiped them.
String describeOptimizeFilterEmpty({
  required SetsOptimizeFilterBreakdown b,
  String? engineEmptyMessage,
}) {
  if (b.engineCount == 0) {
    return engineEmptyMessage ??
        'No kits found — sync inventory and re-optimize';
  }
  if (b.afterAll > 0) {
    return '${b.afterAll} of ${b.engineCount} kits · filters applied';
  }
  final parts = <String>[];
  if (b.exoticFilterLabel != 'any' && b.failedExotic > 0) {
    parts.add('exotic ${b.exoticFilterLabel} (${b.failedExotic} missed)');
  }
  if (b.activeMinLabels.isNotEmpty && b.failedStatMin > 0) {
    parts.add(
      'mins ${b.activeMinLabels.join(' · ')} (${b.failedStatMin} missed)',
    );
  }
  if (b.activeMaxLabels.isNotEmpty && b.failedStatMax > 0) {
    parts.add(
      'max ${b.activeMaxLabels.join(' · ')} (${b.failedStatMax} missed)',
    );
  }
  if (parts.isEmpty) {
    return '0 of ${b.engineCount} kits match filters';
  }
  return '0 of ${b.engineCount} kits — ${parts.join('; ')}. '
      'Re-optimize to search with mins, or loosen filters';
}

SetsOptimizeFilterBreakdown breakdownOptimizeFilters({
  required List<SetsOptimizeKitRowData> kits,
  String exoticFilter = 'any',
  Map<String, int?> statMin = const {},
  Map<String, int?> statMax = const {},
  String exoticFilterLabel = 'any',
}) {
  var afterExotic = 0;
  var afterAll = 0;
  var failedExotic = 0;
  var failedMin = 0;
  var failedMax = 0;
  var engine = 0;
  for (final k in kits) {
    if (k.isCurrent) continue;
    engine++;
    final reason = _kitRejectReason(
      k,
      exoticFilter: exoticFilter,
      statMin: statMin,
      statMax: statMax,
    );
    if (reason == null) {
      afterExotic++;
      afterAll++;
      continue;
    }
    if (reason == SetsOptimizeKitReject.exotic) {
      failedExotic++;
    } else if (reason == SetsOptimizeKitReject.statMin) {
      afterExotic++;
      failedMin++;
    } else {
      afterExotic++;
      failedMax++;
    }
  }
  final minLabels = <String>[
    for (final label in kArmorBoardEofStatLabels)
      if ((statMin[label] ?? 0) > 0) '$label≥${statMin[label]}',
  ];
  final maxLabels = <String>[
    for (final label in kArmorBoardEofStatLabels)
      if ((statMax[label] ?? kSetsOptimizeStatSliderMax) <
          kSetsOptimizeStatSliderMax)
        '$label≤${statMax[label]}',
  ];
  return SetsOptimizeFilterBreakdown(
    engineCount: engine,
    afterExotic: afterExotic,
    afterAll: afterAll,
    failedExotic: failedExotic,
    failedStatMin: failedMin,
    failedStatMax: failedMax,
    activeMinLabels: minLabels,
    activeMaxLabels: maxLabels,
    exoticFilterLabel: exoticFilterLabel,
  );
}

/// Client-side filter + sort of kit proposals (mockup refilter; G-SET-027/036).
List<SetsOptimizeKitRowData> filterSortOptimizeKits({
  required List<SetsOptimizeKitRowData> kits,
  String exoticFilter = 'any',
  SetsOptimizeSortMode sort = SetsOptimizeSortMode.total,
  Map<String, int?> statMin = const {},
  Map<String, int?> statMax = const {},
  SetsOptimizeKitRowData? baseline,
}) {
  final filtered = <SetsOptimizeKitRowData>[];
  for (final k in kits) {
    if (k.isCurrent) continue;
    if (_kitRejectReason(
          k,
          exoticFilter: exoticFilter,
          statMin: statMin,
          statMax: statMax,
        ) !=
        null) {
      continue;
    }
    final delta = baseline == null ? k.deltaVsCurrent : k.total - baseline.total;
    filtered.add(
      baseline == null
          ? k
          : k.copyWith(deltaVsCurrent: delta),
    );
  }

  int goalScore(SetsOptimizeKitRowData k) {
    if (!k.goalsOk) return 0;
    if (k.goalsLabel == '—' || k.goalsLabel.isEmpty) return 1;
    return 2;
  }

  filtered.sort((a, b) {
    switch (sort) {
      case SetsOptimizeSortMode.goals:
        final g = goalScore(b).compareTo(goalScore(a));
        if (g != 0) return g;
        return b.total.compareTo(a.total);
      case SetsOptimizeSortMode.total:
        return b.total.compareTo(a.total);
      default:
        final label = sort.statLabel;
        if (label == null) return b.total.compareTo(a.total);
        final av = a.stats[label] ?? 0;
        final bv = b.stats[label] ?? 0;
        final c = bv.compareTo(av);
        if (c != 0) return c;
        return b.total.compareTo(a.total);
    }
  });

  return [
    for (var i = 0; i < filtered.length; i++)
      filtered[i].copyWith(rank: i + 1),
  ];
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
