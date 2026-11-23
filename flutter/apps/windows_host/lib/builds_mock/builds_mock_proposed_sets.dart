import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_models.dart';

const _kArmorSlotWires = {'helmet', 'arms', 'chest', 'legs', 'class_item'};

/// Placeholder / synthetic slot setIds that are not armor-set families.
bool _isPlaceholderSetId(String raw) {
  final id = raw.trim().toLowerCase();
  if (id.isEmpty) return true;
  if (id == 'exotic' || id == 'exotic_weapon' || id == 'weapon') return true;
  if (id == 'fill_in' || id == 'optimize') return true;
  if (id.startsWith('dim_')) return true;
  return false;
}

/// Same key rules as [candidatesFromDimArmorItems] so Optimize goals match
/// stamped [CandidatePiece.setBonusKey] values.
///
/// Prefers catalog display name from [setBonusKeyByItemHash]; falls back to
/// `set:${armorSetHash}` when the catalog map misses.
String? setKeyForInventoryItem({
  required FillInInventoryItem item,
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  if (item.isExotic) return null;
  final mapped = setBonusKeyByItemHash[item.itemHash]?.trim();
  if (mapped != null && mapped.isNotEmpty) return mapped;
  final fromHash = item.armorSetHash;
  if (fromHash != null && fromHash > 0) return 'set:$fromHash';
  return null;
}

FillInAppliedSlot? _appliedForSlot(
  FillInSavedBuildPlan plan,
  String slotWire,
) {
  for (final a in plan.applied) {
    if (a.slotWire == slotWire) return a;
  }
  return null;
}

/// Inventory matches for one Fill In armor row (slot-gated; hash/instance first).
List<FillInInventoryItem> _inventoryMatchesForPlanRow({
  required FillInSavedSlotRow row,
  FillInAppliedSlot? applied,
  required List<FillInInventoryItem> armorItems,
}) {
  final slotWire = row.slotWire;
  final wantHash = applied?.itemHash;
  final wantInstance = applied?.instanceId?.trim() ?? '';
  final name = row.itemName.trim().toLowerCase();
  final out = <FillInInventoryItem>[];
  for (final item in armorItems) {
    if (item.isExotic) continue;
    if (item.slot.wireName != slotWire) continue;
    if (wantHash != null) {
      if (item.itemHash == wantHash) out.add(item);
      continue;
    }
    if (wantInstance.isNotEmpty) {
      if (item.instanceId == wantInstance) out.add(item);
      continue;
    }
    if (name.isEmpty) continue;
    if ((item.name ?? '').trim().toLowerCase() == name) out.add(item);
  }
  return out;
}

/// Resolve one row's set key, or null when unmatched / ambiguous set family.
String? _setKeyForPlanRow({
  required FillInSavedSlotRow row,
  FillInAppliedSlot? applied,
  required List<FillInInventoryItem> armorItems,
  required Map<int, String> setBonusKeyByItemHash,
}) {
  final matches = _inventoryMatchesForPlanRow(
    row: row,
    applied: applied,
    armorItems: armorItems,
  );
  if (matches.isEmpty) return null;
  final keys = <String>{};
  for (final item in matches) {
    final key = setKeyForInventoryItem(
      item: item,
      setBonusKeyByItemHash: setBonusKeyByItemHash,
    );
    if (key != null && key.isNotEmpty) keys.add(key);
  }
  // Same-name (or multi-copy) hits that disagree on family → no goal for row.
  if (keys.length != 1) return null;
  return keys.single;
}

/// Resolve set-bonus family keys from Fill In proposed/filled armor rows.
Map<String, int> _planSetPieceCounts({
  required FillInSavedBuildPlan plan,
  required List<FillInInventoryItem> armorItems,
  required Map<int, String> setBonusKeyByItemHash,
}) {
  final counts = <String, int>{};
  for (final row in plan.rows) {
    if (!_kArmorSlotWires.contains(row.slotWire)) continue;
    final state = row.state.trim().toLowerCase();
    if (state != 'proposed' && state != 'filled') continue;
    final key = _setKeyForPlanRow(
      row: row,
      applied: _appliedForSlot(plan, row.slotWire),
      armorItems: armorItems,
      setBonusKeyByItemHash: setBonusKeyByItemHash,
    );
    if (key == null || key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Count legendary armor pieces per set family from [build.slots].
///
/// When inventory + catalog map are provided, resolves each piece through
/// [setKeyForInventoryItem] so keys match optimizer candidates; otherwise
/// uses non-placeholder [MockSlotAssignment.setId] as-is.
Map<String, int> _slotSetPieceCounts(
  MockBuild build, {
  List<FillInInventoryItem> armorItems = const [],
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  final counts = <String, int>{};
  for (final s in build.slots) {
    if (s.isExoticSlot) continue;
    if (!_kArmorSlotWires.contains(s.slot)) continue;
    String? key;
    if (armorItems.isNotEmpty) {
      final name = s.pieceName.trim().toLowerCase();
      if (name.isNotEmpty) {
        final matches = <FillInInventoryItem>[
          for (final item in armorItems)
            if (!item.isExotic &&
                item.slot.wireName == s.slot &&
                (item.name ?? '').trim().toLowerCase() == name)
              item,
        ];
        final keys = <String>{};
        for (final item in matches) {
          final resolved = setKeyForInventoryItem(
            item: item,
            setBonusKeyByItemHash: setBonusKeyByItemHash,
          );
          if (resolved != null && resolved.isNotEmpty) keys.add(resolved);
        }
        if (keys.length == 1) {
          key = keys.single;
        } else if (keys.length > 1) {
          // Ambiguous name across families — skip this slot.
          continue;
        }
      }
    }
    key ??= _isPlaceholderSetId(s.setId) ? null : s.setId.trim();
    if (key == null || key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

List<MockSetBonus> _bonusesFromCounts(
  Map<String, int> counts, {
  Map<String, String> nameById = const {},
  Map<String, String> textById = const {},
}) {
  if (counts.isEmpty) return const [];
  final four = <MapEntry<String, int>>[
    for (final e in counts.entries)
      if (e.value >= 4) e,
  ];
  if (four.isNotEmpty) {
    // Prefer a single 4pc (legal G-SET-013).
    four.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    final e = four.first;
    final name = nameById[e.key] ?? e.key;
    return [
      MockSetBonus(
        setId: e.key,
        setName: name,
        pieces: 4,
        tier: '4pc',
        text: textById[e.key] ?? '4pc $name',
      ),
    ];
  }
  final twos = <MapEntry<String, int>>[
    for (final e in counts.entries)
      if (e.value >= 2) e,
  ]..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
  if (twos.isEmpty) return const [];
  final take = twos.length >= 2 ? twos.sublist(0, 2) : twos;
  return [
    for (final e in take)
      MockSetBonus(
        setId: e.key,
        setName: nameById[e.key] ?? e.key,
        pieces: 2,
        tier: '2pc',
        text: textById[e.key] ?? '2pc ${nameById[e.key] ?? e.key}',
      ),
  ];
}

/// Proposed armor set bonuses for a build (display + Optimize goals).
///
/// Interpretation (Daniel Nov 15 2026): the armor set(s) / set-bonus the build
/// specifies — [MockBuild.setBonuses] when present (4pc or 2+2), else Mario's
/// [MockBuild.armorSetProposal] rematched via catalog keys, else Fill In
/// `proposed`/`filled` armor rows resolved via inventory set keys, else
/// legendary slot [MockSlotAssignment.setId] counts that form 4pc or 2+2.
///
/// Mario's proposal is the default; non-empty [MockBuild.setBonuses] (user /
/// Optimize / fixture) win and are not overwritten here.
List<MockSetBonus> proposedSetBonusesFor({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
  List<FillInInventoryItem> armorItems = const [],
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  if (build.setBonuses.isNotEmpty) {
    return combineBuildsMockSetBonuses(build.setBonuses);
  }
  // Mario proposal → catalog keys (import may have run before catalog load).
  final proposal = build.armorSetProposal?.trim() ?? '';
  if (proposal.isNotEmpty && setBonusKeyByItemHash.isNotEmpty) {
    final resolved = resolveArmorSetProposal(
      raw: proposal,
      catalogNames: {
        for (final n in setBonusKeyByItemHash.values)
          if (n.trim().isNotEmpty) n.trim(),
      },
    );
    if (resolved.goals.isNotEmpty) {
      return combineBuildsMockSetBonuses([
        for (final g in resolved.goals)
          MockSetBonus(
            setId: g.setBonusKey,
            setName: g.setBonusKey,
            pieces: g.minPieces,
            tier: g.minPieces >= 4 ? '4pc' : '2pc',
            text: '${g.minPieces}pc ${g.setBonusKey}',
          ),
      ]);
    }
  }
  if (plan != null && plan.rows.isNotEmpty && armorItems.isNotEmpty) {
    final fromPlan = _bonusesFromCounts(
      _planSetPieceCounts(
        plan: plan,
        armorItems: armorItems,
        setBonusKeyByItemHash: setBonusKeyByItemHash,
      ),
    );
    if (fromPlan.isNotEmpty) return combineBuildsMockSetBonuses(fromPlan);
  }
  final fromSlots = _bonusesFromCounts(
    _slotSetPieceCounts(
      build,
      armorItems: armorItems,
      setBonusKeyByItemHash: setBonusKeyByItemHash,
    ),
  );
  if (fromSlots.isEmpty) return const [];
  return combineBuildsMockSetBonuses(fromSlots);
}

/// Hard Optimize set-bonus goals from [proposedSetBonusesFor] (4pc or 2+2).
///
/// Empty when the build has no proposed sets — caller keeps prior behavior.
List<SetBonusCoverageGoal> proposedSetBonusGoalsFor({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
  List<FillInInventoryItem> armorItems = const [],
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  final bonuses = proposedSetBonusesFor(
    build: build,
    plan: plan,
    armorItems: armorItems,
    setBonusKeyByItemHash: setBonusKeyByItemHash,
  );
  if (bonuses.isEmpty) return const [];
  final goals = <SetBonusCoverageGoal>[
    for (final b in bonuses)
      SetBonusCoverageGoal(
        setBonusKey: b.setId,
        minPieces: b.pieces >= 4 ? 4 : 2,
      ),
  ];
  if (!isLegalSetBonusGoalCombo(goals)) return const [];
  return List<SetBonusCoverageGoal>.unmodifiable(goals);
}
