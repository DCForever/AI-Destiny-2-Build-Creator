import 'pilot_identity.dart';
import 'pilot_perk_requirement.dart';
import 'pilot_reasons.dart';
import 'pilot_source_record.dart';
import 'pilot_text.dart';

class PilotLinkParts {
  const PilotLinkParts({required this.code, required this.path});

  final String? code;
  final String path;
}

class PilotRecordReview {
  const PilotRecordReview({
    required this.record,
    required this.reasons,
    required this.perkRequirement,
  });

  final PilotSourceRecord record;
  final List<String> reasons;
  final PilotPerkRequirement perkRequirement;

  bool get blocksExport => reasons.isNotEmpty;
}

class PilotCaseReview {
  const PilotCaseReview({
    required this.caseId,
    required this.records,
    required this.caseReasons,
    required this.ambiguityNotes,
  });

  final String caseId;
  final List<PilotRecordReview> records;
  final List<String> caseReasons;
  final List<String> ambiguityNotes;

  bool get exportAllowed {
    if (records.isEmpty || caseReasons.isNotEmpty) return false;
    return records.every((review) => !review.blocksExport);
  }
}

List<PilotCaseReview> reviewPilotRecords(List<PilotSourceRecord> records) {
  return [
    for (final identity in pilotIdentities)
      _reviewCase(
        identity.caseId,
        records.where((record) => record.caseId == identity.caseId).toList(),
      ),
  ];
}

PilotCaseReview _reviewCase(String caseId, List<PilotSourceRecord> records) {
  final reviews = <PilotRecordReview>[
    for (final record in records) _reviewRecord(record),
  ];
  final caseReasons = _caseReasons(reviews);
  return PilotCaseReview(
    caseId: caseId,
    records: reviews,
    caseReasons: caseReasons,
    ambiguityNotes: _ambiguity(caseId, reviews, caseReasons),
  );
}

PilotRecordReview _reviewRecord(PilotSourceRecord record) {
  final reasons = <String>[
    ..._intentReasons(record),
    ..._solipsismReasons(record),
    ..._ergoReasons(record),
    ..._notesReasons(record),
  ]..sort();
  return PilotRecordReview(
    record: record,
    reasons: reasons,
    perkRequirement: perkRequirementFor(record),
  );
}

List<String> _intentReasons(PilotSourceRecord record) {
  final reasons = <String>[];
  final does = _textReason(
    record.doesText,
    PilotReason.absentDoes,
    PilotReason.blankDoes,
  );
  final loop = _textReason(
    record.loopText,
    PilotReason.absentLoop,
    PilotReason.blankLoop,
  );
  if (does != null) reasons.add(does);
  if (loop != null) reasons.add(loop);
  return reasons;
}

String? _textReason(PilotText text, String absent, String blank) {
  if (!text.present) return absent;
  if (text.isBlank) return blank;
  return null;
}

List<String> _solipsismReasons(PilotSourceRecord record) {
  if (!pilotRowIsSolipsism(record)) return const [];
  final reasons = <String>[];
  final subclass = record.subclassText;
  if (!subclass.present || subclass.isBlank) {
    reasons.add(PilotReason.solipsismSubclassUnstated);
  } else if (!pilotSameText(subclass.value, 'prismatic')) {
    reasons.add(PilotReason.invalidSolipsism);
  }
  if (!perkRequirementFor(record).resolved) {
    reasons.add(PilotReason.solipsismPerksUnresolved);
  }
  return reasons;
}

List<String> _ergoReasons(PilotSourceRecord record) {
  if (!pilotRowIsErgo(record)) return const [];
  final reasons = <String>[];
  final trait = _perkReason(record.ergoTrait, PilotReason.ergoTraitUnresolved);
  final element = _perkReason(
    record.ergoElement,
    PilotReason.ergoElementUnresolved,
  );
  final frame = _perkReason(record.ergoFrame, PilotReason.ergoFrameUnresolved);
  if (trait != null) reasons.add(trait);
  if (element != null) reasons.add(element);
  if (frame != null) reasons.add(frame);
  return reasons;
}

String? _perkReason(PilotText text, String code) {
  if (!text.present || text.isBlank || pilotIsUnknownPerk(text.value)) {
    return code;
  }
  return null;
}

List<String> _notesReasons(PilotSourceRecord record) {
  final reasons = <String>[];
  if (_notesDisagree(record.doesText, record.notesDoes)) {
    reasons.add(PilotReason.doesNotesConflict);
  }
  if (_notesDisagree(record.loopText, record.notesLoop)) {
    reasons.add(PilotReason.loopNotesConflict);
  }
  if (record.notesSet.present &&
      !pilotNotesRestateSet(record.armorSetProposal, record.notesSet.value)) {
    reasons.add(PilotReason.notesSetConflict);
  }
  return reasons;
}

bool _notesDisagree(PilotText structured, PilotText notes) {
  if (!structured.present || !notes.present) return false;
  return structured.value.trim() != notes.value.trim();
}

List<String> _caseReasons(List<PilotRecordReview> reviews) {
  if (reviews.isEmpty) return const [];
  final reasons = <String>[];
  final sets = reviews
      .map((review) => review.record.armorSetProposal.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (sets.length > 1) reasons.add(PilotReason.setProposalConflict);
  final pairs = reviews
      .map((review) => review.perkRequirement)
      .where((requirement) => requirement.resolved)
      .map((requirement) => requirement.canonical)
      .toSet();
  if (pairs.length > 1) reasons.add(PilotReason.perkLabelConflict);
  if (_pathsDiffer(reviews)) reasons.add(PilotReason.linkPathMismatch);
  return reasons..sort();
}

bool _pathsDiffer(List<PilotRecordReview> reviews) {
  final paths = <String>{};
  String? code;
  for (final review in reviews) {
    final parts = pilotLinkParts(review.record.originalDimLink);
    if (parts.path.isEmpty) continue;
    paths.add(parts.path);
    code ??= parts.code;
    if (parts.code != null && code != null && parts.code != code) return true;
  }
  return paths.length > 1;
}

PilotLinkParts pilotLinkParts(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.toLowerCase() != 'dim.gg') {
    return PilotLinkParts(code: null, path: url.trim());
  }
  final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  final path = segments.isEmpty ? '' : '/${segments.join('/')}';
  return PilotLinkParts(
    code: segments.isEmpty ? null : segments.first,
    path: path,
  );
}

List<String> _ambiguity(
    String caseId, List<PilotRecordReview> reviews, List<String> reasons) {
  if (reviews.isEmpty) {
    return <String>['$caseId has no selected source row in this fixture.'];
  }
  final notes = <String>[
    '${reviews.length} source row(s) match $caseId by creator and title.',
  ];
  final exotics = reviews.map((review) => review.record.filingExotic).toSet();
  if (exotics.length > 1) {
    notes.add('Filing exotic differs: ${exotics.join(' vs ')}.');
  }
  final kinds = reviews.map((review) => review.record.sourceKind).toSet();
  if (kinds.length == 1) {
    notes
        .add('Only ${kinds.single} rows matched. The other source has no row.');
  }
  if (reasons.contains(PilotReason.setProposalConflict)) {
    notes.add('Armor set proposals disagree. No set was chosen.');
  }
  if (reasons.contains(PilotReason.perkLabelConflict)) {
    notes.add('Perk labels disagree. They were not aliased.');
  }
  if (reasons.contains(PilotReason.linkPathMismatch)) {
    notes.add('Original DIM paths differ. They were not merged.');
  }
  return notes;
}
