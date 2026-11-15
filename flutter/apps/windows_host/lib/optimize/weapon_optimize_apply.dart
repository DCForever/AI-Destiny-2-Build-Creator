import 'dart:math';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../builds_mock/builds_mock_models.dart';
import '../fill_in/fill_in_labels.dart';

/// Empty / unpinned Kinetic/Energy/Power slots on [build].
///
/// A slot is pinned when it has a real piece name and either [filledIn] or an
/// entry in [plan.applied]. Held/pinned slots are never returned.
List<EquipmentSlot> emptyUnpinnedWeaponSlots({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
}) {
  final pinnedWires = <String>{};
  if (plan != null) {
    for (final a in plan.applied) {
      final wire = a.slotWire.trim();
      if (wire.isEmpty) continue;
      if (!_isWeaponWire(wire)) continue;
      if (a.label.trim().isEmpty &&
          (a.instanceId == null || a.instanceId!.trim().isEmpty)) {
        continue;
      }
      pinnedWires.add(wire);
    }
  }

  final out = <EquipmentSlot>[];
  for (final slot in EquipmentSlot.weaponSlots) {
    final assignment = _slotOnBuild(build, slot);
    final wire = slot.wireName;
    if (pinnedWires.contains(wire)) continue;
    if (assignment != null &&
        assignment.filledIn &&
        _isRealWeaponLabel(assignment.pieceName)) {
      continue;
    }
    if (assignment != null && _isRealWeaponLabel(assignment.pieceName)) {
      // Occupied by a real (non-fill-in) piece — treat as pinned.
      continue;
    }
    out.add(slot);
  }
  return out;
}

/// Instance ids already pinned on the build / plan (weapons only).
Set<String> pinnedWeaponInstanceIds({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
}) {
  final ids = <String>{};
  if (plan != null) {
    for (final a in plan.applied) {
      if (!_isWeaponWire(a.slotWire)) continue;
      final id = a.instanceId?.trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

/// Drop CSV rows whose instance id is absent from [cachedInventory].
///
/// Stale import protection — read-only; never equips / deletes.
List<FillInInventoryItem> filterWeaponsPresentInCache({
  required Iterable<FillInInventoryItem> csvWeapons,
  required Iterable<FillInInventoryItem> cachedInventory,
}) {
  final live = <String>{
    for (final item in cachedInventory)
      if (_isWeaponCombatSlot(item.slot)) item.instanceId,
  };
  if (live.isEmpty) {
    // No separate live cache — treat CSV itself as the offline store.
    return [
      for (final item in csvWeapons)
        if (_isWeaponCombatSlot(item.slot)) item,
    ];
  }
  return [
    for (final item in csvWeapons)
      if (_isWeaponCombatSlot(item.slot) && live.contains(item.instanceId))
        item,
  ];
}

/// Build keywords for perk/synergy soft scoring from the mock build.
List<String> weaponOptimizeKeywordsForBuild(MockBuild build) {
  final out = <String>[];
  final subclass = build.subclass.trim();
  if (subclass.isNotEmpty) out.add(subclass);
  final exotic = build.exoticWeapon.trim();
  if (exotic.isNotEmpty) out.add(exotic);
  for (final p in build.artifact.perks) {
    final t = p.trim();
    if (t.isNotEmpty) out.add(t);
  }
  return out;
}

/// Merge a [WeaponOptimizeCombination] into [build] + Fill In plan.
///
/// Only touches empty/unpinned weapon wires. Armor applied entries stay.
/// Substitute kits are never marked optimized on the build.
WeaponOptimizeApplyResult applyWeaponOptimizeCombination({
  required MockBuild build,
  required WeaponOptimizeCombination combination,
  FillInSavedBuildPlan? existingPlan,
}) {
  final slotByWire = <String, MockSlotAssignment>{
    for (final s in build.slots) s.slot: s,
  };
  final appliedByWire = <String, FillInAppliedSlot>{
    if (existingPlan != null)
      for (final a in existingPlan.applied)
        if (a.slotWire.trim().isNotEmpty) a.slotWire: a,
  };
  final rowsByWire = <String, FillInSavedSlotRow>{
    if (existingPlan != null)
      for (final r in existingPlan.rows)
        if (r.slotWire.trim().isNotEmpty) r.slotWire: r,
  };

  var working = build;
  for (final pick in combination.picks) {
    final wire = pick.slot.wireName;
    final label = (pick.item.name ?? '').trim();
    if (label.isEmpty) continue;

    // Never overwrite an existing pin.
    final existingApplied = appliedByWire[wire];
    if (existingApplied != null &&
        (existingApplied.label.trim().isNotEmpty ||
            (existingApplied.instanceId?.trim().isNotEmpty ?? false))) {
      continue;
    }
    final existingSlot = slotByWire[wire];
    if (existingSlot != null &&
        existingSlot.filledIn &&
        _isRealWeaponLabel(existingSlot.pieceName)) {
      continue;
    }
    if (existingSlot != null && _isRealWeaponLabel(existingSlot.pieceName)) {
      continue;
    }

    appliedByWire[wire] = FillInAppliedSlot(
      slotWire: wire,
      label: label,
      originalLabel: '',
      instanceId: pick.item.instanceId,
      itemHash: pick.item.itemHash,
    );

    final isExotic = pick.item.isExotic;
    if (isExotic && working.exoticWeapon.trim().isEmpty) {
      working = working.copyWith(
        exoticWeapon: label,
        exoticWeaponSlot: wire,
        exoticWeaponType: pick.item.weaponType,
        exoticWeaponDamageType: pick.item.damageType,
      );
    }

    slotByWire[wire] = MockSlotAssignment(
      slot: wire,
      setId: existingSlot?.setId ?? (isExotic ? 'exotic_weapon' : 'weapon'),
      pieceName: label,
      isExoticSlot: isExotic,
      statTotal: existingSlot?.statTotal,
      // Substitute fills are Fill In activity; optimized fills too — but
      // MockBuild.isOptimized stays armor-only (never set from substitute).
      filledIn: true,
    );

    final state = combination.isSubstitute ? 'proposed' : 'filled';
    rowsByWire[wire] = FillInSavedSlotRow(
      slotWire: wire,
      slotLabel: fillInMissingSlotLabel(slot: pick.slot, isExotic: isExotic),
      state: state,
      itemName: label,
    );
  }

  working = working.copyWith(
    slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
    // Never mark the build optimized from a substitute weapon kit.
    isOptimized: combination.isSubstitute ? working.isOptimized : working.isOptimized,
  );

  final plan = FillInSavedBuildPlan(
    buildId: working.id,
    missing: existingPlan?.missing ?? const [],
    similarWeaponName: existingPlan?.similarWeaponName,
    similarForName: existingPlan?.similarForName,
    applied: List<FillInAppliedSlot>.unmodifiable(appliedByWire.values),
    rows: List<FillInSavedSlotRow>.unmodifiable(rowsByWire.values),
    updatedAt: DateTime.now().toUtc().toIso8601String(),
  );
  return WeaponOptimizeApplyResult(build: working, plan: plan);
}

/// Result of applying a weapon optimize combination.
class WeaponOptimizeApplyResult {
  const WeaponOptimizeApplyResult({
    required this.build,
    required this.plan,
  });

  final MockBuild build;
  final FillInSavedBuildPlan plan;
}

/// Run weapon optimize (CSV scored or substitute) for empty slots.
WeaponOptimizeResponse runWeaponOptimizeForBuild({
  required MockBuild build,
  required List<FillInInventoryItem> weaponInventory,
  required bool hasWeaponsCsv,
  FillInSavedBuildPlan? plan,
  Random? random,
  int maxResults = 3,
}) {
  final empty = emptyUnpinnedWeaponSlots(build: build, plan: plan);
  if (empty.isEmpty) {
    return const WeaponOptimizeResponse(combinations: []);
  }
  var exoticCount = 0;
  for (final s in build.slots) {
    if (!_isWeaponWire(s.slot)) continue;
    if (s.isExoticSlot) exoticCount += 1;
  }
  if (exoticCount == 0 && build.exoticWeapon.trim().isNotEmpty) {
    exoticCount = 1;
  }
  return optimizeWeapons(
    WeaponOptimizeRequest(
      emptySlots: empty,
      inventory: weaponInventory,
      subclassKey: build.subclass,
      exoticWeaponType: build.exoticWeaponType,
      pinnedInstanceIds: pinnedWeaponInstanceIds(build: build, plan: plan),
      buildKeywords: weaponOptimizeKeywordsForBuild(build),
      exoticsAlreadyOnBuild: exoticCount,
      maxResults: maxResults,
      hasWeaponsCsv: hasWeaponsCsv,
      random: random,
    ),
  );
}

MockSlotAssignment? _slotOnBuild(MockBuild build, EquipmentSlot slot) {
  for (final s in build.slots) {
    if (s.slot == slot.wireName) return s;
  }
  return null;
}

bool _isWeaponWire(String wire) {
  final slot = EquipmentSlot.tryParse(wire);
  return slot != null && _isWeaponCombatSlot(slot);
}

bool _isWeaponCombatSlot(EquipmentSlot slot) {
  return slot == EquipmentSlot.primary ||
      slot == EquipmentSlot.special ||
      slot == EquipmentSlot.heavy;
}

bool _isRealWeaponLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed == kFillInNoWeaponInDimLink) return false;
  final lower = trimmed.toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return false;
  }
  return true;
}
