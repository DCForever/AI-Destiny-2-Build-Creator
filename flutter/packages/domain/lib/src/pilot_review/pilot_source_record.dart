import 'pilot_text.dart';

/// One immutable community row selected for the offline pilot.
///
/// Strings stay as the source wrote them. Empty and absent are different.
class PilotSourceRecord {
  const PilotSourceRecord({
    required this.caseId,
    required this.sourceKind,
    required this.sourceDetail,
    required this.rowType,
    required this.filingExotic,
    required this.weaponExotic,
    required this.subclassText,
    required this.buildName,
    required this.creator,
    required this.season,
    required this.date,
    required this.originalDimLink,
    required this.armorSetProposal,
    required this.personalDimLink,
    required this.dimName,
    required this.doesText,
    required this.loopText,
    required this.notesDoes,
    required this.notesLoop,
    required this.notesSet,
    required this.classItemPerk1,
    required this.classItemPerk2,
    required this.ergoTrait,
    required this.ergoElement,
    required this.ergoFrame,
  });

  final String caseId;
  final String sourceKind;
  final String sourceDetail;
  final String rowType;
  final String filingExotic;
  final PilotText weaponExotic;
  final PilotText subclassText;
  final String buildName;
  final String creator;
  final PilotText season;
  final PilotText date;
  final String originalDimLink;
  final String armorSetProposal;
  final PilotText personalDimLink;
  final PilotText dimName;
  final PilotText doesText;
  final PilotText loopText;
  final PilotText notesDoes;
  final PilotText notesLoop;
  final PilotText notesSet;
  final PilotText classItemPerk1;
  final PilotText classItemPerk2;
  final PilotText ergoTrait;
  final PilotText ergoElement;
  final PilotText ergoFrame;

  String get label => '$creator — $buildName ($sourceDetail)';
}
