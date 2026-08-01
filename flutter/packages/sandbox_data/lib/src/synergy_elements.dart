// Damage elements selectable as Element synergy sub-types (product 006).
// Port of `src/data/synergyElements.ts`.

const List<String> synergyElements = [
  'Kinetic',
  'Solar',
  'Arc',
  'Void',
  'Stasis',
  'Strand',
  'Prismatic',
];

// Returns true when [name] is a known synergy element (exact wire match).
bool isSynergyElement(String name) => synergyElements.contains(name);
