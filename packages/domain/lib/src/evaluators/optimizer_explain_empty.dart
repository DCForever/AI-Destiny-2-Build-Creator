/// Empty-result explanation for armor optimize (TS `explainEmpty.ts`).
library;

import '../models/optimizer.dart';

/// Inputs for first-unmet empty reason (ordering matches product contract).
class EmptyReasonInput {
  const EmptyReasonInput({
    required this.hasInventory,
    required this.classArmorCount,
    this.lockedExoticItemHash,
    required this.lockedExoticAvailable,
    this.setBonusGoals,
    required this.setBonusReachable,
    this.requireThresholds = false,
    this.thresholdsFilteredAll = false,
  });

  final bool hasInventory;
  final int classArmorCount;
  final int? lockedExoticItemHash;
  final bool lockedExoticAvailable;
  final List<SetBonusCoverageGoal>? setBonusGoals;
  final bool setBonusReachable;
  final bool requireThresholds;
  final bool thresholdsFilteredAll;
}

/// First unmet hard constraint wins; ordering mirrors product empty codes.
ArmorOptimizeEmptyReason explainEmpty(EmptyReasonInput input) {
  if (!input.hasInventory) {
    return const ArmorOptimizeEmptyReason(
      code: ArmorOptimizeEmptyReasonCode.noInventory,
      message: 'No synced inventory. Sync your inventory and retry.',
    );
  }

  if (input.classArmorCount == 0) {
    return const ArmorOptimizeEmptyReason(
      code: ArmorOptimizeEmptyReasonCode.noClassArmor,
      message: 'No owned armor for this class.',
    );
  }

  final locked = input.lockedExoticItemHash;
  if (locked != null && !input.lockedExoticAvailable) {
    return ArmorOptimizeEmptyReason(
      code: ArmorOptimizeEmptyReasonCode.exoticUnavailable,
      message: 'The locked exotic is not owned in a usable slot.',
      details: {'lockedExoticItemHash': locked},
    );
  }

  final goals = input.setBonusGoals;
  if (goals != null && goals.isNotEmpty && !input.setBonusReachable) {
    return ArmorOptimizeEmptyReason(
      code: ArmorOptimizeEmptyReasonCode.setBonusUnsatisfiable,
      message: 'Owned armor cannot satisfy the requested set-bonus coverage.',
      details: {
        'setBonusGoals': goals
            .map(
              (g) => {
                'setBonusKey': g.setBonusKey,
                'minPieces': g.minPieces,
              },
            )
            .toList(),
      },
    );
  }

  if (input.requireThresholds && input.thresholdsFilteredAll) {
    return const ArmorOptimizeEmptyReason(
      code: ArmorOptimizeEmptyReasonCode.thresholdsUnmet,
      message: 'No kit meets the required stat thresholds.',
    );
  }

  return const ArmorOptimizeEmptyReason(
    code: ArmorOptimizeEmptyReasonCode.noValidKits,
    message: 'No complete kit satisfies the given constraints.',
  );
}

/// Whether set-bonus goals can still be met by distinct slots in [candidates].
bool goalsReachable(
  List<CandidatePiece> candidates,
  List<SetBonusCoverageGoal> goals,
) {
  return goals.every((goal) {
    final slots = <Object>{};
    for (final c in candidates) {
      if (c.setBonusKey == goal.setBonusKey) slots.add(c.slot);
    }
    return slots.length >= goal.minPieces;
  });
}
