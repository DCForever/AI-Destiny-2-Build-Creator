/// Armor Set auto-name + collision suffix (G-SET / brief 001-armor).
///
/// Pattern: `{Class} · {pc} · {Family|—}[ · tags]` with numeric suffix on
/// collision (`… 2`, `… 3`, …). Blank user name → auto-name.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// Build the base auto-name (no collision suffix).
///
/// [pcLabel] examples: `2pc`, `4pc`, `2+2pc`, `—` when no goals.
/// [familyLabel] is the primary family name or `—`.
/// [tags] optional free tags (already sanitized; not Synergy Type vocab).
String buildArmorSetAutoNameBase({
  required GuardianClass guardianClass,
  required String pcLabel,
  required String familyLabel,
  List<String> tags = const [],
}) {
  final classPart = guardianClass.wireName;
  final pc = pcLabel.trim().isEmpty ? '—' : pcLabel.trim();
  final family = familyLabel.trim().isEmpty ? '—' : familyLabel.trim();
  final parts = <String>[classPart, pc, family];
  final tagBits = [
    for (final t in tags)
      if (t.trim().isNotEmpty) t.trim(),
  ];
  if (tagBits.isNotEmpty) {
    parts.add(tagBits.join(', '));
  }
  return parts.join(' · ');
}

/// Derive pc + family labels from legal G-SET-013 goals.
({String pcLabel, String familyLabel}) labelsFromSetBonusGoals(
  List<SetBonusCoverageGoal> goals,
) {
  if (goals.isEmpty) {
    return (pcLabel: '—', familyLabel: '—');
  }
  if (goals.length == 1) {
    final g = goals.first;
    final pc = g.minPieces == 4 ? '4pc' : '2pc';
    return (pcLabel: pc, familyLabel: g.setBonusKey.trim());
  }
  // 2×2pc
  final a = goals[0].setBonusKey.trim();
  final b = goals[1].setBonusKey.trim();
  return (pcLabel: '2+2pc', familyLabel: '$a+$b');
}

/// Auto-name with collision suffix against [existingNames] (case-insensitive).
///
/// When [preferredName] is non-blank after trim, it is used as the base instead
/// of generating from class/goals; collision suffix still applies.
String resolveArmorSetName({
  required GuardianClass guardianClass,
  List<SetBonusCoverageGoal> goals = const [],
  List<String> tags = const [],
  String? preferredName,
  Iterable<String> existingNames = const [],
}) {
  final preferred = preferredName?.trim() ?? '';
  String base;
  if (preferred.isNotEmpty) {
    base = preferred;
  } else {
    final labels = labelsFromSetBonusGoals(goals);
    base = buildArmorSetAutoNameBase(
      guardianClass: guardianClass,
      pcLabel: labels.pcLabel,
      familyLabel: labels.familyLabel,
      tags: tags,
    );
  }
  return applyNameCollisionSuffix(base, existingNames);
}

/// Append ` 2`, ` 3`, … when [base] collides with [existingNames].
String applyNameCollisionSuffix(
  String base,
  Iterable<String> existingNames,
) {
  final taken = {
    for (final n in existingNames) n.trim().toLowerCase(),
  };
  final root = base.trim();
  if (root.isEmpty) return root;
  if (!taken.contains(root.toLowerCase())) return root;
  var n = 2;
  while (taken.contains('$root $n'.toLowerCase())) {
    n += 1;
  }
  return '$root $n';
}
