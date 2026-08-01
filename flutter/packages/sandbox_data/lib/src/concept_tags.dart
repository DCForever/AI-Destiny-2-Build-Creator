// Faceted concept tags for UI pickers and filter bars.
// Port of `src/data/conceptTags.ts` (without Zod).

const List<String> conceptTagFacets = [
  'activity',
  'element',
  'playstyle',
  'role',
];

class ConceptTag {
  const ConceptTag({
    required this.id,
    required this.label,
    required this.facet,
  });

  final String id;
  final String label;
  final String facet;
}

const List<ConceptTag> conceptTags = [
  // activity
  ConceptTag(id: 'pve', label: 'PVE', facet: 'activity'),
  ConceptTag(id: 'pvp', label: 'PVP', facet: 'activity'),
  ConceptTag(id: 'grandmaster', label: 'Grandmaster', facet: 'activity'),
  ConceptTag(id: 'nightfall', label: 'Nightfall', facet: 'activity'),
  ConceptTag(id: 'dungeon', label: 'Dungeon', facet: 'activity'),
  ConceptTag(id: 'raid', label: 'Raid', facet: 'activity'),
  ConceptTag(id: 'solo', label: 'Solo', facet: 'activity'),
  ConceptTag(id: 'trials', label: 'Trials', facet: 'activity'),
  ConceptTag(id: 'crucible', label: 'Crucible', facet: 'activity'),
  // element
  ConceptTag(id: 'solar', label: 'Solar', facet: 'element'),
  ConceptTag(id: 'arc', label: 'Arc', facet: 'element'),
  ConceptTag(id: 'void', label: 'Void', facet: 'element'),
  ConceptTag(id: 'stasis', label: 'Stasis', facet: 'element'),
  ConceptTag(id: 'strand', label: 'Strand', facet: 'element'),
  ConceptTag(id: 'kinetic', label: 'Kinetic', facet: 'element'),
  ConceptTag(id: 'prismatic', label: 'Prismatic', facet: 'element'),
  // playstyle
  ConceptTag(id: 'melee', label: 'Melee', facet: 'playstyle'),
  ConceptTag(id: 'grenade', label: 'Grenade', facet: 'playstyle'),
  ConceptTag(id: 'super', label: 'Super', facet: 'playstyle'),
  ConceptTag(id: 'support', label: 'Support', facet: 'playstyle'),
  ConceptTag(id: 'dps', label: 'DPS', facet: 'playstyle'),
  ConceptTag(id: 'survival', label: 'Survival', facet: 'playstyle'),
  ConceptTag(id: 'healing', label: 'Healing', facet: 'playstyle'),
  ConceptTag(id: 'ability', label: 'Ability', facet: 'playstyle'),
  // role
  ConceptTag(id: 'additive', label: 'Additive', facet: 'role'),
  ConceptTag(id: 'crowd_control', label: 'Crowd Control', facet: 'role'),
  ConceptTag(id: 'champion', label: 'Champion', facet: 'role'),
  ConceptTag(id: 'orbit', label: 'Orbit', facet: 'role'),
];

final Set<String> _conceptTagIds = conceptTags.map((t) => t.id).toSet();

bool isConceptTagId(String value) => _conceptTagIds.contains(value);

ConceptTag? getConceptTag(String id) {
  for (final t in conceptTags) {
    if (t.id == id) return t;
  }
  return null;
}

String getConceptTagLabel(String id) => getConceptTag(id)?.label ?? id;
