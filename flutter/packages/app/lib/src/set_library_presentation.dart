import 'package:destiny2_domain/destiny2_domain.dart';

import 'errors.dart';

/// Attachment ref display for used-by strip (GAP-UI-SETS-05).
class SetUsedByDisplay {
  const SetUsedByDisplay({
    required this.buildId,
    required this.variantId,
    this.buildName,
  });

  final String buildId;
  final String variantId;
  final String? buildName;

  String get label {
    final name = buildName?.trim();
    if (name != null && name.isNotEmpty) {
      return '$name · $variantId';
    }
    return 'build $buildId · $variantId';
  }
}

/// Readiness summary for a library set detail (GAP-UI-SETS-05 + dart-070).
class SetReadinessSummary {
  const SetReadinessSummary({
    required this.filled,
    required this.capacity,
    required this.emptySlots,
    this.nextEmptySlot,
    this.isMods = false,
    this.modCount = 0,
    this.meetsPackageMinimum = true,
    this.packageMinimumCode,
    this.packageMinimumMessage,
    this.packageMinimumCount = 0,
    this.packageMinimumRequired = 0,
  });

  final int filled;
  final int capacity;
  final int emptySlots;
  final String? nextEmptySlot;
  final bool isMods;

  /// Raw mod row count (not piece groups). Prefer [packageMinimumCount] for floors.
  final int modCount;

  /// True when pure [setWouldPassSaveRules] passes (DBR-CMP-008–010).
  final bool meetsPackageMinimum;

  /// Occupancy failure wire code when under min.
  final String? packageMinimumCode;

  /// Plain-language occupancy reason when under min.
  final String? packageMinimumMessage;

  /// Occupancy count used by package floors (items / mod pieces / pair slots).
  final int packageMinimumCount;

  /// Required floor for this set type (0 fashion, 2 otherwise).
  final int packageMinimumRequired;

  /// Product-ish tone: verified | fuzzy | unresolved.
  String get tone {
    if (!meetsPackageMinimum) return 'unresolved';
    if (isMods) {
      return packageMinimumCount > 0 ? 'verified' : 'unresolved';
    }
    if (emptySlots == 0 && filled > 0) return 'verified';
    if (filled == 0) return 'unresolved';
    return 'fuzzy';
  }

  String get badgeLabel {
    if (!meetsPackageMinimum && packageMinimumMessage != null) {
      if (isMods) {
        return '${packageMinimumCount}/${packageMinimumRequired} pieces';
      }
      return '$filled/$capacity · need ${packageMinimumRequired}+';
    }
    if (isMods) {
      final pieces = packageMinimumCount;
      if (pieces > 0) {
        return pieces == 1 ? '1 armor piece' : '$pieces armor pieces';
      }
      return modCount == 1 ? '1 mod' : '$modCount mods';
    }
    final empty = emptySlots > 0 ? ' · $emptySlots empty' : '';
    return '$filled/$capacity filled$empty';
  }
}

/// Count board slots that have an active item with exact [slot] key.
int filledSlotCount({
  required List<String> boardSlots,
  required Iterable<String> activeItemSlots,
}) {
  final active = activeItemSlots.toSet();
  return boardSlots.where(active.contains).length;
}

/// First board slot without an exact active item (product `firstEmptySlot`).
String? firstEmptyBoardSlot({
  required List<String> boardSlots,
  required Iterable<String> activeItemSlots,
}) {
  final active = activeItemSlots.toSet();
  for (final slot in boardSlots) {
    if (!active.contains(slot)) return slot;
  }
  return null;
}

/// Build readiness for a set type + active item slots.
///
/// Package minimum fields/tone come from the same pure occupancy helper as
/// save/attach (DBR-CMP-008–010). Mod floors use distinct armor pieces via
/// [modSetArmorSlotOf], not raw mod row count.
SetReadinessSummary buildSetReadiness({
  required SetType setType,
  required List<String> boardSlots,
  required Iterable<String> activeItemSlots,
}) {
  final occupancyItems = [
    for (final slot in activeItemSlots) SetOccupancyItem(slot: slot),
  ];
  final occupancy = evaluateSetMinimumOccupancy(setType, occupancyItems);

  if (setType == SetType.mod) {
    final mods = activeItemSlots.length;
    final pieces = occupancy.count;
    return SetReadinessSummary(
      filled: pieces,
      capacity: boardSlots.isEmpty ? 0 : boardSlots.length,
      emptySlots: 0,
      nextEmptySlot: null,
      isMods: true,
      modCount: mods,
      meetsPackageMinimum: occupancy.ok,
      packageMinimumCode: occupancy.code,
      packageMinimumMessage: occupancy.ok
          ? null
          : formatSetOccupancyMessage(
              code: occupancy.code ?? DomainFailureCodes.modSetMinSlots,
              setType: setType,
              count: occupancy.count,
              required: occupancy.required,
              fallbackMessage: occupancy.message,
            ),
      packageMinimumCount: pieces,
      packageMinimumRequired: occupancy.required,
    );
  }
  final filled = filledSlotCount(
    boardSlots: boardSlots,
    activeItemSlots: activeItemSlots,
  );
  final capacity = boardSlots.length;
  final empty = (capacity - filled).clamp(0, capacity);
  return SetReadinessSummary(
    filled: filled,
    capacity: capacity,
    emptySlots: empty,
    nextEmptySlot: firstEmptyBoardSlot(
      boardSlots: boardSlots,
      activeItemSlots: activeItemSlots,
    ),
    meetsPackageMinimum: occupancy.ok,
    packageMinimumCode: occupancy.code,
    packageMinimumMessage: occupancy.ok
        ? null
        : formatSetOccupancyMessage(
            code: occupancy.code ?? DomainFailureCodes.setMinItems,
            setType: setType,
            count: occupancy.count,
            required: occupancy.required,
            fallbackMessage: occupancy.message,
          ),
    packageMinimumCount: occupancy.count,
    packageMinimumRequired: occupancy.required,
  );
}

/// Plain-language occupancy error for hosts (not bare hashes).
String formatSetOccupancyUseCaseMessage(UseCaseException e) {
  final code = e.code.wireName;
  final setTypeWire = e.details['setType'] as String?;
  final setType =
      setTypeWire != null ? SetType.tryParse(setTypeWire) : null;
  final count = e.details['count'] is int ? e.details['count'] as int : null;
  final required =
      e.details['required'] is int ? e.details['required'] as int : null;
  return formatSetOccupancyMessage(
    code: code,
    setType: setType,
    count: count,
    required: required,
    fallbackMessage: e.message,
  );
}

/// Used-by pills when attachments exist; empty → unused.
List<SetUsedByDisplay> mapUsedByDisplays(
  Iterable<({String buildId, String variantId, String? buildName})> refs,
) {
  return [
    for (final r in refs)
      SetUsedByDisplay(
        buildId: r.buildId,
        variantId: r.variantId,
        buildName: r.buildName,
      ),
  ];
}

/// Plain-language SET_IN_USE message (GAP-UI-SETS-06 / BR-DEL-001).
String formatSetInUseMessage({
  List<String> buildIds = const [],
  List<String> variantIds = const [],
}) {
  final builds = buildIds.toSet().toList()..sort();
  final variants = variantIds.toSet().toList()..sort();
  if (builds.isEmpty && variants.isEmpty) {
    return 'SET_IN_USE: This set is attached to one or more build variants '
        'and cannot be deleted until detached.';
  }
  final b = builds.isEmpty ? 'builds' : builds.join(', ');
  final v = variants.isEmpty ? 'variants' : variants.join(', ');
  return 'SET_IN_USE: Set is used by build(s) [$b] / variant(s) [$v]. '
      'Detach before deleting.';
}
