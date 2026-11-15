/// Pure planner: build-detail plugs → ordered InsertSocketPlugFree steps.
///
/// Order (DIM-aligned, documented):
/// 1. Equip subclass item (caller) when not already equipped.
/// 2. Subclass sockets: super → class ability → movement → melee → grenade →
///    aspects → fragments (manifest socket-category indexes).
/// 3. Armor mods on equipped pieces. Before inserting a higher-cost mod set,
///    clear conflicting plugs first (empty-plug steps precede inserts) so
///    energy/slot caps are freed — same idea as DIM's clear-then-assign.
///
/// Never calls the paid non-Free plug-insert action. Skips unowned /
/// unaffordable / ambiguous names with fixed-text reasons (no guessing).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';

/// Fixed skip / miss reasons (never Exception.toString).
const String kApplySubclassNotOnCharacterMessage =
    'Subclass not on character';
const String kApplyPlugNotUnlockedPrefix = 'Not unlocked: ';
const String kApplyPlugNotEnoughEnergyPrefix = 'Not enough armor energy: ';
const String kApplyPlugUnresolvablePrefix = 'Could not resolve: ';

/// Kind used for ordering + outcome labels.
enum ApplyPlugKind {
  superAbility,
  classAbility,
  movement,
  melee,
  grenade,
  aspect,
  fragment,
  armorMod,
  /// Empty-plug clear used before armor mod inserts (energy/slot free-up).
  armorModClear,
}

/// Display prefix for outcome rows (`Aspect: Weaver's Call`).
String applyPlugKindLabel(ApplyPlugKind kind) {
  switch (kind) {
    case ApplyPlugKind.superAbility:
      return 'Super';
    case ApplyPlugKind.classAbility:
      return 'Class ability';
    case ApplyPlugKind.movement:
      return 'Movement';
    case ApplyPlugKind.melee:
      return 'Melee';
    case ApplyPlugKind.grenade:
      return 'Grenade';
    case ApplyPlugKind.aspect:
      return 'Aspect';
    case ApplyPlugKind.fragment:
      return 'Fragment';
    case ApplyPlugKind.armorMod:
      return 'Mod';
    case ApplyPlugKind.armorModClear:
      return 'Clear mod';
  }
}

String formatApplyPlugOutcomeLabel(ApplyPlugKind kind, String plugName) {
  final name = plugName.trim();
  final prefix = applyPlugKindLabel(kind);
  if (name.isEmpty) return prefix;
  return '$prefix: $name';
}

String notUnlockedPlugMessage(String name) =>
    '$kApplyPlugNotUnlockedPrefix${name.trim()}';

String notEnoughArmorEnergyMessage(String name) =>
    '$kApplyPlugNotEnoughEnergyPrefix${name.trim()}';

String unresolvablePlugMessage(String name) =>
    '$kApplyPlugUnresolvablePrefix${name.trim()}';

/// One resolved (or skipped) plug step for Apply.
class ApplyPlugStep {
  const ApplyPlugStep({
    required this.id,
    required this.label,
    required this.kind,
    required this.itemInstanceId,
    required this.socketIndex,
    required this.plugItemHash,
    this.currentPlugHash,
    this.skipReason,
  });

  final String id;
  final String label;
  final ApplyPlugKind kind;
  final String itemInstanceId;
  final int socketIndex;
  final int plugItemHash;
  final int? currentPlugHash;

  /// When set, Apply records the row and makes no write call.
  final String? skipReason;

  bool get shouldCall {
    if (skipReason != null) return false;
    if (currentPlugHash != null && currentPlugHash == plugItemHash) {
      return false;
    }
    return true;
  }
}

/// Subclass inventory pin for EquipItem (mirrors ApplyToCharacterItem fields).
class ApplySubclassPin {
  const ApplySubclassPin({
    required this.id,
    required this.label,
    required this.itemHash,
    required this.instanceId,
  });

  final String id;
  final String label;
  final int itemHash;
  final String instanceId;
}

/// Equipped armor piece that may receive mods.
class ApplyArmorPin {
  const ApplyArmorPin({
    required this.id,
    required this.label,
    required this.itemHash,
    required this.instanceId,
  });

  final String id;
  final String label;
  final int itemHash;
  final String instanceId;
}

/// Subclass + plug plan consumed after gear moves/equips.
class ApplySocketPlan {
  const ApplySocketPlan({
    this.subclass,
    this.subclassAlreadyEquipped = false,
    this.subclassMissingReason,
    this.subclassPlugs = const [],
    this.armorMods = const [],
  });

  /// Subclass inventory pin to EquipItem when not already equipped.
  final ApplySubclassPin? subclass;

  final bool subclassAlreadyEquipped;

  /// When set, subclass is not on the character — report and skip plug steps.
  final String? subclassMissingReason;

  /// Ordered: super → abilities → aspects → fragments.
  final List<ApplyPlugStep> subclassPlugs;

  /// Ordered after subclass plugs; clears (if any) precede inserts.
  final List<ApplyPlugStep> armorMods;

  bool get hasWork =>
      subclass != null ||
      subclassMissingReason != null ||
      subclassPlugs.isNotEmpty ||
      armorMods.isNotEmpty;
}

/// Minimal item-def socket category view (fakeable in tests).
class ApplyManifestSocketCategory {
  const ApplyManifestSocketCategory({
    required this.socketCategoryHash,
    required this.socketIndexes,
  });

  final int socketCategoryHash;
  final List<int> socketIndexes;
}

/// Minimal plug definition for planning (fakeable).
class ApplyManifestPlugDef {
  const ApplyManifestPlugDef({
    required this.hash,
    required this.name,
    required this.plugCategoryIdentifier,
    this.energyCost = 0,
  });

  final int hash;
  final String name;
  final String plugCategoryIdentifier;
  final int energyCost;
}

/// Minimal item definition for socket-index lookup (fakeable).
class ApplyManifestItemDef {
  const ApplyManifestItemDef({
    required this.hash,
    required this.name,
    this.socketCategories = const [],
  });

  final int hash;
  final String name;
  final List<ApplyManifestSocketCategory> socketCategories;
}

/// Live socket state on an instance (fakeable profile slice).
class ApplyInstanceSocketState {
  const ApplyInstanceSocketState({
    required this.instanceId,
    required this.itemHash,
    required this.bucketHash,
    this.characterId,
    this.location = 'character',
    this.equippedPlugBySocket = const {},
    this.ownedPlugHashes = const {},
    this.energyCapacity = 0,
    this.energyUsed = 0,
    this.emptyPlugHashBySocket = const {},
  });

  final String instanceId;
  final int itemHash;
  final int bucketHash;
  final String? characterId;
  final String location;
  final Map<int, int> equippedPlugBySocket;
  final Set<int> ownedPlugHashes;
  final int energyCapacity;
  final int energyUsed;
  final Map<int, int> emptyPlugHashBySocket;
}

/// Manifest + name lookup ports for [planApplySockets].
class ApplySocketManifestLookup {
  const ApplySocketManifestLookup({
    required this.itemDef,
    required this.plugDef,
    required this.resolveUniquePlugHashByName,
  });

  final ApplyManifestItemDef? Function(int itemHash) itemDef;
  final ApplyManifestPlugDef? Function(int plugHash) plugDef;

  /// Returns a single hash when [name] resolves uniquely; otherwise null.
  final int? Function(String name) resolveUniquePlugHashByName;
}

/// Socket category hashes used for subclass plug ordering (DIM / enums).
const List<int> kApplySuperSocketCategoryHashes = <int>[457473665];
const List<int> kApplyAbilitySocketCategoryHashes = <int>[
  309722977, // Abilities_Abilities
  3218807805, // Abilities_Abilities_Ikora
];
const List<int> kApplyAspectSocketCategoryHashes = <int>[
  2047681910,
  2140934067,
  764703411,
  3400923910,
];
const List<int> kApplyFragmentSocketCategoryHashes = <int>[
  271461480,
  1313488945,
  193371309,
  2819965312,
];
const List<int> kApplyArmorModSocketCategoryHashes = <int>[
  590099826, // ArmorMods
];

/// Named plug from build detail / DIM cache (hash optional until resolved).
class ApplyNamedPlug {
  const ApplyNamedPlug({
    required this.name,
    this.hash,
  });

  final String name;
  final int? hash;
}

/// Build-detail inputs for socket planning.
class ApplyBuildSocketInputs {
  const ApplyBuildSocketInputs({
    this.subclassHash,
    this.subclassName = '',
    this.subclassPlugs = const [],
    this.armorMods = const [],
  });

  final int? subclassHash;
  final String subclassName;

  /// Display order from detail; planner reorders by kind.
  final List<ApplyNamedPlug> subclassPlugs;
  final List<ApplyNamedPlug> armorMods;
}

/// Plans subclass equip + free plug inserts from build detail + fakeable lookup.
ApplySocketPlan planApplySockets({
  required String characterId,
  required ApplyBuildSocketInputs build,
  required ApplySocketManifestLookup manifest,
  required List<ApplyInstanceSocketState> instances,
  required List<ApplyArmorPin> equippedArmor,
}) {
  final wantsSubclass = build.subclassHash != null ||
      build.subclassName.trim().isNotEmpty ||
      build.subclassPlugs.isNotEmpty;

  ApplySubclassPin? subclassItem;
  var subclassAlreadyEquipped = false;
  String? subclassMissingReason;
  final subclassPlugs = <ApplyPlugStep>[];

  if (wantsSubclass) {
    final subclassState = _findSubclass(
      characterId: characterId,
      subclassHash: build.subclassHash,
      subclassName: build.subclassName,
      instances: instances,
      manifest: manifest,
    );
    if (subclassState.missingReason != null) {
      // Still plan armor mods; report subclass miss separately.
      subclassMissingReason = subclassState.missingReason;
    } else {
      subclassItem = subclassState.item;
      subclassAlreadyEquipped = subclassState.alreadyEquipped;
      final subclassInstance = subclassState.instance!;
      final subclassDef = manifest.itemDef(subclassInstance.itemHash);
      if (subclassDef != null) {
        subclassPlugs.addAll(
          _planSubclassPlugs(
            plugs: build.subclassPlugs,
            instance: subclassInstance,
            itemDef: subclassDef,
            manifest: manifest,
          ),
        );
      }
    }
  }

  final armorSteps = <ApplyPlugStep>[];
  for (final armor in equippedArmor) {
    final live = _instanceById(instances, armor.instanceId);
    if (live == null) continue;
    final def = manifest.itemDef(armor.itemHash);
    if (def == null) continue;
    armorSteps.addAll(
      _planArmorModsForPiece(
        targets: build.armorMods,
        armor: armor,
        instance: live,
        itemDef: def,
        manifest: manifest,
      ),
    );
  }

  return ApplySocketPlan(
    subclass: subclassItem,
    subclassAlreadyEquipped: subclassAlreadyEquipped,
    subclassMissingReason: subclassMissingReason,
    subclassPlugs: subclassPlugs,
    armorMods: armorSteps,
  );
}

class _SubclassLocate {
  const _SubclassLocate({
    this.item,
    this.instance,
    this.alreadyEquipped = false,
    this.missingReason,
  });

  final ApplySubclassPin? item;
  final ApplyInstanceSocketState? instance;
  final bool alreadyEquipped;
  final String? missingReason;
}

_SubclassLocate _findSubclass({
  required String characterId,
  required int? subclassHash,
  required String subclassName,
  required List<ApplyInstanceSocketState> instances,
  required ApplySocketManifestLookup manifest,
}) {
  ApplyInstanceSocketState? match;
  for (final row in instances) {
    if (row.bucketHash != kSubclassBucketHash) continue;
    if (row.characterId != null && row.characterId != characterId) continue;
    if (subclassHash != null && row.itemHash == subclassHash) {
      match = row;
      break;
    }
  }
  if (match == null && subclassName.trim().isNotEmpty) {
    final needle = subclassName.trim().toLowerCase();
    for (final row in instances) {
      if (row.bucketHash != kSubclassBucketHash) continue;
      if (row.characterId != null && row.characterId != characterId) continue;
      final def = manifest.itemDef(row.itemHash);
      final name = (def?.name ?? '').trim().toLowerCase();
      if (name == needle || name.contains(needle) || needle.contains(name)) {
        match = row;
        break;
      }
    }
  }
  if (match == null) {
    return const _SubclassLocate(
      missingReason: kApplySubclassNotOnCharacterMessage,
    );
  }
  final label = () {
    final def = manifest.itemDef(match!.itemHash);
    final n = def?.name.trim();
    if (n != null && n.isNotEmpty) return n;
    final fallback = subclassName.trim();
    return fallback.isNotEmpty ? fallback : 'Subclass';
  }();
  return _SubclassLocate(
    item: ApplySubclassPin(
      id: 'subclass:${match.instanceId}',
      label: label,
      itemHash: match.itemHash,
      instanceId: match.instanceId,
    ),
    instance: match,
    alreadyEquipped: match.location == 'equipped',
  );
}

ApplyInstanceSocketState? _instanceById(
  List<ApplyInstanceSocketState> instances,
  String id,
) {
  for (final row in instances) {
    if (row.instanceId == id) return row;
  }
  return null;
}

List<int> _indexesForCategories(
  ApplyManifestItemDef itemDef,
  List<int> categoryHashes,
) {
  for (final cat in itemDef.socketCategories) {
    if (categoryHashes.contains(cat.socketCategoryHash)) {
      return cat.socketIndexes;
    }
  }
  return const [];
}

ApplyPlugKind? _kindFromPlugCategory(String cat) {
  if (cat.contains('.supers') || cat.endsWith('.supers')) {
    return ApplyPlugKind.superAbility;
  }
  if (cat.contains('class_abilities')) return ApplyPlugKind.classAbility;
  if (cat.contains('.movement') || cat.endsWith('.movement')) {
    return ApplyPlugKind.movement;
  }
  if (cat.contains('.melee') || cat.endsWith('.melee')) {
    return ApplyPlugKind.melee;
  }
  if (cat.contains('.grenades') || cat.endsWith('.grenades')) {
    return ApplyPlugKind.grenade;
  }
  if (cat.contains('.aspects') || cat.endsWith('.aspects')) {
    return ApplyPlugKind.aspect;
  }
  if (cat.contains('.fragments') || cat.endsWith('.fragments')) {
    return ApplyPlugKind.fragment;
  }
  if (cat.startsWith('enhancements.')) return ApplyPlugKind.armorMod;
  return null;
}

int _kindOrder(ApplyPlugKind kind) {
  switch (kind) {
    case ApplyPlugKind.superAbility:
      return 0;
    case ApplyPlugKind.classAbility:
      return 1;
    case ApplyPlugKind.movement:
      return 2;
    case ApplyPlugKind.melee:
      return 3;
    case ApplyPlugKind.grenade:
      return 4;
    case ApplyPlugKind.aspect:
      return 5;
    case ApplyPlugKind.fragment:
      return 6;
    case ApplyPlugKind.armorModClear:
      return 7;
    case ApplyPlugKind.armorMod:
      return 8;
  }
}

({int? hash, String? skip}) _resolvePlugHash(
  ApplyNamedPlug plug,
  ApplySocketManifestLookup manifest,
) {
  final named = plug.name.trim();
  final h = plug.hash;
  if (h != null && h != 0) {
    final def = manifest.plugDef(h);
    if (def != null) return (hash: h, skip: null);
  }
  if (named.isEmpty) {
    return (hash: null, skip: unresolvablePlugMessage('(empty)'));
  }
  final resolved = manifest.resolveUniquePlugHashByName(named);
  if (resolved == null) {
    return (hash: null, skip: unresolvablePlugMessage(named));
  }
  return (hash: resolved, skip: null);
}

List<ApplyPlugStep> _planSubclassPlugs({
  required List<ApplyNamedPlug> plugs,
  required ApplyInstanceSocketState instance,
  required ApplyManifestItemDef itemDef,
  required ApplySocketManifestLookup manifest,
}) {
  final abilityIndexes = [
    ..._indexesForCategories(itemDef, kApplySuperSocketCategoryHashes),
    ..._indexesForCategories(itemDef, kApplyAbilitySocketCategoryHashes),
  ];
  final aspectIndexes =
      _indexesForCategories(itemDef, kApplyAspectSocketCategoryHashes);
  final fragmentIndexes =
      _indexesForCategories(itemDef, kApplyFragmentSocketCategoryHashes);

  final resolved = <({ApplyPlugKind kind, int hash, String name, String? skip})>[];
  for (final plug in plugs) {
    final r = _resolvePlugHash(plug, manifest);
    final name = plug.name.trim().isNotEmpty
        ? plug.name.trim()
        : (r.hash != null ? (manifest.plugDef(r.hash!)?.name ?? '') : '');
    if (r.skip != null || r.hash == null) {
      resolved.add((
        kind: ApplyPlugKind.aspect,
        hash: 0,
        name: name,
        skip: r.skip ?? unresolvablePlugMessage(name),
      ));
      continue;
    }
    final def = manifest.plugDef(r.hash!);
    final kind = def == null
        ? null
        : _kindFromPlugCategory(def.plugCategoryIdentifier);
    if (kind == null ||
        kind == ApplyPlugKind.armorMod ||
        kind == ApplyPlugKind.armorModClear) {
      resolved.add((
        kind: ApplyPlugKind.aspect,
        hash: r.hash!,
        name: name.isNotEmpty ? name : (def?.name ?? ''),
        skip: unresolvablePlugMessage(name.isNotEmpty ? name : '${r.hash}'),
      ));
      continue;
    }
    resolved.add((
      kind: kind,
      hash: r.hash!,
      name: name.isNotEmpty ? name : (def?.name ?? ''),
      skip: null,
    ));
  }

  resolved.sort((a, b) => _kindOrder(a.kind).compareTo(_kindOrder(b.kind)));

  final usedSockets = <int>{};
  final steps = <ApplyPlugStep>[];
  var i = 0;
  for (final row in resolved) {
    i += 1;
    final id = 'subclass-plug:$i:${row.hash}';
    if (row.skip != null) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(row.kind, row.name),
          kind: row.kind,
          itemInstanceId: instance.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: row.skip,
        ),
      );
      continue;
    }
    if (!instance.ownedPlugHashes.contains(row.hash) &&
        instance.ownedPlugHashes.isNotEmpty) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(row.kind, row.name),
          kind: row.kind,
          itemInstanceId: instance.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: notUnlockedPlugMessage(row.name),
        ),
      );
      continue;
    }

    final indexes = switch (row.kind) {
      ApplyPlugKind.superAbility ||
      ApplyPlugKind.classAbility ||
      ApplyPlugKind.movement ||
      ApplyPlugKind.melee ||
      ApplyPlugKind.grenade =>
        abilityIndexes,
      ApplyPlugKind.aspect => aspectIndexes,
      ApplyPlugKind.fragment => fragmentIndexes,
      _ => const <int>[],
    };

    int? socketIndex;
    // Prefer a socket that already has this plug (no-op), else first free slot.
    for (final idx in indexes) {
      if (instance.equippedPlugBySocket[idx] == row.hash) {
        socketIndex = idx;
        break;
      }
    }
    if (socketIndex == null) {
      for (final idx in indexes) {
        if (usedSockets.contains(idx)) continue;
        socketIndex = idx;
        break;
      }
    }
    if (socketIndex == null) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(row.kind, row.name),
          kind: row.kind,
          itemInstanceId: instance.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: unresolvablePlugMessage(row.name),
        ),
      );
      continue;
    }
    usedSockets.add(socketIndex);
    final current = instance.equippedPlugBySocket[socketIndex];
    steps.add(
      ApplyPlugStep(
        id: id,
        label: formatApplyPlugOutcomeLabel(row.kind, row.name),
        kind: row.kind,
        itemInstanceId: instance.instanceId,
        socketIndex: socketIndex,
        plugItemHash: row.hash,
        currentPlugHash: current,
      ),
    );
  }
  return steps;
}

List<ApplyPlugStep> _planArmorModsForPiece({
  required List<ApplyNamedPlug> targets,
  required ApplyArmorPin armor,
  required ApplyInstanceSocketState instance,
  required ApplyManifestItemDef itemDef,
  required ApplySocketManifestLookup manifest,
}) {
  final modIndexes =
      _indexesForCategories(itemDef, kApplyArmorModSocketCategoryHashes);
  if (modIndexes.isEmpty) return const [];

  final wanted = <({int hash, String name, int cost, String? skip})>[];
  for (final plug in targets) {
    final r = _resolvePlugHash(plug, manifest);
    final name = plug.name.trim();
    if (r.skip != null || r.hash == null) {
      wanted.add((
        hash: 0,
        name: name,
        cost: 0,
        skip: r.skip ?? unresolvablePlugMessage(name),
      ));
      continue;
    }
    final def = manifest.plugDef(r.hash!);
    if (def == null || _kindFromPlugCategory(def.plugCategoryIdentifier) !=
        ApplyPlugKind.armorMod) {
      // Not an armor mod — ignore for this piece (mods list is global).
      continue;
    }
    // Slot filter: only mods that match this armor piece via category when known.
    wanted.add((
      hash: r.hash!,
      name: name.isNotEmpty ? name : def.name,
      cost: def.energyCost,
      skip: null,
    ));
  }
  if (wanted.isEmpty) return const [];

  final steps = <ApplyPlugStep>[];
  var energyUsed = instance.energyUsed;
  final capacity = instance.energyCapacity;
  final usedSockets = <int>{};
  var n = 0;

  // DIM-style: clear plugs on sockets we will overwrite when energy is tight.
  for (final row in wanted) {
    n += 1;
    final id = 'armor-mod:${armor.instanceId}:$n';
    if (row.skip != null) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: row.skip,
        ),
      );
      continue;
    }
    if (!instance.ownedPlugHashes.contains(row.hash) &&
        instance.ownedPlugHashes.isNotEmpty) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: notUnlockedPlugMessage(row.name),
        ),
      );
      continue;
    }

    int? socketIndex;
    for (final idx in modIndexes) {
      if (instance.equippedPlugBySocket[idx] == row.hash) {
        socketIndex = idx;
        break;
      }
    }
    socketIndex ??= () {
      for (final idx in modIndexes) {
        if (usedSockets.contains(idx)) continue;
        return idx;
      }
      return null;
    }();
    if (socketIndex == null) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: unresolvablePlugMessage(row.name),
        ),
      );
      continue;
    }

    final current = instance.equippedPlugBySocket[socketIndex];
    if (current == row.hash) {
      usedSockets.add(socketIndex);
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: socketIndex,
          plugItemHash: row.hash,
          currentPlugHash: current,
        ),
      );
      continue;
    }

    final currentCost = current == null
        ? 0
        : (manifest.plugDef(current)?.energyCost ?? 0);
    final projected = energyUsed - currentCost + row.cost;
    if (capacity > 0 && projected > capacity) {
      // Clear other non-target sockets first to free energy (DIM order).
      var freed = false;
      for (final idx in modIndexes) {
        if (idx == socketIndex) continue;
        if (usedSockets.contains(idx)) continue;
        final equipped = instance.equippedPlugBySocket[idx];
        if (equipped == null) continue;
        final empty = instance.emptyPlugHashBySocket[idx];
        if (empty == null) continue;
        final eqCost = manifest.plugDef(equipped)?.energyCost ?? 0;
        if (eqCost <= 0) continue;
        steps.add(
          ApplyPlugStep(
            id: '$id:clear:$idx',
            label: formatApplyPlugOutcomeLabel(
              ApplyPlugKind.armorModClear,
              manifest.plugDef(equipped)?.name ?? 'mod',
            ),
            kind: ApplyPlugKind.armorModClear,
            itemInstanceId: armor.instanceId,
            socketIndex: idx,
            plugItemHash: empty,
            currentPlugHash: equipped,
          ),
        );
        energyUsed -= eqCost;
        freed = true;
        if (energyUsed - currentCost + row.cost <= capacity) break;
      }
      if (!freed && energyUsed - currentCost + row.cost > capacity) {
        steps.add(
          ApplyPlugStep(
            id: id,
            label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
            kind: ApplyPlugKind.armorMod,
            itemInstanceId: armor.instanceId,
            socketIndex: socketIndex,
            plugItemHash: row.hash,
            skipReason: notEnoughArmorEnergyMessage(row.name),
          ),
        );
        continue;
      }
      if (energyUsed - currentCost + row.cost > capacity) {
        steps.add(
          ApplyPlugStep(
            id: id,
            label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
            kind: ApplyPlugKind.armorMod,
            itemInstanceId: armor.instanceId,
            socketIndex: socketIndex,
            plugItemHash: row.hash,
            skipReason: notEnoughArmorEnergyMessage(row.name),
          ),
        );
        continue;
      }
    }

    usedSockets.add(socketIndex);
    energyUsed = energyUsed - currentCost + row.cost;
    steps.add(
      ApplyPlugStep(
        id: id,
        label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, row.name),
        kind: ApplyPlugKind.armorMod,
        itemInstanceId: armor.instanceId,
        socketIndex: socketIndex,
        plugItemHash: row.hash,
        currentPlugHash: current,
      ),
    );
  }
  return steps;
}
