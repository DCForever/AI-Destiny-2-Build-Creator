import 'dart:math';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../builds_mock/builds_mock_models.dart';
import 'fill_in_build_mapper.dart';
import 'fill_in_cache_loader.dart';
import 'fill_in_dialog.dart' show enforceAtMostOneExoticWeapon;
import 'fill_in_labels.dart';

/// Result of headless weapon Fill In after Optimize auto-apply.
class WeaponFillInApplyResult {
  const WeaponFillInApplyResult({
    required this.build,
    required this.plan,
  });

  final MockBuild build;
  final FillInSavedBuildPlan plan;
}

/// Run the existing subclass-influenced weapon substitute path and merge
/// weapon pins into [existingPlan] without touching armor applied entries.
///
/// Returns null when caches are missing/unreadable (caller keeps armor-only
/// apply). Never writes stores — caller persists [plan].
Future<WeaponFillInApplyResult?> applyWeaponFillInAfterOptimize({
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInSavedBuildPlan? existingPlan,
  CachedDimLoadout? dimLoadout,
  GuardianClass guardianClass = GuardianClass.warlock,
  Random? random,
}) async {
  final loaded = await loadCaches();
  if (!loaded.isOk) return null;

  var working = enrichMockBuildFromDimLoadout(build, loadout: dimLoadout);
  final mapped = mapMockBuildForFillIn(
    build: working,
    inventory: loaded.items,
    guardianClass: guardianClass,
    dimLoadout: dimLoadout,
  );
  final report = matchFillIn(
    inventory: mapped.inventory,
    builds: [mapped.requirement],
  );
  final result = report.builds.single;
  final missing = [
    for (final slot in result.slots)
      if (!slot.isHeld) slot,
  ];

  FillInWeaponNeed? weaponNeed;
  final exoticWeaponNeed = fillInWeaponNeedForBuild(
    build: working,
    inventory: loaded.items,
  );
  if (exoticWeaponNeed != null &&
      missing.any((m) => m.slot == exoticWeaponNeed.slot)) {
    weaponNeed = exoticWeaponNeed;
  }

  final currentLabels = <EquipmentSlot, String>{
    for (final s in working.slots)
      if (EquipmentSlot.tryParse(s.slot) != null &&
          s.pieceName.trim().isNotEmpty &&
          !_isWirePlaceholder(s.pieceName))
        EquipmentSlot.tryParse(s.slot)!: s.pieceName.trim(),
  };

  var diffs = planFillInSubstitutes(
    match: result,
    requirement: mapped.requirement,
    inventory: mapped.inventory,
    currentLabels: currentLabels,
    weaponNeed: weaponNeed,
    random: random ?? Random(),
  );
  diffs = enforceAtMostOneExoticWeapon(
    diffs: diffs,
    inventory: mapped.inventory,
  );

  final weaponDiffs = [
    for (final d in diffs)
      if (_isWeaponSlot(d.slot)) d,
  ];
  if (weaponDiffs.isEmpty) {
    return WeaponFillInApplyResult(
      build: working,
      plan: existingPlan ??
          FillInSavedBuildPlan(buildId: working.id, missing: const []),
    );
  }

  final slotByWire = <String, MockSlotAssignment>{
    for (final s in working.slots) s.slot: s,
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

  for (final diff in weaponDiffs) {
    final label = diff.applyLabel;
    final original = diff.currentLabel;
    final instanceId = diff.applyInstanceId;
    final itemHash = diff.applyItemHash;
    final filled = diff.isHeld || diff.wouldSubstitute;
    final realLabel = _isRealItemLabel(label);
    final realOriginal = _isRealItemLabel(original);

    if (realLabel ||
        (instanceId != null && instanceId.trim().isNotEmpty)) {
      appliedByWire[diff.slot.wireName] = FillInAppliedSlot(
        slotWire: diff.slot.wireName,
        label: realLabel ? label.trim() : '',
        originalLabel: realOriginal ? original.trim() : '',
        instanceId: instanceId,
        itemHash: itemHash,
      );
    }

    final existingWeapon = slotByWire[diff.slot.wireName];
    final isExotic =
        diff.isExotic || (existingWeapon?.isExoticSlot ?? false);
    if (realLabel &&
        isExotic &&
        (diff.wouldSubstitute || working.exoticWeapon.trim().isEmpty)) {
      working = working.copyWith(
        exoticWeapon: label,
        exoticWeaponSlot: diff.slot.wireName,
      );
    }
    final pieceName = realLabel
        ? label.trim()
        : (existingWeapon?.pieceName ?? '').trim();
    final markFilled = filled && pieceName.isNotEmpty;
    slotByWire[diff.slot.wireName] = MockSlotAssignment(
      slot: diff.slot.wireName,
      setId: existingWeapon?.setId ??
          (isExotic ? 'exotic_weapon' : 'weapon'),
      pieceName: pieceName,
      isExoticSlot: isExotic,
      statTotal: existingWeapon?.statTotal,
      filledIn: markFilled,
    );

    if (realLabel) {
      rowsByWire[diff.slot.wireName] = FillInSavedSlotRow(
        slotWire: diff.slot.wireName,
        slotLabel: fillInMissingSlotLabel(
          slot: diff.slot,
          isExotic: isExotic,
        ),
        state: markFilled ? 'filled' : (diff.wouldSubstitute ? 'proposed' : 'held'),
        itemName: pieceName,
      );
    }
  }

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
  return WeaponFillInApplyResult(build: working, plan: plan);
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

bool _isWirePlaceholder(String label) {
  final lower = label.trim().toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return true;
  }
  return false;
}

bool _isRealItemLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed == kFillInNoWeaponInDimLink) return false;
  return !_isWirePlaceholder(trimmed);
}
