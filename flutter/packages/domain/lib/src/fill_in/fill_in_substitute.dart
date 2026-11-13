import 'dart:math';

import '../models/equipment.dart';
import 'fill_in_inventory.dart';
import 'fill_in_requirement.dart';
import 'fill_in_result.dart';
import 'fill_in_similar_weapon.dart';
import 'fill_in_two_plus_two.dart';

/// Display when a weapon combat slot has no known piece from the DIM link.
const String kFillInNoWeaponInDimLink = 'No weapon in DIM link';

/// Note when no held weapon matched the subclass element filter.
const String kFillInWeaponElementFallbackNote =
    'No subclass-element match; any held in bucket';

/// One slot's Fill In preview: current build label → proposed substitute.
///
/// Pure / read-only — never mutates inventory or Bungie state. Hosts persist
/// applied diffs via the Fill In store and update the app build copy.
class FillInSlotDiff {
  const FillInSlotDiff({
    required this.slot,
    required this.currentLabel,
    required this.isHeld,
    this.isExotic = false,
    this.substituteLabel,
    this.substituteInstanceId,
    this.substituteItemHash,
    this.heldInstanceId,
    this.heldItemHash,
    this.note,
  });

  final EquipmentSlot slot;

  /// Display name currently on the build for this slot.
  final String currentLabel;

  /// True when inventory already holds a matching copy of [currentLabel].
  final bool isHeld;

  /// Whether this row's requirement is the exotic piece for its bucket.
  final bool isExotic;

  /// Proposed substitute display name (null when none / already held as-is).
  final String? substituteLabel;

  final String? substituteInstanceId;
  final int? substituteItemHash;

  /// Held matching instance when [isHeld] (for Apply to character pins).
  final String? heldInstanceId;
  final int? heldItemHash;

  /// Optional review note (e.g. element-filter fallback).
  final String? note;

  /// True when Apply to build would change the slot label.
  bool get wouldSubstitute =>
      substituteLabel != null &&
      substituteLabel!.trim().isNotEmpty &&
      substituteLabel!.trim().toLowerCase() != currentLabel.trim().toLowerCase();

  /// Instance to equip after Fill In apply (substitute or held match).
  String? get applyInstanceId =>
      wouldSubstitute ? substituteInstanceId : heldInstanceId;

  int? get applyItemHash => wouldSubstitute ? substituteItemHash : heldItemHash;

  String get applyLabel => wouldSubstitute
      ? (substituteLabel ?? currentLabel)
      : currentLabel;
}

/// Build current→substitute diffs from a Fill In match + inventory.
///
/// - Held / DIM-owned slots: keep current label; never replace.
/// - Missing weapon slots: random held pick in the same bucket, filtered by
///   subclass element (any for Prismatic/unknown), excluding the exotic
///   weapon's type and duplicate substitute types, preferring the opposite
///   range class. At most one exotic weapon across all picks.
/// - Missing armor (helmet/arms/chest/legs): random legendary picks that form
///   a 4-piece set or two 2-piece sets (exotic slot is set-neutral). Class
///   Item is independent; exotic armor never lands on Class Item.
///
/// Pass a seeded [random] for deterministic tests. Production hosts should
/// pass a fresh [Random] each dialog open so picks re-roll when there is no
/// saved plan.
List<FillInSlotDiff> planFillInSubstitutes({
  required FillInBuildResult match,
  required FillInBuildRequirement requirement,
  required Iterable<FillInInventoryItem> inventory,
  required Map<EquipmentSlot, String> currentLabels,
  FillInWeaponNeed? weaponNeed,
  Random? random,
}) {
  final rng = random ?? Random();
  final inv = inventory.toList(growable: false);
  final needBySlot = <EquipmentSlot, FillInSlotRequirement>{
    for (final s in requirement.slots) s.slot: s,
  };
  final exoticWeaponSlots = <EquipmentSlot>{
    for (final s in requirement.slots)
      if (s.isExotic && _isWeaponSlot(s.slot)) s.slot,
  };

  var usedExoticWeapon = false;
  for (final slotMatch in match.slots) {
    if (!slotMatch.isHeld) continue;
    if (!_isWeaponSlot(slotMatch.slot)) continue;
    final need = needBySlot[slotMatch.slot];
    if (need != null && need.isExotic) {
      usedExoticWeapon = true;
      break;
    }
    final held = _findHeldMatch(
      inventory: inv,
      guardianClass: requirement.guardianClass,
      need: need,
      currentLabel: (currentLabels[slotMatch.slot] ?? '').trim(),
    );
    if (held?.isExotic ?? false) {
      usedExoticWeapon = true;
      break;
    }
  }

  final exoticWeaponType = _resolveExoticWeaponType(
    requirement: requirement,
    inventory: inv,
    currentLabels: currentLabels,
    weaponNeed: weaponNeed,
  );
  final preferredRange = fillInOppositeWeaponRange(
    fillInWeaponRangeClass(exoticWeaponType),
  );
  final subclassDamage = fillInDamageTypeForSubclass(requirement.subclassKey);
  final usedWeaponTypes = <String>{
    if (exoticWeaponType != null && exoticWeaponType.trim().isNotEmpty)
      exoticWeaponType.trim().toLowerCase(),
  };

  final armorPicks = _planArmorSetSubstitutes(
    match: match,
    requirement: requirement,
    inventory: inv,
    needBySlot: needBySlot,
    random: rng,
  );

  final diffs = <FillInSlotDiff>[];
  final orderedMatches = _dedupeSlotMatches(match, requirement);

  for (final slotMatch in orderedMatches) {
    final slot = slotMatch.slot;
    final current = (currentLabels[slot] ?? '').trim();
    final need = _preferredNeed(needBySlot, requirement.slots, slot);
    final isExotic = need?.isExotic ?? false;
    final displayCurrent = _displayCurrentLabel(slot, current);

    if (slotMatch.isHeld) {
      final held = _findHeldMatch(
        inventory: inv,
        guardianClass: requirement.guardianClass,
        need: need,
        currentLabel: current,
      );
      final heldName = (held?.name ?? '').trim();
      final label = displayCurrent.isNotEmpty
          ? displayCurrent
          : (heldName.isNotEmpty ? heldName : displayCurrent);
      if (_isWeaponSlot(slot) && (held?.isExotic ?? isExotic)) {
        usedExoticWeapon = true;
      }
      final heldType = (held?.weaponType ?? '').trim().toLowerCase();
      if (_isWeaponSlot(slot) && heldType.isNotEmpty) {
        usedWeaponTypes.add(heldType);
      }
      diffs.add(
        FillInSlotDiff(
          slot: slot,
          currentLabel: label,
          isHeld: true,
          isExotic: isExotic,
          heldInstanceId: held?.instanceId,
          heldItemHash: held?.itemHash,
        ),
      );
      continue;
    }

    if (_isWeaponSlot(slot)) {
      final excludeExotic = _shouldExcludeExoticWeapon(
        forSlot: slot,
        exoticWeaponSlots: exoticWeaponSlots,
        alreadyUsedExoticWeapon: usedExoticWeapon,
      );
      final pick = _pickWeaponSubstitute(
        slot: slot,
        inventory: inv,
        subclassDamage: subclassDamage,
        usedWeaponTypes: usedWeaponTypes,
        preferredRange: preferredRange,
        excludeExotic: excludeExotic,
        random: rng,
      );
      final item = pick.item;
      if (item != null && item.isExotic) {
        usedExoticWeapon = true;
      }
      final type = (item?.weaponType ?? '').trim().toLowerCase();
      if (type.isNotEmpty) usedWeaponTypes.add(type);
      diffs.add(
        FillInSlotDiff(
          slot: slot,
          currentLabel: displayCurrent,
          isHeld: false,
          isExotic: isExotic,
          substituteLabel: item?.name,
          substituteInstanceId: item?.instanceId,
          substituteItemHash: item?.itemHash,
          note: pick.note,
        ),
      );
      continue;
    }

    if (kFillInTwoPlusTwoSlotOrder.contains(slot)) {
      final armor = armorPicks[slot];
      diffs.add(
        FillInSlotDiff(
          slot: slot,
          currentLabel: displayCurrent,
          isHeld: false,
          isExotic: isExotic,
          substituteLabel: armor?.name,
          substituteInstanceId: armor?.instanceId,
          substituteItemHash: armor?.itemHash,
        ),
      );
      continue;
    }

    // Class Item / exoticArmor pad — independent of set rule.
    final armorSub = _suggestClassItemOrExoticArmor(
      inventory: inv,
      guardianClass: requirement.guardianClass,
      need: need,
      slot: slot,
      random: rng,
    );
    diffs.add(
      FillInSlotDiff(
        slot: slot,
        currentLabel: displayCurrent,
        isHeld: false,
        isExotic: isExotic,
        substituteLabel: armorSub?.name,
        substituteInstanceId: armorSub?.instanceId,
        substituteItemHash: armorSub?.itemHash,
      ),
    );
  }

  return List<FillInSlotDiff>.unmodifiable(diffs);
}

/// One row per equipment slot; when duplicates exist prefer the exotic need's
/// match (guards against 2+2 + exotic race until the mapper drops the legend).
///
/// [FillInBuildResult.slots] is built in the same order as
/// [FillInBuildRequirement.slots], so indices align.
List<FillInSlotMatch> _dedupeSlotMatches(
  FillInBuildResult match,
  FillInBuildRequirement requirement,
) {
  if (match.slots.length != requirement.slots.length) {
    final seen = <EquipmentSlot>{};
    return [
      for (final s in match.slots)
        if (seen.add(s.slot)) s,
    ];
  }
  final chosenIndex = <EquipmentSlot, int>{};
  for (var i = 0; i < requirement.slots.length; i++) {
    final need = requirement.slots[i];
    final prev = chosenIndex[need.slot];
    if (prev == null || need.isExotic) {
      chosenIndex[need.slot] = i;
    }
  }
  final seen = <EquipmentSlot>{};
  return [
    for (var i = 0; i < requirement.slots.length; i++)
      if (chosenIndex[requirement.slots[i].slot] == i &&
          seen.add(requirement.slots[i].slot))
        match.slots[i],
  ];
}

FillInSlotRequirement? _preferredNeed(
  Map<EquipmentSlot, FillInSlotRequirement> bySlot,
  List<FillInSlotRequirement> all,
  EquipmentSlot slot,
) {
  FillInSlotRequirement? exotic;
  FillInSlotRequirement? any;
  for (final need in all) {
    if (need.slot != slot) continue;
    any ??= need;
    if (need.isExotic) exotic = need;
  }
  return exotic ?? any ?? bySlot[slot];
}

bool _shouldExcludeExoticWeapon({
  required EquipmentSlot forSlot,
  required Set<EquipmentSlot> exoticWeaponSlots,
  required bool alreadyUsedExoticWeapon,
}) {
  for (final exoticSlot in exoticWeaponSlots) {
    if (exoticSlot != forSlot) return true;
  }
  if (alreadyUsedExoticWeapon) return true;
  return false;
}

String? _resolveExoticWeaponType({
  required FillInBuildRequirement requirement,
  required List<FillInInventoryItem> inventory,
  required Map<EquipmentSlot, String> currentLabels,
  required FillInWeaponNeed? weaponNeed,
}) {
  if (weaponNeed != null && weaponNeed.weaponType.trim().isNotEmpty) {
    return weaponNeed.weaponType.trim();
  }
  for (final need in requirement.slots) {
    if (!need.isExotic || !_isWeaponSlot(need.slot)) continue;
    final label = (currentLabels[need.slot] ?? '').trim().toLowerCase();
    if (need.exoticItemHash != null) {
      for (final item in inventory) {
        if (item.itemHash == need.exoticItemHash &&
            (item.weaponType ?? '').trim().isNotEmpty) {
          return item.weaponType!.trim();
        }
      }
    }
    if (label.isNotEmpty) {
      for (final item in inventory) {
        if ((item.name ?? '').trim().toLowerCase() != label) continue;
        if ((item.weaponType ?? '').trim().isNotEmpty) {
          return item.weaponType!.trim();
        }
      }
    }
  }
  return null;
}

class _WeaponPick {
  const _WeaponPick({this.item, this.note});
  final FillInInventoryItem? item;
  final String? note;
}

_WeaponPick _pickWeaponSubstitute({
  required EquipmentSlot slot,
  required List<FillInInventoryItem> inventory,
  required String? subclassDamage,
  required Set<String> usedWeaponTypes,
  required FillInWeaponRangeClass? preferredRange,
  required bool excludeExotic,
  required Random random,
}) {
  final bucket = <FillInInventoryItem>[
    for (final item in inventory)
      if (_isWeaponSlot(item.slot) &&
          item.slot == slot &&
          !(excludeExotic && item.isExotic) &&
          _hasRealWeaponName(item))
        item,
  ];
  if (bucket.isEmpty) return const _WeaponPick();

  String? note;
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
      note = kFillInWeaponElementFallbackNote;
    }
  }

  final typed = _filterDistinctTypes(pool, usedWeaponTypes);
  final candidates = typed.isNotEmpty ? typed : pool;

  List<FillInInventoryItem> ranged = candidates;
  if (preferredRange != null) {
    final opposite = [
      for (final item in candidates)
        if (fillInWeaponRangeClass(item.weaponType) == preferredRange) item,
    ];
    if (opposite.isNotEmpty) ranged = opposite;
  }

  final pick = ranged[random.nextInt(ranged.length)];
  return _WeaponPick(item: pick, note: note);
}

List<FillInInventoryItem> _filterDistinctTypes(
  List<FillInInventoryItem> pool,
  Set<String> usedWeaponTypes,
) {
  return [
    for (final item in pool)
      if (!_typeBlocked(item, usedWeaponTypes)) item,
  ];
}

bool _typeBlocked(FillInInventoryItem item, Set<String> usedWeaponTypes) {
  final type = (item.weaponType ?? '').trim().toLowerCase();
  if (type.isEmpty) return false;
  return usedWeaponTypes.contains(type);
}

bool _hasRealWeaponName(FillInInventoryItem item) {
  final name = (item.name ?? '').trim();
  if (name.isEmpty) return false;
  if (name == kFillInNoWeaponInDimLink) return false;
  return !_isWireName(name.toLowerCase());
}

/// Armor set rule for helmet/arms/chest/legs (class item excluded).
///
/// Held / DIM pieces stay. Exotic armor counts as no set. Remaining free
/// slots are filled so the four form either one 4-piece set or two 2-piece
/// sets. With an exotic occupying one slot, the other three form a 2-piece
/// plus one leftover (leftover prefers the same set as the 2-piece when held
/// inventory allows).
Map<EquipmentSlot, FillInInventoryItem?> _planArmorSetSubstitutes({
  required FillInBuildResult match,
  required FillInBuildRequirement requirement,
  required List<FillInInventoryItem> inventory,
  required Map<EquipmentSlot, FillInSlotRequirement> needBySlot,
  required Random random,
}) {
  final heldBySlot = <EquipmentSlot, FillInInventoryItem?>{};
  final lockedSetBySlot = <EquipmentSlot, int?>{};
  EquipmentSlot? exoticSlot;

  for (final slot in kFillInTwoPlusTwoSlotOrder) {
    final need = _preferredNeed(needBySlot, requirement.slots, slot);
    final isHeld = match.slots.any((s) => s.slot == slot && s.isHeld);
    if (need != null && need.isExotic) {
      exoticSlot = slot;
      if (isHeld) {
        heldBySlot[slot] = _findHeldMatch(
          inventory: inventory,
          guardianClass: requirement.guardianClass,
          need: need,
          currentLabel: '',
        );
      }
      lockedSetBySlot[slot] = null; // set-neutral
      continue;
    }
    if (isHeld) {
      final held = _findHeldMatch(
        inventory: inventory,
        guardianClass: requirement.guardianClass,
        need: need,
        currentLabel: '',
      );
      heldBySlot[slot] = held;
      lockedSetBySlot[slot] = held?.armorSetHash;
    }
  }

  final freeSlots = [
    for (final slot in kFillInTwoPlusTwoSlotOrder)
      if (!heldBySlot.containsKey(slot) && slot != exoticSlot) slot,
  ];
  final picks = <EquipmentSlot, FillInInventoryItem?>{
    for (final e in heldBySlot.entries) e.key: e.value,
  };

  if (freeSlots.isEmpty) return picks;

  final lockedSets = <int>[
    for (final h in lockedSetBySlot.values)
      if (h != null) h,
  ];

  final legendaryBySlot = <EquipmentSlot, List<FillInInventoryItem>>{};
  for (final slot in freeSlots) {
    legendaryBySlot[slot] = [
      for (final item in inventory)
        if (!item.isExotic &&
            item.guardianClass == requirement.guardianClass &&
            item.slot == slot &&
            item.armorSetHash != null &&
            (item.name ?? '').trim().isNotEmpty)
          item,
    ];
  }

  // With exotic: need 2-piece + leftover among the (up to) 3 non-exotic slots.
  if (exoticSlot != null) {
    _assignWithExotic(
      freeSlots: freeSlots,
      lockedSets: lockedSets,
      legendaryBySlot: legendaryBySlot,
      picks: picks,
      random: random,
    );
    return picks;
  }

  _assignFourPieceOrTwoPlusTwo(
    freeSlots: freeSlots,
    lockedSets: lockedSets,
    legendaryBySlot: legendaryBySlot,
    picks: picks,
    random: random,
  );
  return picks;
}

void _assignWithExotic({
  required List<EquipmentSlot> freeSlots,
  required List<int> lockedSets,
  required Map<EquipmentSlot, List<FillInInventoryItem>> legendaryBySlot,
  required Map<EquipmentSlot, FillInInventoryItem?> picks,
  required Random random,
}) {
  // Count locked legendary sets among non-exotic held slots.
  final setCounts = <int, int>{};
  for (final h in lockedSets) {
    setCounts[h] = (setCounts[h] ?? 0) + 1;
  }

  // Prefer completing a 2-piece for an already-held set.
  int? pairSet;
  for (final entry in setCounts.entries) {
    if (entry.value == 1) {
      pairSet = entry.key;
      break;
    }
  }
  pairSet ??= setCounts.isEmpty ? null : setCounts.keys.first;

  if (pairSet != null) {
    final needPair = 2 - (setCounts[pairSet] ?? 0);
    var paired = 0;
    for (final slot in freeSlots) {
      if (paired >= needPair) break;
      final pool = [
        for (final item in legendaryBySlot[slot] ?? const <FillInInventoryItem>[])
          if (item.armorSetHash == pairSet) item,
      ];
      if (pool.isEmpty) continue;
      picks[slot] = pool[random.nextInt(pool.length)];
      paired += 1;
    }
  }

  // Leftover free slots: prefer same set as the pair when possible.
  for (final slot in freeSlots) {
    if (picks.containsKey(slot)) continue;
    final prefer = pairSet;
    final preferred = prefer == null
        ? const <FillInInventoryItem>[]
        : [
            for (final item
                in legendaryBySlot[slot] ?? const <FillInInventoryItem>[])
              if (item.armorSetHash == prefer) item,
          ];
    final pool = preferred.isNotEmpty
        ? preferred
        : (legendaryBySlot[slot] ?? const <FillInInventoryItem>[]);
    if (pool.isEmpty) {
      picks[slot] = null;
      continue;
    }
    picks[slot] = pool[random.nextInt(pool.length)];
  }
}

void _assignFourPieceOrTwoPlusTwo({
  required List<EquipmentSlot> freeSlots,
  required List<int> lockedSets,
  required Map<EquipmentSlot, List<FillInInventoryItem>> legendaryBySlot,
  required Map<EquipmentSlot, FillInInventoryItem?> picks,
  required Random random,
}) {
  final setCounts = <int, int>{};
  for (final h in lockedSets) {
    setCounts[h] = (setCounts[h] ?? 0) + 1;
  }

  // Try 4-piece when a held set can be completed, else 2+2.
  int? fourSet;
  for (final entry in setCounts.entries) {
    if (entry.value >= 1 && entry.value < 4) {
      fourSet = entry.key;
      break;
    }
  }

  if (fourSet != null && freeSlots.length + (setCounts[fourSet] ?? 0) >= 4) {
    var ok = true;
    final trial = <EquipmentSlot, FillInInventoryItem>{};
    for (final slot in freeSlots) {
      final pool = [
        for (final item in legendaryBySlot[slot] ?? const <FillInInventoryItem>[])
          if (item.armorSetHash == fourSet) item,
      ];
      if (pool.isEmpty) {
        ok = false;
        break;
      }
      trial[slot] = pool[random.nextInt(pool.length)];
    }
    if (ok) {
      picks.addAll(trial);
      return;
    }
  }

  // 2+2: pick two set hashes and assign.
  final availableSets = <int>{
    for (final slot in freeSlots)
      for (final item in legendaryBySlot[slot] ?? const <FillInInventoryItem>[])
        if (item.armorSetHash != null) item.armorSetHash!,
    ...setCounts.keys,
  }.toList()
    ..sort();

  int? first = setCounts.keys.isEmpty ? null : setCounts.keys.first;
  int? second;
  for (final s in availableSets) {
    if (s != first) {
      second = s;
      break;
    }
  }
  first ??= availableSets.isEmpty ? null : availableSets.first;
  if (first != null && second == null && availableSets.length > 1) {
    second = availableSets[1];
  }

  // Walk free slots: fill first set to 2, then second to 2, then leftovers.
  var needFirst = 2 - (setCounts[first] ?? 0);
  var needSecond = second == null ? 0 : 2 - (setCounts[second] ?? 0);
  if (needFirst < 0) needFirst = 0;
  if (needSecond < 0) needSecond = 0;

  for (final slot in freeSlots) {
    final items = legendaryBySlot[slot] ?? const <FillInInventoryItem>[];
    if (items.isEmpty) {
      picks[slot] = null;
      continue;
    }
    FillInInventoryItem? chosen;
    if (needFirst > 0 && first != null) {
      final pool = [for (final i in items) if (i.armorSetHash == first) i];
      if (pool.isNotEmpty) {
        chosen = pool[random.nextInt(pool.length)];
        needFirst -= 1;
      }
    }
    if (chosen == null && needSecond > 0 && second != null) {
      final pool = [for (final i in items) if (i.armorSetHash == second) i];
      if (pool.isNotEmpty) {
        chosen = pool[random.nextInt(pool.length)];
        needSecond -= 1;
      }
    }
    chosen ??= items[random.nextInt(items.length)];
    picks[slot] = chosen;
  }
}

FillInInventoryItem? _suggestClassItemOrExoticArmor({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required FillInSlotRequirement? need,
  required EquipmentSlot slot,
  required Random random,
}) {
  if (need != null && need.isExotic) {
    // Exotic armor never on Class Item — only exact exotic hash match.
    if (slot == EquipmentSlot.classItem) return null;
    final wantHash = need.exoticItemHash;
    if (wantHash == null) return null;
    final pool = [
      for (final item in inventory)
        if (item.isExotic &&
            item.guardianClass == guardianClass &&
            item.itemHash == wantHash &&
            (slot == EquipmentSlot.exoticArmor || item.slot == slot))
          item,
    ];
    if (pool.isEmpty) return null;
    return pool[random.nextInt(pool.length)];
  }

  final pool = [
    for (final item in inventory)
      if (!item.isExotic &&
          item.guardianClass == guardianClass &&
          item.slot == slot &&
          (item.name ?? '').trim().isNotEmpty)
        item,
  ];
  if (pool.isEmpty) return null;
  if (need?.armorSetHash != null) {
    final same = [
      for (final item in pool)
        if (item.armorSetHash == need!.armorSetHash) item,
    ];
    if (same.isNotEmpty) return same[random.nextInt(same.length)];
  }
  return pool[random.nextInt(pool.length)];
}

String _displayCurrentLabel(EquipmentSlot slot, String current) {
  if (current.isNotEmpty) {
    final lower = current.toLowerCase();
    if (_isWireName(lower)) {
      if (_isWeaponSlot(slot)) return kFillInNoWeaponInDimLink;
      return '';
    }
    if (current == kFillInNoWeaponInDimLink) return current;
    return current;
  }
  if (_isWeaponSlot(slot)) return kFillInNoWeaponInDimLink;
  return '';
}

bool _isWireName(String lower) {
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return true;
  }
  return false;
}

FillInInventoryItem? _findHeldMatch({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required FillInSlotRequirement? need,
  required String currentLabel,
}) {
  if (need == null) return null;
  final wantName = currentLabel.trim().toLowerCase();

  FillInInventoryItem? byName;
  FillInInventoryItem? byNeed;

  for (final item in inventory) {
    if (!_matchesNeed(item, guardianClass, need)) continue;
    byNeed ??= item;
    final name = (item.name ?? '').trim().toLowerCase();
    if (wantName.isNotEmpty && name == wantName) {
      byName = item;
      break;
    }
  }
  return byName ?? byNeed;
}

bool _matchesNeed(
  FillInInventoryItem item,
  GuardianClass guardianClass,
  FillInSlotRequirement need,
) {
  if (_isWeaponSlot(need.slot) || need.slot == EquipmentSlot.exoticWeapon) {
    if (!_isWeaponSlot(item.slot)) return false;
    if (need.slot != EquipmentSlot.exoticWeapon && item.slot != need.slot) {
      return false;
    }
    if (need.exoticItemHash != null) {
      return item.itemHash == need.exoticItemHash;
    }
    return item.isExotic;
  }
  if (item.guardianClass != guardianClass) return false;
  if (item.slot != need.slot) return false;
  if (need.isExotic) {
    if (!item.isExotic) return false;
    if (need.exoticItemHash != null) {
      return item.itemHash == need.exoticItemHash;
    }
    return true;
  }
  if (item.isExotic) return false;
  if (need.armorSetHash != null) {
    return item.armorSetHash == need.armorSetHash;
  }
  return true;
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}
