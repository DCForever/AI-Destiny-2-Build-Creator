/// Common Bungie [PlatformErrorCodes] used by apply / equip paths.
///
/// Prefer [errorStatusName] for user-visible status text (e.g.
/// `DestinyItemNotFound`) — never dump raw response bodies.
library;

/// Success.
const int kPlatformErrorSuccess = 1;

/// Item instance not found on the account / character.
const int kDestinyItemNotFound = 1623;

/// Character inventory is full.
const int kDestinyInventoryFull = 1637;

/// Item cannot be unequipped (often locked-equipment activity).
const int kDestinyItemUnequippable = 1640;

/// Destination bucket has no free space.
const int kDestinyNoRoomInDestination = 1642;

/// Character is in an activity where inventory actions are blocked.
const int kDestinyCannotPerformActionAtThisLocation = 1671;

/// Known code → ErrorStatus-style name for UI rows.
const Map<int, String> kPlatformErrorStatusNames = {
  kPlatformErrorSuccess: 'Success',
  kDestinyItemNotFound: 'DestinyItemNotFound',
  kDestinyInventoryFull: 'DestinyInventoryFull',
  kDestinyItemUnequippable: 'DestinyItemUnequippable',
  kDestinyNoRoomInDestination: 'DestinyNoRoomInDestination',
  kDestinyCannotPerformActionAtThisLocation:
      'DestinyCannotPerformActionAtThisLocation',
};

/// User-facing status label for a platform error code.
///
/// Returns a known ErrorStatus name when mapped; otherwise `ErrorCode N`.
String errorStatusName(int code, {String? errorStatus}) {
  final fromEnvelope = errorStatus?.trim();
  if (fromEnvelope != null && fromEnvelope.isNotEmpty) {
    return fromEnvelope;
  }
  return kPlatformErrorStatusNames[code] ?? 'ErrorCode $code';
}

/// True when further equips on this character cannot succeed (DIM parity).
bool isEquipNotPossibleErrorCode(int code) {
  return code == kDestinyCannotPerformActionAtThisLocation ||
      code == kDestinyItemUnequippable;
}

/// Clear message when the guardian is in an activity.
const String kInActivityEquipMessage =
    'You are in an activity; equip from orbit or a social space';

/// Clear message when the target character bucket is full and make-room cannot
/// free a slot (no eligible unequipped non-plan item, or vault full).
///
/// Prefer [kCharacterSlotFullNoUnlockedItemMessage] when the bucket is full and
/// every candidate is locked / equipped / non-transferable (nothing was moved).
const String kNoRoomOnCharacterMessage = 'No room on character';

/// Character equipment bucket is full and no unlocked, unequipped item can move.
const String kCharacterSlotFullNoUnlockedItemMessage =
    'Character slot full; no unlocked item to move';

/// Vault cannot accept another transfer (including make-room eviction).
///
/// Capacity gate uses [kApplyVaultCapacity] in the app package (Bungie vault
/// size as of Update 9.7.0 — see that constant's doc comment).
const String kNoRoomInVaultMessage = 'No room in vault';

/// To-vault hop succeeded but vault→character failed after make-room attempts.
const String kMovedToVaultStuckMessage =
    'Moved to vault; could not move to character';

/// Pin itemHash does not match the live instance.
const String kItemHashMismatchMessage =
    'Pinned item does not match inventory';

/// Generic apply failure — never surface Exception.toString() / tokens.
const String kGenericApplyFailureMessage = 'Apply failed';

/// Fixed-text failure after make-room retries still cannot free a character slot.
String kMakeRoomStillFullMessage(String itemLabel) =>
    'No room on character for $itemLabel: tried to free a slot, still full';

/// Outcome-row text when an unequipped item was moved to vault to free a slot.
String kMakeRoomMovedToVaultMessage(String evicteeName) =>
    'Moved $evicteeName to vault to make room';

/// Needed item is equipped on another character and no valid replacement exists
/// (non-exotic, same bucket, class-compatible, on that character or vault).
const String kCannotUnequipOnOtherCharacterMessage =
    'Cannot unequip on other character: no valid non-exotic replacement';

/// Side-effect row: an item was transferred during Apply.
String kApplyMovedItemMessage(String name, String from, String to) =>
    'Moved $name from $from to $to';

/// Side-effect row: a replacement was equipped on another character to free a pin.
String kApplyEquippedOnOtherCharacterMessage(
  String name,
  String characterId,
) =>
    'Equipped $name on character $characterId';

/// True for Bungie codes that mean the destination inventory/bucket is full.
bool isNoRoomInDestinationErrorCode(int code) {
  return code == kDestinyNoRoomInDestination || code == kDestinyInventoryFull;
}

/// Fixed HTTP failure text for apply rows (auth-style; no body/snippet).
String bungieHttpFailureMessage(int statusCode) =>
    'Bungie request failed (HTTP $statusCode)';

/// Destiny inventory tierType / gearTier value for Exotic.
const int kDestinyExoticTier = 6;

/// True when gearTier or definition tierType marks the item exotic.
bool isExoticTier({int? gearTier, int? tierType}) {
  return gearTier == kDestinyExoticTier || tierType == kDestinyExoticTier;
}
