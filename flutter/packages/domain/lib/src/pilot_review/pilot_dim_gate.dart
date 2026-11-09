import '../evaluators/dim_builders.dart';
import '../models/dim_loadout.dart';
import '../models/equipment.dart';
import '../models/slot_claim.dart';
import 'pilot_review.dart';
import 'pilot_text.dart';

/// Personal output for a case. Null when the case is unresolved or invalid.
///
/// The JSON is still a shape sample: notes carry [pilotSyntheticBanner], and
/// the original DIM URL is not copied into the document.
Map<String, Object?>? gatedPersonalDimJson(PilotCaseReview review) {
  if (!review.exportAllowed || review.records.length != 1) return null;
  final record = review.records.single.record;
  final loadout = buildVariantDimLoadout(
    VariantDimLoadoutInput(
      buildName: 'SYNTHETIC ${record.buildName}',
      className: GuardianClass.warlock,
      subclass: const DimSubclassNote(name: 'stated on the source row'),
      equipment: _syntheticHelmet(),
    ),
    id: 'synthetic-${review.caseId}',
  );
  final body = loadout.toJson();
  body['name'] = 'SYNTHETIC — NOT A PERSONAL LOADOUT';
  body['notes'] = _notes(record.doesText.value, record.loopText.value);
  return <String, Object?>{
    'loadout': body,
    'synthetic': true,
    'dimAcceptance': false,
  };
}

/// Shape sample that is not produced from a pilot row.
Map<String, Object?> syntheticDimShapeSample() {
  final loadout = buildVariantDimLoadout(
    VariantDimLoadoutInput(
      buildName: 'SYNTHETIC SHAPE SAMPLE',
      className: GuardianClass.warlock,
      variantName: 'not a pilot row',
      equipment: _syntheticHelmet(),
    ),
    id: 'synthetic-shape-sample',
  );
  final body = loadout.toJson();
  body['name'] = 'SYNTHETIC SHAPE SAMPLE — NOT A PERSONAL LOADOUT';
  body['notes'] = pilotSyntheticBanner;
  return <String, Object?>{
    'loadout': body,
    'synthetic': true,
    'dimAcceptance': false,
  };
}

String _notes(String doesText, String loopText) {
  return '$pilotSyntheticBanner\nDoes: $doesText\nLoop: $loopText';
}

Map<EquipmentSlot, SlotClaim> _syntheticHelmet() {
  return <EquipmentSlot, SlotClaim>{
    EquipmentSlot.helmet: const SlotClaim(
      slot: EquipmentSlot.helmet,
      itemHash: 810001,
      itemName: 'SYNTHETIC helmet',
      source: ClaimSource.set,
      instanceId: 'synthetic-stat-helmet',
    ),
  };
}
