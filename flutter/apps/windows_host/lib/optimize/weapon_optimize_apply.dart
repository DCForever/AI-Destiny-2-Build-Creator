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

/// Exotic weapons already on the build **or** pinned only in [plan].
///
/// Counts slot flags, plan row labels (`Exotic …`), plan applied pins that
/// match exotic inventory rows / [MockBuild.exoticWeapon], and a named
/// [MockBuild.exoticWeapon] with no slot yet.
int countWeaponExoticsAlreadyOnBuild({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
  Iterable<FillInInventoryItem> weaponInventory = const [],
}) {
  final exoticWires = <String>{};
  for (final s in build.slots) {
    if (!_isWeaponWire(s.slot)) continue;
    if (s.isExoticSlot) exoticWires.add(s.slot);
  }

  final exoticByInstance = <String>{
    for (final item in weaponInventory)
      if (item.isExotic && _isWeaponCombatSlot(item.slot)) item.instanceId,
  };
  final exoticName = build.exoticWeapon.trim().toLowerCase();

  if (plan != null) {
    for (final row in plan.rows) {
      if (!_isWeaponWire(row.slotWire)) continue;
      final state = row.state.trim().toLowerCase();
      if (state != 'filled' && state != 'proposed' && state != 'held') {
        continue;
      }
      if (row.slotLabel.trim().toLowerCase().startsWith('exotic')) {
        exoticWires.add(row.slotWire);
      }
    }
    for (final a in plan.applied) {
      if (!_isWeaponWire(a.slotWire)) continue;
      if (exoticWires.contains(a.slotWire)) continue;
      final id = a.instanceId?.trim() ?? '';
      final fromInv = id.isNotEmpty && exoticByInstance.contains(id);
      final fromName = exoticName.isNotEmpty &&
          a.label.trim().toLowerCase() == exoticName;
      if (fromInv || fromName) {
        exoticWires.add(a.slotWire);
      }
    }
  }

  if (exoticWires.isNotEmpty) return exoticWires.length;
  if (exoticName.isNotEmpty) return 1;
  return 0;
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
  final isSubstitute = combination.isSubstitute;
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
      filledIn: true,
      isSubstitute: isSubstitute,
    );

    final state = isSubstitute ? 'proposed' : 'filled';
    rowsByWire[wire] = FillInSavedSlotRow(
      slotWire: wire,
      slotLabel: fillInMissingSlotLabel(slot: pick.slot, isExotic: isExotic),
      state: state,
      itemName: label,
    );
  }

  // Weapon apply never flips [MockBuild.isOptimized] (armor-only flag).
  working = working.copyWith(
    slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
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
  final exoticCount = countWeaponExoticsAlreadyOnBuild(
    build: build,
    plan: plan,
    weaponInventory: weaponInventory,
  );
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
