/// Pure planner: build-detail plugs → ordered InsertSocketPlugFree steps.
///
/// Order (DIM-aligned, documented):
/// 1. Equip subclass item (caller) when not already equipped.
/// 2. Subclass sockets by category: super → class ability → movement → melee →
///    grenade → aspects → fragments (never a shared first-free ability list).
/// 3. Armor mods: each mod → exactly one armor piece by slot category; check
///    allowed plugs; clear only when its matching insert is planned and fits
///    energy after the clear.
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
const String kApplyPlugDoesNotFitPrefix = 'Does not fit: ';
const String kArmorModsSkippedUnavailableMessage =
    'Armor mods skipped: mod data unavailable';
const String kApplySocketChangeFailedMessage = 'Socket change failed';
const String kApplySocketRestoredMessage =
    'Socket change failed; original plug restored';
const String kApplySocketRestoreFailedMessage =
    'Socket change failed; could not restore original plug';

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
  /// Empty-plug clear used before armor mod inserts (energy free-up).
  armorModClear,
}

/// Armor slot used to assign each mod to exactly one piece.
enum ApplyArmorSlot {
  helmet,
  arms,
  chest,
  legs,
  classItem,
  general,
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

String doesNotFitPlugMessage(String name) =>
    '$kApplyPlugDoesNotFitPrefix${name.trim()}';

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
    this.requiresClearStepId,
    this.restorePlugHash,
    this.restoreSocketIndex,
    this.restoreItemInstanceId,
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

  /// Insert step: id of a preceding clear that must be restored if insert fails.
  final String? requiresClearStepId;

  /// Original plug to restore on [restoreSocketIndex] after a failed insert.
  final int? restorePlugHash;
  final int? restoreSocketIndex;
  final String? restoreItemInstanceId;

  bool get shouldCall {
    if (skipReason != null) return false;
    if (currentPlugHash != null && currentPlugHash == plugItemHash) {
      return false;
    }
    return true;
  }
}

/// Subclass inventory pin for EquipItem.
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
    this.slot,
  });

  final String id;
  final String label;
  final int itemHash;
  final String instanceId;

  /// Wire name: helmet / arms / chest / legs / class_item.
  final String? slot;
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

  final ApplySubclassPin? subclass;
  final bool subclassAlreadyEquipped;
  final String? subclassMissingReason;
  final List<ApplyPlugStep> subclassPlugs;
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
    this.allowedPlugHashesBySocket = const {},
    this.socketPlugCategoryHint = const {},
  });

  final int hash;
  final String name;
  final List<ApplyManifestSocketCategory> socketCategories;

  /// Reusable / randomized / socketType whitelist per socket index.
  final Map<int, Set<int>> allowedPlugHashesBySocket;

  /// Optional plugCategoryIdentifier hint per socket (from initial plug).
  final Map<int, String> socketPlugCategoryHint;
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
    this.allowedPlugHashesBySocket = const {},
    this.armorModDataKnown = false,
  });

  final String instanceId;
  final int itemHash;
  final int bucketHash;
  final String? characterId;
  final String location;

  /// Equipped plug keyed by socket index (never assume flat plugHashes order).
  final Map<int, int> equippedPlugBySocket;
  final Set<int> ownedPlugHashes;
  final int energyCapacity;
  final int energyUsed;
  final Map<int, int> emptyPlugHashBySocket;
  final Map<int, Set<int>> allowedPlugHashesBySocket;

  /// When false, planner skips all armor-mod steps with fixed text (R3).
  final bool armorModDataKnown;
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
  final int? Function(String name) resolveUniquePlugHashByName;
}

/// Socket category hashes used for subclass plug ordering (DIM / enums).
const List<int> kApplySuperSocketCategoryHashes = <int>[457473665];
const List<int> kApplyAbilitySocketCategoryHashes = <int>[
  309722977,
  3218807805,
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
  590099826,
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

  final armorSteps = _planArmorMods(
    targets: build.armorMods,
    equippedArmor: equippedArmor,
    instances: instances,
    manifest: manifest,
  );

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

/// Exact hash or exact non-empty name only; never vault (null characterId).
_SubclassLocate _findSubclass({
  required String characterId,
  required int? subclassHash,
  required String subclassName,
  required List<ApplyInstanceSocketState> instances,
  required ApplySocketManifestLookup manifest,
}) {
  ApplyInstanceSocketState? match;
  if (subclassHash != null) {
    for (final row in instances) {
      if (row.bucketHash != kSubclassBucketHash) continue;
      if (row.characterId == null || row.characterId != characterId) continue;
      if (row.itemHash == subclassHash) {
        match = row;
        break;
      }
    }
  }
  final needle = subclassName.trim().toLowerCase();
  if (match == null && needle.isNotEmpty) {
    for (final row in instances) {
      if (row.bucketHash != kSubclassBucketHash) continue;
      if (row.characterId == null || row.characterId != characterId) continue;
      final def = manifest.itemDef(row.itemHash);
      final name = (def?.name ?? '').trim().toLowerCase();
      if (name.isNotEmpty && name == needle) {
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
  final out = <int>[];
  for (final cat in itemDef.socketCategories) {
    if (categoryHashes.contains(cat.socketCategoryHash)) {
      out.addAll(cat.socketIndexes);
    }
  }
  return out;
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

ApplyArmorSlot? armorSlotFromPlugCategory(String cat) {
  if (RegExp(r'enhancements\.(v2_)?head').hasMatch(cat)) {
    return ApplyArmorSlot.helmet;
  }
  if (RegExp(r'enhancements\.(v2_)?arms').hasMatch(cat)) {
    return ApplyArmorSlot.arms;
  }
  if (RegExp(r'enhancements\.(v2_)?chest').hasMatch(cat)) {
    return ApplyArmorSlot.chest;
  }
  if (RegExp(r'enhancements\.(v2_)?legs').hasMatch(cat)) {
    return ApplyArmorSlot.legs;
  }
  if (RegExp(r'enhancements\.(v2_)?class').hasMatch(cat)) {
    return ApplyArmorSlot.classItem;
  }
  if (cat.contains('tuning') ||
      RegExp(r'enhancements\.(v2_)?general').hasMatch(cat) ||
      cat.contains('enhancements.universal')) {
    return ApplyArmorSlot.general;
  }
  return null;
}

ApplyArmorSlot? armorSlotFromWire(String? slot) {
  switch ((slot ?? '').trim().toLowerCase()) {
    case 'helmet':
      return ApplyArmorSlot.helmet;
    case 'arms':
    case 'gauntlets':
      return ApplyArmorSlot.arms;
    case 'chest':
      return ApplyArmorSlot.chest;
    case 'legs':
      return ApplyArmorSlot.legs;
    case 'class_item':
    case 'classitem':
      return ApplyArmorSlot.classItem;
    default:
      return null;
  }
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

List<int> _indexesForKind(ApplyManifestItemDef itemDef, ApplyPlugKind kind) {
  switch (kind) {
    case ApplyPlugKind.superAbility:
      return _indexesForCategories(itemDef, kApplySuperSocketCategoryHashes);
    case ApplyPlugKind.classAbility:
    case ApplyPlugKind.movement:
    case ApplyPlugKind.melee:
    case ApplyPlugKind.grenade:
      return _indexesForCategories(itemDef, kApplyAbilitySocketCategoryHashes);
    case ApplyPlugKind.aspect:
      return _indexesForCategories(itemDef, kApplyAspectSocketCategoryHashes);
    case ApplyPlugKind.fragment:
      return _indexesForCategories(itemDef, kApplyFragmentSocketCategoryHashes);
    case ApplyPlugKind.armorMod:
    case ApplyPlugKind.armorModClear:
      return _indexesForCategories(itemDef, kApplyArmorModSocketCategoryHashes);
  }
}

bool _socketAllowsPlug({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required int socketIndex,
  required int plugHash,
  required ApplyPlugKind kind,
}) {
  final liveAllowed = instance.allowedPlugHashesBySocket[socketIndex];
  final defAllowed = itemDef.allowedPlugHashesBySocket[socketIndex];
  final allowed = liveAllowed ?? defAllowed;
  if (allowed != null && allowed.isNotEmpty) {
    return allowed.contains(plugHash);
  }
  final hint = itemDef.socketPlugCategoryHint[socketIndex];
  if (hint != null && hint.isNotEmpty) {
    final hintKind = _kindFromPlugCategory(hint);
    return hintKind == kind;
  }
  // Aspects/fragments are interchangeable within their category when no
  // whitelist is present. Ability/super sockets require a match.
  return kind == ApplyPlugKind.aspect || kind == ApplyPlugKind.fragment;
}

int? _pickSocketForKind({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required ApplyPlugKind kind,
  required int plugHash,
  required Set<int> usedSockets,
}) {
  final indexes = _indexesForKind(itemDef, kind);
  for (final idx in indexes) {
    if (instance.equippedPlugBySocket[idx] == plugHash) return idx;
  }
  for (final idx in indexes) {
    if (usedSockets.contains(idx)) continue;
    if (_socketAllowsPlug(
      itemDef: itemDef,
      instance: instance,
      socketIndex: idx,
      plugHash: plugHash,
      kind: kind,
    )) {
      return idx;
    }
  }
  return null;
}

List<ApplyPlugStep> _planSubclassPlugs({
  required List<ApplyNamedPlug> plugs,
  required ApplyInstanceSocketState instance,
  required ApplyManifestItemDef itemDef,
  required ApplySocketManifestLookup manifest,
}) {
  final resolved =
      <({ApplyPlugKind kind, int hash, String name, String? skip})>[];
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
    if (instance.ownedPlugHashes.isNotEmpty &&
        !instance.ownedPlugHashes.contains(row.hash)) {
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

    final socketIndex = _pickSocketForKind(
      itemDef: itemDef,
      instance: instance,
      kind: row.kind,
      plugHash: row.hash,
      usedSockets: usedSockets,
    );
    if (socketIndex == null) {
      steps.add(
        ApplyPlugStep(
          id: id,
          label: formatApplyPlugOutcomeLabel(row.kind, row.name),
          kind: row.kind,
          itemInstanceId: instance.instanceId,
          socketIndex: 0,
          plugItemHash: row.hash,
          skipReason: doesNotFitPlugMessage(row.name),
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

List<ApplyPlugStep> _planArmorMods({
  required List<ApplyNamedPlug> targets,
  required List<ApplyArmorPin> equippedArmor,
  required List<ApplyInstanceSocketState> instances,
  required ApplySocketManifestLookup manifest,
}) {
  if (targets.isEmpty || equippedArmor.isEmpty) return const [];

  for (final armor in equippedArmor) {
    final live = _instanceById(instances, armor.instanceId);
    if (live == null || !live.armorModDataKnown) {
      return [
        const ApplyPlugStep(
          id: 'armor-mods:skipped',
          label: 'Mods',
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: 0,
          skipReason: kArmorModsSkippedUnavailableMessage,
        ),
      ];
    }
  }

  final steps = <ApplyPlugStep>[];
  final generalAssigned = <int>{};
  var n = 0;

  for (final plug in targets) {
    n += 1;
    final r = _resolvePlugHash(plug, manifest);
    final name = plug.name.trim();
    if (r.skip != null || r.hash == null) {
      steps.add(
        ApplyPlugStep(
          id: 'armor-mod:skip:$n',
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, name),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: r.hash ?? 0,
          skipReason: r.skip ?? unresolvablePlugMessage(name),
        ),
      );
      continue;
    }
    final def = manifest.plugDef(r.hash!);
    if (def == null ||
        _kindFromPlugCategory(def.plugCategoryIdentifier) !=
            ApplyPlugKind.armorMod) {
      continue;
    }
    final modSlot = armorSlotFromPlugCategory(def.plugCategoryIdentifier);
    if (modSlot == null) {
      steps.add(
        ApplyPlugStep(
          id: 'armor-mod:skip:$n',
          label: formatApplyPlugOutcomeLabel(
            ApplyPlugKind.armorMod,
            name.isNotEmpty ? name : def.name,
          ),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: r.hash!,
          skipReason: doesNotFitPlugMessage(name.isNotEmpty ? name : def.name),
        ),
      );
      continue;
    }

    // General/tuning: exactly one piece (first that accepts the plug).
    if (modSlot == ApplyArmorSlot.general) {
      if (generalAssigned.contains(r.hash!)) continue;
      final placed = _planOneArmorModOnMatchingPiece(
        idPrefix: 'armor-mod:$n',
        plugHash: r.hash!,
        plugName: name.isNotEmpty ? name : def.name,
        cost: def.energyCost,
        modSlot: modSlot,
        anyPiece: true,
        equippedArmor: equippedArmor,
        instances: instances,
        manifest: manifest,
      );
      if (placed != null) {
        generalAssigned.add(r.hash!);
        steps.addAll(placed);
      }
      continue;
    }

    final placed = _planOneArmorModOnMatchingPiece(
      idPrefix: 'armor-mod:$n',
      plugHash: r.hash!,
      plugName: name.isNotEmpty ? name : def.name,
      cost: def.energyCost,
      modSlot: modSlot,
      anyPiece: false,
      equippedArmor: equippedArmor,
      instances: instances,
      manifest: manifest,
    );
    if (placed != null) steps.addAll(placed);
  }
  return steps;
}

List<ApplyPlugStep>? _planOneArmorModOnMatchingPiece({
  required String idPrefix,
  required int plugHash,
  required String plugName,
  required int cost,
  required ApplyArmorSlot modSlot,
  required bool anyPiece,
  required List<ApplyArmorPin> equippedArmor,
  required List<ApplyInstanceSocketState> instances,
  required ApplySocketManifestLookup manifest,
}) {
  for (final armor in equippedArmor) {
    final pieceSlot = armorSlotFromWire(armor.slot);
    if (!anyPiece) {
      if (pieceSlot == null || pieceSlot != modSlot) continue;
    }
    final live = _instanceById(instances, armor.instanceId);
    if (live == null) continue;
    final def = manifest.itemDef(armor.itemHash);
    if (def == null) continue;

    if (live.ownedPlugHashes.isNotEmpty &&
        !live.ownedPlugHashes.contains(plugHash)) {
      return [
        ApplyPlugStep(
          id: idPrefix,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: 0,
          plugItemHash: plugHash,
          skipReason: notUnlockedPlugMessage(plugName),
        ),
      ];
    }

    final modIndexes =
        _indexesForCategories(def, kApplyArmorModSocketCategoryHashes);
    int? socketIndex;
    for (final idx in modIndexes) {
      if (live.equippedPlugBySocket[idx] == plugHash) {
        socketIndex = idx;
        break;
      }
    }
    socketIndex ??= () {
      for (final idx in modIndexes) {
        if (_socketAllowsPlug(
          itemDef: def,
          instance: live,
          socketIndex: idx,
          plugHash: plugHash,
          kind: ApplyPlugKind.armorMod,
        )) {
          return idx;
        }
      }
      return null;
    }();

    if (socketIndex == null) {
      if (anyPiece) continue;
      return [
        ApplyPlugStep(
          id: idPrefix,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: 0,
          plugItemHash: plugHash,
          skipReason: doesNotFitPlugMessage(plugName),
        ),
      ];
    }

    final current = live.equippedPlugBySocket[socketIndex];
    if (current == plugHash) {
      return [
        ApplyPlugStep(
          id: idPrefix,
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: armor.instanceId,
          socketIndex: socketIndex,
          plugItemHash: plugHash,
          currentPlugHash: current,
        ),
      ];
    }

    final currentCost =
        current == null ? 0 : (manifest.plugDef(current)?.energyCost ?? 0);
    var energyUsed = live.energyUsed;
    final capacity = live.energyCapacity;
    final projected = energyUsed - currentCost + cost;

    final clearSteps = <ApplyPlugStep>[];
    String? clearId;
    int? restoreHash;
    int? restoreSocket;
    if (capacity > 0 && projected > capacity) {
      // Tentative clears — only keep them if the insert fits afterward.
      var tentativeEnergy = energyUsed;
      final tentative = <ApplyPlugStep>[];
      for (final idx in modIndexes) {
        if (idx == socketIndex) continue;
        final equipped = live.equippedPlugBySocket[idx];
        if (equipped == null) continue;
        final empty = live.emptyPlugHashBySocket[idx];
        if (empty == null) continue;
        final eqCost = manifest.plugDef(equipped)?.energyCost ?? 0;
        if (eqCost <= 0) continue;
        final tentativeClearId = '$idPrefix:clear:$idx';
        tentative.add(
          ApplyPlugStep(
            id: tentativeClearId,
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
        tentativeEnergy -= eqCost;
        clearId = tentativeClearId;
        restoreHash = equipped;
        restoreSocket = idx;
        if (tentativeEnergy - currentCost + cost <= capacity) break;
      }
      if (tentativeEnergy - currentCost + cost > capacity) {
        // Insert cannot fit — never clear without a planned insert.
        return [
          ApplyPlugStep(
            id: idPrefix,
            label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
            kind: ApplyPlugKind.armorMod,
            itemInstanceId: armor.instanceId,
            socketIndex: socketIndex,
            plugItemHash: plugHash,
            skipReason: notEnoughArmorEnergyMessage(plugName),
          ),
        ];
      }
      clearSteps.addAll(tentative);
    }

    return [
      ...clearSteps,
      ApplyPlugStep(
        id: idPrefix,
        label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
        kind: ApplyPlugKind.armorMod,
        itemInstanceId: armor.instanceId,
        socketIndex: socketIndex,
        plugItemHash: plugHash,
        currentPlugHash: current,
        requiresClearStepId: clearId,
        restorePlugHash: restoreHash,
        restoreSocketIndex: restoreSocket,
        restoreItemInstanceId:
            restoreHash == null ? null : armor.instanceId,
      ),
    ];
  }

  return [
    ApplyPlugStep(
      id: idPrefix,
      label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, plugName),
      kind: ApplyPlugKind.armorMod,
      itemInstanceId: '',
      socketIndex: 0,
      plugItemHash: plugHash,
      skipReason: doesNotFitPlugMessage(plugName),
    ),
  ];
}
