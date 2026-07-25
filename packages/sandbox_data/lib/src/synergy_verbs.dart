// Curated Destiny 2 keyword verbs for Verb synergy sub-types.
// Port of `src/data/synergyVerbs.ts`.

class SynergyVerbEntry {
  const SynergyVerbEntry({
    required this.name,
    required this.description,
    this.element,
  });

  final String name;
  final String description;

  /// Damage element when element-specific; null for agnostic keywords.
  final String? element;
}

// Legacy / plural display names accepted and normalized to canonical names.
const Map<String, String> synergyVerbAliases = {
  'Suppress': 'Suppression',
  'Stasis Shards': 'Stasis Shard',
};

const List<SynergyVerbEntry> synergyVerbs = [
  // Solar
  SynergyVerbEntry(
    name: 'Scorch',
    description: 'Solar damage over time; stacks lead to Ignition.',
    element: 'Solar',
  ),
  SynergyVerbEntry(
    name: 'Ignition',
    description: 'Large Solar explosion.',
    element: 'Solar',
  ),
  SynergyVerbEntry(
    name: 'Restoration',
    description: 'Regenerates health and shields over time.',
    element: 'Solar',
  ),
  SynergyVerbEntry(name: 'Cure', description: 'Instant heal.', element: 'Solar'),
  SynergyVerbEntry(
    name: 'Radiant',
    description: 'Increases weapon damage.',
    element: 'Solar',
  ),
  SynergyVerbEntry(
    name: 'Firesprite',
    description: 'Solar pickup companion.',
    element: 'Solar',
  ),
  // Arc
  SynergyVerbEntry(
    name: 'Jolt',
    description: 'Chains lightning; stuns Overload champions.',
    element: 'Arc',
  ),
  SynergyVerbEntry(
    name: 'Blind',
    description: 'Disorients targets; stuns Unstoppable champions.',
    element: 'Arc',
  ),
  SynergyVerbEntry(
    name: 'Amplified',
    description: 'Increased movement speed and weapon handling.',
    element: 'Arc',
  ),
  SynergyVerbEntry(
    name: 'Bolt Charge',
    description: 'Arc stacks that proc a lightning bolt at max.',
    element: 'Arc',
  ),
  SynergyVerbEntry(
    name: 'Ionic Trace',
    description: 'Arc pickup that grants Bolt Charge stacks.',
    element: 'Arc',
  ),
  // Subclass-agnostic / armor keyword
  SynergyVerbEntry(
    name: 'Armor Charge',
    description:
        'Stacks from orbs/armor mods that empower armor-charge effects.',
  ),
  // Void
  SynergyVerbEntry(
    name: 'Suppression',
    description: 'Disables abilities; stuns Overload champions.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Volatile',
    description: 'Unstable Void energy; explodes on further damage.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Weaken',
    description: 'Reduces target damage output.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Void Breach',
    description: 'Void pickup orb.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Devour',
    description: 'Defeating targets heals you.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Void Overshield',
    description: 'Bonus Void shields.',
    element: 'Void',
  ),
  SynergyVerbEntry(
    name: 'Invisibility',
    description: 'Void stealth buff.',
    element: 'Void',
  ),
  // Stasis
  SynergyVerbEntry(
    name: 'Slow',
    description: 'Reduces movement; stuns Overload champions.',
    element: 'Stasis',
  ),
  SynergyVerbEntry(
    name: 'Freeze',
    description: 'Immobilizes targets for shatter combos.',
    element: 'Stasis',
  ),
  SynergyVerbEntry(
    name: 'Shatter',
    description: 'Burst on frozen break; stuns Unstoppable champions.',
    element: 'Stasis',
  ),
  SynergyVerbEntry(
    name: 'Frost Armor',
    description: 'Damage reduction buff.',
    element: 'Stasis',
  ),
  SynergyVerbEntry(
    name: 'Stasis Crystal',
    description: 'Solidified Stasis matter; freezes nearby targets.',
    element: 'Stasis',
  ),
  SynergyVerbEntry(
    name: 'Stasis Shard',
    description: 'Stasis pickup; grants melee and grenade energy.',
    element: 'Stasis',
  ),
  // Strand
  SynergyVerbEntry(
    name: 'Suspend',
    description: 'Lifts and immobilizes; stuns Unstoppable champions.',
    element: 'Strand',
  ),
  SynergyVerbEntry(
    name: 'Unravel',
    description: 'Strand damage propagates to linked targets.',
    element: 'Strand',
  ),
  SynergyVerbEntry(
    name: 'Sever',
    description: 'Reduces target damage output.',
    element: 'Strand',
  ),
  SynergyVerbEntry(
    name: 'Threadling',
    description: 'Seeking Strand creature.',
    element: 'Strand',
  ),
  SynergyVerbEntry(
    name: 'Woven Mail',
    description: 'Damage reduction buff.',
    element: 'Strand',
  ),
  SynergyVerbEntry(
    name: 'Tangle',
    description: 'Strand pickup; can be thrown for damage.',
    element: 'Strand',
  ),
  // Prismatic
  SynergyVerbEntry(
    name: 'Transcendence',
    description: 'Light and Darkness harmony state.',
    element: 'Prismatic',
  ),
  // Subclass-agnostic
  SynergyVerbEntry(
    name: 'Exhaust',
    description: 'Reduces enemy damage output; applied across elements.',
  ),
  SynergyVerbEntry(
    name: 'Sliding',
    description: 'Slide-based movement and slide-shoot interactions.',
  ),
];

List<String> get synergyVerbNames =>
    synergyVerbs.map((v) => v.name).toList(growable: false);

final Map<String, SynergyVerbEntry> _verbByNameLower = {
  for (final v in synergyVerbs) v.name.toLowerCase(): v,
};

List<String> _singularPluralForms(String name) {
  final t = name.trim();
  if (t.isEmpty) return const [];
  final forms = <String>{t};
  final endsWithS = RegExp(r's$', caseSensitive: false).hasMatch(t);
  final endsWithSs = RegExp(r'ss$', caseSensitive: false).hasMatch(t);
  if (endsWithS && !endsWithSs && t.length > 3) {
    forms.add(t.replaceFirst(RegExp(r's$', caseSensitive: false), ''));
  } else {
    forms.add('${t}s');
  }
  return forms.toList();
}

String? _resolveVerbSubTypeExact(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;

  final names = synergyVerbNames;
  for (final form in _singularPluralForms(trimmed)) {
    if (names.contains(form)) return form;
    final aliasExact = synergyVerbAliases[form];
    if (aliasExact != null) return aliasExact;
  }

  final lowerForms =
      _singularPluralForms(trimmed).map((f) => f.toLowerCase()).toList();
  for (final canonical in names) {
    if (lowerForms.contains(canonical.toLowerCase())) return canonical;
  }
  for (final entry in synergyVerbAliases.entries) {
    if (lowerForms.contains(entry.key.toLowerCase())) return entry.value;
    if (lowerForms.contains(entry.value.toLowerCase())) return entry.value;
  }

  return null;
}

// Map free-text verb name to the canonical curated subType.
// Case-insensitive; aliases, simple plurals, element-prefixed phrases.
String? resolveVerbSubType(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;

  final exact = _resolveVerbSubTypeExact(trimmed);
  if (exact != null) return exact;

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length < 2) return null;
  for (var start = 1; start < parts.length; start++) {
    final suffix = parts.sublist(start).join(' ');
    final hit = _resolveVerbSubTypeExact(suffix);
    if (hit != null) return hit;
  }
  return null;
}

bool isKnownVerbSubType(String name) => resolveVerbSubType(name) != null;

// Element implied by a curated verb (Ionic Trace → Arc).
String? impliedElementForVerb(String? verbName) {
  if (verbName == null || verbName.trim().isEmpty) return null;
  final canonical = resolveVerbSubType(verbName);
  if (canonical == null) return null;
  return _verbByNameLower[canonical.toLowerCase()]?.element;
}

SynergyVerbEntry? getSynergyVerbEntry(String? verbName) {
  if (verbName == null || verbName.trim().isEmpty) return null;
  final canonical = resolveVerbSubType(verbName);
  if (canonical == null) return null;
  return _verbByNameLower[canonical.toLowerCase()];
}
