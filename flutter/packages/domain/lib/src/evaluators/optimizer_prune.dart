/// Pure per-slot prune for armor optimizer (TS `prune.ts`).
library;

import '../models/equipment.dart';
import '../models/optimizer.dart';
import '../models/soft_stats.dart';
import 'optimizer_score.dart';

/// Per-slot retention cap. With five slots this bounds the Cartesian product
/// near the ~250k evaluation budget; enumeration truncates beyond it.
const int defaultPruneK = 16;

int _pieceScore(CandidatePiece piece, List<ArmorStatName>? priorities) {
  return sumPrioritizedStats(piece.statValues, priorities);
}

List<CandidatePiece> _topK(
  List<CandidatePiece> pieces,
  List<ArmorStatName>? priorities,
  int k,
) {
  final sorted = List<CandidatePiece>.from(pieces)
    ..sort((a, b) => _pieceScore(b, priorities) - _pieceScore(a, priorities));
  if (sorted.length <= k) return sorted;
  return sorted.sublist(0, k);
}

List<CandidatePiece> prunePiecesForSlot(
  List<CandidatePiece> pieces,
  PruneOptions options,
) {
  final k = options.k ?? defaultPruneK;
  final kept = <String, CandidatePiece>{};

  void retain(List<CandidatePiece> list) {
    for (final piece in list) {
      kept[piece.instanceId] = piece;
    }
  }

  retain(_topK(pieces, options.priorities, k));

  final locked = options.lockedExoticItemHash;
  if (locked != null) {
    retain(pieces.where((p) => p.itemHash == locked).toList());
  }

  for (final goal in options.setBonusGoals ?? const <SetBonusCoverageGoal>[]) {
    final family =
        pieces.where((p) => p.setBonusKey == goal.setBonusKey).toList();
    retain(_topK(family, options.priorities, k));
  }

  return kept.values.toList();
}

Map<EquipmentSlot, List<CandidatePiece>> prunePiecesBySlot(
  Map<EquipmentSlot, List<CandidatePiece>> bySlot,
  PruneOptions options,
) {
  final result = <EquipmentSlot, List<CandidatePiece>>{};
  for (final slot in armorOptimizerSlots) {
    result[slot] = prunePiecesForSlot(bySlot[slot] ?? const [], options);
  }
  return result;
}
