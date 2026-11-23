import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../builds_mock/builds_mock_models.dart';
import '../builds_mock/builds_mock_set_bonuses_from_combo.dart';

/// Snapshot a [MockBuild] for Optimize Undo (exact restore).
MockBuild snapshotMockBuild(MockBuild build) {
  return MockBuild(
    id: build.id,
    name: build.name,
    subclass: build.subclass,
    exoticArmor: build.exoticArmor,
    exoticWeapon: build.exoticWeapon,
    slots: [
      for (final s in build.slots)
        MockSlotAssignment(
          slot: s.slot,
          setId: s.setId,
          pieceName: s.pieceName,
          heldCopies: s.heldCopies,
          isExoticSlot: s.isExoticSlot,
          statTotal: s.statTotal,
          filledIn: s.filledIn,
          isSubstitute: s.isSubstitute,
        ),
    ],
    loop: build.loop,
    artifact: MockArtifact(
      name: build.artifact.name,
      season: build.artifact.season,
      perks: List<String>.from(build.artifact.perks),
    ),
    setBonuses: [
      for (final b in build.setBonuses)
        MockSetBonus(
          setId: b.setId,
          setName: b.setName,
          pieces: b.pieces,
          tier: b.tier,
          text: b.text,
        ),
    ],
    stats: [
      for (final s in build.stats) MockStatTotal(id: s.id, value: s.value),
    ],
    splitWhy: build.splitWhy,
    creator: build.creator,
    dimLink: build.dimLink,
    exoticWeaponType: build.exoticWeaponType,
    exoticWeaponDamageType: build.exoticWeaponDamageType,
    exoticWeaponSlot: build.exoticWeaponSlot,
    armorSetProposal: build.armorSetProposal,
    setBonusUnresolvedNote: build.setBonusUnresolvedNote,
    isOptimized: build.isOptimized,
  );
}

MockStatId? mockStatIdFromArmorStat(ArmorStatName name) {
  switch (name) {
    case ArmorStatName.health:
      return MockStatId.health;
    case ArmorStatName.melee:
      return MockStatId.melee;
    case ArmorStatName.grenade:
      return MockStatId.grenade;
    case ArmorStatName.superStat:
      return MockStatId.superAbility;
    case ArmorStatName.classStat:
      return MockStatId.classAbility;
    case ArmorStatName.weapons:
      return MockStatId.weapons;
  }
}

ArmorStatName? armorStatFromMockStatId(MockStatId id) {
  switch (id) {
    case MockStatId.health:
      return ArmorStatName.health;
    case MockStatId.melee:
      return ArmorStatName.melee;
    case MockStatId.grenade:
      return ArmorStatName.grenade;
    case MockStatId.superAbility:
      return ArmorStatName.superStat;
    case MockStatId.classAbility:
      return ArmorStatName.classStat;
    case MockStatId.weapons:
      return ArmorStatName.weapons;
  }
}

String mockStatIdWire(MockStatId id) => id.name;

MockStatId? mockStatIdFromWire(String wire) {
  for (final id in MockStatId.values) {
    if (id.name == wire) return id;
  }
  return null;
}

/// Apply an [ArmorCombination] onto [build] (app copy only).
///
/// Sets [MockBuild.isOptimized], replaces armor combat slots + stats + set
/// bonus boxes. Weapons and non-armor fields are preserved.
MockBuild applyOptimizeCombinationToBuild({
  required MockBuild build,
  required ArmorCombination combination,
  required int resultIndexOneBased,
}) {
  final slotByWire = <String, MockSlotAssignment>{
    for (final s in build.slots) s.slot: s,
  };

  String? exoticArmor = build.exoticArmor;
  for (final piece in combination.pieces) {
    final setId = piece.isExotic
        ? 'exotic'
        : (piece.setBonusKey?.trim().isNotEmpty == true
            ? piece.setBonusKey!.trim()
            : 'optimize');
    final name = (piece.itemName != null && piece.itemName!.trim().isNotEmpty)
        ? piece.itemName!.trim()
        : 'Armor ${piece.itemHash}';
    final total = piece.statValues.isEmpty
        ? null
        : piece.statValues.values.fold<int>(0, (a, b) => a + b);
    slotByWire[piece.slot.wireName] = MockSlotAssignment(
      slot: piece.slot.wireName,
      setId: setId,
      pieceName: name,
      isExoticSlot: piece.isExotic,
      statTotal: total,
      filledIn: true,
    );
    if (piece.isExotic) {
      exoticArmor = name;
    }
  }

  final stats = <MockStatTotal>[];
  for (final name in ArmorStatName.all) {
    final id = mockStatIdFromArmorStat(name);
    if (id == null) continue;
    final v = combination.estimatedStats[name];
    if (v == null) continue;
    stats.add(MockStatTotal(id: id, value: v));
  }

  // One combined 4pc box, or two boxes for 2+2 (never separate 2pc+4pc).
  final bonuses = mockSetBonusesFromCombination(combination);

  return build.copyWith(
    exoticArmor: exoticArmor,
    slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
    stats: List<MockStatTotal>.unmodifiable(stats),
    setBonuses: List<MockSetBonus>.unmodifiable(bonuses),
    isOptimized: true,
  );
}

/// Clear Optimized flag and restore [baseline] exactly.
MockBuild undoOptimizeOnBuild(MockBuild baseline) {
  return snapshotMockBuild(baseline).copyWith(isOptimized: false);
}

/// Persistable overlay for [OptimizeBuildStore].
OptimizedBuildRecord optimizedRecordFromBuild({
  required MockBuild build,
  required int resultIndexOneBased,
}) {
  return OptimizedBuildRecord(
    buildId: build.id,
    isOptimized: build.isOptimized,
    resultIndexOneBased: resultIndexOneBased,
    slots: [
      for (final s in build.slots)
        if (EquipmentSlot.armorSlots
            .any((a) => a.wireName == s.slot))
          OptimizedArmorSlot(
            slotWire: s.slot,
            pieceName: s.pieceName,
            setId: s.setId,
            isExotic: s.isExoticSlot,
            statTotal: s.statTotal,
          ),
    ],
    stats: [
      for (final s in build.stats)
        OptimizedStatTotal(idWire: mockStatIdWire(s.id), value: s.value),
    ],
    setBonuses: [
      for (final b in build.setBonuses)
        OptimizedSetBonus(
          setId: b.setId,
          setName: b.setName,
          pieces: b.pieces,
          tier: b.tier,
          text: b.text,
        ),
    ],
    exoticArmor: build.exoticArmor,
  );
}

/// Merge a persisted Optimize overlay onto a matrix/fixture build.
MockBuild applyOptimizedRecordToBuild({
  required MockBuild build,
  required OptimizedBuildRecord record,
}) {
  if (!record.isOptimized) {
    return build.copyWith(isOptimized: false);
  }
  final slotByWire = <String, MockSlotAssignment>{
    for (final s in build.slots) s.slot: s,
  };
  for (final s in record.slots) {
    if (s.slotWire.isEmpty) continue;
    slotByWire[s.slotWire] = MockSlotAssignment(
      slot: s.slotWire,
      setId: s.setId.isEmpty ? 'optimize' : s.setId,
      pieceName: s.pieceName,
      isExoticSlot: s.isExotic,
      statTotal: s.statTotal,
      filledIn: true,
    );
  }
  final stats = <MockStatTotal>[
    for (final s in record.stats)
      if (mockStatIdFromWire(s.idWire) != null)
        MockStatTotal(id: mockStatIdFromWire(s.idWire)!, value: s.value),
  ];
  final bonuses = <MockSetBonus>[
    for (final b in record.setBonuses)
      MockSetBonus(
        setId: b.setId,
        setName: b.setName,
        pieces: b.pieces,
        tier: b.tier,
        text: b.text,
      ),
  ];
  return build.copyWith(
    exoticArmor: record.exoticArmor ?? build.exoticArmor,
    slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
    stats: stats.isEmpty
        ? build.stats
        : List<MockStatTotal>.unmodifiable(stats),
    setBonuses: bonuses.isEmpty
        ? build.setBonuses
        : List<MockSetBonus>.unmodifiable(bonuses),
    isOptimized: true,
  );
}

/// Real item name from an optimizer piece, or null when unset (never invent
/// `Armor <hash>` placeholders for persistence).
String? optimizePieceDisplayName(ArmorOptimizePiece piece) {
  final name = piece.itemName?.trim();
  if (name == null || name.isEmpty) return null;
  return name;
}

/// Merge optimizer armor pins into an existing Fill In plan.
///
/// Replaces only slots covered by [combination]; keeps every other applied
/// entry and row (weapons, uncovered class item, etc.) exactly as they were.
/// Labels use the real item name when present; otherwise leave the name unset
/// (empty) — never persist `Armor <hash>` placeholders.
FillInSavedBuildPlan fillInPlanFromCombination({
  required String buildId,
  required ArmorCombination combination,
  FillInSavedBuildPlan? existing,
}) {
  final appliedByWire = <String, FillInAppliedSlot>{
    if (existing != null)
      for (final a in existing.applied)
        if (a.slotWire.trim().isNotEmpty) a.slotWire: a,
  };
  final rowsByWire = <String, FillInSavedSlotRow>{
    if (existing != null)
      for (final r in existing.rows)
        if (r.slotWire.trim().isNotEmpty) r.slotWire: r,
  };

  for (final p in combination.pieces) {
    final wire = p.slot.wireName;
    final name = optimizePieceDisplayName(p) ?? '';
    final prior = appliedByWire[wire];
    appliedByWire[wire] = FillInAppliedSlot(
      slotWire: wire,
      label: name,
      originalLabel: prior?.originalLabel ?? '',
      instanceId: p.instanceId,
      itemHash: p.itemHash,
    );
    if (name.isNotEmpty) {
      rowsByWire[wire] = FillInSavedSlotRow(
        slotWire: wire,
        slotLabel: wire,
        state: 'filled',
        itemName: name,
      );
    }
    // No real name → leave any prior row as-is; do not invent a placeholder.
  }

  return FillInSavedBuildPlan(
    buildId: buildId,
    missing: existing?.missing ?? const [],
    similarWeaponName: existing?.similarWeaponName,
    similarForName: existing?.similarForName,
    applied: List<FillInAppliedSlot>.unmodifiable(appliedByWire.values),
    rows: List<FillInSavedSlotRow>.unmodifiable(rowsByWire.values),
    updatedAt: DateTime.now().toUtc().toIso8601String(),
  );
}

/// After armor Optimize + optional weapon merge, choose the in-memory build.
///
/// When weapon persist fails, keep [armorOnly] so the UI matches the store
/// (armor pins written; unsaved weapon picks stay off screen).
MockBuild buildAfterWeaponMergePersist({
  required MockBuild armorOnly,
  required MockBuild? weaponMerged,
  required bool persistOk,
}) {
  if (weaponMerged != null && persistOk) return weaponMerged;
  return armorOnly;
}

/// Toast copy after confirm apply (Undo is SnackBar-lifetime only).
String optimizeAppliedToastMessage(int resultIndexOneBased) =>
    'Optimized with result #$resultIndexOneBased · Undo available briefly';

/// Caption kept on the results panel.
const String kBuildsOptimizeAdvisoryCaption =
    'Suggestions are not applied until you confirm.';

/// Whether Apply to character should first confirm the highlighted Optimize
/// result (same path as "Use this result") so Undo still works.
///
/// True only while the results panel is open with combinations and nothing is
/// already applying. Selecting a tab or pressing Use this result never fires
/// Apply by itself.
bool shouldConfirmHighlightedOptimizeBeforeApply({
  required bool panelOpen,
  required int combinationCount,
  required bool applying,
}) {
  return panelOpen && combinationCount > 0 && !applying;
}

/// Disabled Optimize reason when DIM armor CSV cache is missing.
const String kBuildsOptimizeNoCsvReason =
    'Import a DIM Armor CSV in Settings before Optimize.';

/// Detail caption: Fill In undo + Apply has no undo (covered by page tests).
const String kBuildsMockDetailUndoCaption =
    'Fill In updates this app copy; Undo fill in restores it. '
    'Fill In auto-applies Optimize result #1 then fills weapons; Optimize '
    'opens the results panel. Use this result / Undo only change this app '
    'copy — never Mario files or Bungie inventory. Apply to character equips '
    'one item at a time and has no undo.';
