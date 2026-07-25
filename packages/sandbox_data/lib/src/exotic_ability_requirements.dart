// Curated exotic armor → required ability pins (DBR-SUB-005 / DAC-DST-004).
// Port of `src/data/exoticAbilityRequirements.ts`.
//
// Soft synergies (prefer an ability) must not appear here.

class ExoticAbilityRequirement {
  const ExoticAbilityRequirement({
    this.hash,
    required this.name,
    this.superAbility,
    this.melee,
    this.grenade,
    this.classAbility,
  });

  final int? hash;
  final String name;
  final String? superAbility;
  final String? melee;
  final String? grenade;
  final String? classAbility;
}

// Ability pin fields returned by lookup (non-empty only).
class AbilityRequirementFields {
  const AbilityRequirementFields({
    this.superAbility,
    this.melee,
    this.grenade,
    this.classAbility,
  });

  final String? superAbility;
  final String? melee;
  final String? grenade;
  final String? classAbility;

  bool get isEmpty =>
      superAbility == null &&
      melee == null &&
      grenade == null &&
      classAbility == null;
}

// Seeded curated requirements. Empty requirements on a row are ignored.
// Expand when product identifies hard-gated exotics.
const List<ExoticAbilityRequirement> exoticAbilityRequirements = [
  // Example hard gates are uncommon; keep list product-curated.
];

String _normalizeName(String value) => value.trim().toLowerCase();

// Lookup by hash first, then exact name (case-insensitive).
AbilityRequirementFields? lookupExoticAbilityRequirements({
  int? hash,
  String? name,
}) {
  ExoticAbilityRequirement? byHash;
  if (hash != null && hash > 0) {
    for (final r in exoticAbilityRequirements) {
      if (r.hash == hash) {
        byHash = r;
        break;
      }
    }
  }
  ExoticAbilityRequirement? byName;
  if (name != null && name.trim().isNotEmpty) {
    final n = _normalizeName(name);
    for (final r in exoticAbilityRequirements) {
      if (_normalizeName(r.name) == n) {
        byName = r;
        break;
      }
    }
  }
  final row = byHash ?? byName;
  if (row == null) return null;

  final superAbility = row.superAbility?.trim();
  final melee = row.melee?.trim();
  final grenade = row.grenade?.trim();
  final classAbility = row.classAbility?.trim();
  final out = AbilityRequirementFields(
    superAbility:
        superAbility != null && superAbility.isNotEmpty ? superAbility : null,
    melee: melee != null && melee.isNotEmpty ? melee : null,
    grenade: grenade != null && grenade.isNotEmpty ? grenade : null,
    classAbility: classAbility != null && classAbility.isNotEmpty
        ? classAbility
        : null,
  );
  return out.isEmpty ? null : out;
}

bool hasAbilityRequirements(AbilityRequirementFields? req) {
  if (req == null) return false;
  return !req.isEmpty;
}
