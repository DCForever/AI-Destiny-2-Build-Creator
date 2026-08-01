/// Unified catalog browse row (inventory-agnostic for DART-020).
///
/// Port of product `CatalogItem` from `src/lib/catalog/types.ts` (subset).
class CatalogItem {
  const CatalogItem({
    required this.hash,
    required this.name,
    this.icon,
    this.slot,
    this.element,
    this.ammo,
    this.itemTypeName,
    this.frame,
    this.classType,
    this.description,
    required this.isExotic,
    this.owned = false,
    this.ownedCount = 0,
    this.sourceStore,
    this.linkedSynergyIds = const [],
  });

  final int hash;
  final String name;
  final String? icon;
  final String? slot;
  final String? element;
  final String? ammo;
  final String? itemTypeName;
  final String? frame;
  final String? classType;
  final String? description;
  final bool isExotic;

  /// True when [ownedCount] &gt; 0 after inventory annotate (DART-026).
  final bool owned;

  /// Local inventory instance count for this definition hash (DART-026).
  final int ownedCount;

  /// MVP store stem for debugging / UI grouping (optional).
  final String? sourceStore;

  /// Optional synergy ids for pure filter parity (UI not required in DART-020).
  final List<String> linkedSynergyIds;

  CatalogItem copyWith({
    int? hash,
    String? name,
    String? icon,
    String? slot,
    String? element,
    String? ammo,
    String? itemTypeName,
    String? frame,
    String? classType,
    String? description,
    bool? isExotic,
    bool? owned,
    int? ownedCount,
    String? sourceStore,
    List<String>? linkedSynergyIds,
  }) {
    return CatalogItem(
      hash: hash ?? this.hash,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      slot: slot ?? this.slot,
      element: element ?? this.element,
      ammo: ammo ?? this.ammo,
      itemTypeName: itemTypeName ?? this.itemTypeName,
      frame: frame ?? this.frame,
      classType: classType ?? this.classType,
      description: description ?? this.description,
      isExotic: isExotic ?? this.isExotic,
      owned: owned ?? this.owned,
      ownedCount: ownedCount ?? this.ownedCount,
      sourceStore: sourceStore ?? this.sourceStore,
      linkedSynergyIds: linkedSynergyIds ?? this.linkedSynergyIds,
    );
  }

  @override
  String toString() => 'CatalogItem($hash, $name)';
}
