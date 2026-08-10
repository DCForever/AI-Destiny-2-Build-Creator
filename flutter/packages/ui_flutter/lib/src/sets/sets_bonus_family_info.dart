import '../catalog/entity_info_hotspot.dart';
import 'sets_models.dart';

/// Build [EntityInfoData] for a set-bonus family (full 2pc + 4pc body).
EntityInfoData entityInfoForSetBonusFamily(SetsBonusFamilyOption family) {
  final meta = <String>[];
  final body = StringBuffer();

  final twoName = family.twoPcName.trim();
  final twoDesc = family.twoPcDescription.trim();
  final fourName = family.fourPcName.trim();
  final fourDesc = family.fourPcDescription.trim();

  if (twoName.isNotEmpty || twoDesc.isNotEmpty) {
    final twoLabel = twoName.isEmpty ? '2-piece bonus' : twoName;
    meta.add('2pc · $twoLabel');
    body.writeln('2pc · $twoLabel');
    if (twoDesc.isNotEmpty) body.writeln(twoDesc);
    body.writeln();
  }

  if (fourName.isNotEmpty || fourDesc.isNotEmpty) {
    final fourLabel = fourName.isEmpty ? '4-piece bonus' : fourName;
    meta.add('4pc · $fourLabel');
    body.writeln('4pc · $fourLabel');
    if (fourDesc.isNotEmpty) body.writeln(fourDesc);
  }

  return EntityInfoData(
    id: 'set_bonus_${family.hash ?? family.name}',
    name: family.name,
    kind: 'Armor set bonus',
    iconPath: family.iconPath,
    description: body.toString().trim(),
    metaLines: meta,
    hashFooter: family.hash != null ? '#${family.hash}' : null,
  );
}

/// Build [EntityInfoData] focused on one selected tier (2 or 4), with family context.
EntityInfoData entityInfoForSetBonusTier(
  SetsBonusFamilyOption family,
  int minPieces,
) {
  final isTwo = minPieces <= 2;
  final perkName = (isTwo ? family.twoPcName : family.fourPcName).trim();
  final perkDesc = (isTwo ? family.twoPcDescription : family.fourPcDescription)
      .trim();
  final tierLabel = isTwo ? '2pc' : '4pc';
  final title = perkName.isEmpty ? '$tierLabel bonus' : perkName;

  final body = StringBuffer();
  if (perkDesc.isNotEmpty) {
    body.writeln(perkDesc);
  }
  // Always include the other tier as secondary context when present.
  final otherName = (isTwo ? family.fourPcName : family.twoPcName).trim();
  final otherDesc =
      (isTwo ? family.fourPcDescription : family.twoPcDescription).trim();
  final otherTier = isTwo ? '4pc' : '2pc';
  if (otherName.isNotEmpty || otherDesc.isNotEmpty) {
    body.writeln();
    body.writeln('Also on ${family.name}:');
    body.writeln(
      otherName.isEmpty ? otherTier : '$otherTier · $otherName',
    );
    if (otherDesc.isNotEmpty) body.writeln(otherDesc);
  }

  return EntityInfoData(
    id: 'set_bonus_${family.hash ?? family.name}_${minPieces}pc',
    name: '${family.name} · $tierLabel',
    kind: 'Armor set bonus',
    iconPath: family.iconPath,
    description: body.toString().trim(),
    metaLines: [
      if (perkName.isNotEmpty) title,
      'Family · ${family.name}',
    ],
    hashFooter: family.hash != null ? '#${family.hash}' : null,
  );
}
