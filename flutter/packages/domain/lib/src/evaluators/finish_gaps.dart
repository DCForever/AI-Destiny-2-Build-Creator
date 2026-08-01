/// Pure finish-gap evaluation for Builds guided walkthrough.
///
/// Mirrors TypeScript `src/lib/builds/finishGaps.ts`.
/// Category order: armor → weapon → mod.
/// Satisfied requires covering set + required slots filled
/// (mod: set or hasModCoverage).
library;

import '../models/equipment.dart';

/// Finish walkthrough categories (TS `FinishCategory`).
enum FinishCategory {
  armor('armor'),
  weapon('weapon'),
  mod('mod');

  const FinishCategory(this.wireName);
  final String wireName;

  static FinishCategory? tryParse(String wire) {
    for (final v in FinishCategory.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Per-category finish status (TS `FinishGapStatus`).
enum FinishGapStatus {
  satisfied('satisfied'),
  needsSet('needs_set'),
  needsFill('needs_fill'),
  captureAvailable('capture_available');

  const FinishGapStatus(this.wireName);
  final String wireName;

  static FinishGapStatus? tryParse(String wire) {
    for (final v in FinishGapStatus.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Attachment input for finish-gap evaluation.
class FinishAttachmentInput {
  const FinishAttachmentInput({
    required this.setId,
    required this.mode,
    required this.setType,
    this.setName,
  });

  final String setId;
  final AttachmentMode mode;
  final SetType setType;
  final String? setName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinishAttachmentInput &&
        other.setId == setId &&
        other.mode == mode &&
        other.setType == setType &&
        other.setName == setName;
  }

  @override
  int get hashCode => Object.hash(setId, mode, setType, setName);
}

/// Equipment claim input for finish-gap evaluation (pure, string slot keys).
class FinishEquipmentClaim {
  const FinishEquipmentClaim({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
  });

  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinishEquipmentClaim &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.itemName == itemName &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => Object.hash(slot, itemHash, itemName, instanceId);
}

/// One category row in a finish-gap result.
class FinishGap {
  const FinishGap({
    required this.category,
    required this.status,
    this.coveringSetId,
    this.coveringSetName,
    this.coveringMode,
    this.emptySlots = const [],
    required this.filledSlotCount,
    required this.requiredSlotCount,
    required this.resolvedClaimCount,
    required this.canCapture,
  });

  final FinishCategory category;
  final FinishGapStatus status;
  final String? coveringSetId;
  final String? coveringSetName;
  final AttachmentMode? coveringMode;
  final List<String> emptySlots;
  final int filledSlotCount;
  final int requiredSlotCount;
  final int resolvedClaimCount;
  final bool canCapture;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinishGap) return false;
    if (other.category != category ||
        other.status != status ||
        other.coveringSetId != coveringSetId ||
        other.coveringSetName != coveringSetName ||
        other.coveringMode != coveringMode ||
        other.filledSlotCount != filledSlotCount ||
        other.requiredSlotCount != requiredSlotCount ||
        other.resolvedClaimCount != resolvedClaimCount ||
        other.canCapture != canCapture) {
      return false;
    }
    if (other.emptySlots.length != emptySlots.length) return false;
    for (var i = 0; i < emptySlots.length; i++) {
      if (other.emptySlots[i] != emptySlots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        category,
        status,
        coveringSetId,
        coveringSetName,
        coveringMode,
        Object.hashAll(emptySlots),
        filledSlotCount,
        requiredSlotCount,
        resolvedClaimCount,
        canCapture,
      );
}

/// Aggregate finish-gap evaluation result.
class FinishGapsResult {
  const FinishGapsResult({
    required this.variantId,
    required this.isDefaultVariant,
    required this.complete,
    required this.gaps,
    this.nextActionable,
  });

  final String variantId;
  final bool isDefaultVariant;
  final bool complete;
  final List<FinishGap> gaps;
  final FinishGap? nextActionable;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinishGapsResult) return false;
    if (other.variantId != variantId ||
        other.isDefaultVariant != isDefaultVariant ||
        other.complete != complete ||
        other.nextActionable != nextActionable) {
      return false;
    }
    if (other.gaps.length != gaps.length) return false;
    for (var i = 0; i < gaps.length; i++) {
      if (other.gaps[i] != gaps[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        variantId,
        isDefaultVariant,
        complete,
        Object.hashAll(gaps),
        nextActionable,
      );
}

/// Input for [evaluateFinishGaps].
class EvaluateFinishGapsInput {
  const EvaluateFinishGapsInput({
    required this.variantId,
    required this.isDefaultVariant,
    this.attachments = const [],
    this.equipment = const {},
    this.hasModCoverage,
    this.skippedKeys,
  });

  final String variantId;
  final bool isDefaultVariant;
  final List<FinishAttachmentInput> attachments;

  /// Slot wire name → claim (null values treated as empty).
  final Map<String, FinishEquipmentClaim?> equipment;

  /// When true, mod category can be satisfied without a mod-type set.
  final bool? hasModCoverage;

  /// Session skip keys (`armor`, `weapon`, `mod`, or `armor:helmet`).
  /// Does not change status; used only for nextActionable preference.
  final List<String>? skippedKeys;
}

const List<FinishCategory> _categoryOrder = [
  FinishCategory.armor,
  FinishCategory.weapon,
  FinishCategory.mod,
];

List<String> _requiredSlots(FinishCategory category) {
  switch (category) {
    case FinishCategory.armor:
      return EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
    case FinishCategory.weapon:
      return EquipmentSlot.weaponSlots.map((s) => s.wireName).toList();
    case FinishCategory.mod:
      return const [];
  }
}

SetType _setTypeFor(FinishCategory category) {
  switch (category) {
    case FinishCategory.armor:
      return SetType.armor;
    case FinishCategory.weapon:
      return SetType.weapon;
    case FinishCategory.mod:
      return SetType.mod;
  }
}

FinishAttachmentInput? _coveringFor(
  List<FinishAttachmentInput> attachments,
  FinishCategory category,
) {
  final type = _setTypeFor(category);
  final matches = attachments.where((a) => a.setType == type).toList();
  if (matches.isEmpty) return null;
  for (final a in matches) {
    if (a.mode == AttachmentMode.live) return a;
  }
  return matches.first;
}

bool _slotFilled(
  Map<String, FinishEquipmentClaim?> equipment,
  String slot,
) {
  final claim = equipment[slot];
  if (claim == null) return false;
  final hash = claim.itemHash;
  return hash.isFinite && hash > 0;
}

int _claimsInSlots(
  Map<String, FinishEquipmentClaim?> equipment,
  List<String> slots,
) {
  var n = 0;
  for (final slot in slots) {
    if (_slotFilled(equipment, slot)) n += 1;
  }
  return n;
}

FinishGap _evaluateCategory(
  FinishCategory category,
  EvaluateFinishGapsInput input,
) {
  final covering = _coveringFor(input.attachments, category);
  final required = _requiredSlots(category);

  if (category == FinishCategory.mod) {
    final hasSet = covering != null;
    final soft = input.hasModCoverage == true;
    final satisfied = hasSet || soft;
    // create-from-build currently skips mod snapshot — never canCapture for mod
    return FinishGap(
      category: category,
      status: satisfied ? FinishGapStatus.satisfied : FinishGapStatus.needsSet,
      coveringSetId: covering?.setId,
      coveringSetName: covering?.setName,
      coveringMode: covering?.mode,
      emptySlots: const [],
      filledSlotCount: satisfied ? 1 : 0,
      requiredSlotCount: 1,
      resolvedClaimCount: 0,
      canCapture: false,
    );
  }

  final emptySlots =
      required.where((s) => !_slotFilled(input.equipment, s)).toList();
  final filledSlotCount = required.length - emptySlots.length;
  final resolvedClaimCount = _claimsInSlots(input.equipment, required);
  final hasCovering = covering != null;

  final FinishGapStatus status;
  if (hasCovering && emptySlots.isEmpty) {
    status = FinishGapStatus.satisfied;
  } else if (hasCovering && emptySlots.isNotEmpty) {
    status = FinishGapStatus.needsFill;
  } else if (!hasCovering && resolvedClaimCount > 0) {
    status = FinishGapStatus.captureAvailable;
  } else {
    status = FinishGapStatus.needsSet;
  }

  return FinishGap(
    category: category,
    status: status,
    coveringSetId: covering?.setId,
    coveringSetName: covering?.setName,
    coveringMode: covering?.mode,
    emptySlots: emptySlots,
    filledSlotCount: filledSlotCount,
    requiredSlotCount: required.length,
    resolvedClaimCount: resolvedClaimCount,
    canCapture: status == FinishGapStatus.captureAvailable,
  );
}

/// Pure finish-gap evaluation for Builds guided walkthrough.
FinishGapsResult evaluateFinishGaps(EvaluateFinishGapsInput input) {
  final gaps = _categoryOrder.map((c) => _evaluateCategory(c, input)).toList();
  final complete = gaps.every((g) => g.status == FinishGapStatus.satisfied);
  final skipped = {...?input.skippedKeys};

  FinishGap? nextActionable;
  for (final g in gaps) {
    if (g.status != FinishGapStatus.satisfied &&
        !skipped.contains(g.category.wireName)) {
      nextActionable = g;
      break;
    }
  }
  if (nextActionable == null) {
    for (final g in gaps) {
      if (g.status != FinishGapStatus.satisfied) {
        nextActionable = g;
        break;
      }
    }
  }

  return FinishGapsResult(
    variantId: input.variantId,
    isDefaultVariant: input.isDefaultVariant,
    complete: complete,
    gaps: gaps,
    nextActionable: nextActionable,
  );
}

/// Human label for a finish category (TS `finishCategoryLabel`).
String finishCategoryLabel(FinishCategory category) {
  switch (category) {
    case FinishCategory.armor:
      return 'Armor';
    case FinishCategory.weapon:
      return 'Weapons';
    case FinishCategory.mod:
      return 'Mods';
  }
}
