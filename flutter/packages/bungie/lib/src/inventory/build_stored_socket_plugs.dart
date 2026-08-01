// Next parity: `src/lib/inventory/instances/buildStoredSocketPlugs.ts` (DART-052).

import '../profile/profile_types.dart';
import 'classify_weapon_socket.dart';

/// Per-socket capture persisted on `inventory_items.socket_plugs`.
class StoredSocketPlug {
  const StoredSocketPlug({
    required this.socketIndex,
    required this.equippedPlugHash,
    required this.reusablePlugHashes,
    required this.columnKind,
    required this.columnLabel,
  });

  final int socketIndex;
  final int equippedPlugHash;
  final List<int> reusablePlugHashes;
  final SocketColumnKind columnKind;
  final String columnLabel;

  Map<String, Object?> toJsonMap() => {
        'socketIndex': socketIndex,
        'equippedPlugHash': equippedPlugHash,
        'reusablePlugHashes': reusablePlugHashes,
        'columnKind': socketColumnKindWire(columnKind),
        'columnLabel': columnLabel,
      };

  static StoredSocketPlug? tryFromJsonMap(Map<String, Object?> map) {
    final socketIndex = map['socketIndex'];
    final equipped = map['equippedPlugHash'];
    final kind = socketColumnKindFromWire(map['columnKind'] as String?);
    if (socketIndex is! int || equipped is! int || kind == null) return null;
    final reusableRaw = map['reusablePlugHashes'];
    final reusable = <int>[];
    if (reusableRaw is List) {
      for (final e in reusableRaw) {
        if (e is int) {
          reusable.add(e);
        } else if (e is num) {
          reusable.add(e.toInt());
        }
      }
    }
    return StoredSocketPlug(
      socketIndex: socketIndex,
      equippedPlugHash: equipped,
      reusablePlugHashes: reusable,
      columnKind: kind,
      columnLabel: (map['columnLabel'] as String?) ?? '',
    );
  }
}

/// Capture readiness for instance perk grids (Next `deriveCaptureStatus`).
enum PerkCaptureStatus {
  complete,
  pending,
  unavailable,
}

/// Build categorized stored plugs for weapons from raw socket capture + context.
List<StoredSocketPlug> buildStoredSocketPlugs({
  required List<RawSocketCapture> socketCapture,
  required Map<int, String> plugCategoryByHash,
  Map<int, String>? plugItemTypeByHash,
  required List<int> weaponPerkSocketIndexes,
}) {
  final result = <StoredSocketPlug>[];

  for (final row in socketCapture) {
    final classified = classifyWeaponSocket(
      socketIndex: row.socketIndex,
      equippedPlugHash: row.equippedPlugHash,
      plugCategoryByHash: plugCategoryByHash,
      plugItemTypeByHash: plugItemTypeByHash,
      weaponPerkSocketIndexes: weaponPerkSocketIndexes,
    );

    if (!classified.includeInGrid) continue;

    final reusable = <int>{
      row.equippedPlugHash,
      ...row.reusablePlugHashes,
    }.toList(growable: false);

    result.add(
      StoredSocketPlug(
        socketIndex: row.socketIndex,
        equippedPlugHash: row.equippedPlugHash,
        reusablePlugHashes: reusable,
        columnKind: classified.columnKind,
        columnLabel: classified.columnLabel,
      ),
    );
  }

  return result;
}

/// Derive capture status from stored plugs (null = pending).
PerkCaptureStatus deriveCaptureStatus(
  List<StoredSocketPlug>? socketPlugs,
) {
  if (socketPlugs == null) return PerkCaptureStatus.pending;
  if (socketPlugs.isEmpty) return PerkCaptureStatus.unavailable;
  return PerkCaptureStatus.complete;
}

/// Same as [deriveCaptureStatus] for raw JSON maps (Drift rows).
PerkCaptureStatus deriveCaptureStatusFromMaps(
  List<Map<String, Object?>>? socketPlugs,
) {
  if (socketPlugs == null) return PerkCaptureStatus.pending;
  if (socketPlugs.isEmpty) return PerkCaptureStatus.unavailable;
  return PerkCaptureStatus.complete;
}
