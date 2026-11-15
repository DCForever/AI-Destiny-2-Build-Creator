import 'dart:math';

import '../models/equipment.dart';
import 'fill_in_inventory.dart';
import 'fill_in_similar_weapon.dart';
import 'fill_in_substitute.dart';

/// Soft-score weights (Daniel / PR #44 plan; Nov 14 2026).
const int kWeaponOptimizeOppositeRangePoints = 40;
const int kWeaponOptimizeElementMatchPoints = 20;
const int kWeaponOptimizePerkSynergyPoints = 15;
const int kWeaponOptimizeLegendaryPreferredPoints = 10;

/// Reason when Optimize falls back to random Fill In substitute (no CSV).
const String kWeaponOptimizeNoCsvReason = 'No weapons CSV imported';

/// Visible reason when CSV is missing and no held weapons can substitute.
///
/// Never leave Kinetic/Energy/Power blank silently in this case.
const String kWeaponOptimizeEmptySubstitutePoolReason =
    'No weapons CSV imported; no held weapons available to substitute';

/// Label for a random Fill In substitute — never "optimized".
const String kWeaponOptimizeSubstituteLabel = 'substitute';

/// Label for a scored CSV pick.
const String kWeaponOptimizeOptimizedLabel = 'optimized';

/// Note when the best pick does not match subclass element.
const String kWeaponOptimizeElementMismatchNote = 'element mismatch';

/// How a weapon pick was produced.
enum WeaponOptimizeSource {
  /// Ranked from imported Weapons CSV / offline perk tags.
  optimized,

  /// Random Fill In substitute (no Weapons CSV).
  substitute,
}

/// One slot pick inside a [WeaponOptimizeCombination].
class WeaponOptimizePick {
  const WeaponOptimizePick({
    required this.slot,
    required this.item,
    required this.score,
    required this.source,
    this.elementMismatch = false,
    this.note,
  });

  final EquipmentSlot slot;
  final FillInInventoryItem item;
  final int score;
  final WeaponOptimizeSource source;

  /// True when the pick failed the subclass element filter and fell back.
  final bool elementMismatch;

  final String? note;

  String get sourceLabel => source == WeaponOptimizeSource.optimized
      ? kWeaponOptimizeOptimizedLabel
      : kWeaponOptimizeSubstituteLabel;
}

/// Ranked kit of weapon picks for empty Kinetic/Energy/Power slots.
class WeaponOptimizeCombination {
  const WeaponOptimizeCombination({
    required this.picks,
    required this.score,
    required this.source,
    this.reason,
  });

  final List<WeaponOptimizePick> picks;
  final int score;
  final WeaponOptimizeSource source;

  /// Present for substitutes (e.g. [kWeaponOptimizeNoCsvReason]).
  final String? reason;

  bool get isOptimized => source == WeaponOptimizeSource.optimized;
  bool get isSubstitute => source == WeaponOptimizeSource.substitute;
}

/// Inputs for ranking weapon substitutes (read-only; no network).
class WeaponOptimizeRequest {
  const WeaponOptimizeRequest({
    required this.emptySlots,
    required this.inventory,
    required this.subclassKey,
    this.exoticWeaponType,
    this.pinnedInstanceIds = const <String>{},
    this.buildKeywords = const <String>[],
    this.exoticsAlreadyOnBuild = 0,
    this.maxResults = 3,
    this.hasWeaponsCsv = true,
    this.random,
  });

  /// Combat buckets that still need a weapon (empty / unpinned only).
  final List<EquipmentSlot> emptySlots;

  /// Held weapons from offline cache or imported CSV.
  ///
  /// Optimizer scoring uses this local list only; Apply to character later
  /// checks each picked instance against the live profile before equipping.
  final List<FillInInventoryItem> inventory;

  /// Build subclass key (Arc/Solar/…/Prismatic).
  final String subclassKey;

  /// Exotic weapon's DIM Type — candidates of this type are hard-excluded.
  final String? exoticWeaponType;

  /// Instance ids already pinned on the build (never re-picked).
  final Set<String> pinnedInstanceIds;

  /// Build keywords for perk/synergy soft scoring (lowercase ok).
  final List<String> buildKeywords;

  /// Exotic weapons already equipped/pinned on the build (one-exotic cap).
  final int exoticsAlreadyOnBuild;

  final int maxResults;

  /// When false, return a single substitute kit (never labeled optimized).
  final bool hasWeaponsCsv;

  /// Seeded RNG for substitute fallback / tie noise.
  final Random? random;
}

/// Rank held weapons for empty Kinetic/Energy/Power slots.
///
/// Hard filters (must pass before soft score):
/// 1. Same combat bucket as the empty slot.
/// 2. Weapon type ≠ exotic's type.
/// Soft score then ranks; element match applies to all three slots (Prismatic =
/// any). When no element match exists, fall back to the best non-matching
/// candidate and label [kWeaponOptimizeElementMismatchNote] — never leave a
/// slot blank when any candidate remains.
///
/// One-exotic cap is applied **after** ranking, counting [exoticsAlreadyOnBuild].
///
/// When [WeaponOptimizeRequest.hasWeaponsCsv] is false, returns one substitute
/// combination labeled [kWeaponOptimizeSubstituteLabel] with reason
/// [kWeaponOptimizeNoCsvReason] — never [kWeaponOptimizeOptimizedLabel].
WeaponOptimizeResponse optimizeWeapons(WeaponOptimizeRequest request) {
  final slots = [
    for (final s in request.emptySlots)
      if (_isWeaponCombatSlot(s)) s,
  ];
  if (slots.isEmpty) {
    return const WeaponOptimizeResponse(combinations: []);
  }

  if (!request.hasWeaponsCsv) {
    return _substituteResponse(request, slots);
  }

  final subclassDamage = fillInDamageTypeForSubclass(request.subclassKey);
  final exoticType = (request.exoticWeaponType ?? '').trim().toLowerCase();
  final preferredRange = fillInOppositeWeaponRange(
    fillInWeaponRangeClass(request.exoticWeaponType),
  );
  final keywords = [
    for (final k in request.buildKeywords)
      if (k.trim().isNotEmpty) k.trim().toLowerCase(),
  ];
  final usedIds = Set<String>.from(request.pinnedInstanceIds);

  final rankedPerSlot = <EquipmentSlot, List<_ScoredCandidate>>{};
  for (final slot in slots) {
    rankedPerSlot[slot] = _rankSlotCandidates(
      slot: slot,
      inventory: request.inventory,
      subclassDamage: subclassDamage,
      exoticTypeLower: exoticType,
      preferredRange: preferredRange,
      keywords: keywords,
      usedIds: usedIds,
      exoticsAlreadyOnBuild: request.exoticsAlreadyOnBuild,
    );
  }

  final combos = _buildCombinations(
    slots: slots,
    rankedPerSlot: rankedPerSlot,
    maxResults: request.maxResults,
    exoticsAlreadyOnBuild: request.exoticsAlreadyOnBuild,
  );
  return WeaponOptimizeResponse(
    combinations: List<WeaponOptimizeCombination>.unmodifiable(combos),
  );
}

/// Result of [optimizeWeapons].
class WeaponOptimizeResponse {
  const WeaponOptimizeResponse({required this.combinations});

  final List<WeaponOptimizeCombination> combinations;
}

WeaponOptimizeResponse _substituteResponse(
  WeaponOptimizeRequest request,
  List<EquipmentSlot> slots,
) {
  final rng = request.random ?? Random();
  final subclassDamage = fillInDamageTypeForSubclass(request.subclassKey);
  final exoticType = (request.exoticWeaponType ?? '').trim().toLowerCase();
  final preferredRange = fillInOppositeWeaponRange(
    fillInWeaponRangeClass(request.exoticWeaponType),
  );
  final usedTypes = <String>{
    if (exoticType.isNotEmpty) exoticType,
  };
  var usedExotic = request.exoticsAlreadyOnBuild > 0;
  final usedIds = Set<String>.from(request.pinnedInstanceIds);
  final picks = <WeaponOptimizePick>[];

  for (final slot in slots) {
    final pick = _pickSubstitute(
      slot: slot,
      inventory: request.inventory,
      subclassDamage: subclassDamage,
      exoticTypeLower: exoticType,
      preferredRange: preferredRange,
      usedTypes: usedTypes,
      usedIds: usedIds,
      excludeExotic: usedExotic,
      random: rng,
    );
    if (pick == null) continue;
    usedIds.add(pick.item.instanceId);
    final type = (pick.item.weaponType ?? '').trim().toLowerCase();
    if (type.isNotEmpty) usedTypes.add(type);
    if (pick.item.isExotic) usedExotic = true;
    picks.add(pick);
  }

  if (picks.isEmpty) {
    return const WeaponOptimizeResponse(combinations: []);
  }
  return WeaponOptimizeResponse(
    combinations: [
      WeaponOptimizeCombination(
        picks: List<WeaponOptimizePick>.unmodifiable(picks),
        score: 0,
        source: WeaponOptimizeSource.substitute,
        reason: kWeaponOptimizeNoCsvReason,
      ),
    ],
  );
}

WeaponOptimizePick? _pickSubstitute({
  required EquipmentSlot slot,
  required List<FillInInventoryItem> inventory,
  required String? subclassDamage,
  required String exoticTypeLower,
  required FillInWeaponRangeClass? preferredRange,
  required Set<String> usedTypes,
  required Set<String> usedIds,
  required bool excludeExotic,
  required Random random,
}) {
  final bucket = [
    for (final item in inventory)
      if (_passesHardFilters(
        item: item,
        slot: slot,
        exoticTypeLower: exoticTypeLower,
        usedIds: usedIds,
        excludeExotic: excludeExotic,
      ))
        item,
  ];
  if (bucket.isEmpty) return null;

  var note = kWeaponOptimizeNoCsvReason;
  var elementMismatch = false;
  var pool = bucket;
  if (subclassDamage != null) {
    final want = subclassDamage.toLowerCase();
    final matched = [
      for (final item in bucket)
        if ((item.damageType ?? '').trim().toLowerCase() == want) item,
    ];
    if (matched.isNotEmpty) {
      pool = matched;
    } else {
      elementMismatch = true;
      note = '$kWeaponOptimizeNoCsvReason; $kWeaponOptimizeElementMismatchNote';
    }
  }

  final distinct = [
    for (final item in pool)
      if (!_typeUsed(item, usedTypes)) item,
  ];
  final candidates = distinct.isNotEmpty ? distinct : pool;

  var ranged = candidates;
  if (preferredRange != null) {
    final opposite = [
      for (final item in candidates)
        if (fillInWeaponRangeClass(item.weaponType) == preferredRange) item,
    ];
    if (opposite.isNotEmpty) ranged = opposite;
  }

  final item = ranged[random.nextInt(ranged.length)];
  return WeaponOptimizePick(
    slot: slot,
    item: item,
    score: 0,
    source: WeaponOptimizeSource.substitute,
    elementMismatch: elementMismatch,
    note: note,
  );
}

List<_ScoredCandidate> _rankSlotCandidates({
  required EquipmentSlot slot,
  required List<FillInInventoryItem> inventory,
  required String? subclassDamage,
  required String exoticTypeLower,
  required FillInWeaponRangeClass? preferredRange,
  required List<String> keywords,
  required Set<String> usedIds,
  required int exoticsAlreadyOnBuild,
}) {
  final hard = [
    for (final item in inventory)
      if (_passesHardFilters(
        item: item,
        slot: slot,
        exoticTypeLower: exoticTypeLower,
        usedIds: usedIds,
        // Cap applied after ranking — still allow exotic candidates here.
        excludeExotic: false,
      ))
        item,
  ];
  if (hard.isEmpty) return const [];

  final matching = <FillInInventoryItem>[];
  final mismatch = <FillInInventoryItem>[];
  if (subclassDamage == null) {
    matching.addAll(hard);
  } else {
    final want = subclassDamage.toLowerCase();
    for (final item in hard) {
      if ((item.damageType ?? '').trim().toLowerCase() == want) {
        matching.add(item);
      } else {
        mismatch.add(item);
      }
    }
  }

  final preferLegendary = exoticsAlreadyOnBuild > 0;
  final scored = <_ScoredCandidate>[
    for (final item in matching)
      _ScoredCandidate(
        item: item,
        score: _softScore(
          item: item,
          preferredRange: preferredRange,
          elementMatched: true,
          keywords: keywords,
          preferLegendary: preferLegendary,
        ),
        elementMismatch: false,
      ),
  ];
  if (scored.isEmpty) {
    for (final item in mismatch) {
      scored.add(
        _ScoredCandidate(
          item: item,
          score: _softScore(
            item: item,
            preferredRange: preferredRange,
            elementMatched: false,
            keywords: keywords,
            preferLegendary: preferLegendary,
          ),
          elementMismatch: true,
        ),
      );
    }
  }

  scored.sort(_compareScored);
  return scored;
}

int _softScore({
  required FillInInventoryItem item,
  required FillInWeaponRangeClass? preferredRange,
  required bool elementMatched,
  required List<String> keywords,
  required bool preferLegendary,
}) {
  var score = 0;
  if (preferredRange != null &&
      fillInWeaponRangeClass(item.weaponType) == preferredRange) {
    score += kWeaponOptimizeOppositeRangePoints;
  }
  if (elementMatched) {
    score += kWeaponOptimizeElementMatchPoints;
  }
  score += _perkSynergyHits(item, keywords) * kWeaponOptimizePerkSynergyPoints;
  if (preferLegendary && !item.isExotic) {
    score += kWeaponOptimizeLegendaryPreferredPoints;
  }
  return score;
}

int _perkSynergyHits(FillInInventoryItem item, List<String> keywords) {
  if (keywords.isEmpty) return 0;
  final tags = item.perkTags;
  if (tags.isEmpty) return 0;
  var hits = 0;
  for (final tag in tags) {
    final lower = tag.trim().toLowerCase();
    if (lower.isEmpty) continue;
    for (final kw in keywords) {
      if (lower.contains(kw) || kw.contains(lower)) {
        hits += 1;
        break;
      }
    }
  }
  return hits;
}

List<WeaponOptimizeCombination> _buildCombinations({
  required List<EquipmentSlot> slots,
  required Map<EquipmentSlot, List<_ScoredCandidate>> rankedPerSlot,
  required int maxResults,
  required int exoticsAlreadyOnBuild,
}) {
  // Greedy top-N: take the best unused candidate per slot for each rank depth.
  final combos = <WeaponOptimizeCombination>[];
  final maxDepth = rankedPerSlot.values.fold<int>(
    0,
    (m, list) => list.length > m ? list.length : m,
  );
  if (maxDepth == 0) return combos;

  final depths = maxDepth < maxResults ? maxDepth : maxResults;
  for (var depth = 0; depth < depths; depth++) {
    final usedIds = <String>{};
    var exoticCount = exoticsAlreadyOnBuild;
    final picks = <WeaponOptimizePick>[];
    var total = 0;
    var ok = true;
    for (final slot in slots) {
      final ranked = rankedPerSlot[slot] ?? const <_ScoredCandidate>[];
      _ScoredCandidate? chosen;
      // Prefer depth-th candidate; walk forward for uniqueness / exotic cap.
      for (var i = depth; i < ranked.length; i++) {
        final c = ranked[i];
        if (usedIds.contains(c.item.instanceId)) continue;
        if (c.item.isExotic && exoticCount >= 1) continue;
        chosen = c;
        break;
      }
      // Fall back to any remaining non-conflicting candidate (never blank).
      if (chosen == null) {
        for (final c in ranked) {
          if (usedIds.contains(c.item.instanceId)) continue;
          if (c.item.isExotic && exoticCount >= 1) continue;
          chosen = c;
          break;
        }
      }
      if (chosen == null) {
        ok = false;
        break;
      }
      usedIds.add(chosen.item.instanceId);
      if (chosen.item.isExotic) exoticCount += 1;
      total += chosen.score;
      picks.add(
        WeaponOptimizePick(
          slot: slot,
          item: chosen.item,
          score: chosen.score,
          source: WeaponOptimizeSource.optimized,
          elementMismatch: chosen.elementMismatch,
          note: chosen.elementMismatch
              ? kWeaponOptimizeElementMismatchNote
              : null,
        ),
      );
    }
    if (!ok || picks.isEmpty) continue;
    final combo = WeaponOptimizeCombination(
      picks: List<WeaponOptimizePick>.unmodifiable(picks),
      score: total,
      source: WeaponOptimizeSource.optimized,
    );
    if (_comboKey(combo) case final key?
        when combos.any((c) => _comboKey(c) == key)) {
      continue;
    }
    combos.add(combo);
  }

  combos.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return _comboKey(a)!.compareTo(_comboKey(b)!);
  });
  return combos;
}

String? _comboKey(WeaponOptimizeCombination combo) {
  final parts = [
    for (final p in combo.picks) '${p.slot.wireName}:${p.item.instanceId}',
  ]..sort();
  return parts.join('|');
}

bool _passesHardFilters({
  required FillInInventoryItem item,
  required EquipmentSlot slot,
  required String exoticTypeLower,
  required Set<String> usedIds,
  required bool excludeExotic,
}) {
  if (!_isWeaponCombatSlot(item.slot)) return false;
  if (item.slot != slot) return false;
  if (usedIds.contains(item.instanceId)) return false;
  if (excludeExotic && item.isExotic) return false;
  final name = (item.name ?? '').trim();
  if (name.isEmpty) return false;
  if (name == kFillInNoWeaponInDimLink) return false;
  final type = (item.weaponType ?? '').trim().toLowerCase();
  if (exoticTypeLower.isNotEmpty && type == exoticTypeLower) return false;
  return true;
}

bool _typeUsed(FillInInventoryItem item, Set<String> usedTypes) {
  final type = (item.weaponType ?? '').trim().toLowerCase();
  if (type.isEmpty) return false;
  return usedTypes.contains(type);
}

bool _isWeaponCombatSlot(EquipmentSlot slot) {
  return slot == EquipmentSlot.primary ||
      slot == EquipmentSlot.special ||
      slot == EquipmentSlot.heavy;
}

int _compareScored(_ScoredCandidate a, _ScoredCandidate b) {
  final byScore = b.score.compareTo(a.score);
  if (byScore != 0) return byScore;
  final byHash = a.item.itemHash.compareTo(b.item.itemHash);
  if (byHash != 0) return byHash;
  return a.item.instanceId.compareTo(b.item.instanceId);
}

class _ScoredCandidate {
  const _ScoredCandidate({
    required this.item,
    required this.score,
    required this.elementMismatch,
  });

  final FillInInventoryItem item;
  final int score;
  final bool elementMismatch;
}
