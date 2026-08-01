/// Dense meta chips for catalog / set-fill definition rows (DART-068 / GAP-UI-CATALOG-09).
///
/// Omits Instance|Wishlist (those are set-pin semantics via [buildSetItemMetaChips]).

/// Compact facet list for a definition card: Exotic, slot, element, ammo, type, frame.
List<String> buildCatalogDenseMetaChips({
  bool isExotic = false,
  String? slot,
  String? element,
  String? ammo,
  String? itemTypeName,
  String? frame,
  String? classType,
}) {
  final meta = <String>[];
  if (isExotic) meta.add('Exotic');
  if (slot != null && slot.isNotEmpty) meta.add(slot);
  if (element != null && element.isNotEmpty) meta.add(element);
  if (ammo != null && ammo.isNotEmpty) meta.add(ammo);
  if (itemTypeName != null && itemTypeName.isNotEmpty) meta.add(itemTypeName);
  if (frame != null && frame.isNotEmpty) meta.add(frame);
  if (classType != null && classType.isNotEmpty) meta.add(classType);
  return List.unmodifiable(meta);
}
