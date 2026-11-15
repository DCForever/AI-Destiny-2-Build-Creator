import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_models.dart';

/// Placeholder / synthetic slot setIds that are not armor-set families.
bool _isPlaceholderSetId(String raw) {
  final id = raw.trim().toLowerCase();
  if (id.isEmpty) return true;
  if (id == 'exotic' || id == 'exotic_weapon' || id == 'weapon') return true;
  if (id == 'fill_in' || id == 'optimize') return true;
  if (id.startsWith('dim_')) return true;
  return false;
}

/// Count legendary armor pieces per set family from [build.slots].
Map<String, int> _slotSetPieceCounts(MockBuild build) {
  final counts = <String, int>{};
  const armorWires = {'helmet', 'arms', 'chest', 'legs', 'class_item'};
  for (final s in build.slots) {
    if (s.isExoticSlot) continue;
    if (!armorWires.contains(s.slot)) continue;
    if (_isPlaceholderSetId(s.setId)) continue;
    final key = s.setId.trim();
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Resolve set-bonus family keys from Fill In proposed/filled armor rows.
Map<String, int> _planSetPieceCounts({
  required FillInSavedBuildPlan plan,
  required List<FillInInventoryItem> armorItems,
  required Map<int, String> setBonusKeyByItemHash,
}) {
  final counts = <String, int>{};
  const armorWires = {'helmet', 'arms', 'chest', 'legs', 'class_item'};
  for (final row in plan.rows) {
    if (!armorWires.contains(row.slotWire)) continue;
    final state = row.state.trim().toLowerCase();
    if (state != 'proposed' && state != 'filled') continue;
    final name = row.itemName.trim().toLowerCase();
    if (name.isEmpty) continue;
    String? key;
    for (final item in armorItems) {
      if (item.isExotic) continue;
      if ((item.name ?? '').trim().toLowerCase() != name) continue;
      final mapped = setBonusKeyByItemHash[item.itemHash]?.trim();
      if (mapped != null && mapped.isNotEmpty) {
        key = mapped;
      } else if (item.armorSetHash != null && item.armorSetHash! > 0) {
        key = 'set:${item.armorSetHash}';
      }
      if (key != null) break;
    }
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
/// specifies — [MockBuild.setBonuses] when present (4pc or 2+2), else Fill In
/// `proposed`/`filled` armor rows resolved via inventory set keys, else
/// legendary slot [MockSlotAssignment.setId] counts that form 4pc or 2+2.
List<MockSetBonus> proposedSetBonusesFor({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
  List<FillInInventoryItem> armorItems = const [],
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  if (build.setBonuses.isNotEmpty) {
    return combineBuildsMockSetBonuses(build.setBonuses);
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
  final fromSlots = _bonusesFromCounts(_slotSetPieceCounts(build));
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
