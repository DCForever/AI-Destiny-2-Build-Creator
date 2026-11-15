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

/// Clear message when the target character bucket is full (no auto make-room).
const String kNoRoomOnCharacterMessage = 'No room on character';
