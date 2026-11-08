import 'dart:convert';

import 'pilot_catalog.dart';
import 'pilot_csv.dart';
import 'pilot_matrix.dart';
import 'pilot_perk_requirement.dart';
import 'pilot_proposals.dart';
import 'pilot_review.dart';
import 'pilot_source_record.dart';

class PilotPerkCheck {
  const PilotPerkCheck({
    required this.itemId,
    required this.exoticName,
    required this.matchedDetails,
  });

  final String itemId;
  final String exoticName;
  final List<String> matchedDetails;

  bool get matched => matchedDetails.isNotEmpty;
}

class PilotBoard {
  const PilotBoard({
    required this.cases,
    required this.proposals,
    required this.overlaps,
    required this.perkChecks,
  });

  final List<PilotCaseReview> cases;
  final List<PilotProposal> proposals;
  final List<PilotOverlap> overlaps;
  final List<PilotPerkCheck> perkChecks;
}

/// Parse both sources, keep the five identities, and attach proposals.
///
/// Parsing does not write either source.
PilotBoard loadPilotBoard({
  required String matrixJson,
  required String csvText,
}) {
  final decoded = jsonDecode(matrixJson);
  final records = <PilotSourceRecord>[
    ...parsePilotMatrix(decoded),
    ...parsePilotCsv(csvText),
  ];
  final cases = reviewPilotRecords(records);
  final proposals = proposePilotCases(cases);
  return PilotBoard(
    cases: cases,
    proposals: proposals,
    overlaps: pilotStatOverlaps(proposals),
    perkChecks: _checks(cases),
  );
}

List<PilotPerkCheck> _checks(List<PilotCaseReview> cases) {
  final rows = <PilotRecordReview>[
    for (final review in cases) ...review.records,
  ];
  return [
    for (final item in pilotSyntheticExotics)
      PilotPerkCheck(
        itemId: item.id,
        exoticName: item.exoticName,
        matchedDetails: <String>[
          for (final row in rows)
            if (exactExoticPerkMatch(
              exoticName: item.exoticName,
              perks: item.perks,
              requirement: row.perkRequirement,
            ))
              row.record.sourceDetail,
        ],
      ),
  ];
}
