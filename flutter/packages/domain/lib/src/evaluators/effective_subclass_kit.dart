import '../models/kit.dart';

/// Whether two subclass **tree** names match (DBR-SUB-001 / DBR-ID-008a).
///
/// Kit composition (aspects/fragments/abilities) is intentionally ignored —
/// those are variant-owned (DBR-SUB-003, DBR-ID-008b, DBR-ID-010).
bool subclassTreeNameEqual(String? a, String? b) {
  return (a?.trim() ?? '') == (b?.trim() ?? '');
}

/// True when [kit] carries no composition pieces (aspects/fragments/abilities).
///
/// Tree [SubclassKit.name] is ignored — tree lives on the Build.
bool subclassKitPiecesEmpty(SubclassKit kit) {
  return kit.aspects.isEmpty &&
      kit.fragments.isEmpty &&
      (kit.superAbility == null || kit.superAbility!.trim().isEmpty) &&
      (kit.melee == null || kit.melee!.trim().isEmpty) &&
      (kit.grenade == null || kit.grenade!.trim().isEmpty) &&
      (kit.classAbility == null || kit.classAbility!.trim().isEmpty);
}

/// Variant-owned kit pieces only (no tree name) — for `build_variants.subclass_kit`.
SubclassKit variantKitPiecesOnly(SubclassKit kit) {
  return SubclassKit(
    aspects: kit.aspects,
    fragments: kit.fragments,
    superAbility: kit.superAbility,
    melee: kit.melee,
    grenade: kit.grenade,
    classAbility: kit.classAbility,
  );
}

/// Build-owned tree identity only — for `builds.subclass` going forward.
SubclassKit subclassTreeOnly(String? treeName) {
  final t = treeName?.trim();
  if (t == null || t.isEmpty) return const SubclassKit();
  return SubclassKit(name: t);
}

/// Merge variant kit composition with Build tree name + optional pinned Super.
///
/// ## Rules (DBR-SUB-001 / 003 / 007, DBR-CMPL-001c)
/// - Tree [treeName] is Build-owned and wins over any name on [variantKit].
/// - [pinnedSuper] when non-empty overrides variant Super (identity pin).
/// - Does **not** auto-apply exotic ability pins (soft guidance never mutates).
SubclassKit mergeEffectiveSubclassKit({
  required SubclassKit variantKit,
  String? treeName,
  String? pinnedSuper,
}) {
  final tree = treeName?.trim();
  final pin = pinnedSuper?.trim();
  final kitSuper = variantKit.superAbility?.trim();
  return SubclassKit(
    name: (tree != null && tree.isNotEmpty) ? tree : variantKit.name,
    aspects: variantKit.aspects,
    fragments: variantKit.fragments,
    superAbility: (pin != null && pin.isNotEmpty)
        ? pin
        : (kitSuper != null && kitSuper.isNotEmpty ? kitSuper : null),
    melee: variantKit.melee,
    grenade: variantKit.grenade,
    classAbility: variantKit.classAbility,
  );
}
