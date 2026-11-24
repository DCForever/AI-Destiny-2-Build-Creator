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
const String kApplyPlugNotUnlockedOrUnknownPrefix = 'Not unlocked or unknown: ';
const String kApplyPlugNotEnoughEnergyPrefix = 'Not enough armor energy: ';
const String kApplyPlugEnergyCostUnknownPrefix = 'Armor energy cost unknown: ';
const String kApplyPlugUnresolvablePrefix = 'Could not resolve: ';
const String kApplyPlugDoesNotFitPrefix = 'Does not fit: ';
const String kApplyNoFragmentSocketPrefix = 'No fragment socket: ';
const String kApplyNoTuningSocketMessage = 'No tuning socket (needs Tier 5)';
const String kApplyAlreadySetMessage = 'Already set';
const String kApplySubclassSocketsUnavailableMessage =
    'Subclass sockets unavailable';
const String kApplySocketDataUnavailableMessage =
    'Socket data unavailable';
const String kArmorModsSkippedUnavailableMessage =
    'Armor mods skipped: mod data unavailable';
const String kApplySocketChangeFailedMessage = 'Socket change failed';
const String kApplySocketClearFailedMessage = 'Clear mod failed';
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

String formatApplyPlugOutcomeLabel(
  ApplyPlugKind kind,
  String plugName, {
  String? target,
  String? labelPrefix,
}) {
  final name = plugName.trim();
  final prefix = (labelPrefix ?? applyPlugKindLabel(kind)).trim();
  final base = name.isEmpty ? prefix : '$prefix: $name';
  final t = target?.trim() ?? '';
  if (t.isEmpty) return base;
  return '$base → $t';
}

String noTuningSocketMessage() => kApplyNoTuningSocketMessage;

String notUnlockedPlugMessage(String name) =>
    '$kApplyPlugNotUnlockedPrefix${name.trim()}';

String notUnlockedOrUnknownPlugMessage(String name) =>
    '$kApplyPlugNotUnlockedOrUnknownPrefix${name.trim()}';

String notEnoughArmorEnergyMessage(String name) =>
    '$kApplyPlugNotEnoughEnergyPrefix${name.trim()}';

String armorEnergyCostUnknownMessage(String name) =>
    '$kApplyPlugEnergyCostUnknownPrefix${name.trim()}';

String unresolvablePlugMessage(String name) =>
    '$kApplyPlugUnresolvablePrefix${name.trim()}';

String doesNotFitPlugMessage(String name) =>
    '$kApplyPlugDoesNotFitPrefix${name.trim()}';

String noFragmentSocketMessage(String name) =>
    '$kApplyNoFragmentSocketPrefix${name.trim()}';

/// One clear that must be restored if a later insert fails (or in-activity).
class ApplySocketRestore {
  const ApplySocketRestore({
    required this.clearStepId,
    required this.itemInstanceId,
    required this.socketIndex,
    required this.plugItemHash,
  });

  final String clearStepId;
  final String itemInstanceId;
  final int socketIndex;
  final int plugItemHash;
}

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
    this.requiresClearStepIds = const [],
    this.restorePlugHash,
    this.restoreSocketIndex,
    this.restoreItemInstanceId,
    this.restores = const [],
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
  /// Prefer [requiresClearStepIds] when multiple clears freed energy.
  final String? requiresClearStepId;

  /// All clear step ids that must succeed before this insert runs.
  final List<String> requiresClearStepIds;

  /// Original plug to restore on [restoreSocketIndex] after a failed insert.
  /// Prefer [restores] when multiple clears must be undone.
  final int? restorePlugHash;
  final int? restoreSocketIndex;
  final String? restoreItemInstanceId;

  /// Every socket clear that must be restored if this insert fails.
  final List<ApplySocketRestore> restores;

  /// Clear ids that gate this insert (list first, else singular).
  List<String> get clearStepIdsRequired {
    if (requiresClearStepIds.isNotEmpty) return requiresClearStepIds;
    final singular = requiresClearStepId;
    return singular == null ? const [] : [singular];
  }

  /// Restore targets (list first, else singular fields).
  List<ApplySocketRestore> get restoreTargets {
    if (restores.isNotEmpty) return restores;
    if (restorePlugHash == null ||
        restoreSocketIndex == null ||
        restoreItemInstanceId == null ||
        restoreItemInstanceId!.isEmpty) {
      return const [];
    }
    return [
      ApplySocketRestore(
        clearStepId: requiresClearStepId ?? '',
        itemInstanceId: restoreItemInstanceId!,
        socketIndex: restoreSocketIndex!,
        plugItemHash: restorePlugHash!,
      ),
    ];
  }

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
    this.energyCost,
    this.fragmentCapacity,
  });

  final int hash;
  final String name;
  final String plugCategoryIdentifier;

  /// Null when the manifest does not know the cost — never treat as 0.
  final int? energyCost;

  /// Aspect-only: fragment slots granted when this aspect is selected.
  final int? fragmentCapacity;
}

/// Minimal item definition for socket-index lookup (fakeable).
class ApplyManifestItemDef {
  const ApplyManifestItemDef({
    required this.hash,
    required this.name,
    this.socketCategories = const [],
    this.allowedPlugHashesBySocket = const {},
    this.socketPlugCategoryHint = const {},
    this.emptyPlugHashBySocket = const {},
  });

  final int hash;
  final String name;
  final List<ApplyManifestSocketCategory> socketCategories;

  /// Reusable / randomized / socketType whitelist per socket index.
  final Map<int, Set<int>> allowedPlugHashesBySocket;

  /// Optional plugCategoryIdentifier hint per socket (from initial plug).
  final Map<int, String> socketPlugCategoryHint;

  /// Empty / clear plug per socket from manifest `singleInitialItemHash` only.
  final Map<int, int> emptyPlugHashBySocket;
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
    this.energyCapacity,
    this.energyUsed,
    this.emptyPlugHashBySocket = const {},
    this.allowedPlugHashesBySocket = const {},
    this.armorModDataKnown = false,
    this.subclassPlugOwnershipKnown = false,
    this.unlockedSocketIndexes,
    this.socketDataKnown = false,
  });

  final String instanceId;
  final int itemHash;
  final int bucketHash;
  final String? characterId;
  final String location;

  /// Equipped plug keyed by socket index (never assume flat plugHashes order).
  final Map<int, int> equippedPlugBySocket;
  final Set<int> ownedPlugHashes;

  /// Instance component 300 `energy.energyCapacity`, or host tier fallback.
  /// Null = capacity unknown — planner skips the local energy gate and lets
  /// Bungie `InsertSocketPlugFree` be the judge.
  final int? energyCapacity;

  /// Instance component 300 `energy.energyUsed`. Null = usage unknown.
  final int? energyUsed;
  final Map<int, int> emptyPlugHashBySocket;
  final Map<int, Set<int>> allowedPlugHashesBySocket;

  /// When false, planner skips all armor-mod steps with fixed text (R3).
  final bool armorModDataKnown;

  /// When false (or [ownedPlugHashes] empty), subclass inserts skip with
  /// [notUnlockedOrUnknownPlugMessage] (F3). Empty owned is UNKNOWN, not open.
  final bool subclassPlugOwnershipKnown;

  /// Live unlocked socket indexes (305 enabled+visible) — not "occupied".
  /// Null means use manifest indexes as-is. Fragment capacity may open more
  /// indexes than this set when target aspects are planned.
  final Set<int>? unlockedSocketIndexes;

  /// False until live socket capture is present (defaults false — Skeptic).
  final bool socketDataKnown;
}

/// Manifest + name lookup ports for [planApplySockets].
class ApplySocketManifestLookup {
  const ApplySocketManifestLookup({
    required this.itemDef,
    required this.plugDef,
    required this.resolveUniquePlugHashByName,
    this.resolvePlugHashesByName,
  });

  final ApplyManifestItemDef? Function(int itemHash) itemDef;
  final ApplyManifestPlugDef? Function(int plugHash) plugDef;
  final int? Function(String name) resolveUniquePlugHashByName;

  /// All hashes sharing a display name (element / Prismatic variants).
  final List<int> Function(String name)? resolvePlugHashesByName;
}

/// Per-socket allowed inserts: manifest plug-set ∩ unlocked, else live 310.
///
/// Plug-set sockets (subclass abilities/aspects, armor mods 0–3) often have an
/// empty component-310 list; callers must supply the definition plug-set and
/// the character/profile unlocked hashes (104/105) so the whitelist is not
/// collapsed to the currently equipped plug alone.
Map<int, Set<int>> buildApplyAllowedPlugHashesBySocket({
  required Map<int, Set<int>> manifestPlugSetBySocket,
  required Map<int, Set<int>> liveReusableBySocket,
  required Map<int, int> equippedBySocket,
  required Set<int> unlockedPlugHashes,
}) {
  final indexes = <int>{
    ...manifestPlugSetBySocket.keys,
    ...liveReusableBySocket.keys,
    ...equippedBySocket.keys,
  };
  final out = <int, Set<int>>{};
  for (final idx in indexes) {
    final manifest = manifestPlugSetBySocket[idx] ?? const <int>{};
    final live = liveReusableBySocket[idx] ?? const <int>{};
    final equipped = equippedBySocket[idx] ?? 0;
    if (manifest.isNotEmpty) {
      final unlocked = <int>{
        ...unlockedPlugHashes,
        ...live,
        if (equipped != 0) equipped,
      };
      final allowed = manifest.intersection(unlocked);
      if (equipped != 0) allowed.add(equipped);
      if (allowed.isNotEmpty) out[idx] = allowed;
    } else {
      final hashes = <int>{
        ...live,
        if (equipped != 0) equipped,
      };
      if (hashes.isNotEmpty) out[idx] = hashes;
    }
  }
  return out;
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
    this.targetSlot,
  });

  final String name;
  final int? hash;

  /// Optional armor wire slot for shaders (`helmet` / …). Null → every piece.
  final String? targetSlot;
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
      if (!subclassInstance.socketDataKnown) {
        subclassPlugs.add(
          ApplyPlugStep(
            id: 'subclass-plugs:socket-data',
            label: 'Subclass plugs',
            kind: ApplyPlugKind.aspect,
            itemInstanceId: subclassInstance.instanceId,
            socketIndex: 0,
            plugItemHash: 0,
            skipReason: kApplySocketDataUnavailableMessage,
          ),
        );
      } else {
        final subclassDef = manifest.itemDef(subclassInstance.itemHash);
        if (subclassDef == null ||
            !_subclassSocketLayoutResolvable(subclassDef)) {
          if (build.subclassPlugs.isNotEmpty) {
            subclassPlugs.add(
              const ApplyPlugStep(
                id: 'subclass-plugs:layout',
                label: 'Subclass plugs',
                kind: ApplyPlugKind.aspect,
                itemInstanceId: '',
                socketIndex: 0,
                plugItemHash: 0,
                skipReason: kApplySubclassSocketsUnavailableMessage,
              ),
            );
          }
        } else {
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

bool isTuningPlugCategory(String cat) => cat.contains('tuning');
bool isShaderPlugCategory(String cat) {
  final c = cat.toLowerCase();
  return c == 'shader' || c.contains('shaders');
}

bool isOrnamentPlugCategory(String cat) {
  final c = cat.toLowerCase();
  return c.contains('ornament') || c.contains('armor_skin');
}

enum _FreePlugKind { tuning, shader, ornament }

_FreePlugKind? _freeKindFromCategory(String cat) {
  if (isShaderPlugCategory(cat)) return _FreePlugKind.shader;
  if (isOrnamentPlugCategory(cat)) return _FreePlugKind.ornament;
  if (isTuningPlugCategory(cat)) return _FreePlugKind.tuning;
  return null;
}

String _freePlugLabelPrefix(_FreePlugKind k) => switch (k) {
      _FreePlugKind.tuning => 'Tuning',
      _FreePlugKind.shader => 'Shader',
      _FreePlugKind.ornament => 'Ornament',
    };

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
  if (RegExp(r'enhancements\.(v2_)?general').hasMatch(cat) ||
      cat.contains('enhancements.universal')) {
    return ApplyArmorSlot.general;
  }
  return null;
}

/// Ornament → armor slot from plug category or display name.
ApplyArmorSlot? ornamentSlotFromCategoryOrName(String cat, String name) {
  final hay = '${cat.toLowerCase()} ${name.toLowerCase()}';
  // Prefer slot tokens over bare "arm" in "armor_skins_*".
  if (RegExp(r'head|helmet|hood|mask|\bhelm\b').hasMatch(hay)) {
    return ApplyArmorSlot.helmet;
  }
  if (RegExp(r'chest|robe|plate|vest').hasMatch(hay)) return ApplyArmorSlot.chest;
  if (RegExp(r'leg|boot|greave').hasMatch(hay)) return ApplyArmorSlot.legs;
  if (RegExp(r'class|bond|mark|cloak').hasMatch(hay)) {
    return ApplyArmorSlot.classItem;
  }
  if (RegExp(r'arms|glove|gauntlet').hasMatch(hay)) return ApplyArmorSlot.arms;
  return null;
}

String armorSlotDisplayName(ApplyArmorSlot s) => switch (s) {
      ApplyArmorSlot.helmet => 'Helmet',
      ApplyArmorSlot.arms => 'Arms',
      ApplyArmorSlot.chest => 'Chest',
      ApplyArmorSlot.legs => 'Legs',
      ApplyArmorSlot.classItem => 'Class item',
      ApplyArmorSlot.general => 'General',
    };

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

/// Map equipment bucket hash → Apply armor wire slot (exotic_armor resolve).
ApplyArmorSlot? armorSlotFromBucketHash(int bucketHash) {
  if (bucketHash == 3448274439) return ApplyArmorSlot.helmet;
  if (bucketHash == 3551918588) return ApplyArmorSlot.arms;
  if (bucketHash == 14239492) return ApplyArmorSlot.chest;
  if (bucketHash == 20886954) return ApplyArmorSlot.legs;
  if (bucketHash == 1585787867) return ApplyArmorSlot.classItem;
  return null;
}

/// Resolve wire slot, mapping `exotic_armor` via the piece's real bucket.
ApplyArmorSlot? resolveArmorSlot({
  required String? wireSlot,
  int? bucketHash,
}) {
  final wire = (wireSlot ?? '').trim().toLowerCase();
  if (wire == 'exotic_armor') {
    return bucketHash == null ? null : armorSlotFromBucketHash(bucketHash);
  }
  final fromWire = armorSlotFromWire(wireSlot);
  if (fromWire != null) return fromWire;
  if (bucketHash != null) return armorSlotFromBucketHash(bucketHash);
  return null;
}

/// Wire name for [ApplyArmorPin.slot] from a resolved [ApplyArmorSlot].
String armorSlotToWire(ApplyArmorSlot slot) {
  switch (slot) {
    case ApplyArmorSlot.helmet:
      return 'helmet';
    case ApplyArmorSlot.arms:
      return 'arms';
    case ApplyArmorSlot.chest:
      return 'chest';
    case ApplyArmorSlot.legs:
      return 'legs';
    case ApplyArmorSlot.classItem:
      return 'class_item';
    case ApplyArmorSlot.general:
      return 'general';
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
  ApplySocketManifestLookup manifest, {
  Set<int> ownedPlugHashes = const {},
  bool ownershipKnown = false,
}) {
  final named = plug.name.trim();
  final h = plug.hash;

  // Prefer the unlocked element/Prismatic sibling when several hashes share
  // a display name (Empowering Rift, Feed the Void, …).
  final nameForVariants = named.isNotEmpty
      ? named
      : (h != null && h != 0 ? (manifest.plugDef(h)?.name ?? '') : '');
  final variants = nameForVariants.isEmpty
      ? const <int>[]
      : (manifest.resolvePlugHashesByName?.call(nameForVariants) ??
          const <int>[]);
  if (variants.length > 1) {
    final picked = _pickOwnedVariant(
      variants: variants,
      preferredHash: h,
      ownedPlugHashes: ownedPlugHashes,
      ownershipKnown: ownershipKnown,
    );
    if (picked != null) return (hash: picked, skip: null);
  }

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

int? _pickOwnedVariant({
  required List<int> variants,
  required int? preferredHash,
  required Set<int> ownedPlugHashes,
  required bool ownershipKnown,
}) {
  if (!ownershipKnown || ownedPlugHashes.isEmpty) {
    if (preferredHash != null &&
        preferredHash != 0 &&
        variants.contains(preferredHash)) {
      return preferredHash;
    }
    return null;
  }
  final owned = [
    for (final v in variants)
      if (ownedPlugHashes.contains(v)) v,
  ];
  if (owned.isEmpty) return null;
  if (preferredHash != null && owned.contains(preferredHash)) {
    return preferredHash;
  }
  return owned.first;
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

bool _subclassSocketLayoutResolvable(ApplyManifestItemDef itemDef) {
  // Need at least one known subclass socket category from the manifest /
  // live layout — never invent hard-coded indexes here.
  return itemDef.socketCategories.isNotEmpty &&
      (_indexesForCategories(itemDef, kApplySuperSocketCategoryHashes)
              .isNotEmpty ||
          _indexesForCategories(itemDef, kApplyAbilitySocketCategoryHashes)
              .isNotEmpty ||
          _indexesForCategories(itemDef, kApplyAspectSocketCategoryHashes)
              .isNotEmpty ||
          _indexesForCategories(itemDef, kApplyFragmentSocketCategoryHashes)
              .isNotEmpty);
}

List<int> _unlockedIndexesForKind({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required ApplyPlugKind kind,
}) {
  final indexes = _indexesForKind(itemDef, kind);
  final unlocked = instance.unlockedSocketIndexes;
  if (unlocked == null) return indexes;
  return [for (final idx in indexes) if (unlocked.contains(idx)) idx];
}

int? _pickSocketForKind({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required ApplyPlugKind kind,
  required int plugHash,
  required Set<int> usedSockets,
  List<int>? indexesOverride,
}) {
  final indexes =
      indexesOverride ?? _unlockedIndexesForKind(
        itemDef: itemDef,
        instance: instance,
        kind: kind,
      );
  // Prefer an already-equipped match for THIS plug (may already be reserved
  // for it). Free fills below must not steal reserved sockets (F1).
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

/// Reserve every socket that already holds a wanted plug before free fills
/// so a later wanted no-op is not overwritten (F1).
Set<int> _reserveWantedSockets({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required List<({ApplyPlugKind kind, int hash, String name, String? skip})>
      resolved,
}) {
  final reserved = <int>{};
  for (final row in resolved) {
    if (row.skip != null || row.hash == 0) continue;
    // Use full kind indexes (not live-unlocked only) so an already-equipped
    // fragment on a capacity-opened socket is reserved before free fills.
    final indexes = _indexesForKind(itemDef, row.kind);
    for (final idx in indexes) {
      if (instance.equippedPlugBySocket[idx] == row.hash) {
        reserved.add(idx);
      }
    }
  }
  return reserved;
}

/// Fragment socket indexes sized from target aspects when capacity is known.
///
/// Falls back to the live unlocked fragment list when aspect capacity is
/// unresolved (keeps Prismatic/F2 fail-closed behavior).
List<int> _fragmentIndexesForPlan({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required ApplySocketManifestLookup manifest,
  required List<({ApplyPlugKind kind, int hash, String name, String? skip})>
      resolved,
}) {
  final all = _indexesForKind(itemDef, ApplyPlugKind.fragment);
  if (all.isEmpty) return const [];

  final aspectHashes = <int>{
    for (final row in resolved)
      if (row.kind == ApplyPlugKind.aspect &&
          row.skip == null &&
          row.hash != 0)
        row.hash,
  };
  if (aspectHashes.isEmpty) {
    for (final idx
        in _indexesForKind(itemDef, ApplyPlugKind.aspect)) {
      final h = instance.equippedPlugBySocket[idx];
      if (h != null && h != 0) aspectHashes.add(h);
    }
  }

  var capacity = 0;
  var capacityResolved = false;
  for (final h in aspectHashes) {
    final cap = manifest.plugDef(h)?.fragmentCapacity;
    if (cap != null) {
      capacity += cap;
      capacityResolved = true;
    }
  }
  if (capacityResolved) {
    if (capacity <= 0) return const [];
    return all.take(capacity).toList();
  }
  return _unlockedIndexesForKind(
    itemDef: itemDef,
    instance: instance,
    kind: ApplyPlugKind.fragment,
  );
}

List<ApplyPlugStep> _planSubclassPlugs({
  required List<ApplyNamedPlug> plugs,
  required ApplyInstanceSocketState instance,
  required ApplyManifestItemDef itemDef,
  required ApplySocketManifestLookup manifest,
}) {
  final ownershipKnown = instance.subclassPlugOwnershipKnown &&
      instance.ownedPlugHashes.isNotEmpty;
  final resolved =
      <({ApplyPlugKind kind, int hash, String name, String? skip})>[];
  for (final plug in plugs) {
    final r = _resolvePlugHash(
      plug,
      manifest,
      ownedPlugHashes: instance.ownedPlugHashes,
      ownershipKnown: ownershipKnown,
    );
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
      // Visible skip — never silent for a wanted hash that is not a subclass
      // plug (or not found in the manifest).
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

  // F1: reserve sockets already holding a wanted plug before assigning frees.
  final usedSockets = _reserveWantedSockets(
    itemDef: itemDef,
    instance: instance,
    resolved: resolved,
  );
  // Fragments after aspects: size slots from target aspect capacity so
  // pre-Apply unlocked indexes (still empty until aspects insert) do not
  // cut extras with "No fragment socket".
  final fragmentIndexes = _fragmentIndexesForPlan(
    itemDef: itemDef,
    instance: instance,
    manifest: manifest,
    resolved: resolved,
  );
  var fragmentPlaced = 0;
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

    final alreadyAt = () {
      for (final idx in _indexesForKind(itemDef, row.kind)) {
        if (instance.equippedPlugBySocket[idx] == row.hash) return idx;
      }
      return null;
    }();

    // Ownership: empty/unknown owned set is UNKNOWN (F3), not fail-open.
    // Already-equipped no-ops do not require an ownership proof.
    if (alreadyAt == null) {
      if (!ownershipKnown) {
        steps.add(
          ApplyPlugStep(
            id: id,
            label: formatApplyPlugOutcomeLabel(row.kind, row.name),
            kind: row.kind,
            itemInstanceId: instance.instanceId,
            socketIndex: 0,
            plugItemHash: row.hash,
            skipReason: notUnlockedOrUnknownPlugMessage(row.name),
          ),
        );
        continue;
      }
      if (!instance.ownedPlugHashes.contains(row.hash)) {
        steps.add(
          ApplyPlugStep(
            id: id,
            label: formatApplyPlugOutcomeLabel(row.kind, row.name),
            kind: row.kind,
            itemInstanceId: instance.instanceId,
            socketIndex: 0,
            plugItemHash: row.hash,
            skipReason: notUnlockedOrUnknownPlugMessage(row.name),
          ),
        );
        continue;
      }
    }

    if (row.kind == ApplyPlugKind.fragment) {
      // Extras beyond unlocked fragment slots → fixed skip (F2).
      if (alreadyAt == null && fragmentPlaced >= fragmentIndexes.length) {
        steps.add(
          ApplyPlugStep(
            id: id,
            label: formatApplyPlugOutcomeLabel(row.kind, row.name),
            kind: row.kind,
            itemInstanceId: instance.instanceId,
            socketIndex: 0,
            plugItemHash: row.hash,
            skipReason: noFragmentSocketMessage(row.name),
          ),
        );
        continue;
      }
    }

    final socketIndex = _pickSocketForKind(
      itemDef: itemDef,
      instance: instance,
      kind: row.kind,
      plugHash: row.hash,
      usedSockets: usedSockets,
      indexesOverride: row.kind == ApplyPlugKind.fragment
          ? fragmentIndexes
          : null,
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
          skipReason: row.kind == ApplyPlugKind.fragment
              ? noFragmentSocketMessage(row.name)
              : doesNotFitPlugMessage(row.name),
        ),
      );
      continue;
    }
    usedSockets.add(socketIndex);
    if (row.kind == ApplyPlugKind.fragment) fragmentPlaced += 1;
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

/// Keeps subclass work; armor-mod steps for instances that did not equip are
/// converted to fixed-text skips (prebuilt plans must not bypass the equipped
/// filter).
ApplySocketPlan filterApplySocketPlanToEquipped(
  ApplySocketPlan plan,
  Iterable<String> successfullyEquippedInstanceIds,
) {
  final ids = successfullyEquippedInstanceIds.toSet();
  return ApplySocketPlan(
    subclass: plan.subclass,
    subclassAlreadyEquipped: plan.subclassAlreadyEquipped,
    subclassMissingReason: plan.subclassMissingReason,
    subclassPlugs: plan.subclassPlugs,
    armorMods: [
      for (final step in plan.armorMods)
        if (step.skipReason != null ||
            step.itemInstanceId.isEmpty ||
            ids.contains(step.itemInstanceId))
          step
        else
          ApplyPlugStep(
            id: step.id,
            label: step.label,
            kind: step.kind,
            itemInstanceId: step.itemInstanceId,
            socketIndex: step.socketIndex,
            plugItemHash: step.plugItemHash,
            currentPlugHash: step.currentPlugHash,
            skipReason: 'Item not equipped',
          ),
    ],
  );
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
      // F4: armor path stays off until the host marks live socket/energy known.
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
  // Per-piece used sockets + running energy so two mods on one piece never
  // double-assign a socket or exceed capacity across the plan.
  final usedSocketsByPiece = <String, Set<int>>{};
  final energyUsedByPiece = <String, int>{};
  // Shaders may appear once per armor in DIM lists — plan each hash once.
  final plannedShaderHashes = <int>{};
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
    final displayName = name.isNotEmpty ? name : (def?.name ?? '${r.hash}');
    final freeKind =
        def == null ? null : _freeKindFromCategory(def.plugCategoryIdentifier);
    if (freeKind != null) {
      if (freeKind == _FreePlugKind.shader &&
          plannedShaderHashes.contains(r.hash!)) {
        continue;
      }
      final planned = _planFreeCosmeticOrTuning(
        idPrefix: 'armor-mod:$n',
        freeKind: freeKind,
        plugHash: r.hash!,
        plugName: displayName,
        plugCategory: def!.plugCategoryIdentifier,
        shaderTargetSlot: armorSlotFromWire(plug.targetSlot),
        equippedArmor: equippedArmor,
        instances: instances,
        manifest: manifest,
        usedSocketsByPiece: usedSocketsByPiece,
      );
      if (freeKind == _FreePlugKind.shader) {
        plannedShaderHashes.add(r.hash!);
      }
      steps.addAll(planned);
      continue;
    }
    if (def == null ||
        _kindFromPlugCategory(def.plugCategoryIdentifier) !=
            ApplyPlugKind.armorMod) {
      steps.add(
        ApplyPlugStep(
          id: 'armor-mod:skip:$n',
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, displayName),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: r.hash!,
          skipReason: unresolvablePlugMessage(displayName),
        ),
      );
      continue;
    }

    final modSlot = armorSlotFromPlugCategory(def.plugCategoryIdentifier);
    if (modSlot == null) {
      steps.add(
        ApplyPlugStep(
          id: 'armor-mod:skip:$n',
          label: formatApplyPlugOutcomeLabel(
            ApplyPlugKind.armorMod,
            displayName,
          ),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: r.hash!,
          skipReason: doesNotFitPlugMessage(displayName),
        ),
      );
      continue;
    }

    final cost = def.energyCost;
    if (cost == null) {
      steps.add(
        ApplyPlugStep(
          id: 'armor-mod:skip:$n',
          label: formatApplyPlugOutcomeLabel(ApplyPlugKind.armorMod, displayName),
          kind: ApplyPlugKind.armorMod,
          itemInstanceId: '',
          socketIndex: 0,
          plugItemHash: r.hash!,
          skipReason: armorEnergyCostUnknownMessage(displayName),
        ),
      );
      continue;
    }

    // General: exactly one piece (first that accepts the plug).
    if (modSlot == ApplyArmorSlot.general) {
      if (generalAssigned.contains(r.hash!)) continue;
      final placed = _planOneArmorModOnMatchingPiece(
        idPrefix: 'armor-mod:$n',
        plugHash: r.hash!,
        plugName: displayName,
        cost: cost,
        modSlot: modSlot,
        anyPiece: true,
        equippedArmor: equippedArmor,
        instances: instances,
        manifest: manifest,
        usedSocketsByPiece: usedSocketsByPiece,
        energyUsedByPiece: energyUsedByPiece,
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
      plugName: displayName,
      cost: cost,
      modSlot: modSlot,
      anyPiece: false,
      equippedArmor: equippedArmor,
      instances: instances,
      manifest: manifest,
      usedSocketsByPiece: usedSocketsByPiece,
      energyUsedByPiece: energyUsedByPiece,
    );
    if (placed != null) steps.addAll(placed);
  }
  return steps;
}

/// Socket index that already holds [plugHash] under a matching free category.
int? _findEquippedFreeSocket({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required int plugHash,
  required bool Function(String cat) categoryMatch,
}) {
  for (final e in instance.equippedPlugBySocket.entries) {
    if (e.value != plugHash) continue;
    final hint = itemDef.socketPlugCategoryHint[e.key];
    if (hint != null && categoryMatch(hint)) return e.key;
    final allowed = instance.allowedPlugHashesBySocket[e.key] ??
        itemDef.allowedPlugHashesBySocket[e.key];
    if (allowed != null && allowed.contains(plugHash)) return e.key;
  }
  return null;
}

/// Socket by category hint or allowed whitelist — never a hard-coded index.
int? _pickSocketByCategoryOrAllowList({
  required ApplyManifestItemDef itemDef,
  required ApplyInstanceSocketState instance,
  required int plugHash,
  required bool Function(String cat) categoryMatch,
  required Set<int> usedSockets,
}) {
  for (final map in [
    instance.allowedPlugHashesBySocket,
    itemDef.allowedPlugHashesBySocket,
  ]) {
    for (final e in map.entries) {
      if (!usedSockets.contains(e.key) && e.value.contains(plugHash)) {
        return e.key;
      }
    }
  }
  for (final e in itemDef.socketPlugCategoryHint.entries) {
    if (usedSockets.contains(e.key) || !categoryMatch(e.value)) continue;
    final allowed = instance.allowedPlugHashesBySocket[e.key] ??
        itemDef.allowedPlugHashesBySocket[e.key];
    // Fail closed: null/empty allow list must not accept a category-hint socket
    // (Skeptic should-fix from PR 71). Caller surfaces Does not fit.
    if (allowed == null || allowed.isEmpty || !allowed.contains(plugHash)) {
      continue;
    }
    return e.key;
  }
  return null;
}

ApplyPlugStep _freePlugStep({
  required String id,
  required _FreePlugKind freeKind,
  required String plugName,
  required int plugHash,
  String itemInstanceId = '',
  int socketIndex = 0,
  int? currentPlugHash,
  String? target,
  String? skipReason,
}) =>
    ApplyPlugStep(
      id: id,
      label: formatApplyPlugOutcomeLabel(
        ApplyPlugKind.armorMod,
        plugName,
        target: target,
        labelPrefix: _freePlugLabelPrefix(freeKind),
      ),
      kind: ApplyPlugKind.armorMod,
      itemInstanceId: itemInstanceId,
      socketIndex: socketIndex,
      plugItemHash: plugHash,
      currentPlugHash: currentPlugHash,
      skipReason: skipReason,
    );

/// Tuning / shader / ornament inserts (InsertSocketPlugFree; no energy clears).
List<ApplyPlugStep> _planFreeCosmeticOrTuning({
  required String idPrefix,
  required _FreePlugKind freeKind,
  required int plugHash,
  required String plugName,
  required String plugCategory,
  required ApplyArmorSlot? shaderTargetSlot,
  required List<ApplyArmorPin> equippedArmor,
  required List<ApplyInstanceSocketState> instances,
  required ApplySocketManifestLookup manifest,
  required Map<String, Set<int>> usedSocketsByPiece,
}) {
  final match = switch (freeKind) {
    _FreePlugKind.tuning => isTuningPlugCategory,
    _FreePlugKind.shader => isShaderPlugCategory,
    _FreePlugKind.ornament => isOrnamentPlugCategory,
  };
  final ornamentSlot = freeKind == _FreePlugKind.ornament
      ? ornamentSlotFromCategoryOrName(plugCategory, plugName)
      : null;
  if (freeKind == _FreePlugKind.ornament && ornamentSlot == null) {
    return [
      _freePlugStep(
        id: idPrefix,
        freeKind: freeKind,
        plugName: plugName,
        plugHash: plugHash,
        skipReason: doesNotFitPlugMessage(plugName),
      ),
    ];
  }
  final out = <ApplyPlugStep>[];
  var i = 0;
  for (final armor in equippedArmor) {
    final live = _instanceById(instances, armor.instanceId);
    if (live == null) continue;
    final pieceSlot = resolveArmorSlot(
      wireSlot: armor.slot,
      bucketHash: live.bucketHash,
    );
    if (freeKind == _FreePlugKind.ornament && pieceSlot != ornamentSlot) {
      continue;
    }
    if (freeKind == _FreePlugKind.shader &&
        shaderTargetSlot != null &&
        pieceSlot != shaderTargetSlot) {
      continue;
    }
    final def = manifest.itemDef(armor.itemHash);
    if (def == null) continue;
    final used =
        usedSocketsByPiece.putIfAbsent(armor.instanceId, () => <int>{});
    final socketIndex = _pickSocketByCategoryOrAllowList(
      itemDef: def,
      instance: live,
      plugHash: plugHash,
      categoryMatch: match,
      usedSockets: used,
    );
    final slot = pieceSlot ?? ornamentSlot;
    final target = slot == null
        ? armor.label
        : '${armorSlotDisplayName(slot)} (${armor.label})';
    i += 1;
    final id = freeKind == _FreePlugKind.shader ? '$idPrefix:s:$i' : idPrefix;
    if (socketIndex == null) {
      if (freeKind == _FreePlugKind.tuning) continue;
      // Shader/ornament: prefer Already set when the plug is already on this
      // piece; never emit Does not fit for a duplicate plan of the same plug.
      final alreadyAt = _findEquippedFreeSocket(
        itemDef: def,
        instance: live,
        plugHash: plugHash,
        categoryMatch: match,
      );
      if (alreadyAt != null) {
        out.add(
          _freePlugStep(
            id: id,
            freeKind: freeKind,
            plugName: plugName,
            plugHash: plugHash,
            itemInstanceId: armor.instanceId,
            socketIndex: alreadyAt,
            currentPlugHash: plugHash,
            target: target,
          ),
        );
        if (freeKind != _FreePlugKind.shader) return out;
        continue;
      }
      if (freeKind == _FreePlugKind.shader) continue;
      out.add(
        _freePlugStep(
          id: id,
          freeKind: freeKind,
          plugName: plugName,
          plugHash: plugHash,
          itemInstanceId: armor.instanceId,
          target: target,
          skipReason: doesNotFitPlugMessage(plugName),
        ),
      );
      return out;
    }
    final alreadyEquipped =
        live.equippedPlugBySocket[socketIndex] == plugHash;
    // Ownership: host fills ownedPlugHashes from 310 reusable + 104/105, and
    // live allowedPlugHashesBySocket is already plug-set ∩ unlocked. Do not
    // treat the raw manifest def allow list as owned (that set is unfiltered).
    // Fail closed when both sources are empty or the plug is in neither.
    if (!alreadyEquipped) {
      final allowed =
          live.allowedPlugHashesBySocket[socketIndex] ?? const <int>{};
      final owned = live.ownedPlugHashes;
      final known = owned.isNotEmpty || allowed.isNotEmpty;
      final unlocked =
          owned.contains(plugHash) || allowed.contains(plugHash);
      if (!known || !unlocked) {
        out.add(
          _freePlugStep(
            id: id,
            freeKind: freeKind,
            plugName: plugName,
            plugHash: plugHash,
            itemInstanceId: armor.instanceId,
            socketIndex: socketIndex,
            target: target,
            skipReason: notUnlockedPlugMessage(plugName),
          ),
        );
        if (freeKind != _FreePlugKind.shader) return out;
        continue;
      }
    }
    used.add(socketIndex);
    out.add(
      _freePlugStep(
        id: id,
        freeKind: freeKind,
        plugName: plugName,
        plugHash: plugHash,
        itemInstanceId: armor.instanceId,
        socketIndex: socketIndex,
        currentPlugHash: live.equippedPlugBySocket[socketIndex],
        target: target,
      ),
    );
    if (freeKind != _FreePlugKind.shader) return out;
  }
  if (out.isNotEmpty) return out;
  return [
    _freePlugStep(
      id: idPrefix,
      freeKind: freeKind,
      plugName: plugName,
      plugHash: plugHash,
      target: ornamentSlot == null ? null : armorSlotDisplayName(ornamentSlot),
      skipReason: freeKind == _FreePlugKind.tuning
          ? noTuningSocketMessage()
          : doesNotFitPlugMessage(plugName),
    ),
  ];
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
  required Map<String, Set<int>> usedSocketsByPiece,
  required Map<String, int> energyUsedByPiece,
}) {
  for (final armor in equippedArmor) {
    final live = _instanceById(instances, armor.instanceId);
    if (live == null) continue;
    final pieceSlot = resolveArmorSlot(
      wireSlot: armor.slot,
      bucketHash: live.bucketHash,
    );
    if (!anyPiece) {
      if (pieceSlot == null || pieceSlot != modSlot) continue;
    }
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

    final usedSockets =
        usedSocketsByPiece.putIfAbsent(armor.instanceId, () => <int>{});
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
        if (usedSockets.contains(idx)) continue;
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
      usedSockets.add(socketIndex);
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

    // Empty plug comes from manifest singleInitialItemHash (via host) only —
    // never invent from a zero/unknown-cost 310 plug (M1).
    final emptyBySocket = <int, int>{
      ...def.emptyPlugHashBySocket,
      ...live.emptyPlugHashBySocket,
    };

    final capacity = live.energyCapacity;
    final baselineUsed =
        energyUsedByPiece[armor.instanceId] ?? live.energyUsed;
    // Local energy math only when both capacity and usage are known.
    // Otherwise plan the insert and let InsertSocketPlugFree judge.

    // Outgoing plug cost: empty/default sockets ("Empty Mod Socket") and any
    // plug whose def lacks energyCost count as 0 — never fail the insert on
    // the plug being replaced.
    final currentCost = () {
      if (current == null || current == 0) return 0;
      return manifest.plugDef(current)?.energyCost ?? 0;
    }();

    final clearSteps = <ApplyPlugStep>[];
    final restoreTargets = <ApplySocketRestore>[];
    final clearIds = <String>[];
    if (capacity != null && baselineUsed != null) {
      final knownCapacity = capacity;
      var energyUsed = baselineUsed;
      final projected = energyUsed - currentCost + cost;
      if (projected > knownCapacity) {
        // Tentative clears — only keep them if the insert fits afterward.
        var tentativeEnergy = energyUsed;
        final tentative = <ApplyPlugStep>[];
        final tentativeRestores = <ApplySocketRestore>[];
        final tentativeClearIds = <String>[];
        for (final idx in modIndexes) {
          if (idx == socketIndex) continue;
          if (usedSockets.contains(idx)) continue;
          final equipped = live.equippedPlugBySocket[idx];
          if (equipped == null || equipped == 0) continue;
          final empty = emptyBySocket[idx];
          if (empty == null || empty == 0) continue;
          final eqCost = manifest.plugDef(equipped)?.energyCost;
          // Unknown cost on an equipped mod ⇒ cannot safely clear for energy.
          if (eqCost == null) {
            return [
              ApplyPlugStep(
                id: idPrefix,
                label: formatApplyPlugOutcomeLabel(
                  ApplyPlugKind.armorMod,
                  plugName,
                ),
                kind: ApplyPlugKind.armorMod,
                itemInstanceId: armor.instanceId,
                socketIndex: socketIndex,
                plugItemHash: plugHash,
                skipReason: armorEnergyCostUnknownMessage(
                  manifest.plugDef(equipped)?.name ?? '$equipped',
                ),
              ),
            ];
          }
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
          tentativeRestores.add(
            ApplySocketRestore(
              clearStepId: tentativeClearId,
              itemInstanceId: armor.instanceId,
              socketIndex: idx,
              plugItemHash: equipped,
            ),
          );
          tentativeClearIds.add(tentativeClearId);
          tentativeEnergy -= eqCost;
          if (tentativeEnergy - currentCost + cost <= knownCapacity) break;
        }
        if (tentativeEnergy - currentCost + cost > knownCapacity) {
          // Insert cannot fit — never clear without a planned insert.
          return [
            ApplyPlugStep(
              id: idPrefix,
              label: formatApplyPlugOutcomeLabel(
                ApplyPlugKind.armorMod,
                plugName,
              ),
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: armor.instanceId,
              socketIndex: socketIndex,
              plugItemHash: plugHash,
              skipReason: notEnoughArmorEnergyMessage(plugName),
            ),
          ];
        }
        clearSteps.addAll(tentative);
        restoreTargets.addAll(tentativeRestores);
        clearIds.addAll(tentativeClearIds);
        for (final clear in tentative) {
          usedSockets.add(clear.socketIndex);
        }
        energyUsed = tentativeEnergy;
      }
      energyUsedByPiece[armor.instanceId] = energyUsed - currentCost + cost;
    }

    usedSockets.add(socketIndex);

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
        requiresClearStepId: clearIds.isEmpty ? null : clearIds.last,
        requiresClearStepIds: clearIds,
        restorePlugHash:
            restoreTargets.isEmpty ? null : restoreTargets.last.plugItemHash,
        restoreSocketIndex:
            restoreTargets.isEmpty ? null : restoreTargets.last.socketIndex,
        restoreItemInstanceId:
            restoreTargets.isEmpty ? null : armor.instanceId,
        restores: restoreTargets,
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
