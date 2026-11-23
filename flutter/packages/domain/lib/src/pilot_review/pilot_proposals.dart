import '../evaluators/optimizer_pipeline.dart';
import '../evaluators/optimizer_score.dart';
import '../models/equipment.dart';
import '../models/optimizer.dart';
import '../models/soft_stats.dart';
import 'pilot_reasons.dart';
import 'pilot_review.dart';
import 'pilot_text.dart';

/// One optimizer result shown as a proposal. Nothing is equipped.
class PilotProposal {
  const PilotProposal({
    required this.caseId,
    required this.kind,
    required this.summary,
    required this.instanceIds,
    required this.withheld,
    this.score,
  });

  final String caseId;
  final String kind;
  final String summary;
  final List<String> instanceIds;
  final bool withheld;
  final int? score;
}

class PilotOverlap {
  const PilotOverlap({
    required this.instanceId,
    required this.caseIds,
    required this.note,
  });

  final String instanceId;
  final List<String> caseIds;
  final String note;
}

const String pilotNotGlobalOptimum =
    'Independent per-build picks name the same synthetic instance. '
    'Nothing is assigned. This is not a global optimum.';

List<PilotProposal> proposePilotCases(List<PilotCaseReview> cases) {
  final proposals = <PilotProposal>[];
  for (final review in cases) {
    if (_invalid(review)) continue;
    proposals.add(_statProposal(review));
    proposals.add(_setProposal(review));
  }
  proposals.add(_reuseTieBreak());
  return proposals;
}

List<PilotOverlap> pilotStatOverlaps(List<PilotProposal> proposals) {
  final byInstance = <String, List<String>>{};
  for (final proposal in proposals) {
    if (proposal.kind != 'stat-total' || proposal.withheld) continue;
    for (final id in proposal.instanceIds) {
      byInstance.putIfAbsent(id, () => <String>[]).add(proposal.caseId);
    }
  }
  final overlaps = <PilotOverlap>[];
  for (final entry in byInstance.entries) {
    final cases = entry.value.toSet().toList()..sort();
    if (cases.length < 2) continue;
    overlaps.add(
      PilotOverlap(
        instanceId: entry.key,
        caseIds: cases,
        note: pilotNotGlobalOptimum,
      ),
    );
  }
  overlaps.sort((a, b) => a.instanceId.compareTo(b.instanceId));
  return overlaps;
}

bool _invalid(PilotCaseReview review) {
  return review.records.any(
    (row) => row.reasons.contains(PilotReason.invalidSolipsism),
  );
}

PilotProposal _statProposal(PilotCaseReview review) {
  final response = optimizeArmorCore(
    ArmorOptimizeRequest(
      candidates: _board(null),
      maxResults: 50,
    ),
  );
  final top = response.combinations.first;
  return PilotProposal(
    caseId: review.caseId,
    kind: 'stat-total',
    summary:
        'SYNTHETIC stat proposal. It does not fill unknown perks, choose a '
        'conflicting set, or export a loadout.',
    instanceIds: _ids(top),
    withheld: false,
    score: top.score,
  );
}

PilotProposal _setProposal(PilotCaseReview review) {
  final agreed = _agreedSet(review);
  if (agreed == null) {
    return PilotProposal(
      caseId: review.caseId,
      kind: 'set-goal',
      summary: 'SYNTHETIC set proposal withheld. Sources disagree or the notes '
          'do not restate the set column. No set was chosen.',
      instanceIds: const [],
      withheld: true,
    );
  }
  if (pilotSameText(agreed, 'no strong fit')) {
    return const PilotProposal(
      caseId: '',
      kind: 'set-goal',
      summary:
          'SYNTHETIC set proposal withheld. The source says no strong fit. '
          'A set was not invented.',
      instanceIds: [],
      withheld: true,
    )._withCase(review.caseId);
  }
  final response = optimizeArmorCore(
    ArmorOptimizeRequest(
      candidates: _board(agreed),
      constraints: KitConstraints(
        setBonusGoals: <SetBonusCoverageGoal>[
          SetBonusCoverageGoal(setBonusKey: agreed, minPieces: 4),
        ],
      ),
      maxResults: 50,
    ),
  );
  final top = response.combinations.first;
  return PilotProposal(
    caseId: review.caseId,
    kind: 'set-goal',
    summary: 'SYNTHETIC set proposal for "$agreed". Existing optimizer score '
        '${top.score}. This does not resolve perk or loop gaps.',
    instanceIds: _ids(top),
    withheld: false,
    score: top.score,
  );
}

String? _agreedSet(PilotCaseReview review) {
  if (review.caseReasons.contains(PilotReason.setProposalConflict)) {
    return null;
  }
  if (review.records.any(
    (row) => row.reasons.contains(PilotReason.notesSetConflict),
  )) {
    return null;
  }
  final sets = review.records
      .map((row) => row.record.armorSetProposal.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (sets.length != 1) return null;
  return sets.single;
}

PilotProposal _reuseTieBreak() {
  final plain = _kit(810100, 'synthetic-plain-helmet', null);
  final reused = _kit(
    810200,
    'synthetic-reused-helmet',
    const <ReuseSetRef>[
      ReuseSetRef(id: 'synthetic-other-set', name: 'SYNTHETIC other set'),
    ],
  );
  final request = ArmorOptimizeRequest(
    candidates: <CandidatePiece>[...plain, reused.first],
    preferReuse: true,
    maxResults: 5,
  );
  final winner = optimizeArmorCore(request).combinations.first;
  final helmet = winner.pieces
      .firstWhere((piece) => piece.slot == EquipmentSlot.helmet)
      .instanceId;
  return PilotProposal(
    caseId: 'reuse-tie-break',
    kind: 'reuse-tie-break',
    summary: 'SYNTHETIC reuse tie-break. Equal stats prefer instance $helmet '
        'because it is already in another synthetic set. A higher stat total '
        'still wins. This is not a global optimum.',
    instanceIds: winner.pieces.map((piece) => piece.instanceId).toList(),
    withheld: false,
    score: winner.score,
  );
}

List<CandidatePiece> _board(String? setKey) {
  final pieces = <CandidatePiece>[];
  for (var i = 0; i < armorOptimizerSlots.length; i++) {
    final slot = armorOptimizerSlots[i];
    pieces.add(
      _piece(
        slot,
        810001 + i,
        'synthetic-stat-${slot.wireName}',
        30,
        null,
        const [],
      ),
    );
    if (setKey != null) {
      pieces.add(
        _piece(
          slot,
          820001 + i,
          'synthetic-set-${slot.wireName}',
          10,
          setKey,
          const [],
        ),
      );
    }
  }
  return pieces;
}

List<CandidatePiece> _kit(int hash, String helmetId, List<ReuseSetRef>? used) {
  return [
    for (var i = 0; i < armorOptimizerSlots.length; i++)
      _piece(
        armorOptimizerSlots[i],
        i == 0 ? hash : 810300 + i,
        i == 0 ? helmetId : 'synthetic-tie-${armorOptimizerSlots[i].wireName}',
        10,
        null,
        i == 0 ? (used ?? const <ReuseSetRef>[]) : const <ReuseSetRef>[],
      ),
  ];
}

CandidatePiece _piece(
  EquipmentSlot slot,
  int hash,
  String instanceId,
  int stat,
  String? setKey,
  List<ReuseSetRef> used,
) {
  return CandidatePiece(
    slot: slot,
    itemHash: hash,
    instanceId: instanceId,
    itemName: 'SYNTHETIC $instanceId',
    isExotic: false,
    setBonusKey: setKey,
    statValues: <ArmorStatName, int>{ArmorStatName.weapons: stat},
    usedInSets: used,
  );
}

List<String> _ids(ArmorCombination combination) {
  return combination.pieces.map((piece) => piece.instanceId).toList();
}

extension on PilotProposal {
  PilotProposal _withCase(String caseId) {
    return PilotProposal(
      caseId: caseId,
      kind: kind,
      summary: summary,
      instanceIds: instanceIds,
      withheld: withheld,
      score: score,
    );
  }
}

/// Exposed so tests can show reuse does not beat a higher stat total.
int pilotCompareReuse({
  required bool preferReuse,
  required int reuseCount,
}) {
  const left = RankableCombination(
    estimatedStats: <ArmorStatName, int>{ArmorStatName.weapons: 20},
    reusePieceCount: 0,
  );
  final right = RankableCombination(
    estimatedStats: const <ArmorStatName, int>{ArmorStatName.weapons: 10},
    reusePieceCount: reuseCount,
  );
  return compareCombinations(
    left,
    right,
    const <ArmorStatName>[],
    preferReuse,
  );
}
