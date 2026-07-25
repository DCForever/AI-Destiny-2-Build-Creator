import 'package:destiny2_domain/destiny2_domain.dart';

/// Pure display helpers for soft guidance UI (DART-046 web).
///
/// Soft only — never encodes hard-block semantics. Labels are display keys
/// for chips and captions; hosts map tone keys to theme colors.

/// Advisory caption shown above soft coverage (never auto-applies / never blocks).
const String kSoftGuidanceAdvisoryCaption =
    'Soft guidance is display-only: it never auto-applies kit changes and '
    'does not block save. Hard Destiny limits still block when invalid.';

/// Tier wire/label for a [CoverageTier].
String formatCoverageTierLabel(CoverageTier tier) => tier.wireName;

/// Chip tone key: success | warning | danger | muted.
String coverageTierToneKey(CoverageTier tier) {
  switch (tier) {
    case CoverageTier.supported:
      return 'success';
    case CoverageTier.weak:
      return 'warning';
    case CoverageTier.missing:
      return 'danger';
  }
}

/// One-line synergy chip label: `name · tier`.
String formatSynergyCoverageChipLabel(SynergyCoverageRow row) {
  final name = row.name.trim().isEmpty ? row.synergyId : row.name.trim();
  return '$name · ${formatCoverageTierLabel(row.tier)}';
}

/// Set-bonus soft row summary.
String formatSetBonusSoftSummary(SetBonusSoftRow row) {
  final status = row.status.wireName;
  final pieces = row.pieceCount;
  final name = row.setName.trim().isEmpty ? 'Set bonus' : row.setName.trim();
  return '$name · $status ($pieces pc)';
}

/// Element soft mismatch summary.
String formatElementSoftMismatchSummary(ElementSoftMismatch row) {
  return '${row.slot.wireName}: ${row.weaponElement} vs ${row.subclassElement}';
}

/// Soft-stat warning summary.
String formatSoftStatWarningSummary(SoftStatWarningRow row) {
  return '${row.stat.wireName}: ${row.estimate} / target ${row.target}';
}

/// Compact soft targets map: `Health:100, Melee:80` or empty string.
String formatSoftStatTargetsSummary(SoftStatTargets targets) {
  if (targets.isEmpty) return '';
  final parts = <String>[];
  for (final stat in ArmorStatName.all) {
    final v = targets[stat];
    if (v != null) parts.add('${stat.wireName}:$v');
  }
  return parts.join(', ');
}

/// Parse a single soft target field text into int? (empty → clear).
({int? value, String? error}) parseSoftStatTargetField(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return (value: null, error: null);
  final n = int.tryParse(t);
  if (n == null) {
    return (value: null, error: 'Soft stat target must be an integer');
  }
  if (n < 1 || n > armorStatMax) {
    return (
      value: null,
      error: 'Soft stat target must be between 1 and $armorStatMax',
    );
  }
  return (value: n, error: null);
}

/// Build [SoftStatTargets] from wire-name → text field map.
///
/// Throws [FormatException] with user message on first invalid field.
SoftStatTargets softStatTargetsFromFieldMap(Map<String, String> fields) {
  final out = <ArmorStatName, int>{};
  for (final stat in ArmorStatName.all) {
    final raw = fields[stat.wireName] ?? '';
    final parsed = parseSoftStatTargetField(raw);
    if (parsed.error != null) {
      throw FormatException('${stat.wireName}: ${parsed.error}');
    }
    if (parsed.value != null) {
      out[stat] = parsed.value!;
    }
  }
  return SoftStatTargets(out);
}
