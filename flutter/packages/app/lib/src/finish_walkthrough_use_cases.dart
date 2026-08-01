/// Finish walkthrough mutations: one-tap create-set-attach + capture-from-build.
///
/// Mirrors product `createSetAndAttach` / `createSetsFromBuild` (BR-BLD-008).
/// Soft never auto-applies. Confirm-only optimizer apply lives elsewhere.
library;

import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

import 'attachment_use_cases.dart';
import 'clock_ids.dart';
import 'errors.dart';
import 'optimizer_constraints_json.dart';
import 'set_use_cases.dart';

const Map<SetType, String> kFinishSetTypeLabels = {
  SetType.armor: 'Armor',
  SetType.weapon: 'Weapons',
  SetType.mod: 'Mods',
  SetType.pair: 'Pair',
  SetType.fashion: 'Fashion',
};

/// Input for one-tap empty set create + optional live attach.
class CreateSetAndAttachCommand {
  const CreateSetAndAttachCommand({
    required this.buildId,
    required this.variantId,
    required this.type,
    this.name,
    this.tagIds = const [],
    this.attachNow = true,
    this.optimizerConstraints,
  });

  final String buildId;
  final String variantId;
  final SetType type;
  final String? name;
  final List<String> tagIds;
  final bool attachNow;
  final String? optimizerConstraints;
}

class CreateSetAndAttachResult {
  const CreateSetAndAttachResult({
    required this.set,
    this.attachmentSetId,
    this.replacedSetIds = const [],
  });

  final SetDetail set;
  final String? attachmentSetId;
  final List<String> replacedSetIds;
}

/// Claim used when capturing resolved gear into a set.
class CaptureClaim {
  const CaptureClaim({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.selectedPerks = const [],
  });

  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;
  final List<int> selectedPerks;
}

/// Input for capture-from-build (create sets from claims + attach).
class CreateSetsFromBuildCommand {
  const CreateSetsFromBuildCommand({
    required this.buildId,
    required this.variantId,
    required this.categories,
    this.claimsByCategory = const {},
    this.attachNow = true,
    this.namePrefix,
    this.armorOptimizerConstraints,
  });

  final String buildId;
  final String variantId;
  final List<FinishCategory> categories;

  /// armor/weapon → claims. Mod typically empty (product skips).
  final Map<FinishCategory, List<CaptureClaim>> claimsByCategory;
  final bool attachNow;
  final String? namePrefix;
  final String? armorOptimizerConstraints;
}

class CreatedSetSummary {
  const CreatedSetSummary({
    required this.id,
    required this.type,
    required this.name,
  });

  final String id;
  final SetType type;
  final String name;
}

class CreateSetsFromBuildResult {
  const CreateSetsFromBuildResult({
    required this.createdSets,
    required this.skippedCategories,
  });

  final List<CreatedSetSummary> createdSets;
  final List<FinishCategory> skippedCategories;
}

Future<String> allocateUniqueSetName(
  AppDatabase db,
  int userId,
  SetType type,
  String preferred, {
  NowClock now = defaultNow,
}) async {
  final base = preferred.trim();
  if (base.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Set name must not be empty',
    );
  }
  final typeWire = type.wireName;
  if (!await findDuplicateSetName(db, userId, type: typeWire, name: base)) {
    return base;
  }
  for (var i = 2; i < 1000; i++) {
    final candidate = '$base ($i)';
    if (!await findDuplicateSetName(
      db,
      userId,
      type: typeWire,
      name: candidate,
    )) {
      return candidate;
    }
  }
  throw UseCaseException(
    UseCaseErrorCode.duplicateSetName,
    'Could not allocate unique set name',
    details: {'name': base},
  );
}

String defaultFinishSetName(String buildName, SetType type) {
  final label = kFinishSetTypeLabels[type] ?? type.wireName;
  final prefix = buildName.trim().isEmpty ? 'Build' : buildName.trim();
  return '$prefix $label';
}

/// Create an empty library set and optionally live-attach replace-by-type.
Future<CreateSetAndAttachResult> createSetAndAttach(
  AppDatabase db,
  int userId,
  CreateSetAndAttachCommand command, {
  String? buildName,
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final build = await getBuild(db, userId, command.buildId);
  if (build == null) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Build not found',
      details: {'buildId': command.buildId},
    );
  }
  final variant = await getVariant(db, command.buildId, command.variantId);
  if (variant == null) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Variant not found',
      details: {
        'buildId': command.buildId,
        'variantId': command.variantId,
      },
    );
  }

  final baseName = command.name?.trim().isNotEmpty == true
      ? command.name!.trim()
      : defaultFinishSetName(buildName ?? build.name, command.type);
  final name = await allocateUniqueSetName(db, userId, command.type, baseName);
  final setId = newId();

  final detail = await createUserSet(
    db,
    userId,
    CreateSetCommand(
      id: setId,
      name: name,
      type: command.type,
      tagIds: command.tagIds,
      optimizerConstraints: command.optimizerConstraints,
    ),
    now: now,
    newId: newId,
  );

  if (!command.attachNow) {
    return CreateSetAndAttachResult(set: detail);
  }

  final before = await listAttachments(db, command.variantId);
  final replaced = <String>[];
  for (final att in before) {
    final set = await getSet(db, userId, att.setId);
    if (set?.type == command.type.wireName) {
      replaced.add(att.setId);
    }
  }

  await replaceAttachmentByType(
    db,
    userId,
    command.variantId,
    command.type,
    setId,
    now: now,
  );

  return CreateSetAndAttachResult(
    set: detail,
    attachmentSetId: setId,
    replacedSetIds: replaced,
  );
}

SetType _setTypeForCategory(FinishCategory category) {
  switch (category) {
    case FinishCategory.armor:
      return SetType.armor;
    case FinishCategory.weapon:
      return SetType.weapon;
    case FinishCategory.mod:
      return SetType.mod;
  }
}

/// Capture resolved claims into library set(s) and live-attach.
///
/// Mod with no claims is skipped (product parity). Throws when nothing created.
Future<CreateSetsFromBuildResult> createSetsFromBuild(
  AppDatabase db,
  int userId,
  CreateSetsFromBuildCommand command, {
  String? buildName,
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final build = await getBuild(db, userId, command.buildId);
  if (build == null) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Build not found',
      details: {'buildId': command.buildId},
    );
  }
  final variant = await getVariant(db, command.buildId, command.variantId);
  if (variant == null) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Variant not found',
      details: {
        'buildId': command.buildId,
        'variantId': command.variantId,
      },
    );
  }

  final prefix =
      (command.namePrefix?.trim().isNotEmpty == true
              ? command.namePrefix!.trim()
              : (buildName ?? build.name).trim())
          .ifEmpty('Build');

  final created = <CreatedSetSummary>[];
  final skipped = <FinishCategory>[];

  for (final category in command.categories) {
    if (category == FinishCategory.mod) {
      final modClaims = command.claimsByCategory[category] ?? const [];
      if (modClaims.isEmpty) {
        skipped.add(category);
        continue;
      }
    }

    final claims = command.claimsByCategory[category] ?? const [];
    if (claims.isEmpty) {
      skipped.add(category);
      continue;
    }

    final type = _setTypeForCategory(category);
    final label = kFinishSetTypeLabels[type] ?? type.wireName;
    final name = await allocateUniqueSetName(
      db,
      userId,
      type,
      '$prefix $label',
    );
    final setId = newId();

    String? constraints;
    if (type == SetType.armor) {
      constraints = command.armorOptimizerConstraints ??
          serializeOptimizerConstraints(
            seedConstraintsFromBuild(
              exoticArmorHash: build.exoticArmorHash,
              softStatTargets: _softTargetsAsIntMap(build.softStatTargets),
            ),
          );
    }

    await createUserSet(
      db,
      userId,
      CreateSetCommand(
        id: setId,
        name: name,
        type: type,
        tagIds: const [],
        optimizerConstraints: constraints,
      ),
      now: now,
      newId: newId,
    );

    for (final claim in claims) {
      await upsertUserSetItem(
        db,
        userId,
        setId,
        UpsertSetItemCommand(
          slot: claim.slot,
          itemHash: claim.itemHash,
          itemName: claim.itemName,
          instanceId: claim.instanceId,
          selectedPerks: claim.selectedPerks,
          replaceExisting: true,
        ),
        now: now,
        newId: newId,
      );
    }

    if (command.attachNow) {
      await replaceAttachmentByType(
        db,
        userId,
        command.variantId,
        type,
        setId,
        now: now,
      );
    }

    created.add(CreatedSetSummary(id: setId, type: type, name: name));
  }

  if (created.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'NOTHING_TO_CREATE',
      details: {
        'skippedCategories': [for (final c in skipped) c.wireName],
      },
    );
  }

  return CreateSetsFromBuildResult(
    createdSets: created,
    skippedCategories: skipped,
  );
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

Map<String, int>? _softTargetsAsIntMap(Map<String, Object?> raw) {
  if (raw.isEmpty) return null;
  final out = <String, int>{};
  raw.forEach((k, v) {
    if (v is int) {
      out[k] = v;
    } else if (v is num) {
      out[k] = v.toInt();
    } else if (v is String) {
      final n = int.tryParse(v);
      if (n != null) out[k] = n;
    }
  });
  return out.isEmpty ? null : out;
}
