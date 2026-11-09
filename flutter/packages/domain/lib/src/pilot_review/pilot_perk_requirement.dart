import 'pilot_source_record.dart';
import 'pilot_text.dart';

/// Exotic plus the perk strings a row actually states.
class PilotPerkRequirement {
  const PilotPerkRequirement({
    required this.exoticName,
    required this.perks,
    required this.resolved,
    required this.detail,
  });

  final String exoticName;
  final List<String> perks;
  final bool resolved;
  final String detail;

  /// Case-folded exact set. Order does not matter. Labels are not aliased.
  String get canonical {
    final folded = perks.map((perk) => perk.trim().toLowerCase()).toList()
      ..sort();
    return folded.join(' + ');
  }
}

bool pilotRowIsSolipsism(PilotSourceRecord record) {
  return pilotSameText(record.filingExotic, 'Solipsism');
}

bool pilotRowIsErgo(PilotSourceRecord record) {
  if (record.weaponExotic.present &&
      pilotSameText(record.weaponExotic.value, 'Ergo Sum')) {
    return true;
  }
  if (pilotSameText(record.filingExotic, 'Ergo Sum')) return true;
  return record.rowType.toLowerCase().contains('ergo sum');
}

PilotPerkRequirement perkRequirementFor(PilotSourceRecord record) {
  if (pilotRowIsSolipsism(record)) return _solipsism(record);
  if (pilotRowIsErgo(record)) return _ergo(record);
  return const PilotPerkRequirement(
    exoticName: '',
    perks: [],
    resolved: false,
    detail: 'no exotic perk requirement on this row',
  );
}

PilotPerkRequirement _solipsism(PilotSourceRecord record) {
  final first = record.classItemPerk1;
  final second = record.classItemPerk2;
  final perks = <String>[
    if (first.present) first.value,
    if (second.present) second.value,
  ];
  final resolved = first.present &&
      second.present &&
      !first.isBlank &&
      !second.isBlank &&
      !pilotIsUnknownPerk(first.value) &&
      !pilotIsUnknownPerk(second.value);
  return PilotPerkRequirement(
    exoticName: 'Solipsism',
    perks: perks,
    resolved: resolved,
    detail: resolved ? 'stated class-item pair' : 'class-item pair incomplete',
  );
}

PilotPerkRequirement _ergo(PilotSourceRecord record) {
  final parts = <PilotText>[
    record.ergoTrait,
    record.ergoElement,
    record.ergoFrame,
  ];
  final resolved = parts.every(_knownPerk);
  return PilotPerkRequirement(
    exoticName: 'Ergo Sum',
    perks: <String>[
      for (final part in parts)
        if (part.present) part.value,
    ],
    resolved: resolved,
    detail: resolved
        ? 'stated trait, element, and frame'
        : 'trait, element, or frame is blank or unknown',
  );
}

bool _knownPerk(PilotText text) {
  return text.present && !text.isBlank && !pilotIsUnknownPerk(text.value);
}

/// Name plus exact perk set. A name with a different or empty perk list fails.
bool exactExoticPerkMatch({
  required String exoticName,
  required List<String> perks,
  required PilotPerkRequirement requirement,
}) {
  if (!requirement.resolved) return false;
  if (!pilotSameText(exoticName, requirement.exoticName)) return false;
  final left = perks.map((perk) => perk.trim().toLowerCase()).toSet();
  final right =
      requirement.perks.map((perk) => perk.trim().toLowerCase()).toSet();
  return left.length == right.length && left.containsAll(right);
}
