import 'package:destiny2_domain/destiny2_domain.dart';

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

/// Readiness summary for a library set detail (GAP-UI-SETS-05).
class SetReadinessSummary {
  const SetReadinessSummary({
    required this.filled,
    required this.capacity,
    required this.emptySlots,
    this.nextEmptySlot,
    this.isMods = false,
    this.modCount = 0,
  });

  final int filled;
  final int capacity;
  final int emptySlots;
  final String? nextEmptySlot;
  final bool isMods;
  final int modCount;

  /// Product-ish tone: verified | fuzzy | unresolved.
  String get tone {
    if (isMods) {
      return modCount > 0 ? 'verified' : 'unresolved';
    }
    if (emptySlots == 0 && filled > 0) return 'verified';
    if (filled == 0) return 'unresolved';
    return 'fuzzy';
  }

  String get badgeLabel {
    if (isMods) {
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
SetReadinessSummary buildSetReadiness({
  required SetType setType,
  required List<String> boardSlots,
  required Iterable<String> activeItemSlots,
}) {
  if (setType == SetType.mod) {
    final mods = activeItemSlots.length;
    return SetReadinessSummary(
      filled: mods,
      capacity: boardSlots.isEmpty ? 0 : boardSlots.length,
      emptySlots: 0,
      nextEmptySlot: null,
      isMods: true,
      modCount: mods,
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
