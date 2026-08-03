/// Client-side compose hard-block aggregation for host UX (DART-064).
///
/// Re-uses pure domain evaluators. Soft coverage is never included — soft
/// never auto-applies and must not disable Save alone (GAP-UI-BUILD-08).
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// One hard block for pre-save / disable UX with plain-language [message].
class ComposeHardBlock {
  const ComposeHardBlock({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComposeHardBlock &&
        other.code == code &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(code, message);
}

/// Draft inputs for client hard evaluation (identity + kit + optional equip).
class ComposeHardBlockInput {
  const ComposeHardBlockInput({
    this.exoticWeaponHashes = const [],
    this.exoticArmorHashes = const [],
    this.aspectCount = 0,
    this.fragmentCount = 0,
    this.fragmentCapacity = 0,
    this.capacityResolved = true,
    this.synergyTypeCount = 1,
    this.isDefault = false,
    this.composeMissing = const [],
    this.requiredFailures = const [],
  });

  final List<int> exoticWeaponHashes;
  final List<int> exoticArmorHashes;
  final int aspectCount;
  final int fragmentCount;
  final int fragmentCapacity;
  final bool capacityResolved;

  /// When 0, emits NO_SYNERGY hard block (identity create/save).
  final int synergyTypeCount;

  /// When true, surface gate-1 compose gaps + gate-2 required as hard blocks.
  /// Non-default required failures stay soft (never disable Save alone).
  final bool isDefault;
  final List<String> composeMissing;
  final List<RequiredLinkFailure> requiredFailures;
}

/// Evaluate dual-exotic + subclass kit + synergy presence for client UX.
///
/// Domain remains authoritative on save; this only previews hard codes.
/// Soft coverage / non-default required never contribute to hard blocks.
List<ComposeHardBlock> evaluateComposeHardBlocks(ComposeHardBlockInput input) {
  final out = <ComposeHardBlock>[];

  final synergy = evaluateSynergyRequirement(
    List<Object?>.filled(input.synergyTypeCount, null),
  );
  for (final b in synergy.hardBlocks) {
    out.add(ComposeHardBlock(code: b.code, message: b.message));
  }

  final exotic = evaluateExoticLimits(
    ExoticComposition(
      exoticWeaponHashes: input.exoticWeaponHashes,
      exoticArmorHashes: input.exoticArmorHashes,
    ),
  );
  for (final b in exotic.hardBlocks) {
    out.add(ComposeHardBlock(code: b.code, message: b.message));
  }

  final kit = evaluateSubclassKit(
    SubclassKitEvalInput(
      aspectCount: input.aspectCount,
      fragmentCount: input.fragmentCount,
      fragmentCapacity: input.fragmentCapacity,
      capacityResolved: input.capacityResolved,
    ),
  );
  for (final b in kit.hardBlocks) {
    out.add(ComposeHardBlock(code: b.code, message: b.message));
  }

  if (input.isDefault) {
    if (input.composeMissing.isNotEmpty) {
      out.add(
        ComposeHardBlock(
          code: DomainFailureCodes.defaultVariantIncomplete,
          message:
              'Default loadout incomplete: ${input.composeMissing.join(', ')}',
        ),
      );
    }
    if (input.requiredFailures.isNotEmpty) {
      final names = input.requiredFailures
          .map((f) => f.displayName)
          .join(', ');
      out.add(
        ComposeHardBlock(
          code: DomainFailureCodes.requiredLinkUnsatisfied,
          message:
              'Required links need equip-ready pins or applied kit: $names',
        ),
      );
    }
  }

  return out;
}

/// Plain-language capacity caption for subclass kit composer (GAP-UI-BUILD-02).
String formatSubclassCapacityCaption({
  required int aspectCount,
  required int fragmentCount,
  required int fragmentCapacity,
  required bool capacityResolved,
  int maxAspects = maxSubclassAspects,
}) {
  final aspectLine =
      'Aspects: $aspectCount / $maxAspects (max $maxAspects)';
  if (!capacityResolved) {
    return '$aspectLine · Fragment capacity unknown (aspect data unresolved)';
  }
  final fragLine = 'Fragments: $fragmentCount / $fragmentCapacity';
  if (fragmentCount > fragmentCapacity) {
    return '$aspectLine · $fragLine — too many fragments for selected aspects';
  }
  if (aspectCount > maxAspects) {
    return '$aspectLine — too many aspects · $fragLine';
  }
  return '$aspectLine · $fragLine';
}

/// Whether Save should be disabled for hard blocks (soft never contributes).
bool composeSaveHardBlocked(List<ComposeHardBlock> blocks) => blocks.isNotEmpty;
