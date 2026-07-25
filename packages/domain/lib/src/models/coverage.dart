import 'equipment.dart';
import 'soft_stats.dart';

/// Soft coverage tier for a designated synergy (TS `CoverageTier`).
///
/// Soft only — never implies a hard block or save failure.
enum CoverageTier {
  supported('supported'),
  weak('weak'),
  missing('missing');

  const CoverageTier(this.wireName);
  final String wireName;
}

/// Soft status for armor set bonus progress.
enum SetBonusSoftStatus {
  active('active'),
  partial('partial'),
  inactive('inactive');

  const SetBonusSoftStatus(this.wireName);
  final String wireName;
}

/// Matched or unmatched evidence link summary.
class LinkMatchSummary {
  const LinkMatchSummary({
    required this.kind,
    required this.displayName,
    this.id,
  });

  final String kind;
  final String displayName;
  final String? id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkMatchSummary &&
        other.kind == kind &&
        other.displayName == displayName &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, displayName, id);
}

/// Per-designation soft synergy coverage row.
class SynergyCoverageRow {
  const SynergyCoverageRow({
    required this.synergyId,
    required this.name,
    required this.tier,
    this.matchedLinks = const [],
    this.unmatchedLinks = const [],
    this.hint,
  });

  /// Designation key (`type::subType`).
  final String synergyId;
  final String name;
  final CoverageTier tier;
  final List<LinkMatchSummary> matchedLinks;
  final List<LinkMatchSummary> unmatchedLinks;
  final String? hint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SynergyCoverageRow &&
        other.synergyId == synergyId &&
        other.name == name &&
        other.tier == tier &&
        _linkListEquals(other.matchedLinks, matchedLinks) &&
        _linkListEquals(other.unmatchedLinks, unmatchedLinks) &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(
        synergyId,
        name,
        tier,
        Object.hashAll(matchedLinks),
        Object.hashAll(unmatchedLinks),
        hint,
      );
}

/// Soft armor set-bonus progress row.
class SetBonusSoftRow {
  const SetBonusSoftRow({
    required this.setName,
    required this.pieceCount,
    required this.status,
    this.armorSetHash,
    this.activeBonuses = const [],
    this.supportedSynergyIds = const [],
    this.hint,
  });

  final String setName;
  final int? armorSetHash;
  final int pieceCount;
  final SetBonusSoftStatus status;
  final List<String> activeBonuses;
  final List<String> supportedSynergyIds;
  final String? hint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetBonusSoftRow &&
        other.setName == setName &&
        other.armorSetHash == armorSetHash &&
        other.pieceCount == pieceCount &&
        other.status == status &&
        _strListEquals(other.activeBonuses, activeBonuses) &&
        _strListEquals(other.supportedSynergyIds, supportedSynergyIds) &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(
        setName,
        armorSetHash,
        pieceCount,
        status,
        Object.hashAll(activeBonuses),
        Object.hashAll(supportedSynergyIds),
        hint,
      );
}

/// Soft weapon-vs-subclass element mismatch.
class ElementSoftMismatch {
  const ElementSoftMismatch({
    required this.slot,
    required this.weaponElement,
    required this.subclassElement,
    required this.hint,
  });

  final EquipmentSlot slot;
  final String weaponElement;
  final String subclassElement;
  final String hint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ElementSoftMismatch &&
        other.slot == slot &&
        other.weaponElement == weaponElement &&
        other.subclassElement == subclassElement &&
        other.hint == hint;
  }

  @override
  int get hashCode =>
      Object.hash(slot, weaponElement, subclassElement, hint);
}

/// Aggregate soft coverage result (TS `CoverageResult`).
///
/// Never a hard-block envelope — use [ConstraintEvaluation] for hard gates.
class CoverageResult {
  const CoverageResult({
    this.synergies = const [],
    this.setBonuses = const [],
    this.elementMismatches = const [],
    this.targets = const SoftStatTargets(),
    this.statEstimate,
    this.softStats = const [],
  });

  final List<SynergyCoverageRow> synergies;
  final List<SetBonusSoftRow> setBonuses;
  final List<ElementSoftMismatch> elementMismatches;
  final SoftStatTargets targets;
  final StatEstimate? statEstimate;
  final List<SoftStatWarningRow> softStats;

  static const empty = CoverageResult();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoverageResult) return false;
    return _synListEquals(other.synergies, synergies) &&
        _bonusListEquals(other.setBonuses, setBonuses) &&
        _elemListEquals(other.elementMismatches, elementMismatches) &&
        other.targets == targets &&
        other.statEstimate == statEstimate &&
        _softStatListEquals(other.softStats, softStats);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(synergies),
        Object.hashAll(setBonuses),
        Object.hashAll(elementMismatches),
        targets,
        statEstimate,
        Object.hashAll(softStats),
      );
}

bool _linkListEquals(List<LinkMatchSummary> a, List<LinkMatchSummary> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _strListEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _synListEquals(List<SynergyCoverageRow> a, List<SynergyCoverageRow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _bonusListEquals(List<SetBonusSoftRow> a, List<SetBonusSoftRow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _elemListEquals(List<ElementSoftMismatch> a, List<ElementSoftMismatch> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _softStatListEquals(
  List<SoftStatWarningRow> a,
  List<SoftStatWarningRow> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
