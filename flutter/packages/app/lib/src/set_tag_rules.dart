/// Free-tag hard-block vs Synergy Type vocabulary (G-SET-033 / BR-TAG-009).
///
/// Set free tags must not collide with Synergy Type wire names or common
/// designation chrome labels (Verb, Element, …). Presentation-only block —
/// hosts reject add attempts; no auto-rename.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

import 'designation_chrome.dart';

/// Default blocked vocabulary from domain synergy type wires + family labels.
Set<String> defaultSynergyTypeTagVocabulary() {
  final out = <String>{};
  for (final wire in allSynergyTypeWires) {
    out.add(wire.toLowerCase());
    // Humanized wire: melee → Melee
    if (wire.isNotEmpty) {
      final human = wire[0].toUpperCase() + wire.substring(1);
      out.add(human.toLowerCase());
      out.add(human.replaceAll('_', ' ').toLowerCase());
    }
    out.add(designationFamilyLabel(wire).toLowerCase());
  }
  // Common chrome labels always blocked.
  for (final label in const [
    'Verb',
    'Element',
    'Weapon',
    'Frame',
    'Armor',
    'Activity',
    'Ability',
    'Melee',
    'Grenade',
    'Super',
    'Healing',
    'Solo',
    'Team',
    'DPS',
  ]) {
    out.add(label.toLowerCase());
  }
  return out;
}

/// True when [tag] matches a blocked Synergy Type vocabulary entry.
///
/// Comparison is case-insensitive; trims whitespace; ignores empty.
bool isTagBlockedBySynergyTypeVocab(
  String tag, {
  Set<String>? vocabulary,
}) {
  final t = tag.trim();
  if (t.isEmpty) return false;
  final vocab = vocabulary ?? defaultSynergyTypeTagVocabulary();
  return vocab.contains(t.toLowerCase());
}

/// Result of filtering a multi-select tag list.
class TagFilterResult {
  const TagFilterResult({
    required this.accepted,
    required this.blocked,
  });

  final List<String> accepted;
  final List<String> blocked;

  bool get hasBlocked => blocked.isNotEmpty;
}

/// Split [tags] into accepted vs blocked (preserves order; de-dupes accepted).
TagFilterResult filterTagsAgainstSynergyTypeVocab(
  Iterable<String> tags, {
  Set<String>? vocabulary,
}) {
  final vocab = vocabulary ?? defaultSynergyTypeTagVocabulary();
  final accepted = <String>[];
  final blocked = <String>[];
  final seen = <String>{};
  for (final raw in tags) {
    final t = raw.trim();
    if (t.isEmpty) continue;
    if (isTagBlockedBySynergyTypeVocab(t, vocabulary: vocab)) {
      if (!blocked.contains(t)) blocked.add(t);
      continue;
    }
    final key = t.toLowerCase();
    if (seen.add(key)) accepted.add(t);
  }
  return TagFilterResult(
    accepted: List.unmodifiable(accepted),
    blocked: List.unmodifiable(blocked),
  );
}
