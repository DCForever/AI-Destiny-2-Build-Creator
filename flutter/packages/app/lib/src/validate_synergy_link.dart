import 'package:destiny2_domain/destiny2_domain.dart';

import 'errors.dart';
import 'synergy_use_cases.dart';

/// Structural validation for a synergy evidence link (BR-SYN-005).
///
/// Pure field-shape checks; manifest existence is optional via [hashKnown]
/// callbacks so hosts/tests can reject unknown hashes without IO in app core.
class SynergyLinkValidationResult {
  const SynergyLinkValidationResult.valid()
      : valid = true,
        reason = null;

  const SynergyLinkValidationResult.invalid(this.reason) : valid = false;

  final bool valid;
  final String? reason;
}

/// Optional manifest membership checks (return true when hash is known).
typedef HashKnown = bool Function(int hash);

/// Validate required fields (and optional hash membership) for [link].
SynergyLinkValidationResult validateSynergyLink(
  SynergyLinkWrite link, {
  HashKnown? weaponHashKnown,
  HashKnown? perkHashKnown,
  HashKnown? exoticArmorHashKnown,
  HashKnown? artifactPerkHashKnown,
  HashKnown? originTraitHashKnown,
}) {
  final kind = SynergyLinkKind.tryParse(link.kind);
  if (kind == null) {
    return SynergyLinkValidationResult.invalid(
      'unknown kind: ${link.kind}',
    );
  }
  if (link.displayName.trim().isEmpty) {
    return const SynergyLinkValidationResult.invalid(
      'displayName required',
    );
  }

  switch (kind) {
    case SynergyLinkKind.weapon:
      if (link.itemHash == null) {
        return const SynergyLinkValidationResult.invalid('itemHash required');
      }
      if (weaponHashKnown != null && !weaponHashKnown(link.itemHash!)) {
        return SynergyLinkValidationResult.invalid(
          'weapon hash ${link.itemHash} not found in manifest',
        );
      }
      return const SynergyLinkValidationResult.valid();

    case SynergyLinkKind.weaponPerk:
      if (link.perkHash == null) {
        return const SynergyLinkValidationResult.invalid('perkHash required');
      }
      if (perkHashKnown != null && !perkHashKnown(link.perkHash!)) {
        return SynergyLinkValidationResult.invalid(
          'perk hash ${link.perkHash} not found in manifest',
        );
      }
      return const SynergyLinkValidationResult.valid();

    case SynergyLinkKind.originTrait:
      if (link.originTraitName == null && link.originTraitHash == null) {
        return const SynergyLinkValidationResult.invalid(
          'originTraitName or originTraitHash required',
        );
      }
      if (link.originTraitHash != null &&
          originTraitHashKnown != null &&
          !originTraitHashKnown(link.originTraitHash!)) {
        return const SynergyLinkValidationResult.invalid(
          'origin trait not found in manifest',
        );
      }
      return const SynergyLinkValidationResult.valid();

    case SynergyLinkKind.armorSetBonus:
      if (link.armorSetName == null ||
          link.armorSetName!.trim().isEmpty ||
          link.bonusPieces == null ||
          link.bonusName == null ||
          link.bonusName!.trim().isEmpty) {
        return const SynergyLinkValidationResult.invalid(
          'armorSetName, bonusPieces, bonusName required',
        );
      }
      return const SynergyLinkValidationResult.valid();

    case SynergyLinkKind.exoticArmor:
      if (link.itemHash == null) {
        return const SynergyLinkValidationResult.invalid('itemHash required');
      }
      if (exoticArmorHashKnown != null &&
          !exoticArmorHashKnown(link.itemHash!)) {
        return SynergyLinkValidationResult.invalid(
          'exotic armor hash ${link.itemHash} not found in manifest',
        );
      }
      return const SynergyLinkValidationResult.valid();

    case SynergyLinkKind.artifactPerk:
      if (link.perkHash == null) {
        return const SynergyLinkValidationResult.invalid('perkHash required');
      }
      if (artifactPerkHashKnown != null &&
          !artifactPerkHashKnown(link.perkHash!)) {
        return SynergyLinkValidationResult.invalid(
          'artifact perk hash ${link.perkHash} not found in manifest',
        );
      }
      return const SynergyLinkValidationResult.valid();
  }
}

/// Throw [UseCaseException] with [UseCaseErrorCode.invalidSynergyLink] when invalid.
///
/// Unknown kinds are skipped so callers can map them to
/// [UseCaseErrorCode.invalidSynergyLinkKind] first.
void assertSynergyLinksValid(
  List<SynergyLinkWrite> links, {
  HashKnown? weaponHashKnown,
  HashKnown? perkHashKnown,
  HashKnown? exoticArmorHashKnown,
  HashKnown? artifactPerkHashKnown,
  HashKnown? originTraitHashKnown,
}) {
  for (final link in links) {
    if (SynergyLinkKind.tryParse(link.kind) == null) continue;
    final r = validateSynergyLink(
      link,
      weaponHashKnown: weaponHashKnown,
      perkHashKnown: perkHashKnown,
      exoticArmorHashKnown: exoticArmorHashKnown,
      artifactPerkHashKnown: artifactPerkHashKnown,
      originTraitHashKnown: originTraitHashKnown,
    );
    if (!r.valid) {
      throw UseCaseException(
        UseCaseErrorCode.invalidSynergyLink,
        r.reason ?? 'Invalid synergy link',
        details: {
          'kind': link.kind,
          'displayName': link.displayName,
          if (link.itemHash != null) 'itemHash': link.itemHash,
          if (link.perkHash != null) 'perkHash': link.perkHash,
        },
      );
    }
  }
}
