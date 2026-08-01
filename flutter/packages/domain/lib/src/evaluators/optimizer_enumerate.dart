/// Pure kit enumeration for armor optimizer (TS `enumerate.ts`).
library;

import '../models/equipment.dart';
import '../models/optimizer.dart';
import 'optimizer_constraints.dart';

/// Upper bound on evaluated kits before returning best-so-far (R9 / product).
const int defaultMaxCombinations = 250000;

/// Group candidate pieces by armor optimizer slot (empty lists for missing slots).
Map<EquipmentSlot, List<CandidatePiece>> groupBySlot(
  List<CandidatePiece> pieces,
) {
  final bySlot = <EquipmentSlot, List<CandidatePiece>>{
    for (final slot in armorOptimizerSlots) slot: <CandidatePiece>[],
  };
  for (final piece in pieces) {
    bySlot[piece.slot]?.add(piece);
  }
  return bySlot;
}

class _SearchContext {
  _SearchContext({
    required this.slots,
    required this.constraints,
    required this.max,
  });

  final List<List<CandidatePiece>> slots;
  final KitConstraints constraints;
  final int max;
  final List<List<CandidatePiece>> kits = [];
  int evaluated = 0;
  bool truncated = false;
}

void _evaluateKit(_SearchContext context, List<CandidatePiece> current) {
  if (context.evaluated >= context.max) {
    context.truncated = true;
    return;
  }
  context.evaluated += 1;
  if (isKitValid(current, context.constraints)) {
    context.kits.add(List<CandidatePiece>.from(current));
  }
}

void _search(
  _SearchContext context,
  int index,
  List<CandidatePiece> current,
  int exotics,
) {
  if (context.truncated) return;
  if (index == context.slots.length) {
    _evaluateKit(context, current);
    return;
  }

  for (final piece in context.slots[index]) {
    final nextExotics = exotics + (piece.isExotic ? 1 : 0);
    if (nextExotics > 1) continue;
    current.add(piece);
    _search(context, index + 1, current, nextExotics);
    current.removeLast();
    if (context.truncated) return;
  }
}

EnumerateResult enumerateKits(
  Map<EquipmentSlot, List<CandidatePiece>> bySlot,
  EnumerateOptions options,
) {
  final slots = armorOptimizerSlots
      .map((slot) => bySlot[slot] ?? const <CandidatePiece>[])
      .toList();
  if (slots.any((list) => list.isEmpty)) {
    return const EnumerateResult(
      kits: [],
      evaluatedCount: 0,
      truncated: false,
    );
  }

  final context = _SearchContext(
    slots: slots,
    constraints: options.constraints,
    max: options.maxCombinations ?? defaultMaxCombinations,
  );
  _search(context, 0, <CandidatePiece>[], 0);

  return EnumerateResult(
    kits: context.kits,
    evaluatedCount: context.evaluated,
    truncated: context.truncated,
  );
}
